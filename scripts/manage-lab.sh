#!/bin/bash
# manage-lab.sh - Management script for ThorLabs Lab Environment
# Provides common management operations for the lab environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="thorlabs-rg"

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

# Function to check if resource group exists
check_resource_group() {
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_error "Resource group '$RESOURCE_GROUP' not found. Have you deployed the lab yet?"
        exit 1
    fi
}

# Function to show lab status
show_lab_status() {
    print_status "ThorLabs Lab Environment Status"
    echo "================================="
    
    check_resource_group
    
    echo ""
    print_status "Resource Group Information:"
    az group show --name "$RESOURCE_GROUP" --query "{Name:name, Location:location, State:properties.provisioningState}" --output table
    
    echo ""
    print_status "Virtual Machines:"
    az vm list --resource-group "$RESOURCE_GROUP" --show-details --query "[].{Name:name, PowerState:powerState, Size:hardwareProfile.vmSize, PublicIP:publicIps, PrivateIP:privateIps}" --output table
    
    echo ""
    print_status "Storage Accounts:"
    az storage account list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Kind:kind, Tier:accessTier, Location:location}" --output table
    
    echo ""
    print_status "Key Vaults:"
    az keyvault list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Location:location}" --output table
    
    echo ""
    print_status "Network Resources:"
    az network vnet list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, AddressSpace:join(', ', addressSpace.addressPrefixes), Location:location}" --output table
    
    echo ""
    print_status "Container Resources:"
    az acr list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, LoginServer:loginServer, Tier:sku.tier}" --output table 2>/dev/null || echo "No container registries found"
    
    echo ""
    print_status "Database Resources:"
    az sql server list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Location:location, Version:version}" --output table 2>/dev/null || echo "No SQL servers found"
}

# Function to start all VMs
start_vms() {
    print_status "Starting all virtual machines..."
    
    check_resource_group
    
    local vms
    vms=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)
    
    if [ -z "$vms" ]; then
        print_warning "No virtual machines found in resource group"
        return
    fi
    
    for vm in $vms; do
        print_status "Starting VM: $vm"
        az vm start --resource-group "$RESOURCE_GROUP" --name "$vm" --no-wait
    done
    
    print_success "Start commands sent for all VMs"
    print_status "VMs are starting in the background. Use 'show-status' to check progress."
}

# Function to stop all VMs
stop_vms() {
    print_status "Stopping (deallocating) all virtual machines..."
    
    check_resource_group
    
    local vms
    vms=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)
    
    if [ -z "$vms" ]; then
        print_warning "No virtual machines found in resource group"
        return
    fi
    
    for vm in $vms; do
        print_status "Stopping VM: $vm"
        az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$vm" --no-wait
    done
    
    print_success "Stop commands sent for all VMs"
    print_status "VMs are stopping in the background. Use 'show-status' to check progress."
}

# Function to restart all VMs
restart_vms() {
    print_status "Restarting all virtual machines..."
    
    check_resource_group
    
    local vms
    vms=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)
    
    if [ -z "$vms" ]; then
        print_warning "No virtual machines found in resource group"
        return
    fi
    
    for vm in $vms; do
        print_status "Restarting VM: $vm"
        az vm restart --resource-group "$RESOURCE_GROUP" --name "$vm" --no-wait
    done
    
    print_success "Restart commands sent for all VMs"
    print_status "VMs are restarting in the background. Use 'show-status' to check progress."
}

# Function to get connection information
get_connection_info() {
    print_status "ThorLabs Lab Connection Information"
    echo "==================================="
    
    check_resource_group
    
    # Get VM information with public IPs
    local vms_info
    vms_info=$(az vm list-ip-addresses --resource-group "$RESOURCE_GROUP" --query "[].{VMName:virtualMachine.name, PublicIP:virtualMachine.network.publicIpAddresses[0].ipAddress, PrivateIP:virtualMachine.network.privateIpAddresses[0]}" --output json)
    
    if [ "$vms_info" = "[]" ]; then
        print_warning "No virtual machines found with IP addresses"
        return
    fi
    
    echo ""
    echo "$vms_info" | jq -r '.[] | select(.PublicIP != null) | "🖥️  VM: \(.VMName)\n   Public IP: \(.PublicIP)\n   Private IP: \(.PrivateIP)\n"'
    
    # Generate connection commands
    echo ""
    print_status "Connection Commands:"
    
    local ubuntu_ip
    local windows_ip
    
    ubuntu_ip=$(echo "$vms_info" | jq -r '.[] | select(.VMName | contains("vm1")) | .PublicIP // "Not found"')
    windows_ip=$(echo "$vms_info" | jq -r '.[] | select(.VMName | contains("vm2")) | .PublicIP // "Not found"')
    
    if [ "$ubuntu_ip" != "Not found" ] && [ "$ubuntu_ip" != "null" ]; then
        echo "🐧 SSH to Ubuntu VM:"
        echo "   ssh thorlabsadmin@$ubuntu_ip"
        echo ""
    fi
    
    if [ "$windows_ip" != "Not found" ] && [ "$windows_ip" != "null" ]; then
        echo "🪟 RDP to Windows VM:"
        echo "   mstsc /v:$windows_ip"
        echo ""
    fi
    
    # Get other service endpoints
    echo ""
    print_status "Service Endpoints:"
    
    # Container Registry
    local acr_server
    acr_server=$(az acr list --resource-group "$RESOURCE_GROUP" --query "[0].loginServer" --output tsv 2>/dev/null || echo "")
    if [ -n "$acr_server" ]; then
        echo "🐳 Container Registry: $acr_server"
    fi
    
    # SQL Server
    local sql_server
    sql_server=$(az sql server list --resource-group "$RESOURCE_GROUP" --query "[0].fullyQualifiedDomainName" --output tsv 2>/dev/null || echo "")
    if [ -n "$sql_server" ]; then
        echo "🗄️  SQL Server: $sql_server"
    fi
    
    # Storage Account
    local storage_account
    storage_account=$(az storage account list --resource-group "$RESOURCE_GROUP" --query "[0].primaryEndpoints.blob" --output tsv 2>/dev/null || echo "")
    if [ -n "$storage_account" ]; then
        echo "💾 Storage Account: $storage_account"
    fi
}

# Function to show costs
show_costs() {
    print_status "Cost Information"
    echo "================"
    
    check_resource_group
    
    # Get subscription ID
    local subscription_id
    subscription_id=$(az account show --query "id" --output tsv)
    
    print_status "Resource Group: $RESOURCE_GROUP"
    print_status "Subscription: $subscription_id"
    
    echo ""
    print_status "Current Month Resource Costs:"
    
    # Note: Azure CLI cost management commands may not be available in all environments
    # Provide portal link instead
    echo "💰 View detailed costs in Azure Cost Management:"
    echo "   https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview"
    
    echo ""
    print_status "Cost Optimization Tips:"
    echo "🕰️  VMs auto-shutdown at 7 PM ET daily (if configured)"
    echo "⏹️  Stop VMs when not in use: ./manage-lab.sh stop-vms"
    echo "🔍 Monitor usage: ./manage-lab.sh show-status"
    echo "📊 Use Basic SKUs for lab workloads"
    echo "💡 Estimated monthly cost: $50-100 USD with auto-shutdown"
}

# Function to clean up lab
cleanup_lab() {
    print_warning "This will DELETE the entire lab environment!"
    print_warning "All virtual machines, storage, and data will be permanently lost."
    
    echo ""
    read -p "Type 'DELETE' to confirm deletion of resource group '$RESOURCE_GROUP': " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        print_status "Deleting resource group '$RESOURCE_GROUP'..."
        
        if az group delete --name "$RESOURCE_GROUP" --yes --no-wait; then
            print_success "Deletion initiated. Resource group is being deleted in the background."
            print_status "This process may take several minutes to complete."
        else
            print_error "Failed to initiate resource group deletion."
        fi
    else
        print_warning "Deletion cancelled."
    fi
}

# Function to show help
show_help() {
    echo "ThorLabs Lab Management Script"
    echo "============================="
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  show-status     Show detailed status of all lab resources"
    echo "  start-vms       Start all virtual machines"
    echo "  stop-vms        Stop (deallocate) all virtual machines"
    echo "  restart-vms     Restart all virtual machines"
    echo "  connect-info    Show connection information and commands"
    echo "  show-costs      Show cost information and optimization tips"
    echo "  cleanup         DELETE the entire lab environment"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 show-status"
    echo "  $0 stop-vms"
    echo "  $0 connect-info"
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "show-status"|"status")
            show_lab_status
            ;;
        "start-vms"|"start")
            start_vms
            ;;
        "stop-vms"|"stop")
            stop_vms
            ;;
        "restart-vms"|"restart")
            restart_vms
            ;;
        "connect-info"|"connect"|"info")
            get_connection_info
            ;;
        "show-costs"|"costs")
            show_costs
            ;;
        "cleanup"|"delete")
            cleanup_lab
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
