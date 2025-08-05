module Utils.Validation exposing 
    ( validateExcavatorCapacity
    , validateCycleTime
    , validateTruckCapacity
    , validateRoundTripTime
    , validateWorkHours
    , validatePondDimensions
    , validateAllInputs
    , ProjectInputs
    )

{-| Input validation functions for pond digging calculator

@docs validateExcavatorCapacity, validateCycleTime, validateTruckCapacity
@docs validateRoundTripTime, validateWorkHours, validatePondDimensions
@docs validateAllInputs, ProjectInputs

-}

import Types.Equipment exposing (CubicYards, Minutes)
import Types.Validation exposing (ValidationError(..), ValidationResult)
import Utils.Config exposing (ValidationRules, ValidationRange)


-- TYPES

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
        |> Result.andThen (\_ ->
            validateCycleTime rules.cycleTime inputs.excavatorCycleTime
        )
        |> Result.andThen (\_ ->
            validateTruckCapacity rules.truckCapacity inputs.truckCapacity
        )
        |> Result.andThen (\_ ->
            validateRoundTripTime rules.roundTripTime inputs.truckRoundTripTime
        )
        |> Result.andThen (\_ ->
            validateWorkHours rules.workHours inputs.workHoursPerDay
        )
        |> Result.andThen (\_ ->
            validatePondDimensions rules.pondDimensions inputs.pondLength
        )
        |> Result.andThen (\_ ->
            validatePondDimensions rules.pondDimensions inputs.pondWidth
        )
        |> Result.andThen (\_ ->
            validatePondDimensions rules.pondDimensions inputs.pondDepth
        )
        |> Result.map (\_ -> inputs)


-- HELPER FUNCTIONS

{-| Generic range validation helper.
    Validates a value against minimum and maximum constraints.
-}
validateRange : String -> ValidationRange -> Float -> ValidationResult Float
validateRange fieldName range value =
    if value <= 0 then
        Err (RequiredField fieldName)
    else if value < range.min then
        Err (ValueTooLow value range.min)
    else if value > range.max then
        Err (ValueTooHigh value range.max)
    else
        Ok value


{-| Convert validation error to user-friendly error message.
-}
errorToString : ValidationError -> String
errorToString error =
    case error of
        ValueTooLow actual minimum ->
            "Value " ++ String.fromFloat actual ++ " is too low. Minimum: " ++ String.fromFloat minimum

        ValueTooHigh actual maximum ->
            "Value " ++ String.fromFloat actual ++ " is too high. Maximum: " ++ String.fromFloat maximum

        InvalidFormat message ->
            "Invalid format: " ++ message

        RequiredField fieldName ->
            fieldName ++ " is required and must be greater than zero"

        ConfigurationError message ->
            "Configuration error: " ++ message