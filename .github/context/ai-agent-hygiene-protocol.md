# 🤖 AI Agent Project Hygiene Protocol

## Purpose
This document provides systematic guidelines for AI agents (like GitHub Copilot) to automatically perform project hygiene and optimization during coding sessions, without requiring user intervention.

## When to Trigger Hygiene Checks

### Automatic Triggers
- **After creating 3+ new files** in a session
- **After modifying documentation** across multiple files
- **After infrastructure changes** (Bicep/ARM templates)
- **End of coding session** (when user indicates completion)
- **When file counts exceed thresholds** (see metrics below)

### Manual Triggers
- User says phrases like: "clean up", "optimize", "consolidate", "organize"
- User mentions file/folder confusion or difficulty finding things
- User asks about project structure or organization

## Hygiene Assessment Protocol

### 1. File Relevance Analysis
```bash
# Check for potentially outdated files
find . -type f -name "*.md" -mtime +90  # Documentation older than 90 days
find . -type f -name "*.bicep" ! -path "./infra/*"  # Bicep files outside infra/
find . -type f -name "*.json" ! -name "*.parameters.json" ! -path "./infra/*"  # Compiled JSON outside infra/
```

**AI Actions:**
- Compare file modification dates with git activity
- Identify files with overlapping content/purpose
- Flag files that haven't been referenced recently
- Suggest consolidation opportunities

### 2. Documentation Consolidation Assessment
```bash
# Analyze documentation structure
find docs/ -name "*.md" -exec wc -l {} + | sort -n
grep -r "# " docs/ | cut -d: -f1 | sort | uniq -c | sort -nr
```

**AI Checks:**
- **Duplicate content**: Similar headings, overlapping topics
- **Length imbalance**: Very short docs (<20 lines) that could be merged
- **Naming inconsistencies**: Similar file names with different conventions
- **Cross-references**: Broken or unnecessary internal links

### 3. Infrastructure Organization Review
```bash
# Check infrastructure file organization
find . -name "*.bicep" -exec dirname {} \; | sort | uniq -c
find . -name "*.parameters.json" | while read f; do echo "$f: $(basename "$f" .parameters.json).bicep"; done
```

**AI Actions:**
- Verify modular architecture compliance
- Check for orphaned parameter files
- Identify files that should be in modules/
- Validate naming convention adherence

### 4. Script and Automation Cleanup
```bash
# Analyze script relevance and organization
find scripts/ -name "*.sh" -exec git log --since="90 days ago" --oneline {} \; | wc -l
find . -name "*.sh" ! -path "./scripts/*" ! -path "./.git/*"
```

**AI Checks:**
- Scripts that haven't been modified or referenced
- Functionality overlap between scripts
- Missing executable permissions
- Scripts in wrong directories

## Decision Matrix

### Consolidation Criteria
| Condition | Action |
|-----------|--------|
| 2+ docs with same topic, <30 lines each | **MERGE** - Combine into single comprehensive doc |
| 3+ Bicep files with similar resources | **MODULARIZE** - Extract common patterns to modules/ |
| Documentation >100 lines covering multiple topics | **SPLIT** - Break into focused, single-purpose files |
| Scripts with overlapping functionality | **REFACTOR** - Create unified script with subcommands |
| Files not modified in 120+ days with no git refs | **ARCHIVE** - Move to archive/ or remove if truly obsolete |

### File Relevance Scoring
- **High relevance** (keep): Modified <30 days, referenced in recent commits
- **Medium relevance** (review): Modified 30-90 days, some recent activity  
- **Low relevance** (consolidate/remove): Modified >90 days, no recent references
- **Obsolete** (remove): Modified >180 days, no git activity, superseded functionality

## AI Agent Actions

### Proactive Cleanup Steps
1. **Scan project structure** using file search tools
2. **Analyze content overlap** using semantic search
3. **Check git activity** for usage patterns
4. **Identify consolidation opportunities**
5. **Propose specific actions** with file lists
6. **Execute approved changes** (merge, move, delete)
7. **Update references** and documentation indices

### Communication Protocol
```
🧹 **Project Hygiene Check**
I noticed [trigger condition]. Let me analyze the current structure:

📁 **Current State:**
- [X] documentation files (Y may need consolidation)
- [X] infrastructure templates (Y organization issues)
- [X] scripts (Y potentially obsolete)

🎯 **Recommendations:**
1. **Merge:** [specific files] → [consolidated file] (reason)
2. **Move:** [files] → [better location] (reason)
3. **Remove:** [files] (reason: obsolete/superseded)

Shall I proceed with these optimizations?
```

### Safe Execution Rules
- **Always ask before removing files** (even if obsolete)
- **Create backups** for major consolidations
- **Update all references** when moving/renaming files
- **Test infrastructure** after Bicep changes
- **Preserve git history** (don't delete tracked files without confirmation)

## Quality Metrics

### Optimal Project Health Indicators
- **Documentation ratio**: 1 doc per 2-3 infrastructure templates
- **Average doc length**: 30-150 lines (focused but comprehensive)
- **Infrastructure organization**: >90% of Bicep files in infra/ or modules/
- **Script efficiency**: No duplicate functionality, clear purposes
- **File freshness**: >80% of files modified within 90 days

### Warning Thresholds
- **Too many small docs**: >5 files under 20 lines in docs/
- **Documentation sprawl**: >15 total docs without clear index
- **Infrastructure chaos**: Bicep files scattered across >3 directories
- **Script bloat**: >10 shell scripts with unclear purposes
- **Stale content**: >30% of files not modified in 120+ days

## Integration with Copilot Instructions

### Update Copilot Instructions
Add this section to `.github/copilot-instructions.md`:

```markdown
## AI AGENT HYGIENE: Automatic Project Optimization
- **After significant changes**: Automatically assess project structure
- **Trigger phrases**: "clean up", "optimize", "consolidate", "organize"  
- **Protocol**: Follow `.github/context/ai-agent-hygiene-protocol.md`
- **Safe execution**: Always confirm before removing files
- **Focus areas**: Documentation consolidation, infrastructure organization, script efficiency
```

## Example Scenarios

### Scenario 1: Documentation Cleanup
**Trigger**: Created 4 new markdown files in docs/
**AI Analysis**: Found 3 files under 15 lines covering Azure setup
**Action**: Propose merging into comprehensive "Azure Setup Guide"
**Result**: Reduced file count, improved discoverability

### Scenario 2: Infrastructure Optimization  
**Trigger**: Modified 5+ Bicep templates
**AI Analysis**: Found repeated Key Vault configurations
**Action**: Extract to modules/keyvault.bicep, update references
**Result**: DRY compliance, easier maintenance

### Scenario 3: Script Consolidation
**Trigger**: Added new deployment script
**AI Analysis**: Found 3 scripts with similar Azure CLI operations
**Action**: Propose unified `scripts/azure-operations.sh` with subcommands
**Result**: Single tool, consistent interface, reduced complexity

---

**This protocol enables AI agents to be proactive custodians of project quality, automatically identifying and resolving organizational issues without user intervention.**
