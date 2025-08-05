module Types.Validation exposing (ValidationError(..), ValidationResult)

{-| Validation types and error handling

@docs ValidationError, ValidationResult

-}


-- VALIDATION TYPES

type ValidationError
    = ValueTooLow Float Float  -- actual, minimum
    | ValueTooHigh Float Float  -- actual, maximum
    | InvalidFormat String
    | RequiredField String
    | ConfigurationError String


type alias ValidationResult a =
    Result ValidationError a