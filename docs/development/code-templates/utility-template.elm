{-| [Module Name] Utilities - Pure utility functions for [domain area]

This module provides a collection of pure utility functions for [domain area],
focusing on data transformation, formatting, and helper operations with
comprehensive error handling.

## Data Transformation
@docs transform[DataType], convert[Unit], normalize[Value]

## Formatting and Display  
@docs format[OutputType], display[ComplexType], render[Summary]

## Validation and Parsing
@docs parse[InputType], validate[Format], sanitize[Input]

## Helper Functions
@docs isEmpty[Type], default[Value], clamp[Range]

## Error Types
@docs [UtilityArea]Error(..)

-}
module Utils.[UtilityArea] exposing
    ( transform[DataType]
    , convert[Unit]
    , normalize[Value]
    , format[OutputType]
    , display[ComplexType]
    , render[Summary]
    , parse[InputType]
    , validate[Format]
    , sanitize[Input]
    , isEmpty[Type]
    , default[Value]
    , clamp[Range]
    , [UtilityArea]Error(..)
    )

import Dict exposing (Dict)
import String.Extra
import Regex
import Round
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode

-- Import project types
import Types.[DomainType] exposing ([DomainType], [RelatedType])


-- TYPES


{-| Utility-specific error types with context and recovery information.
    
    Each error includes:
    - Specific error classification
    - Input value that caused the error
    - Expected format or constraints
    - Suggested recovery actions
-}
type [UtilityArea]Error
    = ParseError 
        { input : String
        , expectedFormat : String
        , position : Maybe Int
        , suggestion : String
        }
    | ConversionError 
        { fromUnit : String
        , toUnit : String
        , value : Float
        , reason : String
        }
    | ValidationError 
        { field : String
        , value : String
        , constraint : String
        , example : String
        }
    | FormatError 
        { inputType : String
        , value : String
        , targetFormat : String
        }
    | RangeError 
        { value : Float
        , minimum : Float
        , maximum : Float
        , field : String
        }


{-| Configuration for utility operations with customizable behavior. -}
type alias UtilityConfig =
    { precision : Int
    , nullHandling : NullHandlingStrategy
    , errorMode : ErrorMode
    , locale : LocaleSettings
    }


{-| Strategies for handling null/empty values. -}
type NullHandlingStrategy
    = FailOnNull  -- Return error for null values
    | UseDefault  -- Replace null with default value
    | SkipNull   -- Skip null values in collections


{-| Error handling modes for different use cases. -}
type ErrorMode
    = Strict     -- Fail on any error
    | Permissive -- Continue with warnings
    | Silent     -- Ignore errors silently


{-| Locale settings for formatting operations. -}
type alias LocaleSettings =
    { decimalSeparator : String
    , thousandsSeparator : String
    , currencySymbol : String
    , dateFormat : String
    }


-- CONSTANTS


{-| Default utility configuration for standard operations. -}
defaultConfig : UtilityConfig
defaultConfig =
    { precision = 2
    , nullHandling = UseDefault
    , errorMode = Strict
    , locale = 
        { decimalSeparator = "."
        , thousandsSeparator = ","
        , currencySymbol = "$"
        , dateFormat = "YYYY-MM-DD"
        }
    }


{-| Unit conversion factors for common measurements. -}
conversionFactors : Dict String (Dict String Float)
conversionFactors =
    Dict.fromList
        [ ("length", Dict.fromList
            [ ("feet_to_meters", 0.3048)
            , ("meters_to_feet", 3.28084)
            , ("inches_to_centimeters", 2.54)
            , ("centimeters_to_inches", 0.393701)
            ])
        , ("volume", Dict.fromList
            [ ("cubic_yards_to_cubic_meters", 0.764555)
            , ("cubic_meters_to_cubic_yards", 1.30795)
            , ("gallons_to_liters", 3.78541)
            , ("liters_to_gallons", 0.264172)
            ])
        , ("weight", Dict.fromList
            [ ("pounds_to_kilograms", 0.453592)
            , ("kilograms_to_pounds", 2.20462)
            , ("tons_to_metric_tons", 0.907185)
            , ("metric_tons_to_tons", 1.10231)
            ])
        ]


-- DATA TRANSFORMATION FUNCTIONS


{-| Transform [data type] with comprehensive error handling and validation.
    
    Applies a series of transformations to input data while maintaining
    data integrity and providing detailed error information for failures.
    
    ## Parameters
    - `config`: Configuration for transformation behavior
    - `transformer`: Transformation function to apply
    - `inputData`: Data to transform
    
    ## Returns
    - `Ok transformedData`: Transformation succeeded
    - `Err error`: Transformation failed with specific error details
    
    ## Examples
    ```elm
    transform[DataType] defaultConfig String.toUpper "hello"
    --> Ok "HELLO"
    
    transform[DataType] defaultConfig String.toFloat "invalid"
    --> Err (ParseError { input = "invalid", expectedFormat = "numeric string", ... })
    ```
-}
transform[DataType] : UtilityConfig -> (a -> Result String b) -> a -> Result [UtilityArea]Error b
transform[DataType] config transformer inputData =
    case transformer inputData of
        Ok result ->
            Ok result
            
        Err errorMessage ->
            Err (ParseError 
                { input = Debug.toString inputData
                , expectedFormat = "Valid input for transformation"
                , position = Nothing
                , suggestion = errorMessage
                })


{-| Convert between different units with validation and error handling.
    
    Supports conversions between common measurement units used in the domain,
    with automatic validation of unit compatibility and value ranges.
    
    ## Parameters
    - `fromUnit`: Source unit identifier
    - `toUnit`: Target unit identifier  
    - `value`: Numeric value to convert
    
    ## Returns
    - `Ok convertedValue`: Conversion succeeded
    - `Err error`: Conversion failed (incompatible units, invalid value, etc.)
    
    ## Supported Units
    - Length: feet, meters, inches, centimeters
    - Volume: cubic_yards, cubic_meters, gallons, liters
    - Weight: pounds, kilograms, tons, metric_tons
    
    ## Examples
    ```elm
    convert[Unit] "feet" "meters" 10.0
    --> Ok 3.048
    
    convert[Unit] "feet" "gallons" 10.0
    --> Err (ConversionError { fromUnit = "feet", toUnit = "gallons", ... })
    ```
-}
convert[Unit] : String -> String -> Float -> Result [UtilityArea]Error Float
convert[Unit] fromUnit toUnit value =
    let
        conversionKey = fromUnit ++ "_to_" ++ toUnit
        
        findConversionFactor : Dict String (Dict String Float) -> Maybe Float
        findConversionFactor factors =
            factors
                |> Dict.values
                |> List.filterMap (Dict.get conversionKey)
                |> List.head
    in
    if value < 0 then
        Err (RangeError 
            { value = value
            , minimum = 0.0
            , maximum = 1.0e12  -- Reasonable maximum
            , field = "conversion_value"
            })
    else
        case findConversionFactor conversionFactors of
            Just factor ->
                Ok (value * factor)
                
            Nothing ->
                Err (ConversionError 
                    { fromUnit = fromUnit
                    , toUnit = toUnit
                    , value = value
                    , reason = "No conversion factor available for " ++ fromUnit ++ " to " ++ toUnit
                    })


{-| Normalize [value] to standard range with configurable bounds.
    
    Transforms input values to a normalized range (typically 0-1 or 0-100)
    while preserving relative relationships and handling edge cases.
    
    ## Parameters
    - `config`: Normalization configuration
    - `minValue`: Minimum value in dataset
    - `maxValue`: Maximum value in dataset
    - `targetValue`: Value to normalize
    
    ## Returns
    Normalized value between 0 and 1, or error if inputs are invalid.
-}
normalize[Value] : UtilityConfig -> Float -> Float -> Float -> Result [UtilityArea]Error Float
normalize[Value] config minValue maxValue targetValue =
    let
        range = maxValue - minValue
    in
    if range <= 0 then
        Err (ValidationError 
            { field = "value_range"
            , value = String.fromFloat range
            , constraint = "Maximum must be greater than minimum"
            , example = "min: 0, max: 100"
            })
    else if targetValue < minValue || targetValue > maxValue then
        Err (RangeError 
            { value = targetValue
            , minimum = minValue
            , maximum = maxValue
            , field = "target_value"
            })
    else
        Ok ((targetValue - minValue) / range)


-- FORMATTING AND DISPLAY FUNCTIONS


{-| Format [output type] for display with locale-aware formatting.
    
    Provides consistent formatting for different data types with support
    for internationalization and customizable precision settings.
    
    ## Parameters
    - `config`: Formatting configuration including locale settings
    - `value`: Value to format
    
    ## Returns
    Formatted string representation suitable for display.
    
    ## Examples
    ```elm
    format[OutputType] defaultConfig 1234.56
    --> "1,234.56"
    
    format[OutputType] { defaultConfig | locale = { decimalSeparator = "," }} 1234.56
    --> "1.234,56"
    ```
-}
format[OutputType] : UtilityConfig -> Float -> String
format[OutputType] config value =
    let
        roundedValue = Round.round config.precision value
        
        addThousandsSeparators : String -> String
        addThousandsSeparators str =
            let
                (integerPart, decimalPart) = 
                    case String.split config.locale.decimalSeparator str of
                        [integer] -> (integer, "")
                        [integer, decimal] -> (integer, config.locale.decimalSeparator ++ decimal)
                        _ -> (str, "")
                
                addSeparators : String -> String
                addSeparators intStr =
                    intStr
                        |> String.reverse
                        |> String.toList
                        |> List.indexedMap (\i char -> 
                            if i > 0 && modBy 3 i == 0 then
                                [char, config.locale.thousandsSeparator]
                            else
                                [char]
                        )
                        |> List.concat
                        |> String.fromList
                        |> String.reverse
            in
            addSeparators integerPart ++ decimalPart
    in
    addThousandsSeparators roundedValue


{-| Display [complex type] in human-readable format with comprehensive details.
    
    Converts complex data structures into readable text format suitable
    for reports, logs, or user interface display.
    
    ## Parameters
    - `config`: Display configuration
    - `data`: Complex data structure to display
    
    ## Returns
    Multi-line string representation with proper formatting and indentation.
-}
display[ComplexType] : UtilityConfig -> [ComplexType] -> String
display[ComplexType] config data =
    let
        formatField : String -> String -> String
        formatField label value =
            String.padRight 20 ' ' (label ++ ":") ++ " " ++ value
            
        formatSection : String -> List String -> String
        formatSection title fields =
            title ++ "\n" ++ 
            (fields |> List.map (\field -> "  " ++ field) |> String.join "\n")
    in
    -- Implementation depends on actual complex type structure
    -- This is a placeholder showing the pattern
    formatSection "Data Summary" 
        [ formatField "Type" (getDataTypeName data)
        , formatField "Status" (getDataStatus data)
        , formatField "Last Updated" (getDataTimestamp data)
        ]


{-| Render [summary] with configurable detail level and formatting.
    
    Creates summary representations of data with different levels of detail
    based on configuration and intended use (brief, standard, detailed).
    
    ## Parameters
    - `detailLevel`: Amount of detail to include
    - `data`: Data to summarize
    
    ## Returns
    Formatted summary string appropriate for the specified detail level.
-}
render[Summary] : DetailLevel -> [SummaryData] -> String
render[Summary] detailLevel data =
    case detailLevel of
        Brief ->
            renderBriefSummary data
            
        Standard ->
            renderStandardSummary data
            
        Detailed ->
            renderDetailedSummary data


-- VALIDATION AND PARSING FUNCTIONS


{-| Parse [input type] from string with comprehensive validation.
    
    Converts string input to typed data with detailed error reporting
    for malformed inputs and helpful suggestions for correction.
    
    ## Parameters
    - `config`: Parsing configuration
    - `inputString`: String to parse
    
    ## Returns
    - `Ok parsedValue`: Parsing succeeded
    - `Err error`: Parsing failed with specific error details and suggestions
    
    ## Examples
    ```elm
    parse[InputType] defaultConfig "123.45"
    --> Ok 123.45
    
    parse[InputType] defaultConfig "not-a-number"
    --> Err (ParseError { input = "not-a-number", expectedFormat = "numeric", ... })
    ```
-}
parse[InputType] : UtilityConfig -> String -> Result [UtilityArea]Error [ParsedType]
parse[InputType] config inputString =
    let
        trimmedInput = String.trim inputString
    in
    if String.isEmpty trimmedInput then
        case config.nullHandling of
            FailOnNull ->
                Err (ValidationError 
                    { field = "input"
                    , value = inputString
                    , constraint = "Cannot be empty"
                    , example = "123.45"
                    })
                    
            UseDefault ->
                Ok (getDefaultParsedValue config)
                
            SkipNull ->
                Ok (getDefaultParsedValue config)
    else
        parseNonEmptyInput config trimmedInput


{-| Validate [format] according to specified pattern and constraints.
    
    Checks input format against predefined patterns (regex, business rules)
    and provides specific feedback about format violations.
    
    ## Parameters
    - `pattern`: Validation pattern or rule set
    - `input`: Input string to validate
    
    ## Returns
    - `Ok input`: Validation passed
    - `Err error`: Validation failed with specific format requirements
-}
validate[Format] : ValidationPattern -> String -> Result [UtilityArea]Error String
validate[Format] pattern input =
    case pattern of
        EmailPattern ->
            validateEmail input
            
        PhonePattern ->
            validatePhone input
            
        CustomPattern regex ->
            validateCustomPattern regex input


{-| Sanitize [input] by removing potentially harmful or invalid characters.
    
    Cleans input data by removing or escaping characters that could cause
    issues in processing, storage, or display contexts.
    
    ## Parameters
    - `sanitizationRules`: Rules for cleaning input
    - `input`: Input string to sanitize
    
    ## Returns
    Sanitized string safe for further processing.
-}
sanitize[Input] : SanitizationRules -> String -> String
sanitize[Input] rules input =
    input
        |> removeControlCharacters
        |> escapeDangerousCharacters rules
        |> trimWhitespace
        |> limitLength rules.maxLength


-- HELPER FUNCTIONS


{-| Check if [type] is empty or contains no meaningful data.
    
    ## Parameters
    - `value`: Value to check for emptiness
    
    ## Returns
    True if value is considered empty according to domain rules.
-}
isEmpty[Type] : [Type] -> Bool
isEmpty[Type] value =
    -- Implementation depends on specific type
    -- Examples for common types:
    case Debug.toString value of
        "" -> True
        "[]" -> True
        "{}" -> True  
        "Nothing" -> True
        _ -> False


{-| Get default [value] based on configuration and context.
    
    ## Parameters
    - `config`: Configuration containing default value settings
    
    ## Returns
    Appropriate default value for the given context.
-}
default[Value] : UtilityConfig -> [ValueType]
default[Value] config =
    -- Implementation depends on specific value type and business rules
    -- This is a placeholder for actual default value logic
    Debug.todo "Implement default value generation"


{-| Clamp [range] to ensure value stays within specified bounds.
    
    ## Parameters
    - `minimum`: Lower bound (inclusive)
    - `maximum`: Upper bound (inclusive)
    - `value`: Value to clamp
    
    ## Returns
    Value constrained to the specified range.
    
    ## Examples
    ```elm
    clamp[Range] 0 100 150
    --> 100
    
    clamp[Range] 0 100 -10
    --> 0
    
    clamp[Range] 0 100 50
    --> 50
    ```
-}
clamp[Range] : Float -> Float -> Float -> Float
clamp[Range] minimum maximum value =
    if value < minimum then
        minimum
    else if value > maximum then
        maximum
    else
        value


-- PRIVATE HELPER FUNCTIONS


{-| Parse non-empty input string with error handling. -}
parseNonEmptyInput : UtilityConfig -> String -> Result [UtilityArea]Error [ParsedType]
parseNonEmptyInput config input =
    -- Implementation depends on specific parsing requirements
    -- This is a placeholder for actual parsing logic
    case String.toFloat input of
        Just value ->
            Ok (createParsedValue value)
            
        Nothing ->
            Err (ParseError 
                { input = input
                , expectedFormat = "Valid number"
                , position = Nothing
                , suggestion = "Enter a valid decimal number like 123.45"
                })


{-| Get default parsed value based on configuration. -}
getDefaultParsedValue : UtilityConfig -> [ParsedType]
getDefaultParsedValue config =
    -- Placeholder implementation
    createParsedValue 0.0


{-| Create parsed value from numeric input. -}
createParsedValue : Float -> [ParsedType]
createParsedValue value =
    -- Placeholder implementation - would create actual parsed type
    Debug.todo "Implement parsed value creation"


{-| Validate email format using regex pattern. -}
validateEmail : String -> Result [UtilityArea]Error String
validateEmail email =
    let
        emailRegex = 
            Maybe.withDefault Regex.never <|
                Regex.fromString "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    in
    if Regex.contains emailRegex email then
        Ok email
    else
        Err (ValidationError 
            { field = "email"
            , value = email
            , constraint = "Valid email format"
            , example = "user@example.com"
            })


{-| Validate phone number format. -}
validatePhone : String -> Result [UtilityArea]Error String
validatePhone phone =
    let
        phoneRegex = 
            Maybe.withDefault Regex.never <|
                Regex.fromString "^\\+?[1-9]\\d{1,14}$"
    in
    if Regex.contains phoneRegex phone then
        Ok phone  
    else
        Err (ValidationError 
            { field = "phone"
            , value = phone
            , constraint = "Valid phone number format"
            , example = "+1234567890"
            })


{-| Validate input against custom regex pattern. -}
validateCustomPattern : Regex.Regex -> String -> Result [UtilityArea]Error String
validateCustomPattern regex input =
    if Regex.contains regex input then
        Ok input
    else
        Err (ValidationError 
            { field = "custom_pattern"
            , value = input
            , constraint = "Must match required pattern"
            , example = "See documentation for valid format"
            })


{-| Remove control characters from input string. -}
removeControlCharacters : String -> String
removeControlCharacters input =
    input
        |> String.filter (\char -> 
            let code = Char.toCode char
            in code >= 32 && code <= 126  -- Printable ASCII range
        )


{-| Escape dangerous characters according to sanitization rules. -}
escapeDangerousCharacters : SanitizationRules -> String -> String
escapeDangerousCharacters rules input =
    -- Implementation depends on specific sanitization requirements
    input
        |> String.replace "<" "&lt;"
        |> String.replace ">" "&gt;"
        |> String.replace "&" "&amp;"
        |> String.replace "\"" "&quot;"
        |> String.replace "'" "&#x27;"


{-| Trim whitespace from input string. -}
trimWhitespace : String -> String
trimWhitespace input =
    String.trim input


{-| Limit string length according to rules. -}
limitLength : Int -> String -> String
limitLength maxLength input =
    if String.length input > maxLength then
        String.left (maxLength - 3) input ++ "..."
    else
        input


{-| Get data type name for display purposes. -}
getDataTypeName : [ComplexType] -> String
getDataTypeName data =
    -- Placeholder implementation
    "ComplexType"


{-| Get data status for display purposes. -}
getDataStatus : [ComplexType] -> String
getDataStatus data =
    -- Placeholder implementation
    "Active"


{-| Get data timestamp for display purposes. -}
getDataTimestamp : [ComplexType] -> String
getDataTimestamp data =
    -- Placeholder implementation
    "2025-01-01T00:00:00Z"


{-| Render brief summary of data. -}
renderBriefSummary : [SummaryData] -> String
renderBriefSummary data =
    -- Placeholder implementation
    "Brief summary"


{-| Render standard summary of data. -}
renderStandardSummary : [SummaryData] -> String
renderStandardSummary data =
    -- Placeholder implementation
    "Standard summary"


{-| Render detailed summary of data. -}
renderDetailedSummary : [SummaryData] -> String
renderDetailedSummary data =
    -- Placeholder implementation
    "Detailed summary"


-- PLACEHOLDER TYPES
-- These would be defined based on actual domain requirements

type alias [ParsedType] = Float
type alias [ComplexType] = String
type alias [SummaryData] = String
type alias [ValueType] = Float

type DetailLevel = Brief | Standard | Detailed

type ValidationPattern 
    = EmailPattern 
    | PhonePattern 
    | CustomPattern Regex.Regex

type alias SanitizationRules =
    { maxLength : Int
    , allowedCharacters : List Char
    , escapeHtml : Bool
    }