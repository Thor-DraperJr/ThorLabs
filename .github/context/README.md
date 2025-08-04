# ThorLabs Context Files

This folder contains detailed reference materials for GitHub Copilot that complement the main `.github/copilot-instructions.md` file.

## File Structure

- **`development-guide.md`** - Comprehensive development workflows and patterns
- **`bicep-patterns.md`** - Bicep template patterns and examples
- **`azure-mcp-reference.md`** - Azure MCP server tool reference
- **`security-standards.md`** - Security and compliance patterns

## Usage

The main `.github/copilot-instructions.md` contains the core rules that Copilot reads automatically. 

When you need specific guidance:
1. **Attach relevant context files** from this folder to your Copilot conversations
2. **Reference specific patterns** when asking for detailed implementations
3. **Use as documentation** for contributors and code reviews

## File Purposes

| File | Purpose | When to Attach |
|------|---------|----------------|
| `development-guide.md` | Complete development workflows | Complex multi-step tasks |
| `bicep-patterns.md` | Bicep templates and schemas | Creating/modifying infrastructure |
| `azure-mcp-reference.md` | MCP server tool usage | Troubleshooting MCP operations |
| `security-standards.md` | Security patterns | Security-related implementations |

This approach keeps the main instructions lean while providing detailed context when needed.
