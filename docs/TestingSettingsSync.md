# Testing the Repository Settings Sync Workflow

This document describes how to test the new `sync-repo-settings.yml` workflow.

## Automatic Testing

The workflow is configured to run automatically when:
1. Changes are pushed to `.github/settings.yml` on the `main` branch
2. The workflow is manually triggered via the GitHub Actions UI

## Manual Testing via GitHub UI

### Method 1: Trigger via Actions Tab

1. Navigate to the repository on GitHub
2. Go to the **Actions** tab
3. Find **Sync Repository Settings** in the workflows list
4. Click on the workflow
5. Click the **Run workflow** button
6. Select `main` branch
7. Click **Run workflow**

### Method 2: Test by Modifying settings.yml

1. Create a test branch:
   ```bash
   git checkout -b test-settings-sync
   ```

2. Make a small, harmless change to `.github/settings.yml`:
   ```bash
   # For example, add a test topic to the repository
   yq e '.repository.topics += ["test-automation"]' -i .github/settings.yml
   ```

3. Commit and push the change:
   ```bash
   git add .github/settings.yml
   git commit -m "test: verify settings sync workflow"
   git push origin test-settings-sync
   ```

4. Create a pull request to merge to `main`

5. After merge, check the Actions tab to verify the workflow runs

6. Verify the changes in Repository Settings → General

7. Revert the test change:
   ```bash
   git checkout main
   git pull
   yq e '.repository.topics -= ["test-automation"]' -i .github/settings.yml
   git add .github/settings.yml
   git commit -m "revert: remove test topic"
   git push origin main
   ```

## What the Workflow Does

The workflow applies three categories of settings:

### 1. Repository Settings
- Description
- Homepage URL
- Feature toggles (Issues, Projects, Wiki, Downloads)
- Merge options (Squash, Merge commits, Rebase)
- Branch deletion on merge

### 2. Branch Protection Rules (main branch)
- Required number of approving reviews
- Dismiss stale reviews
- Require code owner reviews
- Require status checks to pass
- Enforce for administrators
- Require linear history
- Allow/disallow force pushes
- Allow/disallow branch deletion
- Require conversation resolution

### 3. Labels
- Creates or updates all labels defined in settings.yml
- Includes name, color, and description

## Expected Workflow Output

When the workflow runs successfully, you should see:

1. ✅ Repository settings applied
2. ✅ Branch protection applied
3. ✅ Labels processed

Each step will show which settings were applied.

## Troubleshooting

### Workflow fails on branch protection step

**Symptom:** Error when applying branch protection rules

**Possible causes:**
1. The `GITHUB_TOKEN` doesn't have sufficient permissions
2. The branch doesn't exist yet
3. Invalid configuration in settings.yml

**Solution:**
1. Verify the workflow has `contents: read` permission (minimum)
2. Ensure the `main` branch exists
3. Validate settings.yml syntax with `yamllint`

### Workflow fails on repository settings step

**Symptom:** API error when updating repository settings

**Possible causes:**
1. Invalid values in settings.yml
2. Token permissions insufficient

**Solution:**
1. Check settings.yml for syntax errors
2. Verify boolean values are `true` or `false` (not quoted)

### Labels not created/updated

**Symptom:** Label step succeeds but labels don't appear

**Possible causes:**
1. Label names contain special characters
2. Color codes are invalid

**Solution:**
1. Ensure label names use only alphanumeric characters, spaces, and hyphens
2. Color codes should be 6-digit hex values (without #)

## Verification Checklist

After running the workflow, verify:

- [ ] Repository description matches settings.yml
- [ ] Repository homepage URL is set correctly
- [ ] Issue/Project/Wiki features match settings
- [ ] Merge button options match settings
- [ ] Branch protection rules are active on main:
  - [ ] Required reviews: 1
  - [ ] Code owner reviews required
  - [ ] Dismiss stale reviews enabled
  - [ ] Conversation resolution required
- [ ] All labels from settings.yml exist in the repository

## Notes

- The workflow uses `yq` to parse YAML files
- All operations use the GitHub CLI (`gh`) and GitHub API
- The workflow is idempotent - running it multiple times produces the same result
- Changes are immediate - no app installation required
