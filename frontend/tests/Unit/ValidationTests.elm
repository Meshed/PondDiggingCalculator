module Unit.ValidationTests exposing (..)

import Expect
import Test exposing (..)
import Types.DeviceType exposing (DeviceType(..))
import Types.Validation exposing (ValidationError(..))
import Utils.Validation as Validation



-- Test data


validationRules : { min : Float, max : Float }
validationRules =
    { min = 1.0, max = 10.0 }


testProjectInputs : Validation.ProjectInputs
testProjectInputs =
    { excavatorCapacity = 2.5
    , excavatorCycleTime = 2.0
    , truckCapacity = 12.0
    , truckRoundTripTime = 15.0
    , workHoursPerDay = 8.0
    , pondLength = 50.0
    , pondWidth = 30.0
    , pondDepth = 6.0
    }


suite : Test
suite =
    describe "Validation Tests"
        [ describe "validateExcavatorCapacity"
            [ test "should_accept_valid_capacity" <|
                \_ ->
                    Validation.validateExcavatorCapacity validationRules 5.0
                        |> Expect.equal (Ok 5.0)
            , test "should_reject_capacity_below_minimum" <|
                \_ ->
                    case Validation.validateExcavatorCapacity validationRules 0.5 of
                        Err (ValueTooLow actual minimum) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) 0.5 actual
                                , \_ -> Expect.within (Expect.Absolute 0.001) 1.0 minimum
                                ]
                                ()

                        _ ->
                            Expect.fail "Should return ValueTooLow error"
            , test "should_reject_capacity_above_maximum" <|
                \_ ->
                    case Validation.validateExcavatorCapacity validationRules 15.0 of
                        Err (ValueTooHigh actual maximum) ->
                            Expect.all
                                [ \_ -> Expect.equal 15.0 actual
                                , \_ -> Expect.equal 10.0 maximum
                                ]
                                ()

                        _ ->
                            Expect.fail "Should return ValueTooHigh error"
            , test "should_reject_zero_capacity" <|
                \_ ->
                    case Validation.validateExcavatorCapacity validationRules 0.0 of
                        Err (RequiredField fieldName) ->
                            Expect.equal "Excavator Capacity" fieldName

                        _ ->
                            Expect.fail "Should return RequiredField error"
            , test "should_reject_negative_capacity" <|
                \_ ->
                    case Validation.validateExcavatorCapacity validationRules -1.0 of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return RequiredField error for negative values"
            ]
        , describe "validateCycleTime"
            [ test "should_accept_valid_cycle_time" <|
                \_ ->
                    Validation.validateCycleTime validationRules 3.0
                        |> Expect.equal (Ok 3.0)
            , test "should_reject_cycle_time_below_minimum" <|
                \_ ->
                    case Validation.validateCycleTime validationRules 0.3 of
                        Err (ValueTooLow _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return ValueTooLow error"
            , test "should_reject_cycle_time_above_maximum" <|
                \_ ->
                    case Validation.validateCycleTime validationRules 15.0 of
                        Err (ValueTooHigh _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return ValueTooHigh error"
            ]
        , describe "validateTruckCapacity"
            [ test "should_accept_valid_truck_capacity" <|
                \_ ->
                    Validation.validateTruckCapacity validationRules 8.0
                        |> Expect.equal (Ok 8.0)
            , test "should_reject_invalid_truck_capacity" <|
                \_ ->
                    case Validation.validateTruckCapacity validationRules 20.0 of
                        Err (ValueTooHigh _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return validation error"
            ]
        , describe "validateRoundTripTime"
            [ test "should_accept_valid_round_trip_time" <|
                \_ ->
                    Validation.validateRoundTripTime validationRules 5.0
                        |> Expect.equal (Ok 5.0)
            , test "should_reject_invalid_round_trip_time" <|
                \_ ->
                    case Validation.validateRoundTripTime validationRules 0.1 of
                        Err (ValueTooLow _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return validation error"
            ]
        , describe "validateWorkHours"
            [ test "should_accept_valid_work_hours" <|
                \_ ->
                    Validation.validateWorkHours validationRules 8.0
                        |> Expect.equal (Ok 8.0)
            , test "should_reject_zero_work_hours" <|
                \_ ->
                    case Validation.validateWorkHours validationRules 0.0 of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return RequiredField error"
            , test "should_reject_excessive_work_hours" <|
                \_ ->
                    case Validation.validateWorkHours validationRules 25.0 of
                        Err (ValueTooHigh _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return ValueTooHigh error"
            ]
        , describe "validatePondDimensions"
            [ test "should_accept_valid_pond_dimension" <|
                \_ ->
                    let
                        pondRules =
                            { min = 1.0, max = 1000.0 }

                        -- More appropriate for pond dimensions
                    in
                    Validation.validatePondDimensions pondRules 50.0
                        |> Expect.equal (Ok 50.0)
            , test "should_reject_zero_pond_dimension" <|
                \_ ->
                    let
                        pondRules =
                            { min = 1.0, max = 1000.0 }
                    in
                    case Validation.validatePondDimensions pondRules 0.0 of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return RequiredField error"
            , test "should_reject_negative_pond_dimension" <|
                \_ ->
                    let
                        pondRules =
                            { min = 1.0, max = 1000.0 }
                    in
                    case Validation.validatePondDimensions pondRules -5.0 of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should return RequiredField error"
            ]
        , describe "validateAllInputs"
            [ test "should_accept_all_valid_inputs" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }
                    in
                    case Validation.validateAllInputs allRules testProjectInputs of
                        Ok validInputs ->
                            Expect.equal testProjectInputs validInputs

                        Err error ->
                            Expect.fail "Validation should pass with valid inputs, but got error"
            , test "should_reject_inputs_with_invalid_excavator_capacity" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        invalidInputs =
                            { testProjectInputs | excavatorCapacity = 0.0 }
                    in
                    case Validation.validateAllInputs allRules invalidInputs of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should reject inputs with invalid excavator capacity"
            , test "should_reject_inputs_with_out_of_range_truck_capacity" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        invalidInputs =
                            { testProjectInputs | truckCapacity = 50.0 }
                    in
                    case Validation.validateAllInputs allRules invalidInputs of
                        Err (ValueTooHigh _ _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should reject inputs with out-of-range truck capacity"
            , test "should_reject_inputs_with_invalid_pond_dimensions" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        invalidInputs =
                            { testProjectInputs | pondDepth = -1.0 }
                    in
                    case Validation.validateAllInputs allRules invalidInputs of
                        Err (RequiredField _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should reject inputs with invalid pond dimensions"
            ]
        , describe "Integration Tests"
            [ test "should_validate_realistic_construction_scenario" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        realisticInputs =
                            { excavatorCapacity = 3.5 -- Mid-size excavator
                            , excavatorCycleTime = 2.5 -- Reasonable cycle time
                            , truckCapacity = 16.0 -- Standard dump truck
                            , truckRoundTripTime = 20.0 -- Typical site distance
                            , workHoursPerDay = 9.0 -- Extended work day
                            , pondLength = 75.0 -- Large residential pond
                            , pondWidth = 45.0
                            , pondDepth = 8.0
                            }
                    in
                    case Validation.validateAllInputs allRules realisticInputs of
                        Ok validInputs ->
                            Expect.equal realisticInputs validInputs

                        Err _ ->
                            Expect.fail "Realistic construction scenario should pass validation"
            ]
        , describe "Cross-Device Validation Consistency"
            [ test "should_apply_bucket_capacity_validation_identically_across_devices" <|
                \_ ->
                    let
                        capacityRules =
                            { min = 0.1, max = 15.0 }

                        testCapacity =
                            0.05

                        -- Below minimum
                        -- Validation functions are pure and device-agnostic
                        mobileResult =
                            Validation.validateExcavatorCapacity capacityRules testCapacity

                        tabletResult =
                            Validation.validateExcavatorCapacity capacityRules testCapacity

                        desktopResult =
                            Validation.validateExcavatorCapacity capacityRules testCapacity
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Err (ValueTooLow actualMobile minMobile), Err (ValueTooLow actualTablet minTablet), Err (ValueTooLow actualDesktop minDesktop) ) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) actualMobile actualTablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) actualTablet actualDesktop
                                , \_ -> Expect.within (Expect.Absolute 0.001) minMobile minTablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) minTablet minDesktop
                                ]
                                ()

                        _ ->
                            Expect.fail "All devices should return identical ValueTooLow errors"
            , test "should_apply_truck_capacity_validation_identically_across_devices" <|
                \_ ->
                    let
                        truckRules =
                            { min = 1.0, max = 50.0 }

                        testCapacity =
                            75.0

                        -- Above maximum
                        mobileResult =
                            Validation.validateTruckCapacity truckRules testCapacity

                        tabletResult =
                            Validation.validateTruckCapacity truckRules testCapacity

                        desktopResult =
                            Validation.validateTruckCapacity truckRules testCapacity
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Err (ValueTooHigh actualMobile maxMobile), Err (ValueTooHigh actualTablet maxTablet), Err (ValueTooHigh actualDesktop maxDesktop) ) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) actualMobile actualTablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) actualTablet actualDesktop
                                , \_ -> Expect.within (Expect.Absolute 0.001) maxMobile maxTablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) maxTablet maxDesktop
                                ]
                                ()

                        _ ->
                            Expect.fail "All devices should return identical ValueTooHigh errors"
            , test "should_apply_pond_dimension_validation_identically_across_devices" <|
                \_ ->
                    let
                        pondRules =
                            { min = 1.0, max = 1000.0 }

                        testDimension =
                            0.0

                        -- Invalid (zero)
                        mobileResult =
                            Validation.validatePondDimensions pondRules testDimension

                        tabletResult =
                            Validation.validatePondDimensions pondRules testDimension

                        desktopResult =
                            Validation.validatePondDimensions pondRules testDimension
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Err (RequiredField fieldMobile), Err (RequiredField fieldTablet), Err (RequiredField fieldDesktop) ) ->
                            Expect.all
                                [ \_ -> Expect.equal fieldMobile fieldTablet
                                , \_ -> Expect.equal fieldTablet fieldDesktop
                                ]
                                ()

                        _ ->
                            Expect.fail "All devices should return identical RequiredField errors"
            , test "should_display_error_messages_consistently_across_devices" <|
                \_ ->
                    let
                        capacityRules =
                            { min = 2.0, max = 10.0 }

                        invalidCapacity =
                            15.0

                        -- Same validation error should produce same message regardless of device
                        error =
                            case Validation.validateExcavatorCapacity capacityRules invalidCapacity of
                                Err validationError ->
                                    validationError

                                Ok _ ->
                                    ValueTooHigh 0.0 0.0

                        -- This shouldn't happen
                        -- Error message content should be identical across devices
                        mobileErrorMessage =
                            errorToString error

                        tabletErrorMessage =
                            errorToString error

                        desktopErrorMessage =
                            errorToString error
                    in
                    Expect.all
                        [ \_ -> Expect.equal mobileErrorMessage tabletErrorMessage
                        , \_ -> Expect.equal tabletErrorMessage desktopErrorMessage
                        , \_ -> String.contains "15" mobileErrorMessage |> Expect.equal True
                        , \_ -> String.contains "10" mobileErrorMessage |> Expect.equal True
                        ]
                        ()
            , test "should_validate_complete_project_inputs_identically_across_devices" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        validInputs =
                            testProjectInputs

                        -- Complete validation should be identical across devices
                        mobileResult =
                            Validation.validateAllInputs allRules validInputs

                        tabletResult =
                            Validation.validateAllInputs allRules validInputs

                        desktopResult =
                            Validation.validateAllInputs allRules validInputs
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Ok mobileValid, Ok tabletValid, Ok desktopValid ) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) mobileValid.excavatorCapacity tabletValid.excavatorCapacity
                                , \_ -> Expect.within (Expect.Absolute 0.001) tabletValid.excavatorCapacity desktopValid.excavatorCapacity
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobileValid.truckCapacity tabletValid.truckCapacity
                                , \_ -> Expect.within (Expect.Absolute 0.001) tabletValid.truckCapacity desktopValid.truckCapacity
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobileValid.workHoursPerDay tabletValid.workHoursPerDay
                                , \_ -> Expect.within (Expect.Absolute 0.001) tabletValid.workHoursPerDay desktopValid.workHoursPerDay
                                ]
                                ()

                        _ ->
                            Expect.fail "Valid inputs should pass validation identically across all devices"
            , test "should_handle_validation_input_boundaries_identically" <|
                \_ ->
                    let
                        rules =
                            { min = 1.0, max = 10.0 }

                        -- Test exact boundary values
                        minimumValue =
                            1.0

                        maximumValue =
                            10.0

                        mobileMinResult =
                            Validation.validateExcavatorCapacity rules minimumValue

                        tabletMinResult =
                            Validation.validateExcavatorCapacity rules minimumValue

                        desktopMinResult =
                            Validation.validateExcavatorCapacity rules minimumValue

                        mobileMaxResult =
                            Validation.validateExcavatorCapacity rules maximumValue

                        tabletMaxResult =
                            Validation.validateExcavatorCapacity rules maximumValue

                        desktopMaxResult =
                            Validation.validateExcavatorCapacity rules maximumValue
                    in
                    -- Test minimum values
                    case ( mobileMinResult, tabletMinResult, desktopMinResult ) of
                        ( Ok minMobile, Ok minTablet, Ok minDesktop ) ->
                            -- Test maximum values
                            case ( mobileMaxResult, tabletMaxResult, desktopMaxResult ) of
                                ( Ok maxMobile, Ok maxTablet, Ok maxDesktop ) ->
                                    Expect.all
                                        [ \_ -> Expect.within (Expect.Absolute 0.001) minMobile minTablet
                                        , \_ -> Expect.within (Expect.Absolute 0.001) minTablet minDesktop
                                        , \_ -> Expect.within (Expect.Absolute 0.001) maxMobile maxTablet
                                        , \_ -> Expect.within (Expect.Absolute 0.001) maxTablet maxDesktop
                                        , \_ -> Expect.within (Expect.Absolute 0.001) 1.0 minMobile
                                        , \_ -> Expect.within (Expect.Absolute 0.001) 10.0 maxMobile
                                        ]
                                        ()

                                _ ->
                                    Expect.fail "Maximum value validation should succeed across all devices"

                        _ ->
                            Expect.fail "Minimum value validation should succeed across all devices"
            , test "should_handle_invalid_complete_inputs_identically_across_devices" <|
                \_ ->
                    let
                        allRules =
                            { excavatorCapacity = { min = 0.5, max = 15.0 }
                            , cycleTime = { min = 0.5, max = 10.0 }
                            , truckCapacity = { min = 5.0, max = 30.0 }
                            , roundTripTime = { min = 5.0, max = 60.0 }
                            , workHours = { min = 1.0, max = 16.0 }
                            , pondDimensions = { min = 1.0, max = 1000.0 }
                            }

                        invalidInputs =
                            { testProjectInputs | excavatorCapacity = -1.0 }

                        -- Invalid
                        mobileResult =
                            Validation.validateAllInputs allRules invalidInputs

                        tabletResult =
                            Validation.validateAllInputs allRules invalidInputs

                        desktopResult =
                            Validation.validateAllInputs allRules invalidInputs
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Err mobileError, Err tabletError, Err desktopError ) ->
                            case ( mobileError, tabletError, desktopError ) of
                                ( RequiredField fieldMobile, RequiredField fieldTablet, RequiredField fieldDesktop ) ->
                                    Expect.all
                                        [ \_ -> Expect.equal fieldMobile fieldTablet
                                        , \_ -> Expect.equal fieldTablet fieldDesktop
                                        ]
                                        ()

                                _ ->
                                    Expect.fail "Error types should be identical across devices"

                        _ ->
                            Expect.fail "Invalid inputs should fail validation identically across all devices"
            ]
        ]



-- Helper function for error message testing


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
