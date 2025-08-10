# Troubleshooting Guide

## Common Issues and Solutions

### Application Startup Issues

#### Issue: Application shows blank white screen
**Symptoms**:
- White screen instead of application interface
- No visible UI elements
- Browser loading spinner may persist

**Diagnosis Steps**:
1. Check browser developer console for JavaScript errors
2. Verify network requests in Network tab
3. Check if config.json loads successfully

**Common Causes and Solutions**:

**Cause: JavaScript compilation error**
```javascript
// Browser console will show Elm compilation errors
Uncaught TypeError: Cannot read property 'init' of undefined
```
**Solution**:
```bash
# Clean build and recompile
npm run clean
npm run build

# Check for Elm compilation errors
npx elm make src/Main.elm
```

**Cause: Configuration loading failure**
```javascript
// Network tab shows 404 for config.json
GET /config.json 404 (Not Found)
```
**Solution**:
```bash
# Verify config file exists
ls -la frontend/public/config.json

# Test config loading manually
curl http://localhost:1234/config.json

# Use fallback configuration temporarily
# Edit Utils/Config.elm to return fallbackConfig directly
```

**Cause: Invalid JSON in configuration**
```javascript
// Console shows JSON parsing error
SyntaxError: Unexpected token in JSON
```
**Solution**:
```bash
# Validate JSON syntax
npx jsonlint frontend/public/config.json

# Fix JSON syntax errors or restore from backup
cp frontend/public/config.json.backup frontend/public/config.json
```

#### Issue: Application loads but shows error message
**Symptoms**:
- Application interface visible but shows error state
- Error message about configuration or validation
- Some functionality may be disabled

**Diagnosis**:
Check the specific error message displayed in the application UI.

**Solution by Error Type**:

**"Configuration could not be loaded"**:
```bash
# Check config file validity
cat frontend/public/config.json | jq empty

# Verify all required config sections exist
jq '.defaults, .fleetLimits, .validation' frontend/public/config.json
```

**"Invalid equipment configuration"**:
```bash
# Check equipment defaults structure
jq '.defaults.excavators[0] | keys' frontend/public/config.json
# Should return: ["bucketCapacity", "cycleTime", "name"]

jq '.defaults.trucks[0] | keys' frontend/public/config.json
# Should return: ["capacity", "roundTripTime", "name"]
```

**"Validation rules missing"**:
```bash
# Ensure all validation ranges are present
jq '.validation | keys' frontend/public/config.json
# Should include: excavatorCapacity, cycleTime, truckCapacity, etc.
```

### Calculation and Validation Issues

#### Issue: Calculations return incorrect results
**Symptoms**:
- Timeline or cost estimates seem unrealistic
- Results inconsistent with input values
- Mathematical errors in displayed calculations

**Debugging Process**:

1. **Enable Debug Logging**:
```elm
-- Add to Utils/Calculations.elm
calculatePondVolume : Float -> Float -> Float -> Float
calculatePondVolume length width depth =
    let
        volume = length * width * depth
        _ = Debug.log "Pond Volume Calculation" 
            { length = length, width = width, depth = depth, result = volume }
    in
    volume
```

2. **Test with Known Values**:
```bash
# Run calculation tests with expected results
npm test -- --grep "CalculationTests"

# Test specific calculation scenarios
elm repl
> import Utils.Calculations exposing (..)
> calculatePondVolume 50 30 5
```

3. **Verify Configuration Values**:
```bash
# Check equipment defaults are reasonable
jq '.defaults.excavators[0].bucketCapacity' frontend/public/config.json
# Should be 0.5-15.0 range

jq '.defaults.excavators[0].cycleTime' frontend/public/config.json
# Should be 0.5-10.0 range
```

**Common Calculation Fixes**:

**Issue: Volume calculation incorrect**
```elm
-- Check for unit conversion errors
calculatePondVolume : Float -> Float -> Float -> Float
calculatePondVolume length width depth =
    -- Ensure all dimensions are in same units (feet)
    length * width * depth -- Result in cubic feet
    
-- Convert to cubic yards if needed
cubicFeetToCubicYards : Float -> Float
cubicFeetToCubicYards cubicFeet =
    cubicFeet / 27.0  -- 27 cubic feet = 1 cubic yard
```

**Issue: Timeline calculation unrealistic**
```elm
-- Verify efficiency factors are applied
calculateExcavationTime : Float -> Float -> Float
calculateExcavationTime volume hourlyRate =
    if hourlyRate <= 0 then
        0
    else
        volume / (hourlyRate * efficiencyFactor)  -- Apply realistic efficiency

efficiencyFactor : Float
efficiencyFactor = 0.75  -- 75% efficiency accounts for real-world conditions
```

#### Issue: Validation errors not showing or incorrect
**Symptoms**:
- Input validation doesn't trigger on invalid values
- Error messages are confusing or incorrect
- Valid inputs show as invalid

**Debugging Steps**:

1. **Check Validation Rules**:
```bash
# Verify validation ranges in config
jq '.validation' frontend/public/config.json

# Test specific validation rule
jq '.validation.excavatorCapacity' frontend/public/config.json
# Should return: {"min": 0.5, "max": 15.0}
```

2. **Test Validation Logic**:
```elm
-- In elm repl
> import Utils.Validation exposing (..)
> validateFieldInput "excavatorCapacity" "2.5" config
-- Should return: Ok 2.5

> validateFieldInput "excavatorCapacity" "50.0" config
-- Should return: Err (OutOfRange ...)
```

**Common Validation Fixes**:

**Issue: Range validation too strict**
```json
// Update validation ranges in config.json
{
  "validation": {
    "excavatorCapacity": { "min": 0.1, "max": 20.0 },
    "pondDimensions": { "min": 0.1, "max": 2000.0 }
  }
}
```

**Issue: Error messages not displaying**
```elm
-- Check ValidationMessage component rendering
viewValidationError : Maybe ValidationError -> Html Msg
viewValidationError maybeError =
    case maybeError of
        Just error ->
            div [ class "error-message" ]
                [ text (validationErrorToString error) ]
        
        Nothing ->
            text ""
```

### Performance and Loading Issues

#### Issue: Application loads slowly (>3 seconds)
**Symptoms**:
- Long white screen before application appears
- Slow network requests
- Poor Lighthouse performance scores

**Performance Diagnosis**:

1. **Network Analysis**:
```bash
# Use curl to measure load times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:1234
```

Create `curl-format.txt`:
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

2. **Bundle Size Analysis**:
```bash
# Analyze build output size
npm run build
ls -lah frontend/dist/

# Use webpack bundle analyzer (if configured)
npx webpack-bundle-analyzer frontend/dist/
```

3. **Lighthouse Performance Audit**:
```bash
# Run Lighthouse audit
npx lighthouse http://localhost:1234 --output html --output-path report.html

# Focus on key metrics:
# - First Contentful Paint < 1.8s
# - Largest Contentful Paint < 2.5s
# - Total Blocking Time < 200ms
```

**Performance Optimization Solutions**:

**Issue: Large bundle size**
```bash
# Optimize Elm build
npx elm make src/Main.elm --optimize --output=main.js

# Enable minification in Parcel
parcel build public/index.html --no-source-maps
```

**Issue: Unused CSS bloating bundle**
```javascript
// Configure Tailwind CSS purging
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.elm', './public/**/*.html'],
  theme: { extend: {} },
  plugins: []
}
```

**Issue: Large static assets**
```bash
# Compress images and assets
npx imagemin frontend/public/images/* --out-dir=frontend/public/images-optimized

# Use appropriate image formats
# Convert PNG to WebP for better compression
```

#### Issue: Memory leaks during extended usage
**Symptoms**:
- Browser memory usage increases over time
- Application becomes slower after prolonged use
- Browser may become unresponsive

**Memory Debugging**:

1. **Browser DevTools Memory Tab**:
```javascript
// In browser console
console.memory
// Shows: usedJSHeapSize, totalJSHeapSize, jsHeapSizeLimit

// Monitor memory over time
setInterval(() => {
    if (performance.memory) {
        console.log('Memory:', performance.memory.usedJSHeapSize / 1024 / 1024, 'MB');
    }
}, 5000);
```

2. **Identify Memory Leaks**:
```elm
-- Check for accumulating data in Model
type alias Model =
    { -- ... other fields
    , debugHistory : List String  -- This could accumulate over time
    , calculationCache : Dict String CalculationResult  -- This could grow large
    }

-- Solution: Implement cleanup
cleanupModel : Model -> Model
cleanupModel model =
    { model 
    | debugHistory = List.take 10 model.debugHistory  -- Keep only recent entries
    , calculationCache = Dict.empty  -- Clear cache periodically
    }
```

**Memory Leak Solutions**:

**Issue: Event listeners not cleaned up**
```elm
-- Ensure subscriptions are properly managed
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize WindowResized
        , if model.showHelpPanel then
            Browser.Events.onKeyDown (KeyPressed)
          else
            Sub.none  -- Only subscribe when needed
        ]
```

**Issue: Large data structures accumulating**
```elm
-- Implement periodic cleanup
update msg model =
    case msg of
        CleanupMemory ->
            ( cleanupModel model, Cmd.none )
            
        _ ->
            -- Regular update logic
            updateHelper msg model
```

### Build and Deployment Issues

#### Issue: Build fails with compilation errors
**Symptoms**:
- `npm run build` command exits with errors
- Elm compiler shows type mismatches
- Parcel bundling fails

**Common Build Errors and Solutions**:

**Error: Elm type mismatch**
```
-- TYPE MISMATCH ---------------------------------------------------------------

The 1st argument to `calculatePondVolume` is not what I expect:

5|   calculatePondVolume "50" 30 5
                          ^^^^
This argument is a string of type:

    String

But `calculatePondVolume` needs the 1st argument to be:

    Float
```

**Solution**:
```elm
-- Fix type mismatch by converting string to float
case String.toFloat inputValue of
    Just value ->
        calculatePondVolume value 30 5
    
    Nothing ->
        -- Handle invalid input
        showError "Invalid input value"
```

**Error: Missing module imports**
```
-- MODULE NOT FOUND ------------------------------------------------------------

You are trying to import a `Utils.MissingModule` module:

4| import Utils.MissingModule exposing (someFunction)
          ^^^^^^^^^^^^^^^^^^^^
I cannot find that module! Is there a typo in the module name?
```

**Solution**:
```bash
# Check if module file exists
ls frontend/src/Utils/MissingModule.elm

# Verify module name matches file name
head -1 frontend/src/Utils/MissingModule.elm
# Should be: module Utils.MissingModule exposing (...)
```

**Error: Parcel bundling failure**
```
🚨 Build failed.

@parcel/core: Failed to resolve './missing-file.css'
```

**Solution**:
```bash
# Check if referenced files exist
ls frontend/src/missing-file.css

# Update import path
# In Elm file: replace relative path with correct path
```

#### Issue: Deployment to GitHub Pages fails
**Symptoms**:
- GitHub Actions workflow shows red X
- Deployment step fails in CI/CD pipeline
- Site not updating on github.io domain

**Diagnosis Steps**:

1. **Check GitHub Actions Log**:
```yaml
# Look for specific error in workflow log
- name: Build Application
  run: |
    cd frontend
    npm ci
    npm run build  # Check if this step fails
```

2. **Verify Build Output**:
```bash
# Local build test
npm run build
ls -la frontend/dist/
# Should contain: index.html, *.js, *.css files
```

3. **Check GitHub Pages Settings**:
- Repository Settings → Pages
- Source should be "GitHub Actions" or "gh-pages branch"
- Custom domain configured correctly (if used)

**Common Deployment Fixes**:

**Issue: Build artifacts missing**
```yaml
# GitHub Actions workflow fix
- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./frontend/dist  # Ensure correct path
    publish_branch: gh-pages
```

**Issue: Relative path issues**
```bash
# Build with correct base path
parcel build public/index.html --public-url ./
```

**Issue: CNAME file missing**
```bash
# Add CNAME file to public directory
echo "your-domain.com" > frontend/public/CNAME
```

### Configuration and Integration Issues

#### Issue: Equipment defaults not loading
**Symptoms**:
- Form fields show no default values
- Equipment selection is empty
- Configuration appears to load but values not applied

**Debugging Configuration Loading**:

1. **Verify Configuration Structure**:
```bash
# Check config file structure
jq '.defaults.excavators[0]' frontend/public/config.json
# Should return complete excavator object

jq '.defaults.trucks[0]' frontend/public/config.json  
# Should return complete truck object
```

2. **Test Configuration Decoder**:
```elm
-- In elm repl
> import Json.Decode as Decode
> import Utils.Config exposing (configDecoder)
> configJson = """{"version":"1.0.0","defaults":{"excavators":[{"bucketCapacity":2.5,"cycleTime":2.0,"name":"Test"}],"trucks":[],"project":{"workHoursPerDay":8}},"fleetLimits":{"maxExcavators":10,"maxTrucks":20},"validation":{}}"""
> Decode.decodeString configDecoder configJson
```

**Common Configuration Fixes**:

**Issue: Missing required fields**
```json
// Ensure all required fields are present
{
  "defaults": {
    "excavators": [
      {
        "bucketCapacity": 2.5,
        "cycleTime": 2.0,
        "name": "CAT 320 Excavator"  // Name field was missing
      }
    ]
  }
}
```

**Issue: Incorrect data types**
```json
// Fix data type mismatches
{
  "fleetLimits": {
    "maxExcavators": 10,     // Should be number, not string
    "maxTrucks": "20"        // Incorrect - should be number
  }
}
```

**Issue: Configuration not propagating to components**
```elm
-- Ensure configuration is passed to components correctly
init flags =
    let
        config = getConfig
        formData = ProjectForm.initFormData config.defaults  -- Pass defaults
    in
    ( { config = Just config, formData = Just formData, ... }, Cmd.none )
```

## Error Recovery Patterns

### Graceful Degradation Strategies

#### Configuration Loading Failure
```elm
-- Robust configuration loading with fallback
getConfigWithRecovery : Cmd Msg
getConfigWithRecovery =
    Http.get
        { url = "/config.json"
        , expect = Http.expectJson ConfigLoaded configDecoder
        }
        |> Cmd.map (\result ->
            case result of
                Ok config ->
                    ConfigLoaded config
                
                Err _ ->
                    ConfigLoaded fallbackConfig  -- Always have working config
        )
```

#### Calculation Error Recovery
```elm
-- Safe calculation with error recovery
safeCalculateTimeline : ProjectData -> List Equipment -> CalculationResult
safeCalculateTimeline project equipment =
    case validateInputs project equipment of
        Ok validData ->
            calculateTimeline validData.project validData.equipment
            
        Err validationErrors ->
            { totalHours = 0
            , isValid = False
            , errors = validationErrors
            , lastValidResult = Nothing
            }
```

#### State Recovery After Errors
```elm
-- Recover application state after errors
update msg model =
    case msg of
        RecoverFromError ->
            let
                cleanModel = 
                    { model
                    | hasValidationErrors = False
                    , fieldValidationErrors = Dict.empty
                    , calculationInProgress = False
                    }
            in
            ( cleanModel, Cmd.none )
```

This troubleshooting guide should be referenced whenever issues arise and updated with new solutions as they are discovered.