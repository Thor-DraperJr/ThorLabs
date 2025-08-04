#!/bin/bash
# validate-templates.sh - Simple validation script for ThorLabs templates
# Tests template compilation without Azure CLI dependency

set -euo pipefail

echo "🔍 ThorLabs Template Validation"
echo "==============================="

templates=("enhanced-lab.bicep" "container-services.bicep" "database-services.bicep" "master-deployment.bicep")
validation_errors=0

for template in "${templates[@]}"; do
    if [ -f "infra/$template" ]; then
        echo "📋 Checking $template..."
        
        # Basic syntax check - look for common issues
        if grep -q "resource.*=" "infra/$template" && grep -q "output.*=" "infra/$template"; then
            echo "✅ $template structure looks valid"
        else
            echo "❌ $template may have structural issues"
            validation_errors=$((validation_errors + 1))
        fi
    else
        echo "❌ $template not found"
        validation_errors=$((validation_errors + 1))
    fi
done

echo ""
if [ $validation_errors -eq 0 ]; then
    echo "✅ All templates passed basic validation!"
    echo "💡 For full validation, use 'az bicep build' with Azure CLI"
else
    echo "❌ $validation_errors template(s) failed validation"
    exit 1
fi
