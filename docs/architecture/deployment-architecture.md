# Deployment Architecture

## Deployment Strategy

**Frontend Deployment:**
- **Platform:** GitHub Pages (primary) with Netlify as backup option
- **Build Command:** `npm run build` (Parcel bundling with Tailwind CSS processing)
- **Output Directory:** `frontend/dist/` containing optimized static files
- **CDN/Edge:** GitHub Pages global CDN for fast worldwide delivery

**Backend Deployment (Future F# Integration):**
- **Platform:** Azure App Service or AWS Elastic Beanstalk
- **Build Command:** `dotnet publish -c Release -o publish/`
- **Deployment Method:** Docker containers with automated CI/CD pipeline

## CI/CD Pipeline

**GitHub Actions Workflow (.github/workflows/deploy-static.yml):**
```yaml
name: Deploy Static Site

on:
  push:
    branches: [ main ]

env:
  NODE_VERSION: '18'
  ELM_VERSION: '0.19.1'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install Elm
        run: npm install -g elm@${{ env.ELM_VERSION }}

      - name: Install dependencies
        run: |
          cd frontend
          npm ci

      - name: Run Elm tests
        run: |
          cd frontend
          npm run test

      - name: Build application
        run: |
          cd frontend
          npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Build for production
        run: |
          cd frontend
          npm ci
          npm run build

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./frontend/dist
```

## Environments

| Environment | Frontend URL | Backend URL (Future) | Purpose |
|-------------|-------------|-------------------|---------|
| Development | http://localhost:3000 | http://localhost:5000 | Local development |
| Staging | https://staging.your-domain.com | https://api-staging.your-domain.com | Pre-production testing |
| Production | https://your-domain.github.io/PondDiggingCalculator | https://api.your-domain.com | Live environment |
