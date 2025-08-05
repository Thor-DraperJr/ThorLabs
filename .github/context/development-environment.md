# ThorLabs Development Environment & Bash Aliases

## Environment Overview

This document provides comprehensive information about the development environment, available bash aliases, and context for AI assistants working with the ThorLabs project.

### System Specifications
- **OS**: WSL Ubuntu 
- **Memory**: 15GB total (13GB available)
- **Storage**: 251GB total (233GB available) 
- **CPU**: Intel i7-1065G7 (8 cores)
- **Shell**: Bash with interactive login (loads ~/.bash_aliases)

### Available Development Tools
- ✅ Node.js (via NVM)
- ✅ NPM & .NET SDK
- ✅ Docker & Git
- ✅ Azure CLI (linked to Windows profile)
- ✅ AWS CLI (linked to Windows profile)
- ✅ Python3 & VS Code integration

## Bash Aliases Reference

### Git Shortcuts (Most Used)
```bash
gs          # git status
ga          # git add  
gc          # git commit
gp          # git push
gl          # git pull
gco         # git checkout
gb          # git branch
glog        # pretty git log with graph
```

### Project Navigation
```bash
projects    # cd ~/projects
c           # code . (open current directory in VS Code)
code-here   # alternative to open VS Code
ll          # detailed file listing
la          # all files including hidden
l           # compact file listing
```

### System Performance & Maintenance
```bash
sysinfo     # quick system overview (memory, disk, load)
cleanup     # automated system cleanup (npm cache, VS Code logs)
meminfo     # show memory-intensive processes
diskusage   # display largest directories
myip        # get public IP
weather     # get weather info
```

### Development Tools
```bash
py          # python3 shortcut
pip         # pip3 shortcut
serve       # start Python HTTP server
nv          # node version
npmg        # global npm packages
```

### Docker Shortcuts
```bash
dk          # docker shortcut
dps         # docker ps
dimg        # docker images
```

### Utility Functions
```bash
mkcd <dir>      # create directory and navigate to it
clone <repo>    # clone repository and enter directory
```

## AI Assistant Context

### Shell Environment
- **Profile**: Development-optimized with 50+ aliases and functions
- **Aliases Location**: `~/.bash_aliases` (outside workspace but available in terminal)
- **Terminal**: Automatically loads with `bash -i` flag

### Common Development Patterns
When suggesting commands, use these patterns:
- `gs` instead of `git status`
- `ga .` instead of `git add .`
- `gc -m "message"` instead of `git commit -m "message"`
- `gp` instead of `git push`
- `c` to open current directory in new VS Code window
- `sysinfo` for quick system health check

### Azure Integration
- Azure CLI ready (linked to Windows profile via ~/.azure symlink)
- Git configured with VS Code as default editor (`code --wait`)
- Modern git defaults (main branch, simple push)

### File Structure Context
```
ThorLabs/                    # Current project
├── .github/context/         # Context files (including this one)
├── .vscode/                 # VS Code settings
├── bicep/                   # Azure Bicep templates
├── infra/                   # Infrastructure definitions (modular layers)
├── scripts/                 # Deployment scripts
└── docs/                    # Documentation

~/                           # Home directory (outside workspace)
├── .bash_aliases           # Development aliases (50+ shortcuts)
├── .gitconfig              # Git configuration
└── projects/               # All projects workspace
```

## Development Workflow

### Typical Session
1. `projects` - Navigate to projects directory
2. `c` - Open current directory in VS Code
3. `gs` - Check git status
4. `ga .` - Stage changes
5. `gc -m "commit message"` - Commit changes
6. `gp` - Push to remote
7. `sysinfo` - Check system health periodically
8. `cleanup` - Run maintenance when needed

### VS Code Integration
- Remote development ready
- Server automatically running
- Git operations integrate with VS Code
- Terminal opens with full environment loaded

### Best Practices
- Use short aliases for common operations
- Terminal automatically loads all aliases (bash -i)
- Azure CLI and development tools ready immediately
- System monitoring available for performance issues

## Usage Tips

1. **Quick Git Workflow**: `gs` → `ga .` → `gc -m "message"` → `gp`
2. **Project Access**: `projects` then `c` to open in VS Code
3. **System Health**: `sysinfo` for overview, `meminfo` for memory issues
4. **Maintenance**: `cleanup` for regular system cleanup
5. **Development**: Use `py`, `nv`, `dk` shortcuts for common tools

This environment is specifically optimized for Azure infrastructure projects like ThorLabs, with emphasis on efficient git workflows and system management.
