#!/bin/bash

# SingleClin - Key Vault Setup and Management Script
# This script helps manage Key Vault secrets and access policies

set -e

# Configuration
RESOURCE_GROUP="singleclin-prod-rg"
KEY_VAULT="singleclin-kv-prod"
APP_NAME="singleclin"
ENVIRONMENT="prod"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
}

# Setup Firebase service account secret
setup_firebase_secret() {
    local firebase_file=${1:-"firebase-service-account.json"}

    if [ ! -f "$firebase_file" ]; then
        print_error "Firebase service account file not found: $firebase_file"
        print_status "Please download your Firebase service account JSON file and run:"
        print_status "$0 firebase /path/to/firebase-service-account.json"
        return 1
    fi

    print_status "Setting up Firebase service account secret..."

    # Read the JSON file and store it as a secret
    firebase_content=$(cat "$firebase_file")
    az keyvault secret set \
        --vault-name "$KEY_VAULT" \
        --name "firebase-service-account" \
        --value "$firebase_content" \
        --output table

    print_status "Firebase service account secret updated successfully"
}

# SendGrid removed - not used in this project

# Setup access policy for a service principal (for GitHub Actions)
setup_github_access() {
    local service_principal_id=$1

    if [ -z "$service_principal_id" ]; then
        print_error "Service principal ID required"
        print_status "Usage: $0 github-access <service-principal-object-id>"
        return 1
    fi

    print_status "Setting up GitHub Actions access to Key Vault..."

    az keyvault set-policy \
        --name "$KEY_VAULT" \
        --object-id "$service_principal_id" \
        --secret-permissions get list \
        --output table

    print_status "GitHub Actions access configured successfully"
}

# Setup access policy for Container Apps managed identity
setup_container_apps_access() {
    local managed_identity_name="${APP_NAME}-${ENVIRONMENT}-identity"

    print_status "Setting up Container Apps managed identity access..."

    # Get the principal ID of the managed identity
    principal_id=$(az identity show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$managed_identity_name" \
        --query principalId -o tsv)

    if [ -z "$principal_id" ]; then
        print_error "Managed identity not found: $managed_identity_name"
        print_status "Please run create-infrastructure.sh first"
        return 1
    fi

    az keyvault set-policy \
        --name "$KEY_VAULT" \
        --object-id "$principal_id" \
        --secret-permissions get list \
        --output table

    print_status "Container Apps managed identity access configured successfully"
}

# List all access policies
list_access_policies() {
    print_status "Current Key Vault access policies:"

    az keyvault show \
        --name "$KEY_VAULT" \
        --query "properties.accessPolicies[].{ObjectId:objectId, Permissions:permissions}" \
        --output table
}

# Validate all required secrets exist
validate_secrets() {
    print_status "Validating all required secrets exist in Key Vault..."

    local required_secrets=(
        "database-connection-string"
        "redis-connection-string"
        "azure-storage-connection-string"
        "jwt-secret-key"
        "firebase-service-account"
    )

    local missing_secrets=()

    for secret in "${required_secrets[@]}"; do
        if az keyvault secret show --name "$secret" --vault-name "$KEY_VAULT" --query value -o tsv &> /dev/null; then
            print_status "✓ $secret"
        else
            print_warning "✗ $secret (missing)"
            missing_secrets+=("$secret")
        fi
    done

    if [ ${#missing_secrets[@]} -eq 0 ]; then
        print_status "All required secrets are present!"
    else
        print_warning "Missing secrets: ${missing_secrets[*]}"
        print_status "You may need to run setup commands or create-infrastructure.sh"
    fi
}

# Backup all secrets to a JSON file
backup_secrets() {
    local backup_file=${1:-"keyvault-backup-$(date +%Y%m%d-%H%M%S).json"}

    print_status "Backing up all secrets to: $backup_file"

    # Get all secret names
    secret_names=$(az keyvault secret list --vault-name "$KEY_VAULT" --query "[].name" -o tsv)

    echo "{" > "$backup_file"
    echo "  \"vault_name\": \"$KEY_VAULT\"," >> "$backup_file"
    echo "  \"backup_date\": \"$(date -Iseconds)\"," >> "$backup_file"
    echo "  \"secrets\": {" >> "$backup_file"

    first=true
    for secret_name in $secret_names; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$backup_file"
        fi

        secret_value=$(az keyvault secret show --name "$secret_name" --vault-name "$KEY_VAULT" --query value -o tsv)
        # Escape quotes and newlines for JSON
        escaped_value=$(echo "$secret_value" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
        echo -n "    \"$secret_name\": \"$escaped_value\"" >> "$backup_file"
    done

    echo "" >> "$backup_file"
    echo "  }" >> "$backup_file"
    echo "}" >> "$backup_file"

    print_status "Backup completed: $backup_file"
    print_warning "Keep this file secure - it contains sensitive data!"
}

# Show help
show_help() {
    echo "SingleClin Key Vault Setup and Management"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  firebase <json-file>           Setup Firebase service account secret"
    echo ""
    echo "  github-access <principal-id>   Setup GitHub Actions access policy"
    echo "  container-apps-access         Setup Container Apps managed identity access"
    echo "  list-policies                 List all access policies"
    echo "  validate                      Validate all required secrets exist"
    echo "  backup [file]                 Backup all secrets to JSON file"
    echo "  help                          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 firebase ./firebase-service-account.json"
    echo ""
    echo "  $0 github-access 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'"
    echo "  $0 container-apps-access"
    echo "  $0 validate"
    echo "  $0 backup"
    echo ""
}

# Main execution
main() {
    local command=${1:-"help"}

    case $command in
        "firebase")
            check_prerequisites
            setup_firebase_secret "$2"
            ;;
        "github-access")
            check_prerequisites
            setup_github_access "$2"
            ;;
        "container-apps-access")
            check_prerequisites
            setup_container_apps_access
            ;;
        "list-policies")
            check_prerequisites
            list_access_policies
            ;;
        "validate")
            check_prerequisites
            validate_secrets
            ;;
        "backup")
            check_prerequisites
            backup_secrets "$2"
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