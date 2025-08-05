# API Specification

**No REST/GraphQL API in MVP Phase** - The application operates entirely client-side with no server communication for core functionality.

## Configuration API (JSON Loading)

**Configuration File Structure:**
```elm
-- Elm decoder for config.json
type alias ConfigFile =
    { version : String
    , defaults : DefaultValues
    , validation : ValidationRules
    , ui : UiSettings
    }

-- JSON file format (config.json)
{
  "version": "1.0.0",
  "defaults": {
    "excavator": {
      "bucketCapacity": 2.5,
      "cycleTime": 2.0,
      "name": "Standard Excavator"
    },
    "truck": {
      "capacity": 12.0,
      "roundTripTime": 15.0,
      "name": "15-yard Dump Truck"
    },
    "project": {
      "workHoursPerDay": 8.0,
      "pondLength": 50.0,
      "pondWidth": 30.0,
      "pondDepth": 6.0
    }
  },
  "validation": {
    "excavatorCapacity": { "min": 0.5, "max": 15.0 },
    "cycleTime": { "min": 0.5, "max": 10.0 },
    "truckCapacity": { "min": 5.0, "max": 30.0 },
    "roundTripTime": { "min": 5.0, "max": 60.0 },
    "workHours": { "min": 1.0, "max": 16.0 },
    "pondDimensions": { "min": 1.0, "max": 1000.0 }
  }
}
```

## Module APIs (Internal Elm Interfaces)

**CalculationEngine Module API:**
```elm
-- Core calculation function
calculateTimeline : List Excavator -> List Truck -> ProjectConfiguration -> Result CalculationError CalculationResult

-- Equipment productivity calculations
calculateExcavatorRate : List Excavator -> Float
calculateTruckRate : List Truck -> Float

-- Validation functions
validateEquipmentFleet : List Excavator -> List Truck -> Result ValidationError ()
validateProjectConfig : ProjectConfiguration -> Result ValidationError ()
```
