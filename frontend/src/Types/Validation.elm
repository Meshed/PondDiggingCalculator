module Types.Validation exposing (ValidationError(..), ValidationResult)

{-| Validation types and error handling

@docs ValidationError, ValidationResult

-}

-- VALIDATION TYPES


type ValidationError
    = ValueTooLow { actual : Float, minimum : Float, guidance : String }
    | ValueTooHigh { actual : Float, maximum : Float, guidance : String }
    | RequiredField { guidance : String }
    | InvalidFormat { input : String, guidance : String }
    | DecimalPrecisionError { actual : Float, maxDecimals : Int, guidance : String }
    | EdgeCaseError { issue : String, guidance : String }
    | ConfigurationError String


type alias ValidationResult a =
    Result ValidationError a
