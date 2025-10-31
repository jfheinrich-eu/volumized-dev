# GitHub Repository Configuration

This directory contains configuration files for managing the volumized-dev repository following GitHub best practices and security guidelines.

## Files

### `settings.yml`

The `settings.yml` file defines repository-level settings that can be managed using the [Probot Settings App](https://github.com/repository-settings/app). This includes:

#### Repository Settings
- **General**: Repository name, description, homepage, and topics
- **Features**: Issues, projects, downloads (wiki disabled for simplicity)
- **Security**: Automated security fixes and vulnerability alerts enabled
- **Merge Options**: Squash merge and rebase merge allowed, merge commits disabled
- **Branch Management**: Auto-delete branches after merge

#### Branch Protection (main branch)
- **Required Reviews**: 1 approval required from code owners
- **Code Owners**: Reviews required from `@jfheinrich-eu/maintainers`
- **Stale Reviews**: Automatically dismissed when new commits are pushed
- **Conversation Resolution**: All conversations must be resolved before merging
- **Status Checks**: Must pass before merging (strict mode - branch must be up to date)
- **Restrictions**: Only maintainers team and jfheinrich-bot can push to main

#### Security Features
- Vulnerability alerts enabled
- Automated security fixes enabled
- Signed commits recommended (optional)

#### Labels
Standard labels for issue and PR management:
- bug, documentation, duplicate, enhancement
- good first issue, help wanted
- security, dependencies, automated

### `workflows/auto-review.yml`

The automated review workflow provides bot-assisted code review when all checks pass.

#### Triggers
- Pull request becomes ready for review
- Pull request is synchronized (new commits)
- Check suite completes successfully
- Any workflow run completes

#### Workflow Steps

1. **Get PR Number**: Extracts the PR number from various event types
2. **Check Status**: Verifies all required status checks have passed
3. **Check Reviewed**: Ensures bot hasn't already reviewed this PR
4. **Perform Review**: Submits an automated approval with summary
5. **Add Label**: Tags PR with "automated" label
6. **Error Handling**: Gracefully handles failures with informative comments

#### Features

**Robust Design:**
- Handles multiple trigger event types (pull_request, check_suite, workflow_run)
- Validates PR state (open, not draft)
- Checks all status checks before reviewing
- Prevents duplicate reviews
- Comprehensive error handling

**Security:**
- Uses `secrets.BOT_TOKEN` for authentication
- Minimal permissions (read contents, write PRs, read checks/statuses)
- Validates PR state before taking action

**User Experience:**
- Detailed review comments with PR statistics
- Clear next steps for human reviewers
- Automated labeling for tracking
- Informative error messages

## Setup Instructions

### 1. Install Probot Settings App

To use the `settings.yml` file:

1. Install the [Probot Settings App](https://github.com/apps/settings) to your repository or organization
2. Grant it access to the `jfheinrich-eu/volumized-dev` repository
3. The app will automatically sync settings from `.github/settings.yml`

### 2. Configure Bot Token

The automated review workflow requires a GitHub token:

1. Create a GitHub App or Personal Access Token with these permissions:
   - `pull_requests: write` - To create reviews and comments
   - `contents: read` - To access repository content
   - `checks: read` - To read check statuses
   - `statuses: read` - To read commit statuses

2. Add the token to repository secrets:
   - Go to Settings → Secrets and variables → Actions
   - Create a new secret named `BOT_TOKEN`
   - Paste your token value

### 3. Create Required Team

The settings reference `@jfheinrich-eu/maintainers` team:

1. Go to https://github.com/orgs/jfheinrich-eu/teams
2. Create a new team named "maintainers"
3. Add team members who should have admin access and review rights

### 4. Configure jfheinrich-bot User

Ensure the `jfheinrich-bot` user:
- Has appropriate repository access
- Is using the `BOT_TOKEN` configured in step 2
- Has permissions to approve PRs

## Testing the Configuration

### Test Settings Sync

After installing the Probot Settings App:
1. Check repository settings match `.github/settings.yml`
2. Verify branch protection rules are active on main
3. Confirm labels have been created

### Test Automated Review

1. Create a test PR
2. Ensure all checks pass
3. Mark PR as "ready for review" (if it was draft)
4. Verify the bot reviews the PR automatically
5. Check that the "automated" label is added

## Maintenance

### Updating Settings

To modify repository settings:
1. Edit `.github/settings.yml`
2. Commit and push changes
3. Probot Settings App will sync within a few minutes
4. Verify changes in repository settings

### Updating Workflow

To modify the automated review workflow:
1. Edit `.github/workflows/auto-review.yml`
2. Test changes in a feature branch first
3. Use GitHub Actions syntax checker
4. Deploy to main after validation

## Best Practices

1. **Keep settings.yml in sync**: Always update settings through the file, not the UI
2. **Test workflows in feature branches**: Use workflow_dispatch for manual testing
3. **Monitor bot activity**: Check Actions tab regularly for workflow runs
4. **Review security alerts**: Address Dependabot and CodeQL alerts promptly
5. **Update dependencies**: Keep GitHub Actions updated to latest versions

## Troubleshooting

### Settings not syncing
- Verify Probot Settings App is installed and has access
- Check app permissions in organization settings
- Review app logs for errors

### Bot not reviewing
- Verify `BOT_TOKEN` secret is configured correctly
- Check workflow run logs in Actions tab
- Ensure bot user has appropriate permissions
- Verify PR meets all conditions (not draft, checks passed)

### Permission errors
- Verify team membership for code reviewers
- Check bot token permissions
- Review branch protection settings

## Security Considerations

1. **Token Security**: Never commit tokens to the repository
2. **Least Privilege**: Bot token has minimal required permissions
3. **Audit Trail**: All bot actions are logged in Actions tab
4. **Code Review**: Human review still required despite bot approval
5. **Vulnerability Scanning**: Enabled at repository level

## References

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Probot Settings](https://github.com/repository-settings/app)
- [Code Owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
