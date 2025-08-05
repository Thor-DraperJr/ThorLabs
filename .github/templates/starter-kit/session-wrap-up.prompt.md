# Session Wrap-Up & Push to GitHub

Complete coding session with comprehensive commit and push to GitHub repository.

## Context
@workspace - Current workspace changes and status
@azure - Any Azure resources that were modified
#README.md - Project overview for commit context

## Workflow Steps

### 1. Assess Session Changes
- Review modified files and new additions
- Check for any temporary files or debug artifacts to exclude
- Verify all work is ready for commit

### 2. Create Comprehensive Commit
- Generate descriptive commit message summarizing session work
- Follow conventional commit format (feat:, fix:, docs:, refactor:, etc.)
- Include BREAKING CHANGE notes if applicable
- Reference any issues or pull requests

### 3. Safety Checks
- Ensure no secrets or sensitive data in commits
- Verify all Azure CLI operations completed successfully
- Check that builds/validations pass

### 4. Push to Repository
- Stage all changes (git add -A)
- Commit with detailed message
- Push to origin/main

## Example Usage
```
I'm ready to wrap up my coding session. Please review my changes, create a comprehensive commit message, and push everything to GitHub.
```

## Anti-Sprawl Compliance
- No wrapper scripts - use direct git commands
- Comprehensive but concise commit messages
- Follow ThorLabs repository standards
- Maintain clean git history

## Common Session Types
- **Feature development**: New Azure resources or capabilities
- **Bug fixes**: Logic Apps connections, template issues
- **Repository maintenance**: Cleanup, documentation updates
- **Infrastructure changes**: Bicep templates, security updates
