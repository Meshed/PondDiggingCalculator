# Maintenance Runbook

## Overview

This runbook provides operational procedures for maintaining, monitoring, and troubleshooting the Pond Digging Calculator application. It covers common maintenance tasks, performance validation, deployment procedures, and incident response.

## Common Maintenance Tasks

### Updating Dependencies

#### NPM Dependencies Update
```bash
# Check for outdated packages
cd frontend
npm outdated

# Update all dependencies to latest versions
npm update

# Update specific packages
npm install package-name@latest

# Update Elm packages
elm install package-name
```

**Validation After Updates**:
```bash
# Run complete validation pipeline
npm run validate:full

# Test specific components
npm run test:e2e:comprehensive
```

**Rollback Procedure**:
```bash
# Restore previous package-lock.json from git
git checkout HEAD~1 -- package-lock.json
npm install

# Or use npm-check-updates for selective rollback
npx npm-check-updates --rollback
```

#### Elm Package Updates
```bash
# Check for Elm package updates
elm install

# Update elm.json dependencies
# Edit elm.json manually or use elm-json tool
npm install -g elm-json
elm-json upgrade
```

**Post-Update Verification**:
```bash
# Verify compilation
npm run build

# Run all tests
npm run validate

# Check for breaking changes in API
npm run test:e2e:user-journeys
```

### Configuration Management Updates

#### Equipment Defaults Updates
**File**: `frontend/public/config.json` (current) or `config/equipment-defaults.json` (future)

**Common Changes**:
1. **Add New Equipment Type**:
```json
{
  "defaults": {
    "excavators": [
      {
        "bucketCapacity": 3.5,
        "cycleTime": 1.8,
        "name": "CAT 350 Large Excavator"
      }
    ]
  }
}
```

2. **Update Validation Ranges**:
```json
{
  "validation": {
    "excavatorCapacity": { "min": 0.5, "max": 20.0 }
  }
}
```

3. **Modify Fleet Limits**:
```json
{
  "fleetLimits": {
    "maxExcavators": 15,
    "maxTrucks": 30
  }
}
```

**Validation Process**:
```bash
# Validate JSON syntax
npx jsonlint config.json

# Test configuration loading
npm run validate:config

# Run full regression
npm run validate:full
```

#### Build-time Configuration Updates (Future)
```bash
# Update configuration file
vi config/equipment-defaults.json

# Regenerate Elm configuration
npm run generate:config

# Rebuild application
npm run build

# Deploy updated application
npm run deploy
```

### Performance Monitoring Updates

#### Performance Budget Adjustments
**File**: `frontend/lighthouse.config.js` (future implementation)

```javascript
module.exports = {
  extends: 'lighthouse:default',
  settings: {
    budgets: [{
      resourceSizes: [{
        resourceType: 'total',
        budget: 500 // KB
      }],
      timings: [{
        metric: 'first-contentful-paint',
        budget: 2000 // ms
      }]
    }]
  }
};
```

#### Performance Monitoring Setup
```bash
# Install Lighthouse CI
npm install -g @lhci/cli

# Run performance audit
lhci autorun

# Generate performance report
npm run audit:performance
```

## Troubleshooting Procedures

### Application Won't Load

#### Symptom: Blank white screen or loading spinner
**Diagnosis Steps**:
1. **Check Browser Console**:
   ```javascript
   // Look for JavaScript errors
   console.log("Application status:", window.Elm);
   ```

2. **Verify Configuration Loading**:
   ```bash
   # Check if config.json is accessible
   curl http://localhost:1234/config.json
   
   # Validate JSON syntax
   npx jsonlint frontend/public/config.json
   ```

3. **Check Build Output**:
   ```bash
   # Verify build completed successfully
   ls -la frontend/dist/
   
   # Check for compilation errors
   npm run build 2>&1 | tee build.log
   ```

**Resolution Steps**:
```bash
# Clear build cache and rebuild
npm run clean
npm run build

# Use fallback configuration
# Edit Utils/Config.elm to force fallback mode
```

#### Symptom: Configuration not loading
**Diagnosis**:
```javascript
// Browser console debugging
fetch('/config.json')
  .then(response => response.json())
  .then(config => console.log('Config loaded:', config))
  .catch(error => console.error('Config error:', error));
```

**Resolution**:
```bash
# Verify config file exists and is valid
cat frontend/public/config.json | jq .

# Check file permissions
ls -la frontend/public/config.json

# Test with minimal configuration
cp frontend/public/config.json frontend/public/config.json.backup
echo '{"version":"1.0.0","defaults":{},"fleetLimits":{},"validation":{}}' > frontend/public/config.json
```

### Calculation Errors

#### Symptom: Incorrect calculation results
**Diagnosis Process**:
1. **Unit Test Validation**:
   ```bash
   # Run calculation-specific tests
   npm test -- --grep "CalculationTests"
   
   # Test with known values
   npm run test:watch
   ```

2. **Input Validation Check**:
   ```elm
   -- Add Debug.log statements to Utils/Calculations.elm
   calculatePondVolume length width depth =
       let
           volume = length * width * depth
           _ = Debug.log "Pond volume calculation" { length = length, width = width, depth = depth, result = volume }
       in
       volume
   ```

3. **Configuration Validation**:
   ```bash
   # Check equipment defaults are reasonable
   jq '.defaults.excavators[] | select(.bucketCapacity > 20)' frontend/public/config.json
   ```

**Resolution Steps**:
```bash
# Update calculation tests with correct expected values
# Run regression tests
npm run validate

# Update documentation if calculation logic changed
# Commit fix with comprehensive test coverage
```

#### Symptom: Validation errors not displaying
**Diagnosis**:
```javascript
// Browser console debugging
window.addEventListener('error', function(e) {
    console.log('Validation error:', e);
});
```

**Resolution**:
```bash
# Check ValidationMessage component rendering
npm run test -- --grep "ValidationMessage"

# Verify error state propagation
npm run test -- --grep "validation.*integration"
```

### Performance Issues

#### Symptom: Slow initial load time
**Diagnosis Tools**:
```bash
# Lighthouse performance audit
npx lighthouse http://localhost:1234 --output html --output-path ./report.html

# Bundle size analysis
npx webpack-bundle-analyzer frontend/dist/

# Network timing analysis
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:1234
```

**Resolution Steps**:
```bash
# Optimize bundle size
npm run build -- --analyze

# Enable compression
# Add gzip compression to deployment

# Lazy load non-critical components
# Review Html.Lazy usage in components
```

#### Symptom: Slow calculation response
**Performance Profiling**:
```elm
-- Add performance timing to Utils/Calculations.elm
calculateProjectTimeline project equipment =
    let
        startTime = performance.now() -- Via ports
        result = actualCalculation project equipment
        endTime = performance.now()
        _ = Debug.log "Calculation time" (endTime - startTime)
    in
    result
```

**Optimization Steps**:
```bash
# Profile calculation performance
npm run test:performance

# Check for unnecessary re-calculations
# Review debounce implementation
# Optimize pure function implementations
```

### Build and Deployment Issues

#### Symptom: Build failure
**Common Causes and Solutions**:

1. **Elm Compilation Errors**:
   ```bash
   # Check for type mismatches
   npx elm make src/Main.elm --output=/dev/null
   
   # Review recent changes
   git diff HEAD~1 -- frontend/src/
   ```

2. **Asset Processing Errors**:
   ```bash
   # Check Tailwind CSS compilation
   npm run build:css
   
   # Verify Parcel bundling
   npx parcel build frontend/public/index.html --no-minify
   ```

3. **Dependency Conflicts**:
   ```bash
   # Clean node_modules and reinstall
   rm -rf frontend/node_modules frontend/package-lock.json
   cd frontend && npm install
   ```

**Resolution Workflow**:
```bash
# Start with clean environment
npm run clean
npm install
npm run validate

# If still failing, use git bisect to find problematic commit
git bisect start
git bisect bad HEAD
git bisect good [last-known-good-commit]
```

#### Symptom: Deployment failure
**GitHub Actions Debugging**:
```yaml
# Add debug step to workflow
- name: Debug Build Environment
  run: |
    node --version
    npm --version
    ls -la frontend/
    cat frontend/package.json
```

**Manual Deployment**:
```bash
# Local deployment test
npm run build
npx serve frontend/dist

# Manual GitHub Pages deployment
npm install -g gh-pages
cd frontend && npx gh-pages -d dist
```

## Monitoring and Performance Validation Procedures

### Automated Performance Monitoring

#### Lighthouse CI Integration
```yaml
# .github/workflows/performance.yml
name: Performance Monitoring
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli
          lhci autorun
```

#### Performance Budget Validation
```bash
# Create performance validation script
#!/bin/bash
# scripts/validate-performance.sh

# Build application
npm run build

# Start local server
npm run serve &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Run Lighthouse audit
npx lighthouse http://localhost:1234 \
  --budget-path=lighthouse-budget.json \
  --output=json \
  --output-path=performance-report.json

# Check if budget passed
if [ $? -eq 0 ]; then
    echo "✅ Performance budget passed"
else
    echo "❌ Performance budget failed"
    exit 1
fi

# Cleanup
kill $SERVER_PID
```

### Manual Performance Testing

#### Load Time Validation
```javascript
// Browser console testing script
const startTime = performance.now();

// Trigger application load
location.reload();

window.addEventListener('load', function() {
    const loadTime = performance.now() - startTime;
    console.log(`Load time: ${loadTime}ms`);
    
    if (loadTime > 3000) {
        console.warn('⚠️ Load time exceeds 3s target');
    } else {
        console.log('✅ Load time within target');
    }
});
```

#### Memory Leak Detection
```javascript
// Memory monitoring script
let memoryTests = [];

function checkMemory() {
    if (performance.memory) {
        const memory = {
            used: performance.memory.usedJSHeapSize,
            total: performance.memory.totalJSHeapSize,
            limit: performance.memory.jsHeapSizeLimit
        };
        
        memoryTests.push({
            timestamp: Date.now(),
            memory: memory
        });
        
        console.log('Memory usage:', memory);
    }
}

// Run memory check every 30 seconds
setInterval(checkMemory, 30000);

// Run for 10 minutes, then analyze
setTimeout(() => {
    console.log('Memory test results:', memoryTests);
    
    const memoryGrowth = memoryTests[memoryTests.length - 1].memory.used - memoryTests[0].memory.used;
    
    if (memoryGrowth > 10 * 1024 * 1024) { // 10MB growth
        console.warn('⚠️ Potential memory leak detected');
    } else {
        console.log('✅ Memory usage stable');
    }
}, 10 * 60 * 1000);
```

### Error Monitoring

#### Client-Side Error Tracking
```javascript
// Add to frontend/public/index.html
window.addEventListener('error', function(event) {
    const errorData = {
        message: event.message,
        filename: event.filename,
        line: event.lineno,
        column: event.colno,
        stack: event.error ? event.error.stack : null,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href
    };
    
    console.error('Application Error:', errorData);
    
    // Send to logging service (if configured)
    if (window.errorLogger) {
        window.errorLogger.log(errorData);
    }
});

// Catch unhandled promise rejections
window.addEventListener('unhandledrejection', function(event) {
    console.error('Unhandled Promise Rejection:', event.reason);
});
```

#### Elm Runtime Error Handling
```elm
-- Ports/ErrorLogging.elm
port module Ports.ErrorLogging exposing (logError)

import Json.Encode as Encode

port logError : Encode.Value -> Cmd msg

-- Usage in application
logApplicationError : String -> String -> Cmd msg
logApplicationError context message =
    Encode.object
        [ ("context", Encode.string context)
        , ("message", Encode.string message)
        , ("timestamp", Encode.string (formatTimestamp currentTime))
        ]
        |> logError
```

## Rollback Procedures

### Failed Deployment Rollback

#### GitHub Pages Rollback
```bash
# Method 1: Revert commit and redeploy
git revert HEAD
git push origin main
# GitHub Actions will automatically redeploy

# Method 2: Manual rollback to previous version
git checkout gh-pages
git reset --hard HEAD~1  # Go back one deployment
git push --force origin gh-pages
```

#### Configuration Rollback
```bash
# Rollback configuration file
git checkout HEAD~1 -- frontend/public/config.json
git commit -m "Rollback configuration to previous version"
git push origin main

# Or restore from backup
cp frontend/public/config.json.backup frontend/public/config.json
```

### Database/State Rollback (Future Implementation)

#### Local Storage Cleanup
```javascript
// Clear problematic local storage
localStorage.removeItem('pond-calculator-state');
localStorage.removeItem('pond-calculator-preferences');

// Reset to default state
localStorage.setItem('pond-calculator-reset', 'true');
location.reload();
```

#### User Data Migration (Future)
```javascript
// Data migration script template
function migrateUserData(oldVersion, newVersion) {
    const userData = localStorage.getItem('user-data');
    
    if (userData) {
        const parsed = JSON.parse(userData);
        
        // Apply migration transformations
        const migrated = applyMigration(parsed, oldVersion, newVersion);
        
        localStorage.setItem('user-data', JSON.stringify(migrated));
        localStorage.setItem('data-version', newVersion);
    }
}
```

## Quick Reference Guide

### Critical Operations Checklist

#### Pre-Deployment Checklist
- [ ] Run `npm run validate:full` - all tests pass
- [ ] Run `npm run build` - build succeeds
- [ ] Test on localhost - application loads correctly
- [ ] Check browser console - no JavaScript errors
- [ ] Validate configuration - defaults load correctly
- [ ] Performance test - load time < 3s
- [ ] Cross-browser test - Chrome, Firefox, Edge work

#### Post-Deployment Verification
- [ ] Production URL loads - https://your-domain.github.io/pond-calculator
- [ ] Configuration loads - check Network tab for config.json
- [ ] Core functionality - complete a calculation
- [ ] Mobile compatibility - test on mobile device
- [ ] Error handling - test with invalid inputs
- [ ] Performance check - Lighthouse score > 90

#### Emergency Response Steps
1. **Immediate**: Rollback to previous version if critical failure
2. **Assess**: Determine scope and impact of issue
3. **Communicate**: Update users if service degradation expected
4. **Fix**: Apply minimal fix to resolve critical issue
5. **Test**: Validate fix in staging environment
6. **Deploy**: Push fix to production
7. **Monitor**: Watch for resolution confirmation
8. **Document**: Record incident and resolution for future reference

### Common Commands Reference
```bash
# Development
npm run dev                    # Start development server
npm run validate              # Run complete validation
npm run clean                 # Clean build artifacts

# Testing
npm test                      # Unit and integration tests
npm run test:e2e              # End-to-end tests
npm run test:watch            # Watch mode testing

# Build and Deploy
npm run build                 # Production build
npm run deploy                # Deploy to production (if configured)

# Maintenance
npm outdated                  # Check for package updates
npm audit                     # Security vulnerability check
npm run format                # Format code
```

### Emergency Contacts and Resources
- **Repository**: https://github.com/your-org/pond-digging-calculator
- **Documentation**: `docs/` directory in repository
- **Issue Tracking**: GitHub Issues
- **Performance Monitoring**: Lighthouse CI reports
- **Error Logs**: Browser console, GitHub Actions logs

This runbook should be updated regularly as the application evolves and new operational procedures are established.