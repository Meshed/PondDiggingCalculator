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

## Troubleshooting

### Build-Time Configuration Issues

**Problem**: Build fails with "Configuration validation error"
```
❌ Error generating Elm configuration:
SyntaxError: Unexpected token...
```

**Solution**: Check `equipment-defaults.json` for JSON syntax errors:
- Ensure all brackets and braces are properly closed
- Check for trailing commas (not allowed in JSON)
- Verify all string values are properly quoted
- Run `npm run validate:config` for detailed error information

---

**Problem**: Build succeeds but application shows unexpected values

**Solution**: Verify configuration generation:
1. Check that `frontend/src/Utils/ConfigGenerated.elm` was updated
2. Ensure you ran `npm run build` (not just `npm run dev`)
3. Clear browser cache or do a hard refresh
4. Confirm configuration changes are within validation ranges

---

**Problem**: Application crashes on startup after configuration changes

**Solution**: Check for invalid configuration values:
1. Ensure all numeric values are positive and within expected ranges
2. Verify equipment arrays are not empty
3. Check that validation min values are less than max values
4. Revert to last known good configuration and test changes incrementally

---

**Problem**: Help tooltips show incorrect ranges after configuration update

**Solution**: Help content uses configuration validation rules:
1. Verify validation ranges are correctly set in configuration
2. Check that `npm run build` completed successfully
3. Confirm `Utils.ConfigGenerated` contains updated validation rules
4. Clear application cache and refresh

---

**Problem**: "Configuration file not found" error during build

**Solution**: Verify file locations:
1. Ensure `config/equipment-defaults.json` exists and is readable
2. Check that build scripts are run from correct directory
3. Verify file permissions allow reading the configuration file

### Development Workflow Issues

**Problem**: Configuration changes don't appear during development

**Solution**: 
1. Kill the dev server (`Ctrl+C`)
2. Run `npm run dev` to restart with configuration regeneration
3. Alternatively, run `npm run generate:config` manually

---

**Problem**: Tests fail after adding configuration validation rules

**Solution**: 
1. Update test fixtures to use valid configuration values
2. Mock configuration in tests using `Utils.Config.fallbackConfig`
3. Ensure test values fall within new validation ranges

### Schema Validation Issues

**Problem**: Custom configuration values fail validation

**Solution**: 
1. Check `config/equipment-defaults.schema.json` for allowed values
2. Ensure numeric ranges in schema match business requirements  
3. Update schema if adding new configuration properties
4. Test schema changes with `npm run validate:config`