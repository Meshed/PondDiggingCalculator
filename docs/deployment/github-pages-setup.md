# GitHub Pages Deployment Setup Guide

## Overview
This guide provides comprehensive instructions for deploying the Pond Digging Calculator to GitHub Pages, including custom domain configuration, HTTPS setup, and deployment procedures.

## Prerequisites
- GitHub repository with admin access
- Node.js 18+ and npm installed locally
- Git configured with repository access
- (Optional) Custom domain with DNS management access

## Repository Configuration

### 1. Enable GitHub Pages
1. Navigate to your repository on GitHub
2. Go to **Settings** → **Pages** (in the left sidebar)
3. Under **Source**, select **GitHub Actions** as the deployment source
4. Save the changes

### 2. Configure Deployment Permissions
1. Go to **Settings** → **Environments**
2. Click on **github-pages** environment (created automatically)
3. Configure protection rules:
   - Required reviewers: Set as needed for your team
   - Deployment branches: Restrict to `main` branch only
4. Save protection rules

### 3. Set Up Repository Secrets (if needed)
No additional secrets are required for basic GitHub Pages deployment. The workflow uses the built-in `GITHUB_TOKEN` for authentication.

## Deployment Workflow

### Automatic Deployment
The application automatically deploys to GitHub Pages when:
- Code is pushed to the `main` branch
- All tests pass successfully
- Build process completes without errors

### Manual Deployment
To trigger a manual deployment:
1. Go to **Actions** tab in your repository
2. Select **Deploy to GitHub Pages** workflow
3. Click **Run workflow**
4. Select the branch and click **Run workflow**

### Deployment Process
1. **Test Phase**: Runs all tests and validations
2. **Build Phase**: Compiles Elm code and processes assets
3. **Deploy Phase**: Publishes to GitHub Pages

## Custom Domain Configuration

### 1. DNS Configuration
Add the following DNS records to your domain:

#### For apex domain (example.com):
```
Type: A
Name: @
Value: 185.199.108.153
       185.199.109.153
       185.199.110.153
       185.199.111.153
```

#### For subdomain (www.example.com):
```
Type: CNAME
Name: www
Value: [your-username].github.io
```

### 2. GitHub Configuration
1. Create a CNAME file in `frontend/public/`:
   ```
   echo "your-domain.com" > frontend/public/CNAME
   ```
2. Commit and push the CNAME file
3. In repository **Settings** → **Pages**:
   - Enter your custom domain
   - Wait for DNS check to complete (can take up to 24 hours)
   - Enable **Enforce HTTPS** once available

### 3. Domain Verification
1. GitHub will automatically verify domain ownership
2. Check status in **Settings** → **Pages**
3. Look for green checkmark next to your domain

## HTTPS Configuration

### Automatic HTTPS
GitHub Pages automatically provisions Let's Encrypt certificates for:
- Default github.io domains
- Custom domains (after DNS verification)

### HTTPS Enforcement
1. Wait for certificate provisioning (up to 24 hours after domain setup)
2. In **Settings** → **Pages**, check **Enforce HTTPS**
3. All HTTP traffic will redirect to HTTPS

### Troubleshooting HTTPS Issues
If HTTPS isn't working:
1. Verify DNS records are correctly configured
2. Check domain verification status in GitHub
3. Clear browser cache and cookies
4. Wait up to 24 hours for certificate provisioning
5. Try accessing via incognito/private browsing

## Branch Protection Rules

### Main Branch Protection
1. Go to **Settings** → **Branches**
2. Add rule for `main` branch:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
     - Select: `test` (from deploy-static.yml)
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators (optional but recommended)
3. Create the protection rule

### Deployment Branch Protection
The GitHub Pages deployment uses GitHub's built-in deployment system, which automatically manages the deployment branch. No manual gh-pages branch is created or needs protection.

## Rollback Procedures

### Quick Rollback via GitHub Actions
1. Go to **Actions** tab
2. Select **Rollback Deployment** workflow
3. Click **Run workflow**
4. Enter:
   - Commit SHA to rollback to
   - Reason for rollback
5. Click **Run workflow**

### Manual Rollback via Git
```bash
# Find the commit to rollback to
git log --oneline -10

# Create a rollback branch
git checkout -b rollback-fix main
git revert HEAD  # or specific commit

# Push and create PR
git push origin rollback-fix

# After PR merge, deployment will automatically trigger
```

### Rollback Verification
After rollback:
1. Check deployment status in **Actions** tab
2. Verify site functionality at deployment URL
3. Review automatically created GitHub issue for rollback
4. Plan and implement permanent fix

## Deployment URLs

### Default GitHub Pages URL
```
https://[username].github.io/PondDiggingCalculator/
```

### With Custom Domain
```
https://your-domain.com/
```

### Preview Deployments
GitHub Pages doesn't support preview deployments natively. For PR previews, consider:
- Local testing with `npm run dev`
- Deploying to a separate test repository
- Using third-party services like Netlify for PR previews

## Monitoring Deployments

### Deployment Status
1. **Actions Tab**: View real-time deployment progress
2. **Settings → Pages**: Check current deployment status
3. **Environment URL**: Listed in workflow run summary

### Deployment History
View deployment history:
1. Go to **Actions** → **Deploy to GitHub Pages**
2. Click on any workflow run to see details
3. Check artifacts for built files

### Performance Monitoring
Monitor deployment performance:
- Build time: Check workflow run duration
- Bundle size: Review artifact sizes in Actions
- Site performance: Use GitHub Pages built-in analytics (if enabled)

## Troubleshooting

### Common Issues and Solutions

#### Build Fails
- Check error logs in GitHub Actions
- Verify all dependencies are in package.json
- Ensure elm.json is properly configured
- Run `npm run validate` locally to reproduce

#### Deployment Succeeds but Site Not Updated
- Clear browser cache (Ctrl+Shift+R)
- Check correct URL (with or without trailing slash)
- Verify CNAME file if using custom domain
- Wait 10 minutes for CDN propagation

#### 404 Errors
- Ensure `frontend/dist/index.html` exists
- Check build output includes all necessary files
- Verify no .gitignore blocking required files
- Check GitHub Pages is enabled in settings

#### Custom Domain Not Working
- Verify DNS propagation (use `nslookup` or online tools)
- Check CNAME file is in correct location
- Ensure domain verification completed in GitHub
- Wait up to 48 hours for full propagation

### Getting Help
1. Check GitHub Actions logs for detailed error messages
2. Review [GitHub Pages documentation](https://docs.github.com/pages)
3. Open issue in repository with deployment logs
4. Contact GitHub Support for infrastructure issues

## Security Considerations

### Secrets Management
- Never commit sensitive data to the repository
- Use GitHub Secrets for API keys (if needed in future)
- Review workflow permissions regularly

### Access Control
- Limit deployment permissions to trusted maintainers
- Use environment protection rules
- Enable required reviews for production deployments
- Audit deployment access regularly

### Content Security
- Implement Content Security Policy headers
- Use HTTPS enforcement
- Regular security updates for dependencies
- Monitor GitHub security alerts

## Maintenance

### Regular Tasks
- Review and update dependencies monthly
- Monitor deployment success rate
- Clean up old workflow artifacts
- Update documentation as needed

### Dependency Updates
```bash
cd frontend
npm update
npm audit fix
npm run validate
```

### Performance Optimization
- Monitor bundle sizes in build artifacts
- Review Lighthouse scores periodically
- Optimize images and assets
- Enable caching headers where appropriate