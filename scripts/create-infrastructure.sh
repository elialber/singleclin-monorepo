#!/bin/bash

# SingleClin - Azure Infrastructure Creation Script
# This script creates all necessary Azure resources for the SingleClin application

set -e

# Configuration
RESOURCE_GROUP="singleclin-prod-rg"
LOCATION="East US"
SUBSCRIPTION_ID=""  # Set your subscription ID
APP_NAME="singleclin"
ENVIRONMENT="prod"

# Derived names
CONTAINER_REGISTRY="${APP_NAME}${ENVIRONMENT}acr"
KEY_VAULT="${APP_NAME}-kv-${ENVIRONMENT}"
POSTGRES_SERVER="${APP_NAME}-${ENVIRONMENT}-postgres"
REDIS_CACHE="${APP_NAME}-${ENVIRONMENT}-redis"
STORAGE_ACCOUNT="${APP_NAME}${ENVIRONMENT}storage"
CONTAINER_APPS_ENV="${APP_NAME}-${ENVIRONMENT}-env"
LOG_ANALYTICS="${APP_NAME}-${ENVIRONMENT}-logs"

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

# Check if Azure CLI is installed and logged in
check_prerequisites() {
    print_status "Checking prerequisites..."

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
    print_status "Using subscription: $SUBSCRIPTION_ID"
}

# Create Resource Group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP"
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output table
}

# Create Log Analytics Workspace
create_log_analytics() {
    print_status "Creating Log Analytics workspace: $LOG_ANALYTICS"
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$LOG_ANALYTICS" \
        --location "$LOCATION" \
        --output table
}

# Create Container Registry
create_container_registry() {
    print_status "Creating Azure Container Registry: $CONTAINER_REGISTRY"
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CONTAINER_REGISTRY" \
        --sku Basic \
        --admin-enabled true \
        --location "$LOCATION" \
        --output table
}

# Create Key Vault
create_key_vault() {
    print_status "Creating Azure Key Vault: $KEY_VAULT"

    # Get current user object ID for Key Vault access
    USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

    az keyvault create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$KEY_VAULT" \
        --location "$LOCATION" \
        --sku standard \
        --enabled-for-deployment true \
        --enabled-for-template-deployment true \
        --output table

    # Set access policy for current user
    az keyvault set-policy \
        --name "$KEY_VAULT" \
        --object-id "$USER_OBJECT_ID" \
        --secret-permissions all \
        --key-permissions all \
        --certificate-permissions all \
        --output table
}

# Create PostgreSQL Flexible Server
create_postgresql() {
    print_status "Creating PostgreSQL Flexible Server: $POSTGRES_SERVER"

    # Generate a random password
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

    az postgres flexible-server create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$POSTGRES_SERVER" \
        --location "$LOCATION" \
        --admin-user "singleclinadmin" \
        --admin-password "$DB_PASSWORD" \
        --sku-name "Standard_B1ms" \
        --tier "Burstable" \
        --storage-size 32 \
        --version 15 \
        --public-access 0.0.0.0 \
        --output table

    # Create the application database
    az postgres flexible-server db create \
        --resource-group "$RESOURCE_GROUP" \
        --server-name "$POSTGRES_SERVER" \
        --database-name "singleclin" \
        --output table

    # Store connection string in Key Vault
    CONNECTION_STRING="Host=${POSTGRES_SERVER}.postgres.database.azure.com;Database=singleclin;Username=singleclinadmin;Password=${DB_PASSWORD};SslMode=Require"
    az keyvault secret set \
        --vault-name "$KEY_VAULT" \
        --name "database-connection-string" \
        --value "$CONNECTION_STRING" \
        --output table

    print_status "Database password stored in Key Vault"
}

# Create Redis Cache
create_redis() {
    print_status "Creating Azure Cache for Redis: $REDIS_CACHE"

    az redis create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$REDIS_CACHE" \
        --location "$LOCATION" \
        --sku Basic \
        --vm-size c0 \
        --output table

    # Get Redis connection string and store in Key Vault
    print_status "Retrieving Redis connection string..."
    REDIS_KEY=$(az redis list-keys --resource-group "$RESOURCE_GROUP" --name "$REDIS_CACHE" --query primaryKey -o tsv)
    REDIS_CONNECTION_STRING="${REDIS_CACHE}.redis.cache.windows.net:6380,password=${REDIS_KEY},ssl=True,abortConnect=False"

    az keyvault secret set \
        --vault-name "$KEY_VAULT" \
        --name "redis-connection-string" \
        --value "$REDIS_CONNECTION_STRING" \
        --output table
}

# Create Storage Account
create_storage() {
    print_status "Creating Storage Account: $STORAGE_ACCOUNT"

    az storage account create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --output table

    # Get storage connection string and store in Key Vault
    STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query connectionString -o tsv)

    az keyvault secret set \
        --vault-name "$KEY_VAULT" \
        --name "azure-storage-connection-string" \
        --value "$STORAGE_CONNECTION_STRING" \
        --output table

    # Create blob containers
    az storage container create \
        --name "clinic-images" \
        --connection-string "$STORAGE_CONNECTION_STRING" \
        --public-access off \
        --output table

    az storage container create \
        --name "user-documents" \
        --connection-string "$STORAGE_CONNECTION_STRING" \
        --public-access off \
        --output table
}

# Create Container Apps Environment
create_container_apps_env() {
    print_status "Creating Container Apps Environment: $CONTAINER_APPS_ENV"

    # Get Log Analytics workspace ID and key
    LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$LOG_ANALYTICS" \
        --query customerId -o tsv)

    LOG_ANALYTICS_KEY=$(az monitor log-analytics workspace get-shared-keys \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$LOG_ANALYTICS" \
        --query primarySharedKey -o tsv)

    az containerapp env create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CONTAINER_APPS_ENV" \
        --location "$LOCATION" \
        --logs-workspace-id "$LOG_ANALYTICS_WORKSPACE_ID" \
        --logs-workspace-key "$LOG_ANALYTICS_KEY" \
        --output table
}

# Create Managed Identity for Container Apps
create_managed_identity() {
    print_status "Creating Managed Identity for Container Apps"

    MANAGED_IDENTITY="${APP_NAME}-${ENVIRONMENT}-identity"

    az identity create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$MANAGED_IDENTITY" \
        --location "$LOCATION" \
        --output table

    # Get the principal ID
    PRINCIPAL_ID=$(az identity show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$MANAGED_IDENTITY" \
        --query principalId -o tsv)

    # Grant Key Vault access to the managed identity
    az keyvault set-policy \
        --name "$KEY_VAULT" \
        --object-id "$PRINCIPAL_ID" \
        --secret-permissions get list \
        --output table

    print_status "Managed Identity created and granted Key Vault access"
}

# Create placeholder secrets in Key Vault
create_placeholder_secrets() {
    print_status "Creating placeholder secrets in Key Vault"

    # JWT Secret
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "\n")
    az keyvault secret set --vault-name "$KEY_VAULT" --name "jwt-secret-key" --value "$JWT_SECRET" --output none

    # Firebase (placeholder - needs to be updated manually)
    az keyvault secret set --vault-name "$KEY_VAULT" --name "firebase-service-account" --value '{"placeholder": "update_with_real_firebase_config"}' --output none

    print_status "Placeholder secrets created. Remember to update Firebase secrets manually if needed."
}

# Main execution
main() {
    print_status "Starting SingleClin Azure infrastructure creation..."

    check_prerequisites
    create_resource_group
    create_log_analytics
    create_container_registry
    create_key_vault
    create_postgresql
    create_redis
    create_storage
    create_container_apps_env
    create_managed_identity
    create_placeholder_secrets

    print_status "Infrastructure creation completed successfully!"

    # Output summary
    echo ""
    echo "=== INFRASTRUCTURE SUMMARY ==="
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Container Registry: $CONTAINER_REGISTRY"
    echo "Key Vault: $KEY_VAULT"
    echo "PostgreSQL Server: $POSTGRES_SERVER"
    echo "Redis Cache: $REDIS_CACHE"
    echo "Storage Account: $STORAGE_ACCOUNT"
    echo "Container Apps Environment: $CONTAINER_APPS_ENV"
    echo "Managed Identity: ${APP_NAME}-${ENVIRONMENT}-identity"
    echo ""
    print_warning "IMPORTANT: Update Firebase secrets in Key Vault manually!"
    print_warning "Run './get-production-credentials.sh' to retrieve connection strings."
}

# Run main function
main "$@"