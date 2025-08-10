# Configuration Management Guide

## Overview

The Pond Digging Calculator uses a build-time configuration system that embeds JSON configuration files directly into the compiled Elm application. This approach eliminates runtime HTTP requests while maintaining the flexibility of JSON-based configuration.

## Configuration Structure

### Primary Configuration File

**Location**: `frontend/public/config.json` (current runtime config - to be deprecated)  
**Future Location**: `config/equipment-defaults.json` (build-time static config)

### Complete Configuration Schema

```json
{
  "version": "1.0.0",
  "defaults": {
    "excavators": [
      {
        "bucketCapacity": 1.1,
        "cycleTime": 2.0,
        "name": "CAT 320C Excavator"
      }
    ],
    "trucks": [
      {
        "capacity": 12.0,
        "roundTripTime": 15.0,
        "name": "Standard Dump Truck"
      }
    ],
    "project": {
      "workHoursPerDay": 8.0,
      "pondLength": 40.0,
      "pondWidth": 25.0,
      "pondDepth": 5.0
    }
  },
  "fleetLimits": {
    "maxExcavators": 10,
    "maxTrucks": 20
  },
  "validation": {
    "excavatorCapacity": { "min": 0.5, "max": 15.0 },
    "cycleTime": { "min": 0.5, "max": 10.0 },
    "truckCapacity": { "min": 10.0, "max": 50.0 },
    "roundTripTime": { "min": 5.0, "max": 60.0 },
    "workHours": { "min": 1.0, "max": 24.0 },
    "pondDimensions": { "min": 1.0, "max": 1000.0 }
  }
}
```

## Configuration Sections Explained

### Equipment Defaults (`defaults.excavators`, `defaults.trucks`)

**Purpose**: Define default equipment specifications that populate form fields when users add new equipment.

**Fields**:
- `bucketCapacity` (Float): Excavator bucket size in cubic yards
- `cycleTime` (Float): Time per excavation cycle in minutes
- `capacity` (Float): Truck capacity in cubic yards
- `roundTripTime` (Float): Complete truck round trip time in minutes
- `name` (String): Display name for the equipment type

**Industry Validation**:
- Excavator capacities: 0.5-15.0 cubic yards (mini to large construction)
- Cycle times: 16-25 seconds typical (0.27-0.42 minutes)
- Truck capacities: 10-90+ cubic yards (highway to mining class)
- Round trip times: 5-60 minutes depending on site distance

### Project Defaults (`defaults.project`)

**Purpose**: Set reasonable default values for new pond digging projects.

**Fields**:
- `workHoursPerDay` (Float): Standard work day length in hours
- `pondLength` (Float): Default pond length in feet
- `pondWidth` (Float): Default pond width in feet
- `pondDepth` (Float): Default pond depth in feet

**Typical Values**:
- Work hours: 8 hours standard, 10-12 hours for extended operations
- Pond dimensions: Residential (20-50 feet), Commercial (50-200+ feet)

### Fleet Limits (`fleetLimits`)

**Purpose**: Prevent users from entering unrealistic equipment fleet sizes.

**Fields**:
- `maxExcavators` (Int): Maximum number of excavators allowed
- `maxTrucks` (Int): Maximum number of trucks allowed

**Rationale**:
- Prevents UI performance issues with excessive equipment
- Reflects realistic construction site limitations
- Typical projects rarely exceed 5-10 excavators

### Validation Rules (`validation`)

**Purpose**: Define input validation boundaries for all numeric fields.

**Structure**: Each validation rule has `min` and `max` properties defining acceptable ranges.

**Rules**:
- `excavatorCapacity`: Bucket capacity bounds (0.5-15.0 cubic yards)
- `cycleTime`: Excavation cycle time bounds (0.5-10.0 minutes)
- `truckCapacity`: Truck capacity bounds (10.0-50.0 cubic yards)
- `roundTripTime`: Round trip time bounds (5.0-60.0 minutes)
- `workHours`: Daily work hours bounds (1.0-24.0 hours)
- `pondDimensions`: Pond dimension bounds (1.0-1000.0 feet)

## Build-time vs Runtime Configuration

### Current Implementation (Runtime - Deprecated)

**Process**:
1. Application loads and makes HTTP request to `/config.json`
2. JSON parsed and validated using Elm decoders
3. Fallback configuration used if HTTP request fails
4. Configuration stored in application model

**Issues**:
- Requires HTTP request on every application load
- Configuration can fail to load in offline scenarios
- Adds complexity to application initialization

### Target Implementation (Build-time)

**Process**:
1. Build script reads `config/equipment-defaults.json`
2. JSON content embedded into `frontend/src/Utils/ConfigGenerated.elm`
3. Configuration compiled directly into application bundle
4. No runtime HTTP requests required

**Benefits**:
- Zero runtime configuration loading time
- Guaranteed configuration availability
- True offline-first behavior
- Type-safe configuration access

## Configuration Change Process

### Current Process (Runtime Config)

1. Edit `frontend/public/config.json`
2. Deploy updated file to hosting
3. Configuration active immediately for new page loads
4. No application rebuild required

### Future Process (Build-time Config)

1. Edit `config/equipment-defaults.json`
2. Run build process: `npm run build`
3. Deploy updated application bundle
4. Configuration embedded in compiled application

## Common Configuration Changes

### Adding New Equipment Types

**Excavators**:
```json
{
  "bucketCapacity": 2.5,
  "cycleTime": 1.8,
  "name": "CAT 330 Excavator"
}
```

**Trucks**:
```json
{
  "capacity": 20.0,
  "roundTripTime": 12.0,
  "name": "Articulated Dump Truck"
}
```

### Adjusting Validation Rules

**Example - Increase max excavator capacity**:
```json
{
  "validation": {
    "excavatorCapacity": { "min": 0.5, "max": 20.0 }
  }
}
```

### Modifying Fleet Limits

**Example - Increase max trucks**:
```json
{
  "fleetLimits": {
    "maxExcavators": 10,
    "maxTrucks": 30
  }
}
```

### Updating Project Defaults

**Example - Adjust for commercial projects**:
```json
{
  "project": {
    "workHoursPerDay": 10.0,
    "pondLength": 100.0,
    "pondWidth": 80.0,
    "pondDepth": 8.0
  }
}
```

## Configuration Validation

### JSON Schema (Future Implementation)

**Location**: `config/equipment-defaults.schema.json`

**Purpose**:
- Validate configuration structure before build
- Ensure all required fields are present
- Verify data types and value ranges
- Provide IDE autocompletion

**Validation Command** (planned):
```bash
npm run validate:config
# Validates config/equipment-defaults.json against schema
```

### Elm Type Validation

**Module**: `frontend/src/Utils/Config.elm`

**Process**:
1. JSON decoded using type-safe Elm decoders
2. Validation failures caught at compile time
3. Fallback configuration used if decoding fails
4. Runtime validation for numeric ranges

**Example Decoder**:
```elm
excavatorDefaultsDecoder : Decoder ExcavatorDefaults
excavatorDefaultsDecoder =
    Decode.map3 ExcavatorDefaults
        (Decode.field "bucketCapacity" Decode.float)
        (Decode.field "cycleTime" Decode.float)
        (Decode.field "name" Decode.string)
```

## Configuration Error Handling

### Fallback Configuration

**Purpose**: Ensure application always has valid configuration even if primary config fails.

**Implementation**: Hardcoded fallback values in `Utils.Config.elm`:

```elm
fallbackConfig : Config
fallbackConfig =
    { version = "1.0.0"
    , defaults = fallbackDefaults
    , fleetLimits = fallbackFleetLimits
    , validation = fallbackValidationRules
    }
```

### Error Messages

**Invalid JSON**: Application shows error message and uses fallback configuration
**Missing Fields**: Elm decoder failure triggers fallback configuration
**Invalid Ranges**: Runtime validation displays field-specific error messages

## Configuration Testing

### Unit Tests

**Location**: `frontend/tests/Unit/ConfigTests.elm`

**Coverage**:
- JSON decoding validation
- Configuration loading process
- Fallback configuration completeness
- Validation rule enforcement

### Example Test**:
```elm
test "should decode valid excavator configuration" <|
    \_ ->
        let
            json = """{"bucketCapacity": 2.5, "cycleTime": 2.0, "name": "Test Excavator"}"""
            result = Decode.decodeString excavatorDefaultsDecoder json
        in
        case result of
            Ok excavator ->
                excavator.bucketCapacity |> Expect.equal 2.5
            
            Err _ ->
                Expect.fail "Should decode valid configuration"
```

## Configuration Documentation Standards

### Inline Documentation

- All configuration fields must have comments explaining purpose
- Include units (cubic yards, minutes, hours, feet) in field descriptions
- Document valid ranges and typical values
- Explain relationships between fields

### Change Documentation

**Location**: `config/CHANGELOG.md` (future)

**Format**:
```markdown
## [1.1.0] - 2025-08-15
### Changed
- Increased max excavator capacity from 15.0 to 20.0 cubic yards
- Added new articulated dump truck default (20.0 cy, 12min round trip)

### Validation Impact
- Projects using excavators >15cy now validate correctly
- Truck selection expanded for large projects
```

## Migration Guide (Runtime to Build-time)

### Phase 1: Dual Configuration Support
1. Maintain current runtime loading
2. Add build-time configuration generation
3. Use build-time as primary, runtime as fallback

### Phase 2: Build-time Transition
1. Update documentation to reference new config location
2. Create migration tool for existing customizations
3. Test configuration changes in CI/CD pipeline

### Phase 3: Runtime Removal
1. Remove HTTP configuration loading code
2. Delete `frontend/public/config.json`
3. Update deployment process for config changes

## Security Considerations

### Input Validation
- All configuration values validated against type and range constraints
- Malformed JSON handled gracefully with fallback configuration
- No user-modifiable configuration in production

### Build-time Safety
- Configuration embedded at build time prevents runtime tampering
- Version tracking enables configuration change auditing
- Schema validation prevents invalid configuration deployment

## Performance Impact

### Build-time Benefits
- Zero runtime configuration loading time
- No HTTP requests during application initialization
- Smaller initial payload (no separate config request)

### Bundle Size
- Configuration adds ~2-3KB to bundle size
- Eliminated HTTP request saves ~100-200ms initial load time
- Net performance improvement for typical usage

## Troubleshooting

### Configuration Not Loading
1. Check browser console for decode errors
2. Verify JSON syntax is valid
3. Ensure all required fields are present
4. Compare against fallback configuration structure

### Invalid Equipment Values
1. Check validation rules in config
2. Verify numeric ranges are reasonable
3. Test with fallback configuration
4. Review equipment research documentation

### Build Failures
1. Validate JSON syntax
2. Run configuration schema validation
3. Check Elm compilation errors
4. Verify file paths in build script