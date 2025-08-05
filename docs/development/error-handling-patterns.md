# Error Handling Patterns

## Overview
This guide establishes comprehensive error handling patterns for the Pond Digging Calculator Elm codebase, using Result types and validation approaches to ensure robust error management.

## Result Type Usage Patterns

### Basic Result Pattern
Use Result types for all operations that can fail, providing specific error information:

```elm
-- ✅ GOOD: Specific error types instead of Maybe
validateBucketCapacity : Float -> Result ValidationError CubicYards
validateBucketCapacity capacity =
    if capacity <= 0 then
        Err (ValueTooLow capacity 0.1)
    else if capacity > 15.0 then
        Err (ValueTooHigh capacity 15.0)
    else
        Ok capacity

-- ❌ BAD: Maybe loses error information
validateBucketCapacity : Float -> Maybe CubicYards
validateBucketCapacity capacity =
    if capacity > 0 && capacity <= 15.0 then
        Just capacity
    else
        Nothing
```

### Nested Result Handling
Handle nested Result operations using Result.andThen for chaining:

```elm
{-| Validate complete equipment configuration through validation pipeline. -}
validateEquipment : RawEquipment -> Result ValidationError Equipment
validateEquipment rawEquipment =
    validateBucketCapacity rawEquipment.bucketCapacity
        |> Result.andThen (\validCapacity ->
            validateCycleTime rawEquipment.cycleTime
                |> Result.andThen (\validCycleTime ->
                    validateEquipmentType rawEquipment.equipmentType
                        |> Result.map (\validType ->
                            { bucketCapacity = validCapacity
                            , cycleTime = validCycleTime
                            , equipmentType = validType
                            , isActive = True
                            }
                        )
                )
        )
```

### Result Accumulation Pattern
Collect multiple validation errors using custom accumulation functions:

```elm
{-| Validate multiple fields and accumulate all errors. -}
validateProjectInputs : RawProjectInputs -> Result (List ValidationError) ValidatedProject
validateProjectInputs inputs =
    let
        lengthResult = validateLength inputs.length
        widthResult = validateWidth inputs.width  
        depthResult = validateDepth inputs.depth
        soilResult = validateSoilType inputs.soilType
    in
    case (lengthResult, widthResult, depthResult, soilResult) of
        (Ok length, Ok width, Ok depth, Ok soil) ->
            Ok { length = length, width = width, depth = depth, soilType = soil }
            
        _ ->
            Err (collectErrors [lengthResult, widthResult, depthResult, soilResult])

{-| Helper function to collect all validation errors. -}
collectErrors : List (Result ValidationError a) -> List ValidationError
collectErrors results =
    results
        |> List.filterMap (\result ->
            case result of
                Err error -> Just error
                Ok _ -> Nothing
        )
```

## Error Type Definitions

### Hierarchical Error Types
Define error types that provide specific, actionable information:

```elm
{-| Comprehensive validation error types with specific context. -}
type ValidationError
    = ValueTooLow Float Float  -- actual, minimum
    | ValueTooHigh Float Float  -- actual, maximum  
    | InvalidFormat String  -- invalid input string
    | RequiredFieldMissing String  -- field name
    | InvalidRange Float Float Float  -- value, min, max
    | BusinessRuleViolation BusinessRule String  -- rule, description

{-| Business rule violations for domain-specific errors. -}
type BusinessRule
    = MinimumEquipmentRequired Int  -- minimum count
    | MaximumProjectDuration Days  -- maximum duration
    | EquipmentCompatibility String  -- compatibility issue
    | BudgetConstraintViolation Currency  -- budget limit

{-| Calculation-specific error types. -}
type CalculationError
    = InsufficientData String  -- missing data description
    | MathematicalError String  -- mathematical constraint violation
    | ConfigurationError String  -- configuration problem
    | ExternalResourceError String  -- external dependency failure
```

### Error Message Standards
Provide clear, user-friendly error messages with actionable guidance:

```elm
{-| Convert validation errors to user-friendly messages. -}
validationErrorToString : ValidationError -> String
validationErrorToString error =
    case error of
        ValueTooLow actual minimum ->
            "Value " ++ String.fromFloat actual 
            ++ " is too low. Minimum allowed is " ++ String.fromFloat minimum
            
        ValueTooHigh actual maximum ->
            "Value " ++ String.fromFloat actual 
            ++ " is too high. Maximum allowed is " ++ String.fromFloat maximum
            
        InvalidFormat input ->
            "Invalid format: '" ++ input 
            ++ "'. Please enter a valid number."
            
        RequiredFieldMissing fieldName ->
            "Required field '" ++ fieldName 
            ++ "' is missing. Please provide a value."
            
        InvalidRange value min max ->
            "Value " ++ String.fromFloat value 
            ++ " is not in valid range " ++ String.fromFloat min 
            ++ " to " ++ String.fromFloat max
            
        BusinessRuleViolation rule description ->
            "Business rule violation: " ++ description
```

### Context-Rich Error Types
Include context information to help with debugging and user guidance:

```elm
{-| Equipment validation errors with field-specific context. -}
type EquipmentValidationError
    = BucketCapacityError 
        { value : Float
        , minimum : Float
        , maximum : Float
        , fieldName : String
        }
    | CycleTimeError 
        { value : Float
        , minimum : Float
        , maximum : Float
        , equipmentType : String
        }
    | EquipmentTypeError 
        { provided : String
        , validTypes : List String
        }

{-| Create bucket capacity error with full context. -}
createBucketCapacityError : Float -> EquipmentValidationError
createBucketCapacityError value =
    BucketCapacityError
        { value = value
        , minimum = 0.1
        , maximum = 15.0
        , fieldName = "Bucket Capacity"
        }
```

## Validation Pipeline Patterns

### Sequential Validation Chain
Validate inputs in sequence, stopping at first error:

```elm
{-| Sequential validation pipeline using Result.andThen. -}
validateEquipmentSequential : RawEquipment -> Result ValidationError Equipment
validateEquipmentSequential raw =
    validateBucketCapacity raw.bucketCapacity
        |> Result.andThen (\capacity ->
            validateCycleTime raw.cycleTime
        )
        |> Result.andThen (\cycleTime ->
            validateOperationalStatus raw.status
        )
        |> Result.map (\status ->
            Equipment capacity cycleTime status
        )
```

### Parallel Validation Pattern
Validate all fields and collect all errors:

```elm
{-| Parallel validation collecting all errors. -}
validateEquipmentParallel : RawEquipment -> Result (List ValidationError) Equipment
validateEquipmentParallel raw =
    let
        capacityResult = validateBucketCapacity raw.bucketCapacity
        cycleTimeResult = validateCycleTime raw.cycleTime
        statusResult = validateOperationalStatus raw.status
    in
    Result.map3 Equipment capacityResult cycleTimeResult statusResult
        |> Result.mapError (\errors -> [errors])  -- Convert single error to list
```

### Validation with Business Rules
Apply business logic validation after basic input validation:

```elm
{-| Two-stage validation: input format then business rules. -}
validateProjectWithBusinessRules : RawProject -> Result ValidationError ValidatedProject
validateProjectWithBusinessRules raw =
    validateBasicProjectInputs raw
        |> Result.andThen validateBusinessRules
        |> Result.andThen validateProjectConstraints

{-| Business rule validation for project feasibility. -}
validateBusinessRules : ValidatedProject -> Result ValidationError ValidatedProject
validateBusinessRules project =
    if project.estimatedDuration > maxProjectDuration then
        Err (BusinessRuleViolation 
            (MaximumProjectDuration maxProjectDuration)
            ("Project duration " ++ String.fromFloat project.estimatedDuration 
             ++ " days exceeds maximum allowed " ++ String.fromFloat maxProjectDuration)
        )
    else if List.length project.equipment < minRequiredEquipment then
        Err (BusinessRuleViolation
            (MinimumEquipmentRequired minRequiredEquipment)
            ("At least " ++ String.fromInt minRequiredEquipment 
             ++ " pieces of equipment required for this project size")
        )
    else
        Ok project
```

## Error Propagation Strategies

### Fail-Fast Strategy
Stop processing immediately when an error occurs:

```elm
{-| Process equipment list, stopping at first validation failure. -}
processEquipmentListFailFast : List RawEquipment -> Result ValidationError (List Equipment)
processEquipmentListFailFast rawEquipment =
    let
        processItem : RawEquipment -> List Equipment -> Result ValidationError (List Equipment)
        processItem raw acc =
            validateEquipment raw
                |> Result.map (\validEquipment -> validEquipment :: acc)
    in
    List.foldl 
        (\raw result -> 
            result |> Result.andThen (\acc -> processItem raw acc)
        )
        (Ok [])
        rawEquipment
```

### Error Collection Strategy
Continue processing and collect all errors:

```elm
{-| Process all equipment and collect validation errors. -}
processEquipmentListCollectErrors : List RawEquipment -> ( List Equipment, List ValidationError )
processEquipmentListCollectErrors rawEquipment =
    let
        processItem : RawEquipment -> ( List Equipment, List ValidationError ) -> ( List Equipment, List ValidationError )
        processItem raw (validEquipment, errors) =
            case validateEquipment raw of
                Ok equipment ->
                    (equipment :: validEquipment, errors)
                    
                Err error ->
                    (validEquipment, error :: errors)
    in
    List.foldl processItem ([], []) rawEquipment
```

### Partial Success Strategy
Process what you can and report both successes and failures:

```elm
{-| Equipment processing result with partial success information. -}
type ProcessingResult a e =
    { successful : List a
    , failed : List ( Int, e )  -- Index and error
    , totalProcessed : Int
    }

{-| Process equipment list with partial success tracking. -}
processEquipmentWithPartialSuccess : List RawEquipment -> ProcessingResult Equipment ValidationError
processEquipmentWithPartialSuccess rawEquipment =
    let
        processWithIndex : Int -> RawEquipment -> ProcessingResult Equipment ValidationError -> ProcessingResult Equipment ValidationError
        processWithIndex index raw acc =
            case validateEquipment raw of
                Ok equipment ->
                    { acc 
                        | successful = equipment :: acc.successful
                        , totalProcessed = acc.totalProcessed + 1
                    }
                    
                Err error ->
                    { acc 
                        | failed = (index, error) :: acc.failed
                        , totalProcessed = acc.totalProcessed + 1
                    }
    in
    List.indexedMap Tuple.pair rawEquipment
        |> List.foldl (\(index, raw) acc -> processWithIndex index raw acc) 
            { successful = [], failed = [], totalProcessed = 0 }
```

## Error Recovery Strategies

### Default Value Recovery
Provide sensible defaults for recoverable errors:

```elm
{-| Parse numeric input with fallback to default value. -}
parseWithDefault : Float -> String -> Float
parseWithDefault defaultValue input =
    case String.toFloat input of
        Just value ->
            if value >= 0 then value else defaultValue
            
        Nothing ->
            defaultValue

{-| Validate with automatic recovery to safe defaults. -}
validateWithRecovery : RawEquipment -> Equipment
validateWithRecovery raw =
    let
        safeCapacity = 
            case validateBucketCapacity raw.bucketCapacity of
                Ok capacity -> capacity
                Err _ -> defaultBucketCapacity  -- Use safe default
                
        safeCycleTime =
            case validateCycleTime raw.cycleTime of
                Ok cycleTime -> cycleTime
                Err _ -> defaultCycleTime  -- Use safe default
    in
    Equipment safeCapacity safeCycleTime Active
```

### Retry Strategy
Implement retry logic for transient failures:

```elm
{-| Configuration loading with retry capability. -}
type LoadingResult a
    = Loading
    | LoadSuccess a
    | LoadFailure String Int  -- error message, retry count

{-| Load configuration with automatic retry. -}
loadConfigWithRetry : Int -> String -> Task Never (LoadingResult Config)
loadConfigWithRetry maxRetries configPath =
    let
        attemptLoad : Int -> Task Never (LoadingResult Config)
        attemptLoad remainingRetries =
            loadConfig configPath
                |> Task.map LoadSuccess
                |> Task.onError (\error ->
                    if remainingRetries > 0 then
                        Process.sleep 1000  -- Wait 1 second
                            |> Task.andThen (\_ -> attemptLoad (remainingRetries - 1))
                    else
                        Task.succeed (LoadFailure (errorToString error) maxRetries)
                )
    in
    attemptLoad maxRetries
```

### Graceful Degradation
Continue with reduced functionality when non-critical features fail:

```elm
{-| Application state with graceful degradation capability. -}
type alias AppState =
    { coreFeatures : CoreFeatures  -- Always available
    , advancedFeatures : Maybe AdvancedFeatures  -- May fail gracefully
    , configurationStatus : ConfigStatus
    }

{-| Initialize application with graceful degradation. -}
initializeApp : Config -> AppState
initializeApp config =
    let
        coreFeatures = initializeCoreFeatures config  -- Never fails
        
        advancedFeatures =
            case initializeAdvancedFeatures config of
                Ok features -> Just features
                Err _ -> Nothing  -- Degrade gracefully
                
        configStatus =
            if advancedFeatures == Nothing then
                PartiallyLoaded "Advanced features disabled due to configuration errors"
            else
                FullyLoaded
    in
    { coreFeatures = coreFeatures
    , advancedFeatures = advancedFeatures
    , configurationStatus = configStatus
    }
```

## Error Logging and Debugging

### Structured Error Logging
Implement consistent error logging for debugging:

```elm
{-| Error log entry with structured information. -}
type alias ErrorLogEntry =
    { timestamp : Time.Posix
    , errorType : String
    , errorMessage : String
    , context : Dict String String
    , severity : ErrorSeverity
    }

type ErrorSeverity
    = Info
    | Warning  
    | Error
    | Critical

{-| Log validation error with context. -}
logValidationError : ValidationError -> String -> Cmd Msg
logValidationError error context =
    let
        logEntry =
            { timestamp = Time.now
            , errorType = "ValidationError"
            , errorMessage = validationErrorToString error
            , context = Dict.fromList [("context", context)]
            , severity = Warning
            }
    in
    logError logEntry
```

### Debug Information
Include debug information in development builds:

```elm
{-| Enhanced error with debug information. -}
type alias DebugError =
    { error : ValidationError
    , debugInfo : DebugInfo
    }

type alias DebugInfo =
    { functionName : String
    , inputValues : List (String, String)
    , stackTrace : List String
    , timestamp : Time.Posix
    }

{-| Create debug error with context information. -}
createDebugError : ValidationError -> String -> List (String, String) -> DebugError
createDebugError error functionName inputs =
    { error = error
    , debugInfo = 
        { functionName = functionName
        , inputValues = inputs
        , stackTrace = []  -- Would be populated by debug runtime
        , timestamp = Time.now  -- Would be actual timestamp
        }
    }
```

## Best Practices Summary

### Error Type Design
1. **Specific Errors**: Use specific error types instead of generic strings
2. **Context Information**: Include relevant context in error types
3. **User-Friendly Messages**: Provide clear, actionable error messages
4. **Hierarchical Structure**: Organize errors by category and severity

### Validation Patterns
1. **Result Types**: Use Result for all operations that can fail
2. **Pipeline Validation**: Chain validations using Result.andThen
3. **Business Rules**: Separate input validation from business rule validation
4. **Error Accumulation**: Collect multiple errors when appropriate

### Error Handling Strategies
1. **Fail-Fast**: Stop at first error for critical operations
2. **Error Collection**: Gather all errors for user feedback
3. **Graceful Degradation**: Continue with reduced functionality when possible
4. **Recovery Mechanisms**: Provide defaults and retry logic where appropriate

### Development Practices
1. **Comprehensive Testing**: Test both success and error cases
2. **Error Documentation**: Document all possible error conditions
3. **Logging Strategy**: Implement structured error logging
4. **Debug Support**: Include debug information in development builds