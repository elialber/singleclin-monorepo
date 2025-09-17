#!/bin/bash

# SingleClin - Production Credentials Retrieval Script
# This script retrieves production secrets from Azure Key Vault

set -e

# Configuration
RESOURCE_GROUP="singleclin-prod-rg"
KEY_VAULT="singleclin-kv-prod"
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

print_secret() {
    echo -e "${BLUE}[SECRET]${NC} $1"
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

    # Check if Key Vault exists
    if ! az keyvault show --name "$KEY_VAULT" &> /dev/null; then
        print_error "Key Vault '$KEY_VAULT' not found. Please run create-infrastructure.sh first."
        exit 1
    fi
}

# Get a specific secret
get_secret() {
    local secret_name=$1
    local description=$2

    print_status "Retrieving $description..."

    if az keyvault secret show --name "$secret_name" --vault-name "$KEY_VAULT" --query value -o tsv &> /dev/null; then
        local secret_value=$(az keyvault secret show --name "$secret_name" --vault-name "$KEY_VAULT" --query value -o tsv)
        print_secret "$description: $secret_value"
    else
        print_warning "$description not found in Key Vault"
    fi
    echo ""
}

# List all secrets
list_all_secrets() {
    print_status "Listing all secrets in Key Vault: $KEY_VAULT"
    echo ""

    get_secret "database-connection-string" "Database Connection String"
    get_secret "redis-connection-string" "Redis Connection String"
    get_secret "azure-storage-connection-string" "Azure Storage Connection String"
    get_secret "jwt-secret-key" "JWT Secret Key"
    get_secret "firebase-service-account" "Firebase Service Account"
}

# Get connection strings for local development
get_local_dev_strings() {
    print_status "Getting connection strings for local development..."
    echo ""

    print_status "Add these to your local .env files:"
    echo ""

    # Database
    if db_conn=$(az keyvault secret show --name "database-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null); then
        echo "DATABASE_CONNECTION_STRING=\"$db_conn\""
    fi

    # Redis
    if redis_conn=$(az keyvault secret show --name "redis-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null); then
        echo "REDIS_CONNECTION_STRING=\"$redis_conn\""
    fi

    # Storage
    if storage_conn=$(az keyvault secret show --name "azure-storage-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null); then
        echo "AZURE_STORAGE_CONNECTION_STRING=\"$storage_conn\""
    fi

    # JWT
    if jwt_secret=$(az keyvault secret show --name "jwt-secret-key" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null); then
        echo "JWT_SECRET_KEY=\"$jwt_secret\""
    fi

    # Firebase
    if firebase_config=$(az keyvault secret show --name "firebase-service-account" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null); then
        echo "FIREBASE_SERVICE_ACCOUNT='$firebase_config'"
    fi

}

# Update a secret
update_secret() {
    local secret_name=$1
    local secret_value=$2

    if [ -z "$secret_name" ] || [ -z "$secret_value" ]; then
        print_error "Usage: update_secret <secret_name> <secret_value>"
        return 1
    fi

    print_status "Updating secret: $secret_name"
    az keyvault secret set --vault-name "$KEY_VAULT" --name "$secret_name" --value "$secret_value" --output table
    print_status "Secret updated successfully"
}

# Create env file for local development
create_env_file() {
    local env_file_path=${1:-".env.local"}

    print_status "Creating environment file: $env_file_path"

    cat > "$env_file_path" << EOF
# SingleClin Local Development Environment Variables
# Retrieved from Azure Key Vault: $KEY_VAULT
# Generated on: $(date)

# Database
DATABASE_CONNECTION_STRING="$(az keyvault secret show --name "database-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null || echo 'NOT_FOUND')"

# Redis Cache
REDIS_CONNECTION_STRING="$(az keyvault secret show --name "redis-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null || echo 'NOT_FOUND')"

# Azure Storage
AZURE_STORAGE_CONNECTION_STRING="$(az keyvault secret show --name "azure-storage-connection-string" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null || echo 'NOT_FOUND')"

# JWT Configuration
JWT_SECRET_KEY="$(az keyvault secret show --name "jwt-secret-key" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null || echo 'NOT_FOUND')"

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT='$(az keyvault secret show --name "firebase-service-account" --vault-name "$KEY_VAULT" --query value -o tsv 2>/dev/null || echo 'NOT_FOUND')'

# SendGrid Configuration - Not used in this project
# SENDGRID_API_KEY="not-configured"

# Azure Key Vault (for Container Apps)
AZURE_KEY_VAULT_URL="https://$KEY_VAULT.vault.azure.net/"
EOF

    print_status "Environment file created: $env_file_path"
    print_warning "Make sure to add $env_file_path to .gitignore!"
}

# Show help
show_help() {
    echo "SingleClin Production Credentials Management"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list                    List all secrets from Key Vault"
    echo "  local                   Show connection strings for local development"
    echo "  create-env [file]       Create .env file for local development (default: .env.local)"
    echo "  get <secret-name>       Get a specific secret value"
    echo "  update <name> <value>   Update a secret value"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 local"
    echo "  $0 create-env .env.production"
    echo "  $0 get database-connection-string"
    echo "  $0 update sendgrid-api-key 'SG.newkey'"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and logged in"
    echo "  - Access to Key Vault: $KEY_VAULT"
}

# Main execution
main() {
    local command=${1:-"list"}

    case $command in
        "list")
            check_prerequisites
            list_all_secrets
            ;;
        "local")
            check_prerequisites
            get_local_dev_strings
            ;;
        "create-env")
            check_prerequisites
            create_env_file "$2"
            ;;
        "get")
            if [ -z "$2" ]; then
                print_error "Secret name required. Usage: $0 get <secret-name>"
                exit 1
            fi
            check_prerequisites
            get_secret "$2" "$2"
            ;;
        "update")
            if [ -z "$2" ] || [ -z "$3" ]; then
                print_error "Secret name and value required. Usage: $0 update <name> <value>"
                exit 1
            fi
            check_prerequisites
            update_secret "$2" "$3"
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