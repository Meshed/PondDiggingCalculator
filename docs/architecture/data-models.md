# Data Models

## Excavator
**Purpose:** Represents an excavator machine with its operational specifications for calculating digging productivity

**Key Attributes:**
- id: EquipmentId - Unique identifier for the excavator instance
- bucketCapacity: Float - Bucket size in cubic yards (typically 0.5-15.0)
- cycleTime: Float - Minutes per dig-dump cycle (typically 0.5-10.0)
- name: String - User-friendly label (e.g., "CAT 320 Excavator")
- isActive: Bool - Whether this excavator is included in calculations

**Elm Type Definition:**
```elm
type EquipmentId = EquipmentId String

type alias Excavator =
    { id : EquipmentId
    , bucketCapacity : Float  -- cubic yards
    , cycleTime : Float       -- minutes
    , name : String
    , isActive : Bool
    }
```

**Relationships:**
- Part of Equipment list in Model
- Used by CalculationEngine module

## Truck
**Purpose:** Represents a dump truck with capacity and travel time specifications for hauling calculations

**Elm Type Definition:**
```elm
type alias Truck =
    { id : EquipmentId
    , capacity : Float        -- cubic yards
    , roundTripTime : Float   -- minutes
    , name : String
    , isActive : Bool
    }
```

## PondDimensions
**Purpose:** Defines the excavation area dimensions and resulting volume to be removed

**Elm Type Definition:**
```elm
type PondShape 
    = Rectangular 
    | Irregular  -- future enhancement

type alias PondDimensions =
    { length : Float          -- feet
    , width : Float           -- feet
    , depth : Float           -- feet
    , volume : Float          -- cubic yards (calculated)
    , shape : PondShape
    }
```

## ProjectConfiguration
**Purpose:** Contains project-specific settings and operational parameters

**Elm Type Definition:**
```elm
type alias ProjectConfiguration =
    { workHoursPerDay : Float
    , projectName : Maybe String
    , location : Maybe String
    , pondDimensions : PondDimensions
    }
```

## CalculationResult
**Purpose:** Contains the timeline calculation output with detailed breakdown and analysis

**Elm Type Definition:**
```elm
type Bottleneck
    = ExcavationLimited
    | HaulingLimited
    | Balanced

type ConfidenceLevel
    = High
    | Medium
    | Low

type alias ValidationWarning =
    { message : String
    , severity : WarningSeverity
    }

type WarningSeverity = Info | Warning | Critical

type alias CalculationResult =
    { timelineInDays : Int      -- whole days
    , totalHours : Float         -- precise calculation
    , excavationRate : Float    -- cy/hour
    , haulingRate : Float       -- cy/hour
    , bottleneck : Bottleneck
    , confidence : ConfidenceLevel
    , assumptions : List String
    , warnings : List ValidationWarning
    }
```

## Application Model
**Purpose:** Root application state containing all data with type-safe validation

**Elm Type Definition:**
```elm
type DeviceType
    = Mobile
    | Tablet
    | Desktop

-- Type-safe validation state
type FieldId
    = ExcavatorField EquipmentId ExcavatorField
    | TruckField EquipmentId TruckField
    | PondField PondField
    | ProjectField ProjectField

type ExcavatorField
    = BucketCapacity
    | CycleTime
    | ExcavatorName

type TruckField
    = TruckCapacity
    | RoundTripTime
    | TruckName

type PondField
    = PondLength
    | PondWidth
    | PondDepth

type ProjectField
    = WorkHours
    | ProjectName
    | Location

type ValidationError
    = ValueTooLow { actual : Float, minimum : Float }
    | ValueTooHigh { actual : Float, maximum : Float }
    | RequiredField
    | InvalidFormat String
    | CustomError String

type alias ValidationState =
    { excavatorErrors : List (EquipmentId, ExcavatorField, ValidationError)
    , truckErrors : List (EquipmentId, TruckField, ValidationError)
    , pondErrors : List (PondField, ValidationError)
    , projectErrors : List (ProjectField, ValidationError)
    }

type alias Model =
    { excavators : List Excavator
    , trucks : List Truck
    , projectConfig : ProjectConfiguration
    , currentResult : Maybe CalculationResult
    , deviceType : DeviceType
    , validationState : ValidationState
    , nextEquipmentId : Int
    }
```
