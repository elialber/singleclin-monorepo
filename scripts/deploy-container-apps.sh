#!/bin/bash

# SingleClin - Container Apps Deployment Script
# This script deploys applications to Azure Container Apps

set -e

# Configuration
RESOURCE_GROUP="singleclin-prod-rg"
SUBSCRIPTION_ID=""  # Set your subscription ID
CONTAINER_REGISTRY="singleclinprodacr"
CONTAINER_APPS_ENV="singleclin-prod-env"
BACKEND_APP_NAME="singleclin-backend"
FRONTEND_APP_NAME="singleclin-frontend"

# Image tags (default to latest)
BACKEND_IMAGE_TAG="${BACKEND_IMAGE_TAG:-latest}"
FRONTEND_IMAGE_TAG="${FRONTEND_IMAGE_TAG:-latest}"

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

# Get managed identity resource ID
get_managed_identity_id() {
    local identity_name="singleclin-prod-identity"
    local identity_id

    print_status "Getting managed identity resource ID..."

    identity_id=$(az identity show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$identity_name" \
        --query id -o tsv)

    if [ -z "$identity_id" ]; then
        print_error "Managed identity not found: $identity_name"
        exit 1
    fi

    echo "$identity_id"
}

# Deploy backend container app
deploy_backend() {
    local identity_id=$1
    local image_name="${CONTAINER_REGISTRY}.azurecr.io/singleclin-backend:${BACKEND_IMAGE_TAG}"

    print_status "Deploying backend container app..."
    print_status "Image: $image_name"

    # Check if container app exists
    if az containerapp show --resource-group "$RESOURCE_GROUP" --name "$BACKEND_APP_NAME" >/dev/null 2>&1; then
        print_status "Updating existing container app: $BACKEND_APP_NAME"

        az containerapp update \
            --resource-group "$RESOURCE_GROUP" \
            --name "$BACKEND_APP_NAME" \
            --image "$image_name" \
            --output table
    else
        print_status "Creating new container app: $BACKEND_APP_NAME"

        az containerapp create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$BACKEND_APP_NAME" \
            --environment "$CONTAINER_APPS_ENV" \
            --image "$image_name" \
            --registry-server "${CONTAINER_REGISTRY}.azurecr.io" \
            --registry-identity "$identity_id" \
            --target-port 8080 \
            --ingress external \
            --min-replicas 0 \
            --max-replicas 3 \
            --cpu 1.0 \
            --memory 2Gi \
            --user-assigned "$identity_id" \
            --env-vars \
                ASPNETCORE_ENVIRONMENT=Production \
                ASPNETCORE_URLS=http://+:8080 \
                "AzureKeyVault__VaultUrl=https://singleclin-kv-prod.vault.azure.net/" \
                "AzureKeyVault__UseMangedIdentity=true" \
                "Logging__LogLevel__Default=Information" \
                "Logging__LogLevel__Microsoft=Warning" \
                "Logging__LogLevel__Azure=Warning" \
                "HealthChecks__Enabled=true" \
            --output table
    fi

    # Get the FQDN
    local backend_fqdn=$(az containerapp show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BACKEND_APP_NAME" \
        --query 'properties.configuration.ingress.fqdn' -o tsv)

    print_status "Backend deployed successfully!"
    print_status "Backend URL: https://$backend_fqdn"

    echo "$backend_fqdn"
}

# Deploy frontend container app
deploy_frontend() {
    local identity_id=$1
    local backend_fqdn=$2
    local image_name="${CONTAINER_REGISTRY}.azurecr.io/singleclin-frontend:${FRONTEND_IMAGE_TAG}"

    print_status "Deploying frontend container app..."
    print_status "Image: $image_name"
    print_status "Backend URL: https://$backend_fqdn"

    # Check if container app exists
    if az containerapp show --resource-group "$RESOURCE_GROUP" --name "$FRONTEND_APP_NAME" >/dev/null 2>&1; then
        print_status "Updating existing container app: $FRONTEND_APP_NAME"

        az containerapp update \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FRONTEND_APP_NAME" \
            --image "$image_name" \
            --set-env-vars "BACKEND_URL=https://$backend_fqdn" \
            --output table
    else
        print_status "Creating new container app: $FRONTEND_APP_NAME"

        az containerapp create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FRONTEND_APP_NAME" \
            --environment "$CONTAINER_APPS_ENV" \
            --image "$image_name" \
            --registry-server "${CONTAINER_REGISTRY}.azurecr.io" \
            --registry-identity "$identity_id" \
            --target-port 8080 \
            --ingress external \
            --min-replicas 0 \
            --max-replicas 2 \
            --cpu 0.5 \
            --memory 1Gi \
            --user-assigned "$identity_id" \
            --env-vars \
                NODE_ENV=production \
                "BACKEND_URL=https://$backend_fqdn" \
            --output table
    fi

    # Get the FQDN
    local frontend_fqdn=$(az containerapp show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$FRONTEND_APP_NAME" \
        --query 'properties.configuration.ingress.fqdn' -o tsv)

    print_status "Frontend deployed successfully!"
    print_status "Frontend URL: https://$frontend_fqdn"

    echo "$frontend_fqdn"
}

# Test deployments
test_deployments() {
    local backend_fqdn=$1
    local frontend_fqdn=$2

    print_status "Testing deployments..."

    # Wait for containers to start
    print_status "Waiting for containers to start..."
    sleep 45

    # Test backend health
    print_status "Testing backend health..."
    if curl -f -s "https://$backend_fqdn/health" >/dev/null; then
        print_status "✅ Backend health check passed"
    else
        print_warning "⚠️ Backend health check failed"
    fi

    # Test frontend health
    print_status "Testing frontend health..."
    if curl -f -s "https://$frontend_fqdn/health" >/dev/null; then
        print_status "✅ Frontend health check passed"
    else
        print_warning "⚠️ Frontend health check failed"
    fi

    # Test backend API
    print_status "Testing backend API..."
    if curl -f -s "https://$backend_fqdn/swagger/index.html" >/dev/null; then
        print_status "✅ Backend API documentation accessible"
    else
        print_warning "⚠️ Backend API documentation not accessible"
    fi
}

# Show deployment summary
show_summary() {
    local backend_fqdn=$1
    local frontend_fqdn=$2

    echo ""
    echo "=== DEPLOYMENT SUMMARY ==="
    echo "Backend URL: https://$backend_fqdn"
    echo "Frontend URL: https://$frontend_fqdn"
    echo "Backend Health: https://$backend_fqdn/health"
    echo "Backend API Docs: https://$backend_fqdn/swagger"
    echo "Backend Detailed Health: https://$backend_fqdn/health/detailed"
    echo ""
    echo "Container Apps:"
    az containerapp list \
        --resource-group "$RESOURCE_GROUP" \
        --query '[].{Name:name, FQDN:properties.configuration.ingress.fqdn, Status:properties.runningStatus}' \
        --output table
}

# Main execution
main() {
    print_status "Starting Container Apps deployment..."

    check_prerequisites

    local identity_id
    identity_id=$(get_managed_identity_id)

    local backend_fqdn
    backend_fqdn=$(deploy_backend "$identity_id")

    local frontend_fqdn
    frontend_fqdn=$(deploy_frontend "$identity_id" "$backend_fqdn")

    test_deployments "$backend_fqdn" "$frontend_fqdn"

    show_summary "$backend_fqdn" "$frontend_fqdn"

    print_status "Container Apps deployment completed successfully!"
}

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "SingleClin Container Apps Deployment"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Environment Variables:"
    echo "  BACKEND_IMAGE_TAG   - Backend image tag (default: latest)"
    echo "  FRONTEND_IMAGE_TAG  - Frontend image tag (default: latest)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with latest images"
    echo "  BACKEND_IMAGE_TAG=v1.2.3 $0         # Deploy specific backend version"
    echo ""
    exit 0
fi

# Run main function
main "$@"