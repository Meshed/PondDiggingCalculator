# Elm Coding Standards Guide

## Overview
This guide establishes comprehensive coding standards for the Pond Digging Calculator Elm codebase, ensuring consistency, maintainability, and adherence to functional programming best practices.

## Naming Conventions

### Types (PascalCase)
```elm
-- Custom types
type DeviceType = Mobile | Tablet | Desktop
type CalculationStatus = Pending | Calculating | Complete | Failed

-- Type aliases
type alias CalculationResult = 
    { volume : CubicYards
    , timeline : Days
    , cost : Currency
    }

type alias ValidationError =
    { field : String
    , message : String
    , value : String
    }
```

### Functions (camelCase)
```elm
-- Pure calculation functions
calculateExcavationRate : CubicYards -> Minutes -> CubicYards
validateBucketCapacity : Float -> Result ValidationError CubicYards
formatCurrency : Float -> String

-- Component functions
renderEquipmentCard : Equipment -> Html Msg
updateProjectForm : FormMsg -> Model -> Model
```

### Variables (camelCase)
```elm
-- Local variables
bucketCapacity : Float
pondVolume : CubicYards
excavationRate : Float

-- Record field names
type alias Equipment =
    { bucketCapacity : CubicYards
    , cycleTime : Minutes
    , isActive : Bool
    , equipmentType : EquipmentType
    }
```

### Constants (camelCase)
```elm
-- Configuration constants
defaultWorkHours : Float
defaultWorkHours = 8.0

excavatorEfficiencyFactor : Float
excavatorEfficiencyFactor = 0.85

maxBucketCapacity : CubicYards
maxBucketCapacity = 15.0
```

### Modules (PascalCase)
```elm
-- Module naming
module Utils.Calculations exposing (..)
module Types.Equipment exposing (..)
module Components.EquipmentCard exposing (..)
module Styles.Theme exposing (..)
```

### Test Functions (descriptive_with_underscores)
```elm
-- Descriptive test names
should_calculate_correct_timeline_for_single_equipment : Test
should_validate_positive_bucket_capacity : Test
should_reject_bucket_capacity_above_maximum : Test
should_format_currency_with_two_decimal_places : Test
```

## Code Formatting Rules

### Indentation and Spacing
- **Indentation**: 4 spaces (no tabs)
- **Line Length**: Maximum 100 characters
- **Function Spacing**: One blank line between top-level functions
- **Import Spacing**: One blank line after imports

```elm
module Utils.Calculations exposing 
    ( calculateExcavationRate
    , calculateTimeline
    , validateInput
    )

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Types.Equipment exposing (Equipment, CubicYards, Minutes)


{-| Calculate the hourly excavation rate for a single excavator.
    Takes bucket capacity and cycle time, returns rate per hour.
-}
calculateExcavationRate : CubicYards -> Minutes -> CubicYards
calculateExcavationRate bucketCapacity cycleTime =
    let
        cyclesPerHour = 60.0 / cycleTime
        theoreticalRate = cyclesPerHour * bucketCapacity
    in
    theoreticalRate * excavatorEfficiencyFactor


{-| Calculate project timeline based on equipment fleet.
    Returns total days required for excavation.
-}
calculateTimeline : List Equipment -> CubicYards -> Result ValidationError Days
calculateTimeline equipment totalVolume =
    -- Implementation here
```

### Let Expressions
```elm
-- Align let bindings and use descriptive names
calculateTotalCost : List Equipment -> Float -> Float
calculateTotalCost equipment dailyRate =
    let
        totalEquipmentCount = List.length equipment
        activeDays = calculateActiveDays equipment
        equipmentCost = toFloat totalEquipmentCount * dailyRate
        operatorCost = activeDays * operatorDailyRate
    in
    equipmentCost + operatorCost
```

### Function Signatures
```elm
-- Multi-line signatures for complex types
validateProjectInputs : 
    { pondLength : Float
    , pondWidth : Float  
    , pondDepth : Float
    , soilType : SoilType
    }
    -> Result (List ValidationError) ValidatedProject
```

### Record Updates
```elm
-- Align record updates vertically
updateEquipment : Equipment -> Equipment
updateEquipment equipment =
    { equipment
        | isActive = True
        , lastUpdated = currentTime
        , status = Active
    }
```

## Style Examples for Common Patterns

### Type Definitions
```elm
-- Union types with clear variants
type EquipmentType
    = Excavator
    | Bulldozer  
    | DumpTruck
    | Compactor

-- Record types with meaningful field names
type alias ProjectConfig =
    { dimensions : PondDimensions
    , soilConditions : SoilConditions
    , timeline : TimelineConstraints
    , budget : BudgetConstraints
    }
```

### Function Composition
```elm
-- Use pipeline operator for readable transformations
processEquipmentList : List RawEquipment -> List Equipment
processEquipmentList rawEquipment =
    rawEquipment
        |> List.filter .isAvailable
        |> List.map validateEquipment
        |> List.filterMap Result.toMaybe
        |> List.sortBy .priority
```

### Pattern Matching
```elm
-- Comprehensive pattern matching with meaningful names
handleCalculationResult : Result CalculationError CalculationResult -> Html Msg
handleCalculationResult result =
    case result of
        Ok calculationResult ->
            renderSuccessResult calculationResult
            
        Err (ValidationFailed errors) ->
            renderValidationErrors errors
            
        Err (CalculationFailed reason) ->
            renderCalculationError reason
            
        Err InsufficientData ->
            renderInsufficientDataMessage
```

### Html Construction
```elm
-- Clear HTML structure with semantic class names
renderEquipmentCard : Equipment -> Html Msg
renderEquipmentCard equipment =
    div 
        [ class "equipment-card bg-white border rounded-lg p-4 shadow-sm" ]
        [ div 
            [ class "equipment-header flex justify-between items-center mb-2" ]
            [ text equipment.name
            , renderStatusBadge equipment.status
            ]
        , div 
            [ class "equipment-details space-y-1" ]
            [ renderCapacityInfo equipment.bucketCapacity
            , renderEfficiencyInfo equipment.efficiency
            ]
        ]
```

## Best Practices Summary

### Code Organization
1. **Module Structure**: Group related functionality in appropriately named modules
2. **Import Organization**: Sort imports alphabetically, group by source (standard library, third-party, local)
3. **Function Order**: Place most important/public functions first, helpers at bottom
4. **Documentation**: Every public function must have a docstring

### Functional Programming
1. **Pure Functions**: All calculations and transformations should be pure
2. **Immutability**: Never modify existing data structures, always create new ones
3. **Result Types**: Use Result for error handling, never throw exceptions
4. **Pipeline Style**: Use |> operator for readable data transformations

### Performance Considerations
1. **Lazy Evaluation**: Use List.foldr for right-associative operations
2. **Tail Recursion**: Prefer tail-recursive functions for large data sets
3. **Type Constraints**: Use specific types instead of generic ones where possible
4. **Minimal Dependencies**: Only import what you need from modules

### Error Prevention
1. **Type Safety**: Use custom types instead of primitives for domain concepts
2. **Total Functions**: Ensure all pattern matches are exhaustive
3. **Validation**: Validate inputs at boundaries using Result types
4. **Documentation**: Document expected behavior and edge cases