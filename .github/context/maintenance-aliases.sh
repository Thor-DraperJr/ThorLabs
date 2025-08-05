#!/bin/bash
# ThorLabs Project Maintenance Helper
# Quick commands for project hygiene and maintenance

# Quick audit functions for ThorLabs project
alias audit-report='cd $HOME/projects/ThorLabs && ./scripts/audit-project.sh --report-only'
alias audit-fix='cd $HOME/projects/ThorLabs && ./scripts/audit-project.sh --fix-issues'
alias audit-status='cd $HOME/projects/ThorLabs && find . -name "audit-report-*.md" -mtime -7 | head -1 | xargs cat | grep -A 10 "Summary Statistics"'

# Project maintenance shortcuts
alias project-health='audit-report && echo -e "\n🎯 Quick Health Check:" && git status --porcelain | wc -l | xargs echo "Uncommitted files:" && find . -name "*.bicep" | wc -l | xargs echo "Bicep templates:" && find docs/ -name "*.md" | wc -l | xargs echo "Documentation files:"'
alias cleanup-reports='cd $HOME/projects/ThorLabs && find . -name "audit-report-*.md" -mtime +30 -delete && echo "Cleaned up old audit reports"'
alias review-checklist='code .github/context/project-review-checklist.md'

# GitHub workflow helpers
alias trigger-audit='gh workflow run project-audit.yml --field audit_mode=report-only --field create_issue=true'
alias trigger-fix='gh workflow run project-audit.yml --field audit_mode=auto-fix --field create_issue=false'
alias check-workflows='gh workflow list --all'
alias audit-logs='gh run list --workflow=project-audit.yml --limit 5'

# Quick project stats
alias project-stats='echo -e "📊 ThorLabs Project Statistics\n========================" && echo "Files by type:" && find . -type f -name "*.*" | sed "s/.*\.//" | sort | uniq -c | sort -nr | head -10 && echo -e "\nDirectory sizes:" && du -sh */ 2>/dev/null | sort -hr | head -5'

# Maintenance reminders
alias maintenance-help='echo -e "🔧 ThorLabs Maintenance Commands\n\n📋 Basic Auditing:\n  audit-report     - Run audit and generate report\n  audit-fix        - Run audit with auto-fixes\n  audit-status     - Show recent audit summary\n  project-health   - Quick health overview\n\n🚀 GitHub Workflows:\n  trigger-audit    - Trigger audit workflow\n  trigger-fix      - Trigger fix workflow\n  audit-logs       - Show recent workflow runs\n\n📊 Project Insights:\n  project-stats    - Show file and directory stats\n  cleanup-reports  - Remove old audit reports\n  review-checklist - Open manual review checklist\n\n💡 Best Practices:\n  - Run 'audit-report' weekly\n  - Use 'audit-fix' for safe automated fixes\n  - Check 'project-health' before major changes\n  - Follow 'review-checklist' monthly"'

echo "🔧 ThorLabs maintenance commands loaded. Type 'maintenance-help' for usage."
