#!/bin/bash
# deploy-lab.sh - Enhanced deployment script for ThorLabs Lab Environment
# Provides interactive deployment with validation and comprehensive options

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="thorlabs-rg"
LOCATION="eastus2"
ADMIN_USERNAME="thorlabsadmin"
TEMPLATE_FILE="infra/master-deployment.bicep"
PARAMETERS_FILE="infra/master-deployment.parameters.json"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if Bicep is available
    if ! az bicep version &> /dev/null; then
        print_warning "Bicep CLI not found. Installing..."
        az bicep install
    fi
    
    print_success "Prerequisites check completed!"
}

# Function to validate templates
validate_templates() {
    print_status "Validating Bicep templates..."
    
    local templates=("enhanced-lab.bicep" "container-services.bicep" "database-services.bicep" "master-deployment.bicep")
    local validation_errors=0
    
    for template in "${templates[@]}"; do
        if [ -f "infra/$template" ]; then
            print_status "Validating $template..."
            if az bicep build --file "infra/$template" --stdout > /dev/null 2>&1; then
                print_success "$template compiled successfully"
            else
                print_error "Validation failed for $template"
                validation_errors=$((validation_errors + 1))
            fi
        fi
    done
    
    if [ $validation_errors -eq 0 ]; then
        print_success "All template validations passed!"
        return 0
    else
        print_error "$validation_errors template(s) failed validation"
        return 1
    fi
}

# Function to get deployment type from user
get_deployment_type() {
    echo ""
    print_status "Select deployment type:"
    echo "1) Core Lab (VMs, networking, storage, monitoring)"
    echo "2) Full Lab (Core + containers + databases)"
    echo "3) Core Lab + Sentinel (includes security monitoring)"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            DEPLOY_CORE=true
            DEPLOY_CONTAINERS=false
            DEPLOY_DATABASES=false
            ENABLE_SENTINEL=false
            print_status "Selected: Core Lab deployment"
            ;;
        2)
            DEPLOY_CORE=true
            DEPLOY_CONTAINERS=true
            DEPLOY_DATABASES=true
            ENABLE_SENTINEL=false
            print_status "Selected: Full Lab deployment"
            ;;
        3)
            DEPLOY_CORE=true
            DEPLOY_CONTAINERS=false
            DEPLOY_DATABASES=false
            ENABLE_SENTINEL=true
            print_status "Selected: Core Lab + Sentinel deployment"
            ;;
        *)
            print_error "Invalid choice. Defaulting to Core Lab."
            DEPLOY_CORE=true
            DEPLOY_CONTAINERS=false
            DEPLOY_DATABASES=false
            ENABLE_SENTINEL=false
            ;;
    esac
}

# Function to get VM size from user
get_vm_size() {
    echo ""
    print_status "Select VM size (lab-optimized):"
    echo "1) Standard_B1s (1 vCPU, 1 GB RAM) - Cheapest (~$8/month)"
    echo "2) Standard_B2s (2 vCPUs, 4 GB RAM) - Recommended (~$30/month)"
    echo "3) Standard_DS1_v2 (1 vCPU, 3.5 GB RAM) - Balanced (~$25/month)"
    echo ""
    read -p "Enter your choice (1-3): " size_choice
    
    case $size_choice in
        1) VM_SIZE="Standard_B1s" ;;
        2) VM_SIZE="Standard_B2s" ;;
        3) VM_SIZE="Standard_DS1_v2" ;;
        *) 
            print_warning "Invalid choice. Using Standard_B1s (cheapest)"
            VM_SIZE="Standard_B1s"
            ;;
    esac
    
    print_status "Selected VM size: $VM_SIZE"
}

# Function to get admin password securely
get_admin_password() {
    echo ""
    while true; do
        read -s -p "Enter admin password (min 12 chars, must include upper, lower, number, special): " password
        echo ""
        read -s -p "Confirm password: " password_confirm
        echo ""
        
        if [ "$password" = "$password_confirm" ]; then
            if [[ ${#password} -ge 12 && "$password" =~ [A-Z] && "$password" =~ [a-z] && "$password" =~ [0-9] && "$password" =~ [^A-Za-z0-9] ]]; then
                ADMIN_PASSWORD="$password"
                print_success "Password accepted"
                break
            else
                print_error "Password does not meet complexity requirements"
            fi
        else
            print_error "Passwords do not match"
        fi
    done
}

# Function to show deployment summary
show_deployment_summary() {
    echo ""
    print_status "=== DEPLOYMENT SUMMARY ==="
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Location: $LOCATION"
    echo "Admin Username: $ADMIN_USERNAME"
    echo "VM Size: $VM_SIZE"
    echo "Core Infrastructure: $DEPLOY_CORE"
    echo "Container Services: $DEPLOY_CONTAINERS"
    echo "Database Services: $DEPLOY_DATABASES"
    echo "Sentinel Security: $ENABLE_SENTINEL"
    echo "Template: $TEMPLATE_FILE"
    echo ""
    
    # Cost estimate
    local cost_estimate
    if [ "$DEPLOY_CONTAINERS" = "true" ] && [ "$DEPLOY_DATABASES" = "true" ]; then
        cost_estimate="~\$40-70/month"
    elif [ "$DEPLOY_CONTAINERS" = "true" ] || [ "$DEPLOY_DATABASES" = "true" ]; then
        cost_estimate="~\$25-50/month"
    else
        cost_estimate="~\$15-35/month"
    fi
    
    print_status "Estimated monthly cost: $cost_estimate (with auto-shutdown)"
    echo ""
    
    read -p "Proceed with deployment? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Function to execute deployment
execute_deployment() {
    print_status "Starting deployment..."
    
    local deployment_name="thorlabs-lab-$(date +%Y%m%d-%H%M%S)"
    
    print_status "Deployment name: $deployment_name"
    
    # Set subscription (get current subscription)
    local subscription_id
    subscription_id=$(az account show --query "id" --output tsv)
    print_status "Using subscription: $subscription_id"
    
    # Execute the deployment
    print_status "Executing deployment... This may take 10-15 minutes."
    
    if az deployment sub create \
        --name "$deployment_name" \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters \
            adminUsername="$ADMIN_USERNAME" \
            adminPassword="$ADMIN_PASSWORD" \
            ubuntuVmSize="$VM_SIZE" \
            windowsVmSize="$VM_SIZE" \
            deployEnhancedLab="$DEPLOY_CORE" \
            deployContainerServices="$DEPLOY_CONTAINERS" \
            deployDatabaseServices="$DEPLOY_DATABASES" \
            enableSentinel="$ENABLE_SENTINEL" \
            resourceGroupName="$RESOURCE_GROUP"; then
        
        print_success "Deployment completed successfully!"
        return 0
    else
        print_error "Deployment failed!"
        return 1
    fi
}

# Function to show post-deployment information
show_post_deployment_info() {
    print_status "Retrieving deployment information..."
    
    # Get VM public IPs
    local ubuntu_ip
    local windows_ip
    
    ubuntu_ip=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "thorlabs-vm1-eastus2" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv 2>/dev/null || echo "Not found")
    windows_ip=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --name "thorlabs-vm2-eastus2" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv 2>/dev/null || echo "Not found")
    
    echo ""
    print_success "=== DEPLOYMENT COMPLETED ==="
    echo ""
    print_status "Connection Information:"
    
    if [ "$ubuntu_ip" != "Not found" ]; then
        echo "🐧 SSH to Ubuntu VM:"
        echo "   ssh $ADMIN_USERNAME@$ubuntu_ip"
    fi
    
    if [ "$windows_ip" != "Not found" ]; then
        echo "🪟 RDP to Windows VM:"
        echo "   mstsc /v:$windows_ip"
    fi
    
    echo ""
    print_status "Azure Portal Links:"
    echo "📊 Resource Group: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
    echo "💰 Cost Management: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview"
    
    echo ""
    print_status "Cost Management:"
    echo "🕰️  Auto-shutdown enabled at 7 PM ET daily"
    echo "💡 Estimated monthly cost: $50-100 USD with auto-shutdown"
    echo "🛑 To stop all VMs now: az vm deallocate --resource-group $RESOURCE_GROUP --name thorlabs-vm1-eastus2 thorlabs-vm2-eastus2"
    
    echo ""
    print_success "Your ThorLabs lab environment is ready for use!"
}

# Main execution
main() {
    echo ""
    print_status "ThorLabs Azure Lab Environment Deployment Script"
    echo "================================================="
    
    # Check prerequisites
    check_prerequisites
    
    # Validate templates
    if ! validate_templates; then
        print_error "Template validation failed. Please fix errors before proceeding."
        exit 1
    fi
    
    # Get deployment configuration
    get_deployment_type
    get_vm_size
    get_admin_password
    
    # Show summary and confirm
    show_deployment_summary
    
    # Execute deployment
    if execute_deployment; then
        show_post_deployment_info
    else
        print_error "Deployment failed. Check Azure portal for details."
        exit 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
