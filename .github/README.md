# GitHub Repository Configuration

This directory contains configuration files for managing the volumized-dev repository following GitHub best practices and security guidelines.

## Files

### `settings.yml`

The `settings.yml` file defines repository-level settings that are automatically applied via the `sync-repo-settings.yml` workflow. This includes:

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

### `workflows/sync-repo-settings.yml`

The repository settings sync workflow automatically applies configuration from `settings.yml` to the repository.

#### Triggers
- Push to main branch when `.github/settings.yml` is modified
- Manual workflow dispatch

#### Workflow Steps

1. **Apply Repository Settings**: Updates repository description, homepage, features, and merge options
2. **Apply Branch Protection**: Configures branch protection rules for the main branch
3. **Create Labels**: Creates or updates issue and PR labels

#### Features

**Automated Configuration:**
- No need for external GitHub Apps (like Probot Settings)
- Settings applied directly via GitHub API
- Runs automatically when settings.yml is updated

**Security:**
- Uses `GITHUB_TOKEN` for authentication
- Minimal required permissions
- Settings validated before application

**User Experience:**
- Clear step-by-step output
- Detailed summary of applied settings
- Error handling with informative messages

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

### 1. Automatic Settings Sync

The repository settings are now automatically applied via the `sync-repo-settings.yml` workflow:

1. Edit `.github/settings.yml` to modify repository configuration
2. Commit and push changes to the main branch
3. The workflow will automatically apply the settings within a few minutes
4. Verify changes in repository settings page

**Note:** This replaces the need for the Probot Settings App. Settings are applied directly via GitHub Actions.

### 2. Configure Bot Token (Optional)

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

**Note:** This is only required for the automated review workflow, not for settings sync.

### 3. Create Required Team (Optional)

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

After pushing changes to `.github/settings.yml`:
1. Go to Actions tab and verify the "Sync Repository Settings" workflow ran
2. Check repository settings match `.github/settings.yml`
3. Verify branch protection rules are active on main
4. Confirm labels have been created

You can also manually trigger the workflow:
1. Go to Actions → Sync Repository Settings
2. Click "Run workflow"
3. Select the main branch and run

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
2. Commit and push changes to main branch
3. The workflow will automatically apply settings within a few minutes
4. Verify changes in repository settings page

Alternatively, manually trigger the workflow after making changes:
1. Go to Actions → Sync Repository Settings
2. Click "Run workflow" to apply immediately

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
- Check the "Sync Repository Settings" workflow run in the Actions tab for errors
- Verify `.github/settings.yml` syntax is correct (valid YAML)
- Ensure the workflow has sufficient permissions (default GITHUB_TOKEN should work)
- Check workflow logs for specific error messages

### Branch protection errors
- The workflow requires admin permissions to set branch protection rules
- Default GITHUB_TOKEN has these permissions when triggered from main branch
- If errors occur, verify repository settings allow Actions to modify protection rules

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
- [GitHub REST API - Repos](https://docs.github.com/en/rest/repos/repos)
- [GitHub REST API - Branch Protection](https://docs.github.com/en/rest/branches/branch-protection)
- [Code Owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
