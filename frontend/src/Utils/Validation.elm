module Utils.Validation exposing
    ( validateExcavatorCapacity, validateCycleTime, validateTruckCapacity
    , validateRoundTripTime, validateWorkHours, validatePondDimensions
    , validateAllInputs, ProjectInputs
    , validateExcavatorFleet, validateTruckFleet
    , ExcavatorField(..), TruckField(..)
    , errorToString, validateDecimalPrecision, validateStringInput, validateWithEdgeCases
    )

{-| Input validation functions for pond digging calculator

@docs validateExcavatorCapacity, validateCycleTime, validateTruckCapacity
@docs validateRoundTripTime, validateWorkHours, validatePondDimensions
@docs validateAllInputs, ProjectInputs
@docs validateExcavatorFleet, validateTruckFleet
@docs ExcavatorField, TruckField

-}

import Types.Equipment exposing (CubicYards, EquipmentId, Excavator, Minutes, Truck)
import Types.Validation exposing (ValidationError(..), ValidationResult)
import Utils.Config exposing (ValidationRange, ValidationRules)



-- TYPES


type ExcavatorField
    = ExcavatorBucketCapacity
    | ExcavatorCycleTime


type TruckField
    = TruckFieldCapacity
    | TruckFieldRoundTripTime


type alias ProjectInputs =
    { excavatorCapacity : Float
    , excavatorCycleTime : Float
    , truckCapacity : Float
    , truckRoundTripTime : Float
    , workHoursPerDay : Float
    , pondLength : Float
    , pondWidth : Float
    , pondDepth : Float
    }



-- VALIDATION FUNCTIONS


{-| Validate excavator bucket capacity against industry standards.
Returns validated capacity or specific validation error.
-}
validateExcavatorCapacity : ValidationRange -> Float -> ValidationResult CubicYards
validateExcavatorCapacity rules capacity =
    validateRange "Excavator Capacity" rules capacity


{-| Validate excavator cycle time against operational limits.
Returns validated cycle time or specific validation error.
-}
validateCycleTime : ValidationRange -> Float -> ValidationResult Minutes
validateCycleTime rules cycleTime =
    validateRange "Cycle Time" rules cycleTime


{-| Validate truck capacity against industry standards.
Returns validated capacity or specific validation error.
-}
validateTruckCapacity : ValidationRange -> Float -> ValidationResult CubicYards
validateTruckCapacity rules capacity =
    validateRange "Truck Capacity" rules capacity


{-| Validate truck round-trip time against operational limits.
Returns validated round-trip time or specific validation error.
-}
validateRoundTripTime : ValidationRange -> Float -> ValidationResult Minutes
validateRoundTripTime rules roundTripTime =
    validateRange "Round Trip Time" rules roundTripTime


{-| Validate daily work hours against labor regulations.
Returns validated work hours or specific validation error.
-}
validateWorkHours : ValidationRange -> Float -> ValidationResult Float
validateWorkHours rules workHours =
    validateRange "Work Hours" rules workHours


{-| Validate pond dimensions against construction feasibility.
Returns validated dimension or specific validation error.
-}
validatePondDimensions : ValidationRange -> Float -> ValidationResult Float
validatePondDimensions rules dimension =
    validateRange "Pond Dimension" rules dimension


{-| Validate all project inputs at once.
Returns validated inputs or the first validation error encountered.
-}
validateAllInputs : ValidationRules -> ProjectInputs -> ValidationResult ProjectInputs
validateAllInputs rules inputs =
    validateExcavatorCapacity rules.excavatorCapacity inputs.excavatorCapacity
        |> Result.andThen
            (\_ ->
                validateCycleTime rules.cycleTime inputs.excavatorCycleTime
            )
        |> Result.andThen
            (\_ ->
                validateTruckCapacity rules.truckCapacity inputs.truckCapacity
            )
        |> Result.andThen
            (\_ ->
                validateRoundTripTime rules.roundTripTime inputs.truckRoundTripTime
            )
        |> Result.andThen
            (\_ ->
                validateWorkHours rules.workHours inputs.workHoursPerDay
            )
        |> Result.andThen
            (\_ ->
                validatePondDimensions rules.pondDimensions inputs.pondLength
            )
        |> Result.andThen
            (\_ ->
                validatePondDimensions rules.pondDimensions inputs.pondWidth
            )
        |> Result.andThen
            (\_ ->
                validatePondDimensions rules.pondDimensions inputs.pondDepth
            )
        |> Result.map (\_ -> inputs)


{-| Validate excavator fleet - each excavator independently
Returns list of validation errors with equipment IDs
-}
validateExcavatorFleet : ValidationRules -> List Excavator -> List ( EquipmentId, ExcavatorField, ValidationError )
validateExcavatorFleet rules excavators =
    List.concatMap (validateSingleExcavator rules) excavators


{-| Validate truck fleet - each truck independently
Returns list of validation errors with equipment IDs
-}
validateTruckFleet : ValidationRules -> List Truck -> List ( EquipmentId, TruckField, ValidationError )
validateTruckFleet rules trucks =
    List.concatMap (validateSingleTruck rules) trucks


{-| Validate a single excavator and return errors with ID and field
-}
validateSingleExcavator : ValidationRules -> Excavator -> List ( EquipmentId, ExcavatorField, ValidationError )
validateSingleExcavator rules excavator =
    let
        bucketCapacityResult =
            validateExcavatorCapacity rules.excavatorCapacity excavator.bucketCapacity

        cycleTimeResult =
            validateCycleTime rules.cycleTime excavator.cycleTime

        bucketCapacityErrors =
            case bucketCapacityResult of
                Err error ->
                    [ ( excavator.id, ExcavatorBucketCapacity, error ) ]

                Ok _ ->
                    []

        cycleTimeErrors =
            case cycleTimeResult of
                Err error ->
                    [ ( excavator.id, ExcavatorCycleTime, error ) ]

                Ok _ ->
                    []
    in
    bucketCapacityErrors ++ cycleTimeErrors


{-| Validate a single truck and return errors with ID and field
-}
validateSingleTruck : ValidationRules -> Truck -> List ( EquipmentId, TruckField, ValidationError )
validateSingleTruck rules truck =
    let
        capacityResult =
            validateTruckCapacity rules.truckCapacity truck.capacity

        roundTripTimeResult =
            validateRoundTripTime rules.roundTripTime truck.roundTripTime

        capacityErrors =
            case capacityResult of
                Err error ->
                    [ ( truck.id, TruckFieldCapacity, error ) ]

                Ok _ ->
                    []

        roundTripTimeErrors =
            case roundTripTimeResult of
                Err error ->
                    [ ( truck.id, TruckFieldRoundTripTime, error ) ]

                Ok _ ->
                    []
    in
    capacityErrors ++ roundTripTimeErrors


{-| Validate string input with edge case handling.
Converts string to float and validates against range with comprehensive error handling.
-}
validateStringInput : String -> ValidationRange -> String -> ValidationResult Float
validateStringInput fieldName range input =
    let
        trimmedInput =
            String.trim input
    in
    if String.isEmpty trimmedInput then
        Err (RequiredField { guidance = getRequiredFieldGuidance fieldName })

    else
        case String.toFloat trimmedInput of
            Nothing ->
                Err (InvalidFormat { input = trimmedInput, guidance = getInvalidFormatGuidance fieldName })

            Just value ->
                validateWithEdgeCases fieldName range value


{-| Validate with comprehensive edge case handling including decimal precision.
-}
validateWithEdgeCases : String -> ValidationRange -> Float -> ValidationResult Float
validateWithEdgeCases fieldName range value =
    -- First check decimal precision
    case validateDecimalPrecision value of
        Err error ->
            Err error

        Ok _ ->
            -- Then check edge cases
            if value < 0 then
                Err (EdgeCaseError { issue = "Negative values are not allowed", guidance = getNegativeValueGuidance fieldName })

            else if value == 0 then
                Err (EdgeCaseError { issue = "Zero values are not practical", guidance = getZeroValueGuidance fieldName })

            else if isInfinite value || isNaN value then
                Err (EdgeCaseError { issue = "Invalid number format", guidance = "Please enter a valid numeric value" })

            else
                -- Finally do standard range validation
                validateRange fieldName range value


{-| Validate decimal precision (maximum 2 decimal places).
-}
validateDecimalPrecision : Float -> ValidationResult Float
validateDecimalPrecision value =
    let
        stringValue =
            String.fromFloat value

        parts =
            String.split "." stringValue
    in
    case parts of
        [ _, decimals ] ->
            if String.length decimals > 2 then
                Err
                    (DecimalPrecisionError
                        { actual = value
                        , maxDecimals = 2
                        , guidance = "Construction measurements typically use up to 2 decimal places for practical accuracy."
                        }
                    )

            else
                Ok value

        _ ->
            Ok value


{-| Generate guidance for invalid format errors.
-}
getInvalidFormatGuidance : String -> String
getInvalidFormatGuidance fieldName =
    "Please enter a valid number for " ++ fieldName ++ ". Use decimal format (e.g., 2.5) without any letters or special characters."


{-| Generate guidance for negative value errors.
-}
getNegativeValueGuidance : String -> String
getNegativeValueGuidance fieldName =
    case fieldName of
        "Excavator Capacity" ->
            "Excavator capacity cannot be negative. Please enter a positive value in cubic yards."

        "Cycle Time" ->
            "Cycle time cannot be negative. Please enter a positive value in minutes."

        "Truck Capacity" ->
            "Truck capacity cannot be negative. Please enter a positive value in cubic yards."

        "Round Trip Time" ->
            "Round trip time cannot be negative. Please enter a positive value in minutes."

        "Work Hours" ->
            "Work hours cannot be negative. Please enter a positive number of hours."

        "Pond Dimension" ->
            "Pond dimensions cannot be negative. Please enter a positive value in feet."

        _ ->
            fieldName ++ " cannot be negative. Please enter a positive value."


{-| Generate guidance for zero value errors.
-}
getZeroValueGuidance : String -> String
getZeroValueGuidance fieldName =
    case fieldName of
        "Excavator Capacity" ->
            "Excavator capacity cannot be zero. Even small excavators have some bucket capacity."

        "Cycle Time" ->
            "Cycle time cannot be zero. All excavation operations require time to complete."

        "Truck Capacity" ->
            "Truck capacity cannot be zero. All trucks must have some hauling capacity."

        "Round Trip Time" ->
            "Round trip time cannot be zero. Material transport requires time."

        "Work Hours" ->
            "Work hours cannot be zero. Projects require at least some working time."

        "Pond Dimension" ->
            "Pond dimensions cannot be zero. All ponds must have measurable size."

        _ ->
            fieldName ++ " cannot be zero. Please enter a positive value."



-- HELPER FUNCTIONS


{-| Generic range validation helper with guidance.
Validates a value against minimum and maximum constraints with user-friendly guidance.
-}
validateRange : String -> ValidationRange -> Float -> ValidationResult Float
validateRange fieldName range value =
    if value <= 0 then
        Err (RequiredField { guidance = getRequiredFieldGuidance fieldName })

    else if value < range.min then
        Err (ValueTooLow { actual = value, minimum = range.min, guidance = getValueTooLowGuidance fieldName range })

    else if value > range.max then
        Err (ValueTooHigh { actual = value, maximum = range.max, guidance = getValueTooHighGuidance fieldName range })

    else
        Ok value


{-| Generate guidance for required field validation errors
-}
getRequiredFieldGuidance : String -> String
getRequiredFieldGuidance fieldName =
    case fieldName of
        "Excavator Capacity" ->
            "Excavator bucket capacity is required. Enter a value between 0.1 and 15.0 cubic yards. Typical excavators range from 1.5-8.0 cubic yards."

        "Cycle Time" ->
            "Excavator cycle time is required. Enter a value between 0.5 and 10.0 minutes. Most excavators complete a cycle in 1.5-3.0 minutes."

        "Truck Capacity" ->
            "Truck capacity is required. Enter a value between 5.0 and 50.0 cubic yards. Standard dump trucks typically hold 10-25 cubic yards."

        "Round Trip Time" ->
            "Round trip time is required. Enter a value between 5.0 and 120.0 minutes. Most job sites require 10-60 minutes per round trip."

        "Work Hours" ->
            "Daily work hours is required. Enter a value between 1.0 and 24.0 hours. Standard work days are typically 8-12 hours."

        "Pond Dimension" ->
            "Pond dimensions are required. Enter a value between 1.0 and 1000.0 feet. Most residential ponds are 10-100 feet in length/width."

        _ ->
            fieldName ++ " is required and must be a positive number."


{-| Generate guidance for value too low validation errors
-}
getValueTooLowGuidance : String -> ValidationRange -> String
getValueTooLowGuidance fieldName range =
    let
        rangeText =
            "Minimum: " ++ String.fromFloat range.min ++ ", Maximum: " ++ String.fromFloat range.max
    in
    case fieldName of
        "Excavator Capacity" ->
            "Excavator bucket capacity is too small. " ++ rangeText ++ " cubic yards. Mini excavators start at 0.1 cubic yards, while large excavators can handle up to 15.0 cubic yards."

        "Cycle Time" ->
            "Cycle time is too fast. " ++ rangeText ++ " minutes. Even the fastest excavators need at least 30 seconds (0.5 minutes) per cycle to safely dig, swing, and dump."

        "Truck Capacity" ->
            "Truck capacity is too small. " ++ rangeText ++ " cubic yards. The smallest commercial dump trucks typically start at 5 cubic yards."

        "Round Trip Time" ->
            "Round trip time is too short. " ++ rangeText ++ " minutes. Even on-site dumping typically requires at least 5 minutes for loading, traveling, and returning."

        "Work Hours" ->
            "Work hours per day is too low. " ++ rangeText ++ " hours. Construction projects typically require at least 1 hour of productive work time."

        "Pond Dimension" ->
            "Pond dimension is too small. " ++ rangeText ++ " feet. Practical excavation projects typically start at 1 foot minimum."

        _ ->
            "Value is below the minimum of " ++ String.fromFloat range.min ++ "."


{-| Generate guidance for value too high validation errors
-}
getValueTooHighGuidance : String -> ValidationRange -> String
getValueTooHighGuidance fieldName range =
    let
        rangeText =
            "Minimum: " ++ String.fromFloat range.min ++ ", Maximum: " ++ String.fromFloat range.max
    in
    case fieldName of
        "Excavator Capacity" ->
            "Excavator bucket capacity is too large. " ++ rangeText ++ " cubic yards. Even the largest mining excavators rarely exceed 15 cubic yards for construction projects."

        "Cycle Time" ->
            "Cycle time is too slow. " ++ rangeText ++ " minutes. If cycles take more than 10 minutes, consider equipment maintenance or operator training."

        "Truck Capacity" ->
            "Truck capacity is too large. " ++ rangeText ++ " cubic yards. Road weight limits and site access typically limit trucks to 50 cubic yards maximum."

        "Round Trip Time" ->
            "Round trip time is too long. " ++ rangeText ++ " minutes. Consider adding more trucks or finding a closer dump site if trips exceed 2 hours."

        "Work Hours" ->
            "Work hours per day is too high. " ++ rangeText ++ " hours. Check labor regulations and operator safety - 24 hours is the absolute maximum."

        "Pond Dimension" ->
            "Pond dimension is extremely large. " ++ rangeText ++ " feet. Projects over 1000 feet may require specialized equipment and permits."

        _ ->
            "Value exceeds the maximum of " ++ String.fromFloat range.max ++ "."


{-| Convert validation error to user-friendly error message.
-}
errorToString : ValidationError -> String
errorToString error =
    case error of
        ValueTooLow { actual, minimum, guidance } ->
            "Value " ++ String.fromFloat actual ++ " is too low. Minimum: " ++ String.fromFloat minimum ++ ". " ++ guidance

        ValueTooHigh { actual, maximum, guidance } ->
            "Value " ++ String.fromFloat actual ++ " is too high. Maximum: " ++ String.fromFloat maximum ++ ". " ++ guidance

        RequiredField { guidance } ->
            guidance

        InvalidFormat { input, guidance } ->
            "Invalid format '" ++ input ++ "'. " ++ guidance

        DecimalPrecisionError { actual, maxDecimals, guidance } ->
            "Too many decimal places in " ++ String.fromFloat actual ++ ". Maximum " ++ String.fromInt maxDecimals ++ " decimal places allowed. " ++ guidance

        EdgeCaseError { issue, guidance } ->
            issue ++ ". " ++ guidance

        ConfigurationError message ->
            "Configuration error: " ++ message
