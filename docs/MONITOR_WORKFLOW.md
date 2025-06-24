# GitHub Actions Workflow: Monitor Deploy Azure Lab Environment

This workflow automatically monitors the "Deploy Azure Lab Environment" workflow and creates GitHub issues when deployments fail, ensuring rapid response to CI/CD failures.

---

## Purpose

The monitoring workflow provides automated failure detection and issue tracking for the ThorLabs lab deployment pipeline:

- **Automatic Failure Detection**: Triggers when the deploy workflow fails
- **Intelligent Issue Creation**: Creates detailed GitHub issues with failure context
- **Security-Conscious Logging**: Provides error summaries without exposing sensitive information
- **Streamlined Incident Response**: Labels issues and assigns them to the Software Agent for review

---

## Workflow Trigger

The workflow uses the `workflow_run` event to monitor the "Deploy Azure Lab Environment" workflow:

```yaml
on:
  workflow_run:
    workflows: ["Deploy Azure Lab Environment"]
    types: [completed]
```

**Key Features**:
- Only triggers when the target workflow completes with failure status
- Uses minimal permissions following least-privilege principle
- Runs on `ubuntu-latest` for consistency with other workflows

---

## Security and Permissions

The workflow follows security best practices with minimal required permissions:

```yaml
permissions:
  issues: write      # Create GitHub issues for failed deployments
  actions: read      # Read workflow run details and logs
  contents: read     # Read repository contents (minimal access)
```

**Security Considerations**:
- **Minimal Permissions**: Only the permissions needed for functionality
- **Limited Log Exposure**: Extracts error summaries, not full logs
- **Safe Content Handling**: Sanitizes commit messages and limits content length
- **No Secret Access**: Workflow does not require access to Azure credentials

---

## Issue Creation Details

When a deployment failure is detected, the workflow creates a GitHub issue with:

### Issue Metadata
- **Title**: Timestamped with workflow name and failure date
- **Label**: `ci-failure` for easy filtering and identification
- **Assignee**: `ghcp-agent` for Software Agent review

### Issue Content
- **Workflow Run Link**: Direct link to the failed workflow execution
- **Branch and Commit**: Context about what triggered the failure
- **Error Summary**: High-level summary of failed jobs (limited for security)
- **Next Steps**: Actionable troubleshooting guidance
- **Common Causes**: Reference to common failure scenarios

### Example Issue Structure
```markdown
## Deployment Failure Alert

The **Deploy Azure Lab Environment** workflow has failed and requires attention.

### Failure Details
- **Workflow Run:** [Deploy Azure Lab Environment #12345](https://github.com/...)
- **Branch:** `main`
- **Commit:** `abc1234` - Update infrastructure templates
- **Failed On:** 2024-01-15 14:30:25 UTC

### Error Summary
**Failed Jobs:**
- Deploy Lab Environment
- Deploy Azure Policies

### Next Steps
1. Review the workflow run for detailed error logs
2. Check Azure resources in the portal
3. Verify GitHub Actions secrets configuration
...
```

---

## Monitoring and Troubleshooting

### Workflow Execution
- **View Monitoring**: Check the Actions tab for "Monitor Deploy Azure Lab Environment" runs
- **Failure Detection**: Monitor triggers only on deploy workflow failures
- **Issue Tracking**: All created issues appear in the Issues tab with `ci-failure` label

### Common Monitoring Scenarios

**Normal Operation**:
- Deploy workflow succeeds → No monitoring action taken
- Deploy workflow fails → Issue created automatically

**Troubleshooting Monitoring Failures**:
- **Permission Errors**: Verify repository settings allow issue creation
- **GitHub CLI Failures**: Check GitHub token permissions and API rate limits
- **Missing Assignee**: Ensure `ghcp-agent` exists and has repository access

### Monitoring Configuration

The workflow automatically handles:
- **Rate Limiting**: Respects GitHub API limits through built-in CLI handling
- **Duplicate Prevention**: Timestamped titles prevent duplicate issues
- **Error Resilience**: Continues monitoring even if individual issue creation fails

---

## Integration with ThorLabs Workflows

This monitoring workflow integrates seamlessly with the existing ThorLabs automation:

### Deployment Pipeline
1. **Code Push** → Deploy workflow triggers
2. **Deploy Failure** → Monitor workflow creates issue
3. **Issue Assignment** → Software Agent reviews and resolves

### Documentation References
- **Main Deployment**: See [`DEPLOY_WORKFLOW.md`](DEPLOY_WORKFLOW.md)
- **Secrets Management**: See [`GITHUB_SECRETS_CHECKLIST.md`](GITHUB_SECRETS_CHECKLIST.md)
- **Troubleshooting**: See common issues in deployment workflow documentation

### Workflow Files
- **Deploy Workflow**: `.github/workflows/deploy.yml`
- **Monitor Workflow**: `.github/workflows/monitor.yml`
- **Cleanup Workflow**: `.github/workflows/cleanup-lab.yml`

---

## Best Practices

### For Repository Maintainers
- **Regular Review**: Monitor created issues for patterns in failures
- **Documentation Updates**: Keep troubleshooting guides current
- **Access Control**: Ensure `ghcp-agent` has appropriate repository permissions

### For Developers
- **Issue Response**: Address `ci-failure` labeled issues promptly
- **Failure Analysis**: Use workflow run links for detailed debugging
- **Prevention**: Follow guidance in created issues to prevent recurring failures

---

> **Note**: This workflow is part of the ThorLabs continuous improvement strategy, providing automated incident detection while maintaining security and operational efficiency.