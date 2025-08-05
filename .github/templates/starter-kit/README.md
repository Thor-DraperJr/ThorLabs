# Portable AI Workspace Starter Kit

This starter kit contains the essential components for setting up frontier AI-human collaboration in any workspace.

## 🚀 Quick Setup (5 minutes)

### 1. Copy Core Files
```bash
# In your new project directory:
mkdir -p .github/prompts
cp starter-kit/copilot-instructions-template.md .github/copilot-instructions.md
cp starter-kit/session-wrap-up.prompt.md .github/prompts/
cp starter-kit/project-status-check.prompt.md .github/prompts/
```

### 2. Customize Instructions
Edit `.github/copilot-instructions.md`:
- Replace `[PROJECT_NAME]` with your project name
- Update naming conventions and patterns
- Add technology-specific tools and preferences
- Customize prohibited/preferred patterns

### 3. Test Frontier Features
```
@workspace - Reference entire solution
#filename.ext - Reference specific files
#prompt:session-wrap-up - Use session management
```

## 📁 Included Files

### **copilot-instructions-template.md**
- Universal anti-sprawl protocol
- Frontier collaboration methods
- Customizable project patterns
- Tool preference hierarchy

### **session-wrap-up.prompt.md**
- End-of-session workflow
- Comprehensive commit generation
- Safety checks and validation
- Repository maintenance

### **project-status-check.prompt.md**
- Quick health check workflow
- File count monitoring
- Resource status validation
- Anti-sprawl compliance

## 🎯 Technology-Specific Adaptations

### **Web Development**
Add to copilot-instructions.md:
```markdown
## PREFERRED TOOLS
- npm/yarn over wrapper scripts
- Framework CLI over custom tools
- Live reload over static builds
- Browser dev tools over logging
```

### **Python/Data Science**
Add to copilot-instructions.md:
```markdown
## PREFERRED TOOLS
- pip install -e . for development
- jupyter notebook over scripts
- Virtual environments (venv/conda)
- Direct library imports over wrappers
```

### **Cloud/DevOps**
Add to copilot-instructions.md:
```markdown
## PREFERRED TOOLS
- Cloud CLI tools over REST calls
- Infrastructure as Code over manual configs
- Live resource queries over cached data
- terraform/pulumi over wrapper scripts
```

## ✅ Success Indicators

After setup, you should have:
- Dynamic reference system working (`@workspace`, `#filename`)
- Prompt templates accessible (`#prompt:session-wrap-up`)
- Anti-sprawl protocol preventing bloat
- Frontier AI collaboration methods active

## 🔄 Maintenance

This starter kit promotes:
- **Prevention over cleanup** (anti-sprawl protocol)
- **Live tools over static docs** (frontier methods)
- **Dynamic over static context** (VS Code 1.10+ features)
- **Functionality over process** (minimal, focused files)

---

*Derived from ThorLabs frontier AI collaboration methods (August 2025)*
