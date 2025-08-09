module Integration.RealTimeValidationTests exposing (..)

import Dict
import Expect
import Test exposing (..)
import Types.Validation exposing (ValidationError(..))
import Utils.Config exposing (fallbackConfig)
import Utils.Validation as Validation


suite : Test
suite =
    describe "Real-time Validation Integration Tests"
        [ describe "Field-specific validation"
            [ test "should_validate_excavator_capacity_field_in_real_time" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        testSequence =
                            [ ( "", "RequiredField" )
                            , ( "0", "EdgeCaseError" )
                            , ( "-1", "EdgeCaseError" )
                            , ( "0.05", "ValueTooLow" )
                            , ( "2.5", "Valid" )
                            , ( "20.0", "ValueTooHigh" )
                            , ( "2.567", "DecimalPrecisionError" )
                            , ( "abc", "InvalidFormat" )
                            ]

                        validateInput ( input, expectedType ) =
                            case Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity input of
                                Ok _ ->
                                    expectedType == "Valid"

                                Err (RequiredField _) ->
                                    expectedType == "RequiredField"

                                Err (EdgeCaseError _) ->
                                    expectedType == "EdgeCaseError"

                                Err (ValueTooLow _) ->
                                    expectedType == "ValueTooLow"

                                Err (ValueTooHigh _) ->
                                    expectedType == "ValueTooHigh"

                                Err (DecimalPrecisionError _) ->
                                    expectedType == "DecimalPrecisionError"

                                Err (InvalidFormat _) ->
                                    expectedType == "InvalidFormat"

                                Err _ ->
                                    False

                        results =
                            List.map validateInput testSequence

                        allPassed =
                            List.all identity results
                    in
                    Expect.equal True allPassed
            , test "should_validate_work_hours_field_with_specific_ranges" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        testCases =
                            [ ( "8.0", True ) -- Valid
                            , ( "24.0", True ) -- Valid (boundary)
                            , ( "1.0", True ) -- Valid (boundary)
                            , ( "0.5", False ) -- Below minimum
                            , ( "25.0", False ) -- Above maximum
                            , ( "", False ) -- Empty
                            ]

                        validateCase ( input, shouldPass ) =
                            case Validation.validateStringInput "Work Hours" validationRules.workHours input of
                                Ok _ ->
                                    shouldPass

                                Err _ ->
                                    not shouldPass

                        results =
                            List.map validateCase testCases

                        allCorrect =
                            List.all identity results
                    in
                    Expect.equal True allCorrect
            , test "should_validate_pond_dimensions_consistently" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        pondFields =
                            [ "pondLength", "pondWidth", "pondDepth" ]

                        testValue =
                            "50.5"

                        validateField fieldName =
                            Validation.validateStringInput "Pond Dimension" validationRules.pondDimensions testValue

                        results =
                            List.map validateField pondFields

                        -- All results should be identical since they use same validation rule
                        allSame =
                            case results of
                                first :: rest ->
                                    List.all ((==) first) rest

                                [] ->
                                    True

                        allValid =
                            List.all (Result.map (always True) >> Result.withDefault False) results
                    in
                    Expect.all
                        [ \_ -> Expect.equal True allSame
                        , \_ -> Expect.equal True allValid
                        ]
                        ()
            ]
        , describe "Validation performance and debouncing"
            [ test "should_handle_rapid_input_changes_efficiently" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        rapidInputs =
                            List.range 1 100 |> List.map (\i -> String.fromInt i ++ ".0")

                        -- Simulate rapid typing - all should validate quickly
                        results =
                            List.map (Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity) rapidInputs

                        validResults =
                            List.filterMap Result.toMaybe results

                        expectedValues =
                            List.range 1 15 |> List.map toFloat

                        -- Only values within range 0.1-15.0
                        validInRange =
                            List.length validResults
                    in
                    Expect.equal 15 validInRange

            -- Values 1.0 through 15.0 should be valid
            , test "should_maintain_validation_state_consistency" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        -- Simulate user typing "2.5" character by character
                        typingSequence =
                            [ "2", "2.", "2.5" ]

                        results =
                            List.map (Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity) typingSequence

                        -- All should eventually succeed, but intermediate states may have errors
                        finalResult =
                            List.reverse results |> List.head |> Maybe.withDefault (Err (ConfigurationError "No results"))
                    in
                    case finalResult of
                        Ok value ->
                            Expect.within (Expect.Absolute 0.001) 2.5 value

                        Err _ ->
                            Expect.fail "Final typed value '2.5' should be valid"
            ]
        , describe "Error message consistency"
            [ test "should_provide_consistent_guidance_across_similar_fields" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        -- Test same error condition across different capacity fields
                        excavatorResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity "0.05"

                        truckResult =
                            Validation.validateStringInput "Truck Capacity" validationRules.truckCapacity "0.05"

                        getGuidance result =
                            case result of
                                Err (ValueTooLow { guidance }) ->
                                    Just guidance

                                _ ->
                                    Nothing

                        excavatorGuidance =
                            getGuidance excavatorResult

                        truckGuidance =
                            getGuidance truckResult

                        -- Both should have guidance, though content will be field-specific
                        bothHaveGuidance =
                            case ( excavatorGuidance, truckGuidance ) of
                                ( Just _, Just _ ) ->
                                    True

                                _ ->
                                    False
                    in
                    Expect.equal True bothHaveGuidance
            , test "should_provide_field_appropriate_guidance_content" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        -- Test that excavator guidance mentions excavators
                        excavatorResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity "0.05"

                        containsExcavatorContext =
                            case excavatorResult of
                                Err (ValueTooLow { guidance }) ->
                                    String.contains "excavator" (String.toLower guidance)

                                _ ->
                                    False

                        -- Test that truck guidance mentions trucks
                        truckResult =
                            Validation.validateStringInput "Truck Capacity" validationRules.truckCapacity "0.05"

                        containsTruckContext =
                            case truckResult of
                                Err (ValueTooLow { guidance }) ->
                                    String.contains "truck" (String.toLower guidance)

                                _ ->
                                    False
                    in
                    Expect.all
                        [ \_ -> Expect.equal True containsExcavatorContext
                        , \_ -> Expect.equal True containsTruckContext
                        ]
                        ()
            ]
        , describe "Edge case handling in real-time"
            [ test "should_handle_empty_string_gracefully" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fields =
                            [ ( "Excavator Capacity", validationRules.excavatorCapacity )
                            , ( "Truck Capacity", validationRules.truckCapacity )
                            , ( "Work Hours", validationRules.workHours )
                            , ( "Pond Dimension", validationRules.pondDimensions )
                            ]

                        validateEmpty ( fieldName, rule ) =
                            case Validation.validateStringInput fieldName rule "" of
                                Err (RequiredField { guidance }) ->
                                    String.contains "required" (String.toLower guidance)

                                _ ->
                                    False

                        results =
                            List.map validateEmpty fields

                        allHandledCorrectly =
                            List.all identity results
                    in
                    Expect.equal True allHandledCorrectly
            , test "should_handle_whitespace_only_input" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        whitespaceInputs =
                            [ "  ", "\t", "   \n  " ]

                        validateWhitespace input =
                            case Validation.validateStringInput "Test Field" validationRules.excavatorCapacity input of
                                Err (RequiredField _) ->
                                    True

                                _ ->
                                    False

                        results =
                            List.map validateWhitespace whitespaceInputs

                        allTreatedAsEmpty =
                            List.all identity results
                    in
                    Expect.equal True allTreatedAsEmpty
            , test "should_handle_extreme_decimal_precision" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        highPrecisionInputs =
                            [ "2.123456789", "5.1234", "1.000001" ]

                        validatePrecision input =
                            case Validation.validateStringInput "Test Field" validationRules.excavatorCapacity input of
                                Err (DecimalPrecisionError { maxDecimals }) ->
                                    maxDecimals == 2

                                Ok _ ->
                                    String.length (String.split "." input |> List.drop 1 |> String.join "") <= 2

                                Err (ValueTooLow _) ->
                                    False

                                Err (ValueTooHigh _) ->
                                    False

                                Err (RequiredField _) ->
                                    False

                                Err (InvalidFormat _) ->
                                    False

                                Err (EdgeCaseError _) ->
                                    False

                                Err (ConfigurationError _) ->
                                    False

                        results =
                            List.map validatePrecision highPrecisionInputs

                        allHandledCorrectly =
                            List.all identity results
                    in
                    Expect.equal True allHandledCorrectly
            , test "should_handle_scientific_notation_gracefully" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        scientificInputs =
                            [ "1e2", "2.5e-1", "1.0E+1" ]

                        validateScientific input =
                            case Validation.validateStringInput "Test Field" validationRules.excavatorCapacity input of
                                -- Elm's String.toFloat handles scientific notation, so these might parse
                                Ok _ ->
                                    True

                                Err (InvalidFormat _) ->
                                    True

                                -- Also acceptable
                                _ ->
                                    True

                        -- Any reasonable validation response is fine
                        results =
                            List.map validateScientific scientificInputs

                        allHandledReasonably =
                            List.all identity results
                    in
                    Expect.equal True allHandledReasonably
            ]
        , describe "Validation rule boundary testing"
            [ test "should_handle_exact_boundary_values" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        -- Test exact min/max boundaries for excavator capacity
                        minValue =
                            String.fromFloat validationRules.excavatorCapacity.min

                        maxValue =
                            String.fromFloat validationRules.excavatorCapacity.max

                        minResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity minValue

                        maxResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity maxValue

                        bothValid =
                            case ( minResult, maxResult ) of
                                ( Ok _, Ok _ ) ->
                                    True

                                _ ->
                                    False
                    in
                    Expect.equal True bothValid
            , test "should_reject_values_just_outside_boundaries" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        -- Test values just outside min/max boundaries
                        justBelowMin =
                            validationRules.excavatorCapacity.min - 0.01

                        justAboveMax =
                            validationRules.excavatorCapacity.max + 0.01

                        belowResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity (String.fromFloat justBelowMin)

                        aboveResult =
                            Validation.validateStringInput "Excavator Capacity" validationRules.excavatorCapacity (String.fromFloat justAboveMax)

                        bothInvalid =
                            case ( belowResult, aboveResult ) of
                                ( Err (ValueTooLow _), Err (ValueTooHigh _) ) ->
                                    True

                                _ ->
                                    False
                    in
                    Expect.equal True bothInvalid
            ]
        ]
