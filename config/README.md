# Equipment Configuration

This directory contains build-time configuration files for the Pond Digging Calculator.

## Files

- `equipment-defaults.json` - Main configuration file with equipment defaults, project settings, fleet limits, and validation rules
- `equipment-defaults.schema.json` - JSON schema for validating the configuration file
- `validate-config.js` - Node.js script that validates the configuration against the schema
- `generate-elm-config.js` - Node.js script that converts JSON configuration to Elm code

## Configuration Updates

**IMPORTANT**: Changes to `equipment-defaults.json` require rebuilding and redeploying the application.

### How Configuration Works

1. Configuration is loaded at **build time**, not runtime
2. The JSON configuration is converted to static Elm code during the build process
3. No HTTP requests are made to load configuration - it's embedded in the JavaScript bundle
4. This enables true offline-first behavior but requires rebuilds for changes

### Making Configuration Changes

1. Edit `equipment-defaults.json` with your desired changes
2. Run `npm run validate:config` to ensure your changes are valid
3. Run `npm run build` to rebuild the application with new configuration
4. Deploy the updated build

### Build Process Integration

The configuration is automatically validated and integrated during builds:

```bash
# Validation and generation happen automatically during build
npm run build

# Manual validation (useful for testing changes)
npm run validate:config

# Manual Elm code generation (useful for development)
npm run generate:config
```

### Configuration Structure

The configuration file contains four main sections:

1. **defaults** - Default equipment specifications and project settings
2. **fleetLimits** - Maximum number of excavators and trucks allowed
3. **validation** - Input validation rules with min/max ranges
4. **version** - Configuration file version for tracking changes

### Validation Rules

All configuration values are validated against the JSON schema during build time:

- Numeric values must be within specified ranges
- Equipment arrays must contain at least one item
- All required fields must be present
- String fields must be non-empty

If validation fails, the build will stop with an error message.

### Performance Benefits

Build-time configuration loading provides several advantages:

- **Faster startup**: No HTTP request delay at application initialization
- **Offline support**: Application works without network connectivity
- **Reliability**: No risk of configuration loading failures in production
- **Security**: Configuration cannot be modified by end users

### Development vs Production

- **Development**: Configuration is regenerated on each build for testing
- **Production**: Configuration changes require full rebuild and redeploy
- **Fallback**: A hardcoded fallback configuration remains in the code for emergency scenarios