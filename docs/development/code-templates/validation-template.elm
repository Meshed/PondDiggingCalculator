{-| [Module Name] Validation - Input validation for [domain area]

This module provides comprehensive validation functions for [domain area] inputs,
ensuring data integrity and providing clear error messages for invalid inputs.

## Validation Functions
@docs validate[DomainType], validate[SpecificField], validateBatch[DomainType]

## Error Types  
@docs [DomainType]ValidationError, ValidationContext

## Helper Functions
@docs is[PropertyName], format[PropertyName], [propertyName]Range

-}
module Utils.[DomainType]Validation exposing
    ( validate[DomainType]
    , validate[SpecificField]
    , validateBatch[DomainType]
    , [DomainType]ValidationError(..)
    , ValidationContext
    , is[PropertyName]
    , format[PropertyName]
    , [propertyName]Range
    )

import String.Extra
import Regex

-- Import project types
import Types.[DomainType] exposing ([DomainType], [FieldType])


-- TYPES


{-| Comprehensive validation error types with specific context.
    
    Each error type includes:
    - The invalid value that caused the error
    - Expected constraints or format
    - Human-readable error message
    - Field context for UI error display
-}
type [DomainType]ValidationError
    = FieldRequired String  -- field name
    | ValueTooLow 
        { field : String
        , value : Float
        , minimum : Float
        }
    | ValueTooHigh 
        { field : String
        , value : Float
        , maximum : Float
        }
    | InvalidFormat 
        { field : String
        , value : String
        , expectedFormat : String
        , example : String
        }
    | InvalidRange 
        { field : String
        , value : Float
        , minimum : Float
        , maximum : Float
        }
    | BusinessRuleViolation 
        { rule : String
        , field : String
        , value : String
        , explanation : String
        }
    | CrossFieldValidationError 
        { primaryField : String
        , relatedField : String
        , constraint : String
        }


{-| Validation context providing additional information for validation logic.
    
    Includes:
    - Validation mode (strict vs. permissive)
    - Business context (e.g., project type, user permissions)
    - Validation timestamp for audit trails
-}
type alias ValidationContext =
    { mode : ValidationMode
    , businessContext : BusinessContext
    , timestamp : String  -- ISO format timestamp
    }


{-| Validation modes for different use cases. -}
type ValidationMode
    = Strict  -- All validation rules enforced
    | Permissive  -- Some rules relaxed for data import/migration
    | Preview  -- Validation for preview/estimation purposes


{-| Business context affecting validation rules. -}
type alias BusinessContext =
    { projectType : String
    , userRole : String
    , organizationSettings : Dict String String
    }


-- CONSTANTS


{-| Valid range for [property name] values. -}  
[propertyName]Range : { minimum : Float, maximum : Float }
[propertyName]Range =
    { minimum = 0.1  -- Minimum meaningful value
    , maximum = 100.0  -- Maximum reasonable value based on business constraints
    }


{-| Default validation context for standard validation. -}
defaultValidationContext : ValidationContext
defaultValidationContext =
    { mode = Strict
    , businessContext = 
        { projectType = "standard"
        , userRole = "user"
        , organizationSettings = Dict.empty
        }
    , timestamp = "2025-01-01T00:00:00Z"  -- Will be replaced with actual timestamp
    }


-- VALIDATION FUNCTIONS


{-| Validate complete [domain type] with all business rules.
    
    Performs comprehensive validation including:
    - Individual field validation (format, range, constraints)
    - Cross-field validation (relationships between fields)
    - Business rule validation (domain-specific rules)
    - Context-aware validation (based on validation context)
    
    ## Parameters
    - `context`: Validation context for rule customization
    - `raw[DomainType]`: Raw input data to validate
    
    ## Returns
    - `Ok validated[DomainType]`: All validation passed
    - `Err validationErrors`: List of specific validation failures
    
    ## Examples
    ```elm
    validate[DomainType] defaultValidationContext rawInput
    --> Ok validated[DomainType]
    
    validate[DomainType] defaultValidationContext invalidInput
    --> Err [ValueTooLow { field = "capacity", value = -1.0, minimum = 0.1 }]
    ```
-}
validate[DomainType] : ValidationContext -> Raw[DomainType] -> Result (List [DomainType]ValidationError) [DomainType]
validate[DomainType] context raw =
    let
        -- Individual field validation results
        field1Result = validate[SpecificField] context.mode raw.field1
        field2Result = validate[SecondField] context.mode raw.field2
        field3Result = validate[ThirdField] context.mode raw.field3
        
        -- Collect individual field errors
        fieldErrors = collectFieldErrors [field1Result, field2Result, field3Result]
    in
    if not (List.isEmpty fieldErrors) then
        Err fieldErrors
    else
        -- All individual fields valid, now validate cross-field relationships
        case (field1Result, field2Result, field3Result) of
            (Ok validField1, Ok validField2, Ok validField3) ->
                validateCrossFieldRules context validField1 validField2 validField3
                    |> Result.andThen (validateBusinessRules context)
                    |> Result.map (\_ -> create[DomainType] validField1 validField2 validField3)
                    
            _ ->
                -- This shouldn't happen given the fieldErrors check above
                Err [BusinessRuleViolation 
                    { rule = "UnexpectedValidationState"
                    , field = "internal"
                    , value = "validation state inconsistency"
                    , explanation = "Internal validation error - please report this issue"
                    }]


{-| Validate specific field with format and range checking.
    
    ## Parameters
    - `mode`: Validation strictness mode
    - `rawValue`: Raw input value to validate
    
    ## Returns
    - `Ok validatedValue`: Value passed validation
    - `Err error`: Specific validation error with context
    
    ## Business Rules
    - [Rule 1]: [Description and rationale]
    - [Rule 2]: [Description and rationale]
    
    ## Examples
    ```elm
    validate[SpecificField] Strict "2.5"
    --> Ok 2.5
    
    validate[SpecificField] Strict "-1.0"  
    --> Err (ValueTooLow { field = "[fieldName]", value = -1.0, minimum = 0.1 })
    ```
-}
validate[SpecificField] : ValidationMode -> String -> Result [DomainType]ValidationError [FieldType]
validate[SpecificField] mode rawValue =
    let
        trimmedValue = String.trim rawValue
    in
    if String.isEmpty trimmedValue then
        Err (FieldRequired "[fieldName]")
    else
        case String.toFloat trimmedValue of
            Nothing ->
                Err (InvalidFormat 
                    { field = "[fieldName]"
                    , value = rawValue
                    , expectedFormat = "Valid decimal number"
                    , example = "2.5"
                    })
                    
            Just numericValue ->
                validateNumericRange mode "[fieldName]" numericValue [propertyName]Range


{-| Validate numeric value against specified range.
    
    ## Parameters
    - `mode`: Validation mode (affects strictness)
    - `fieldName`: Field name for error context
    - `value`: Numeric value to validate
    - `range`: Valid range with minimum and maximum
    
    ## Returns
    Validated numeric value or range validation error.
-}
validateNumericRange : ValidationMode -> String -> Float -> { minimum : Float, maximum : Float } -> Result [DomainType]ValidationError Float
validateNumericRange mode fieldName value range =
    let
        -- Adjust range based on validation mode
        adjustedRange = 
            case mode of
                Strict -> range
                Permissive -> { range | minimum = range.minimum * 0.5 }  -- Relax minimum by 50%
                Preview -> { range | maximum = range.maximum * 2.0 }  -- Allow higher values for estimates
    in
    if value < adjustedRange.minimum then
        Err (ValueTooLow 
            { field = fieldName
            , value = value
            , minimum = adjustedRange.minimum
            })
    else if value > adjustedRange.maximum then
        Err (ValueTooHigh 
            { field = fieldName
            , value = value
            , maximum = adjustedRange.maximum
            })
    else
        Ok value


{-| Validate batch of [domain type] items efficiently.
    
    Processes multiple items and collects all validation errors,
    allowing users to see all issues at once rather than fixing one at a time.
    
    ## Parameters
    - `context`: Validation context
    - `rawItems`: List of raw input items to validate
    
    ## Returns
    - `Ok validatedItems`: All items passed validation
    - `Err batchErrors`: All validation errors with item indices
    
    ## Performance Notes
    - Processes all items even if some fail validation
    - Uses indexed error reporting for UI feedback
    - Optimized for large batches (up to 1000+ items)
-}
validateBatch[DomainType] : ValidationContext -> List Raw[DomainType] -> Result (List (Int, [DomainType]ValidationError)) (List [DomainType])
validateBatch[DomainType] context rawItems =
    let
        validateWithIndex : Int -> Raw[DomainType] -> Result (List (Int, [DomainType]ValidationError)) [DomainType]
        validateWithIndex index rawItem =
            case validate[DomainType] context rawItem of
                Ok validItem ->
                    Ok validItem
                    
                Err errors ->
                    Err (List.map (\error -> (index, error)) errors)
                    
        -- Process all items and separate successes from failures
        results = List.indexedMap validateWithIndex rawItems
        
        successes = List.filterMap Result.toMaybe results
        failures = List.concatMap (Result.toMaybe << Result.mapError identity) results
    in
    if List.isEmpty failures then
        Ok successes
    else
        Err failures


-- CROSS-FIELD VALIDATION


{-| Validate relationships between fields.
    
    Checks business rules that depend on multiple field values:
    - Field A must be greater than Field B
    - Combination of fields must meet specific constraints
    - Derived calculations must be within acceptable ranges
-}
validateCrossFieldRules : ValidationContext -> [FieldType] -> [FieldType] -> [FieldType] -> Result (List [DomainType]ValidationError) ()
validateCrossFieldRules context field1 field2 field3 =
    let
        errors = []
        
        -- Example cross-field validation: field1 should be larger than field2
        field1VsField2Error =
            if field1 <= field2 then
                Just (CrossFieldValidationError 
                    { primaryField = "field1"
                    , relatedField = "field2"
                    , constraint = "Field1 must be greater than Field2"
                    })
            else
                Nothing
                
        -- Example: combination constraint
        combinationError =
            if (field1 + field2) > field3 * 2.0 then
                Just (BusinessRuleViolation 
                    { rule = "CombinationConstraint"
                    , field = "field1,field2,field3"
                    , value = String.fromFloat (field1 + field2) ++ " vs " ++ String.fromFloat (field3 * 2.0)
                    , explanation = "Sum of field1 and field2 cannot exceed twice field3"
                    })
            else
                Nothing
                
        allErrors = List.filterMap identity [field1VsField2Error, combinationError]
    in
    if List.isEmpty allErrors then
        Ok ()
    else
        Err allErrors


-- BUSINESS RULE VALIDATION


{-| Validate business-specific rules and constraints.
    
    Applies domain-specific business logic that goes beyond basic
    field validation, including industry standards and organizational policies.
-}
validateBusinessRules : ValidationContext -> [DomainType] -> Result (List [DomainType]ValidationError) [DomainType]
validateBusinessRules context domainItem =
    let
        errors = []
        
        -- Example business rule: check against organizational policies
        policyError = validateOrganizationalPolicy context domainItem
        
        -- Example business rule: industry standard compliance
        industryStandardError = validateIndustryStandards context domainItem
        
        allErrors = List.filterMap identity [policyError, industryStandardError]
    in
    if List.isEmpty allErrors then
        Ok domainItem
    else
        Err allErrors


{-| Validate against organizational policies. -}
validateOrganizationalPolicy : ValidationContext -> [DomainType] -> Maybe [DomainType]ValidationError
validateOrganizationalPolicy context domainItem =
    -- Implementation depends on specific business rules
    -- This is a placeholder for actual policy validation
    Nothing


{-| Validate against industry standards. -}
validateIndustryStandards : ValidationContext -> [DomainType] -> Maybe [DomainType]ValidationError
validateIndustryStandards context domainItem =
    -- Implementation depends on specific industry requirements
    -- This is a placeholder for actual standards validation
    Nothing


-- HELPER FUNCTIONS


{-| Check if value represents a valid [property name].
    
    ## Parameters
    - `value`: Value to check
    
    ## Returns
    True if value meets basic [property name] criteria.
-}
is[PropertyName] : [FieldType] -> Bool
is[PropertyName] value =
    value >= [propertyName]Range.minimum && value <= [propertyName]Range.maximum


{-| Format [property name] for display with appropriate units and precision.
    
    ## Parameters
    - `value`: Numeric value to format
    
    ## Returns
    Formatted string with units and appropriate decimal places.
    
    ## Examples
    ```elm
    format[PropertyName] 2.5
    --> "2.5 [units]"
    
    format[PropertyName] 10.0  
    --> "10.0 [units]"
    ```
-}
format[PropertyName] : [FieldType] -> String
format[PropertyName] value =
    String.fromFloat value ++ " [units]"


{-| Collect validation errors from multiple field validation results. -}
collectFieldErrors : List (Result [DomainType]ValidationError a) -> List [DomainType]ValidationError
collectFieldErrors results =
    results
        |> List.filterMap (\result ->
            case result of
                Err error -> Just error
                Ok _ -> Nothing
        )


{-| Create validated [domain type] from validated field values. -}
create[DomainType] : [FieldType] -> [FieldType] -> [FieldType] -> [DomainType]
create[DomainType] field1 field2 field3 =
    -- Implementation depends on actual domain type constructor
    { field1 = field1
    , field2 = field2  
    , field3 = field3
    , validatedAt = "2025-01-01T00:00:00Z"  -- Would be actual timestamp
    }


-- ERROR FORMATTING


{-| Convert validation error to user-friendly message.
    
    ## Parameters
    - `error`: Validation error to convert
    
    ## Returns
    Human-readable error message with specific guidance.
-}
errorToString : [DomainType]ValidationError -> String
errorToString error =
    case error of
        FieldRequired fieldName ->
            "The " ++ fieldName ++ " field is required. Please provide a value."
            
        ValueTooLow { field, value, minimum } ->
            "The " ++ field ++ " value " ++ String.fromFloat value 
            ++ " is too low. The minimum allowed value is " ++ String.fromFloat minimum ++ "."
            
        ValueTooHigh { field, value, maximum } ->
            "The " ++ field ++ " value " ++ String.fromFloat value 
            ++ " is too high. The maximum allowed value is " ++ String.fromFloat maximum ++ "."
            
        InvalidFormat { field, value, expectedFormat, example } ->
            "The " ++ field ++ " value '" ++ value 
            ++ "' has an invalid format. Expected: " ++ expectedFormat 
            ++ ". Example: " ++ example
            
        InvalidRange { field, value, minimum, maximum } ->
            "The " ++ field ++ " value " ++ String.fromFloat value 
            ++ " is not in the valid range. Must be between " 
            ++ String.fromFloat minimum ++ " and " ++ String.fromFloat maximum ++ "."
            
        BusinessRuleViolation { rule, field, value, explanation } ->
            "Business rule violation in " ++ field ++ ": " ++ explanation
            
        CrossFieldValidationError { primaryField, relatedField, constraint } ->
            "Field relationship error: " ++ constraint 
            ++ " (affects " ++ primaryField ++ " and " ++ relatedField ++ ")"


{-| Convert validation error to structured data for API responses. -}
errorToStructuredData : [DomainType]ValidationError -> { field : String, code : String, message : String }
errorToStructuredData error =
    case error of
        FieldRequired fieldName ->
            { field = fieldName
            , code = "FIELD_REQUIRED"
            , message = errorToString error
            }
            
        ValueTooLow { field } ->
            { field = field
            , code = "VALUE_TOO_LOW"
            , message = errorToString error
            }
            
        ValueTooHigh { field } ->
            { field = field
            , code = "VALUE_TOO_HIGH"
            , message = errorToString error
            }
            
        InvalidFormat { field } ->
            { field = field
            , code = "INVALID_FORMAT"
            , message = errorToString error
            }
            
        InvalidRange { field } ->
            { field = field
            , code = "INVALID_RANGE"
            , message = errorToString error
            }
            
        BusinessRuleViolation { field } ->
            { field = field
            , code = "BUSINESS_RULE_VIOLATION"
            , message = errorToString error
            }
            
        CrossFieldValidationError { primaryField } ->
            { field = primaryField
            , code = "CROSS_FIELD_ERROR"
            , message = errorToString error
            }