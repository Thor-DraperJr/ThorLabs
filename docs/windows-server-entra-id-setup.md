# Windows Server 2022 VM for Entra ID Connect and Microsoft Defender for Identity Setup

This document provides comprehensive setup instructions for deploying and configuring a Windows Server 2022 VM in the ThorLabs Azure lab environment, specifically configured for Entra ID Connect and Microsoft Defender for Identity.

---

## Repository Structure Reference

This implementation follows the ThorLabs repository structure and conventions:

```
ThorLabs/
├── README.md                           # Main repository overview and quick start
├── docs/                              # All documentation
│   ├── INSTRUCTIONS.md                # General deployment instructions
│   ├── REPO_GUIDE.md                  # Repository structure guide
│   └── windows-server-entra-id-setup.md  # This document
├── bicep/                             # Bicep templates (NEW)
│   └── windows-server-entra-id.bicep  # Windows Server 2022 VM template
├── scripts/                           # PowerShell scripts (NEW)
│   ├── windows-server-entra-prereqs.ps1  # Entra ID Connect prerequisites
│   └── windows-server-mdi-prereqs.ps1    # MDI prerequisites
├── infra/                             # Main infrastructure templates
│   ├── main.bicep                     # Ubuntu VM template
│   └── main.parameters.json           # Parameter files
├── policies/                          # Azure Policy definitions
└── .github/workflows/                 # GitHub Actions workflows
```

**Key Changes:**
- Added `/bicep/` directory for specialized Bicep templates
- Added `/scripts/` directory for PowerShell automation scripts
- Maintained consistent naming conventions: `thorlabs-vm2-eastus2`
- Followed existing tagging standards for cost control

---

## Overview

### Purpose
Deploy a Windows Server 2022 virtual machine optimized for:
- **Azure AD Connect (Entra ID Connect)** - Hybrid identity synchronization between on-premises Active Directory and Azure AD
- **Microsoft Defender for Identity (MDI)** - Advanced threat protection for on-premises Active Directory

### Architecture Components
- Windows Server 2022 Datacenter VM (`thorlabs-vm2-eastus2`)
- Dedicated virtual network with domain subnet (`10.1.0.0/16`)
- Network Security Group with RDP and management access
- Static IP assignment for domain controller functionality
- Premium SSD storage for optimal performance

---

## Prerequisites

### Azure Environment
- Azure subscription with Contributor permissions
- Resource group: `thorlabs-rg` (as per ThorLabs conventions)
- Azure CLI installed and authenticated
- Bicep CLI tools available

### Microsoft Licensing
- Azure AD Premium P1 or P2 licenses
- Microsoft Defender for Identity licenses
- Windows Server 2022 licensing (included in Azure VM)

### Network Requirements
- Internet connectivity for Azure AD Connect
- Firewall access to Microsoft cloud services
- DNS resolution for Azure and Microsoft endpoints

---

## Deployment Instructions

### Step 1: Deploy the Infrastructure

1. **Navigate to the repository root:**
   ```bash
   cd /path/to/ThorLabs
   ```

2. **Deploy the Bicep template:**
   ```bash
   az deployment group create \
     --resource-group thorlabs-rg \
     --template-file bicep/windows-server-entra-id.bicep \
     --parameters vmName="thorlabs-vm2-eastus2" \
     --parameters adminUsername="thorlabsadmin" \
     --parameters adminPassword="YourSecurePassword123!"
   ```

3. **Verify deployment:**
   ```bash
   az vm show --resource-group thorlabs-rg --name thorlabs-vm2-eastus2 --show-details
   ```

### Step 2: Initial Server Configuration

1. **Connect via RDP:**
   - Get the public IP from deployment output
   - Use RDP client to connect with admin credentials
   - Computer name: `THORLABS-DC01`

2. **Download prerequisite scripts:**
   ```powershell
   # Create working directory
   New-Item -ItemType Directory -Path "C:\ThorLabs\Scripts" -Force
   
   # Download scripts from repository
   # (In production, use secure method to transfer scripts)
   ```

### Step 3: Configure Domain Controller

1. **Run Entra ID Connect prerequisites script:**
   ```powershell
   # Run as Administrator
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
   
   # Execute prerequisites script
   .\windows-server-entra-prereqs.ps1 -DomainName "thorlabs.local" -DomainNetBIOSName "THORLABS"
   ```

2. **Follow prompts for domain controller promotion:**
   - The script will install required Windows features
   - Configure DNS and firewall settings
   - Promote server to domain controller
   - **Server will restart automatically**

3. **Post-restart verification:**
   ```powershell
   # Verify domain controller status
   dcdiag /q
   
   # Check DNS configuration
   nslookup thorlabs.local
   ```

### Step 4: Configure Microsoft Defender for Identity

1. **Run MDI prerequisites script:**
   ```powershell
   # After domain controller is fully operational
   .\windows-server-mdi-prereqs.ps1 -DomainName "thorlabs.local"
   ```

2. **Script will configure:**
   - MDI service account with required permissions
   - Windows Event Log settings
   - Audit policies for security monitoring
   - Network connectivity requirements
   - System health validation

### Step 5: Install Azure AD Connect

1. **Download Azure AD Connect:**
   - Visit [Microsoft Download Center](https://www.microsoft.com/en-us/download/details.aspx?id=47594)
   - Download latest version of Azure AD Connect

2. **Run installation:**
   ```powershell
   # Mount downloaded installer
   .\AzureADConnect.msi
   ```

3. **Configuration wizard:**
   - Choose "Express Settings" for initial setup
   - Provide Azure AD Global Administrator credentials
   - Provide domain administrator credentials (thorlabs\administrator)
   - Configure synchronization options

### Step 6: Install MDI Sensor

1. **Access Microsoft 365 Security Center:**
   - Navigate to [security.microsoft.com](https://security.microsoft.com)
   - Go to Settings > Identities > Sensors

2. **Download MDI sensor:**
   - Click "Download sensor setup"
   - Save installer to `C:\ThorLabs\MDI\`

3. **Install sensor:**
   ```powershell
   # Run as Administrator
   .\Azure ATP Sensor Setup.exe
   ```

4. **Configuration:**
   - Use the MDI service account created by prerequisites script
   - Follow sensor configuration wizard
   - Verify sensor connectivity

---

## Configuration Details

### Network Configuration
- **VM Network:** `10.1.0.0/16`
- **Domain Subnet:** `10.1.1.0/24`
- **Static IP:** `10.1.1.10` (Domain Controller)
- **DNS Forwarders:** Azure DNS (168.63.129.16), Google DNS (8.8.8.8)

### Security Configuration
- **Firewall Rules:** RDP (3389), WinRM (5985/5986), HTTPS (443)
- **Service Accounts:**
  - `AADConnect-SVC` - Azure AD Connect service account
  - `MDI-SVC` - Microsoft Defender for Identity service account
- **Audit Policies:** Comprehensive logging for security monitoring

### Storage Configuration
- **OS Disk:** 128 GB Premium SSD
- **VM Size:** Standard_D2s_v3 (2 vCPU, 8 GB RAM)
- **Log Directory:** `C:\ThorLabs\Logs\`

---

## Cost Control and Management

### Auto-Shutdown Configuration
All resources are tagged with auto-shutdown settings:
```json
{
  "AutoShutdown_Time": "19:00",
  "AutoShutdown_TimeZone": "Eastern Standard Time"
}
```

### Resource Management Commands
```bash
# Stop the VM to save costs
az vm deallocate --resource-group thorlabs-rg --name thorlabs-vm2-eastus2

# Start the VM when needed
az vm start --resource-group thorlabs-rg --name thorlabs-vm2-eastus2

# Check VM status
az vm get-instance-view --resource-group thorlabs-rg --name thorlabs-vm2-eastus2 --query instanceView.statuses
```

---

## Monitoring and Maintenance

### Health Checks
1. **Domain Controller Health:**
   ```powershell
   dcdiag /v
   repadmin /showrepl
   ```

2. **Azure AD Connect Status:**
   ```powershell
   # Check synchronization status
   Import-Module ADSync
   Get-ADSyncScheduler
   ```

3. **MDI Sensor Status:**
   - Monitor in Microsoft 365 Security Center
   - Check Windows Event Logs
   - Verify network connectivity

### Regular Maintenance Tasks
- **Weekly:** Review synchronization logs
- **Monthly:** Update Windows and security patches
- **Quarterly:** Review security policies and permissions

### Log Locations
- **Azure AD Connect:** `C:\ProgramData\AADConnect\trace-*.log`
- **MDI Sensor:** `C:\Program Files\Azure Advanced Threat Protection Sensor\*\Logs\`
- **Windows Events:** Event Viewer > Windows Logs > Security/System/Application
- **ThorLabs Logs:** `C:\ThorLabs\Logs\`

---

## Troubleshooting

### Common Issues and Solutions

#### Azure AD Connect Issues
1. **Synchronization Errors:**
   ```powershell
   # Check connector status
   Get-ADSyncConnectorRunStatus
   
   # Force synchronization
   Start-ADSyncSyncCycle -PolicyType Delta
   ```

2. **Password Synchronization:**
   ```powershell
   # Enable password sync debugging
   Set-ADSyncAADPasswordSyncConfiguration -SourceConnector "thorlabs.local" -TargetConnector "company.onmicrosoft.com" -Enable $true
   ```

#### MDI Sensor Issues
1. **Connectivity Problems:**
   ```powershell
   # Test connectivity to MDI cloud
   Test-NetConnection -ComputerName winatp-gw-eus.microsoft.com -Port 443
   ```

2. **Service Account Issues:**
   ```powershell
   # Verify service account permissions
   Get-ADUser MDI-SVC -Properties MemberOf
   ```

#### Domain Controller Issues
1. **DNS Resolution:**
   ```powershell
   # Check DNS settings
   Get-DnsServerForwarder
   nslookup thorlabs.local
   ```

2. **Time Synchronization:**
   ```powershell
   # Sync with Azure time service
   w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual
   w32tm /resync
   ```

---

## Security Best Practices

### Account Security
- Use strong, unique passwords for all service accounts
- Enable MFA for administrative accounts
- Regularly rotate service account passwords
- Follow principle of least privilege

### Network Security
- Restrict RDP access to specific IP ranges
- Use Azure Bastion for secure remote access
- Monitor network traffic for anomalies
- Keep firewall rules minimal and specific

### Monitoring and Alerting
- Enable Azure Security Center monitoring
- Configure alerts for failed logins and suspicious activities
- Review MDI security alerts regularly
- Maintain audit logs for compliance

---

## Integration with ThorLabs Environment

### GitHub Actions Integration
The deployment can be automated through the existing GitHub Actions workflow by:

1. **Adding deployment step:**
   ```yaml
   - name: Deploy Windows Server for Entra ID
     run: |
       az deployment group create \
         --resource-group thorlabs-rg \
         --template-file bicep/windows-server-entra-id.bicep \
         --parameters adminPassword="$ADMIN_PASSWORD"
   ```

### Cost Control Integration
- Resources follow existing auto-shutdown policies
- Compatible with Azure Policy definitions in `/policies/`
- Supports existing cost monitoring and alerting

### Documentation Integration
- Follows ThorLabs documentation standards
- Integrates with existing repository structure
- Maintains consistency with other deployment guides

---

## Next Steps

### Phase 1: Basic Setup (Completed by scripts)
- [x] Infrastructure deployment
- [x] Domain controller configuration
- [x] Service account creation
- [x] Basic security configuration

### Phase 2: Service Configuration
- [ ] Azure AD Connect installation and configuration
- [ ] MDI sensor deployment and tuning
- [ ] User synchronization testing
- [ ] Security policy implementation

### Phase 3: Production Readiness
- [ ] Backup and disaster recovery setup
- [ ] Monitoring and alerting configuration
- [ ] Performance optimization
- [ ] Security hardening review

### Phase 4: Integration and Testing
- [ ] Test hybrid identity scenarios
- [ ] Validate security monitoring
- [ ] Performance testing
- [ ] Documentation updates

---

## Support and Resources

### Microsoft Documentation
- [Azure AD Connect Documentation](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/)
- [Microsoft Defender for Identity Documentation](https://docs.microsoft.com/en-us/defender-for-identity/)
- [Windows Server 2022 Documentation](https://docs.microsoft.com/en-us/windows-server/)

### ThorLabs Resources
- [Repository Guide](REPO_GUIDE.md)
- [General Instructions](INSTRUCTIONS.md)
- [GitHub Secrets Checklist](GITHUB_SECRETS_CHECKLIST.md)
- [Azure Policy Documentation](../policies/README.md)

### Community Resources
- [Azure AD Connect Community](https://techcommunity.microsoft.com/t5/azure-active-directory-identity/ct-p/Azure-Active-Directory)
- [Microsoft Security Community](https://techcommunity.microsoft.com/t5/microsoft-security-and/ct-p/MicrosoftSecurityandCompliance)

---

**Document Version:** 1.0  
**Last Updated:** [Current Date]  
**Maintained by:** ThorLabs Team