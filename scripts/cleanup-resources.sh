#!/bin/bash

# SingleClin - Azure Resources Cleanup Script
# This script removes all Azure resources created for SingleClin

set -e

# Configuration
RESOURCE_GROUP="singleclin-prod-rg"
SUBSCRIPTION_ID=""  # Set your subscription ID

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi

    if ! az account show &> /dev/null; then
        print_error "Please login to Azure CLI first: az login"
        exit 1
    fi

    if [ -z "$SUBSCRIPTION_ID" ]; then
        print_error "Please set SUBSCRIPTION_ID in this script"
        exit 1
    fi

    az account set --subscription "$SUBSCRIPTION_ID"
}

# Confirm deletion
confirm_deletion() {
    print_warning "This will DELETE ALL Azure resources for SingleClin!"
    print_warning "Resource Group: $RESOURCE_GROUP"
    print_warning "This action CANNOT be undone!"
    echo ""

    read -p "Are you absolutely sure you want to continue? (type 'DELETE' to confirm): " confirmation

    if [ "$confirmation" != "DELETE" ]; then
        print_status "Cleanup cancelled."
        exit 0
    fi
}

# List resources before deletion
list_resources() {
    print_status "Current resources in $RESOURCE_GROUP:"

    if az group exists --name "$RESOURCE_GROUP"; then
        az resource list --resource-group "$RESOURCE_GROUP" --output table
    else
        print_warning "Resource group $RESOURCE_GROUP does not exist"
    fi

    echo ""
}

# Delete resource group and all resources
cleanup_all_resources() {
    print_status "Deleting resource group and all resources: $RESOURCE_GROUP"

    if az group exists --name "$RESOURCE_GROUP"; then
        print_status "Starting deletion... this may take several minutes"

        az group delete \
            --name "$RESOURCE_GROUP" \
            --yes \
            --no-wait

        print_status "Deletion initiated. Resources are being removed in the background."
        print_status "You can check the status in the Azure Portal or run:"
        print_status "az group show --name '$RESOURCE_GROUP' --query 'properties.provisioningState'"
    else
        print_warning "Resource group $RESOURCE_GROUP does not exist"
    fi
}

# Wait for deletion to complete
wait_for_deletion() {
    print_status "Waiting for deletion to complete..."

    while az group exists --name "$RESOURCE_GROUP" 2>/dev/null; do
        print_status "Still deleting... (waiting 30 seconds)"
        sleep 30
    done

    print_status "All resources have been successfully deleted!"
}

# Show help
show_help() {
    echo "SingleClin Azure Resources Cleanup"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  list          List current resources (without deleting)"
    echo "  cleanup       Delete all resources (with confirmation)"
    echo "  cleanup-wait  Delete all resources and wait for completion"
    echo "  help          Show this help message"
    echo ""
    echo "DANGER: This will delete ALL resources in the resource group!"
    echo ""
}

# Main execution
main() {
    local command=${1:-"help"}

    case $command in
        "list")
            check_prerequisites
            list_resources
            ;;
        "cleanup")
            check_prerequisites
            list_resources
            confirm_deletion
            cleanup_all_resources
            ;;
        "cleanup-wait")
            check_prerequisites
            list_resources
            confirm_deletion
            cleanup_all_resources
            wait_for_deletion
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"