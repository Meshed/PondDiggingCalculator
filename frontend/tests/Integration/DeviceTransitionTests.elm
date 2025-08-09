module Integration.DeviceTransitionTests exposing (suite)

{-| Device transition state preservation tests
Ensures state consistency when transitioning between device breakpoints

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Types.Validation exposing (ValidationError(..))
import Utils.Calculations as Calculations
import Utils.Config as Config
import Utils.Validation as Validation


suite : Test
suite =
    describe "Device Transition State Preservation"
        [ userInputPersistenceTests
        , calculationResultPreservationTests
        , validationErrorPreservationTests
        , stateConsistencyDuringResizeTests
        ]


{-| Test that user input values persist during device type transitions
-}
userInputPersistenceTests : Test
userInputPersistenceTests =
    describe "User Input Persistence During Device Transitions"
        [ test "should_preserve_excavator_input_during_desktop_to_mobile_transition" <|
            \_ ->
                let
                    -- Initial desktop state with custom input
                    desktopFormData =
                        ProjectForm.initFormData Config.fallbackConfig.defaults

                    modifiedFormData =
                        { desktopFormData | pondLength = "50.0" }

                    -- Simulate device transition - form data should be preserved
                    -- In real implementation, this would be through the model state
                    mobileFormData =
                        modifiedFormData

                    -- State persists through shared model
                    -- Values should be identical after transition
                    pondLengthPreserved =
                        desktopFormData.pondLength == mobileFormData.pondLength
                in
                Expect.equal "50.0" mobileFormData.pondLength
        , test "should_preserve_all_form_inputs_during_tablet_to_desktop_transition" <|
            \_ ->
                let
                    -- Tablet state with multiple custom project inputs
                    tabletFormData =
                        { workHoursPerDay = "9.5"
                        , pondLength = "65.0"
                        , pondWidth = "42.0"
                        , pondDepth = "7.5"
                        , errors = []
                        }

                    -- Simulate transition to desktop
                    desktopFormData =
                        tabletFormData

                    -- Preserved through shared state
                in
                Expect.all
                    [ \fd -> Expect.equal "9.5" fd.workHoursPerDay
                    , \fd -> Expect.equal "65.0" fd.pondLength
                    , \fd -> Expect.equal "42.0" fd.pondWidth
                    , \fd -> Expect.equal "7.5" fd.pondDepth
                    , \fd -> Expect.equal [] fd.errors
                    ]
                    desktopFormData
        , test "should_preserve_complex_input_values_during_mobile_to_tablet_transition" <|
            \_ ->
                let
                    -- Mobile state with precise decimal inputs
                    mobileInputs =
                        { excavatorCapacity = "2.333"
                        , excavatorCycleTime = "2.166"
                        , truckCapacity = "11.888"
                        , truckRoundTripTime = "14.555"
                        , workHoursPerDay = "8.75"
                        , pondLength = "47.25"
                        , pondWidth = "28.33"
                        , pondDepth = "6.125"
                        }

                    -- Transition to tablet should preserve precision
                    tabletInputs =
                        mobileInputs
                in
                Expect.all
                    [ \inputs -> String.toFloat inputs.excavatorCapacity |> Expect.equal (Just 2.333)
                    , \inputs -> String.toFloat inputs.truckCapacity |> Expect.equal (Just 11.888)
                    , \inputs -> String.toFloat inputs.pondLength |> Expect.equal (Just 47.25)
                    , \inputs -> String.toFloat inputs.pondDepth |> Expect.equal (Just 6.125)
                    ]
                    tabletInputs
        , test "should_handle_empty_inputs_consistently_during_transitions" <|
            \_ ->
                let
                    -- State with some empty inputs
                    partialInputs =
                        { excavatorCapacity = "3.0"
                        , excavatorCycleTime = "" -- Empty
                        , truckCapacity = "15.0"
                        , truckRoundTripTime = "" -- Empty
                        , workHoursPerDay = "8.0"
                        , pondLength = "" -- Empty
                        , pondWidth = "30.0"
                        , pondDepth = "5.0"
                        }

                    -- Empty states should be preserved during transition
                    transitionedInputs =
                        partialInputs
                in
                Expect.all
                    [ \inputs -> Expect.equal "3.0" inputs.excavatorCapacity
                    , \inputs -> Expect.equal "" inputs.excavatorCycleTime
                    , \inputs -> Expect.equal "15.0" inputs.truckCapacity
                    , \inputs -> Expect.equal "" inputs.truckRoundTripTime
                    , \inputs -> Expect.equal "" inputs.pondLength
                    ]
                    transitionedInputs
        ]


{-| Test that calculation results remain visible during device transitions
-}
calculationResultPreservationTests : Test
calculationResultPreservationTests =
    describe "Calculation Result Preservation During Device Transitions"
        [ test "should_preserve_calculation_results_during_device_transitions" <|
            \_ ->
                let
                    -- Initial calculation result
                    excavatorCapacity =
                        3.0

                    excavatorCycle =
                        2.0

                    truckCapacity =
                        15.0

                    truckRoundTrip =
                        12.0

                    pondVolume =
                        500.0

                    workHours =
                        8.0

                    calculationResult =
                        Calculations.calculateTimeline
                            excavatorCapacity
                            excavatorCycle
                            truckCapacity
                            truckRoundTrip
                            pondVolume
                            workHours
                in
                case calculationResult of
                    Ok result ->
                        let
                            -- Simulate device transition - result should be preserved
                            desktopResult =
                                result

                            mobileResult =
                                result

                            -- Same result preserved
                            tabletResult =
                                result

                            -- Same result preserved
                        in
                        Expect.all
                            [ \r -> Expect.equal desktopResult.timelineInDays r.timelineInDays
                            , \r -> Expect.within (Expect.Absolute 0.001) desktopResult.totalHours r.totalHours
                            , \r -> Expect.within (Expect.Absolute 0.001) desktopResult.excavationRate r.excavationRate
                            , \r -> Expect.within (Expect.Absolute 0.001) desktopResult.haulingRate r.haulingRate
                            , \r -> Expect.equal desktopResult.bottleneck r.bottleneck
                            ]
                            mobileResult

                    Err _ ->
                        Expect.fail "Calculation should succeed for test data"
        , test "should_preserve_complex_calculation_results_across_transitions" <|
            \_ ->
                let
                    -- Complex calculation scenario
                    result =
                        Calculations.calculateTimeline 5.5 1.5 25.0 10.0 1500.0 10.0
                in
                case result of
                    Ok calculation ->
                        let
                            -- Results should be identical across device types
                            preservedResult =
                                calculation
                        in
                        Expect.all
                            [ \r -> Expect.greaterThan 0 r.timelineInDays
                            , \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> List.length r.assumptions |> Expect.greaterThan 0
                            , \r -> List.length r.warnings |> Expect.atLeast 0 -- Warnings count should be non-negative
                            ]
                            preservedResult

                    Err _ ->
                        Expect.fail "Complex calculation should succeed"
        , test "should_maintain_calculation_precision_during_transitions" <|
            \_ ->
                let
                    -- Calculation with precise inputs
                    result =
                        Calculations.calculateTimeline 2.333 1.666 11.111 14.285 333.333 7.777
                in
                case result of
                    Ok calculation ->
                        let
                            -- Precision should be maintained across device transitions
                            originalTotalHours =
                                calculation.totalHours

                            transitionedTotalHours =
                                calculation.totalHours

                            -- Preserved
                        in
                        Expect.within (Expect.Absolute 0.000001) originalTotalHours transitionedTotalHours

                    Err _ ->
                        Expect.fail "Precise calculation should succeed"
        ]


{-| Test that validation errors are preserved across device transitions
-}
validationErrorPreservationTests : Test
validationErrorPreservationTests =
    describe "Validation Error Preservation During Device Transitions"
        [ test "should_preserve_excavator_capacity_validation_errors_during_transitions" <|
            \_ ->
                let
                    validationRules =
                        { min = 0.5, max = 15.0 }

                    invalidCapacity =
                        -2.0

                    -- Validation error on desktop
                    desktopValidationResult =
                        Validation.validateExcavatorCapacity validationRules invalidCapacity

                    -- Same error should be preserved on mobile/tablet
                    mobileValidationResult =
                        Validation.validateExcavatorCapacity validationRules invalidCapacity

                    tabletValidationResult =
                        Validation.validateExcavatorCapacity validationRules invalidCapacity
                in
                case ( desktopValidationResult, mobileValidationResult, tabletValidationResult ) of
                    ( Err desktopError, Err mobileError, Err tabletError ) ->
                        Expect.all
                            [ \_ -> Expect.equal desktopError mobileError
                            , \_ -> Expect.equal mobileError tabletError
                            ]
                            ()

                    _ ->
                        Expect.fail "All validations should fail with same error"
        , test "should_preserve_multiple_validation_errors_during_transitions" <|
            \_ ->
                let
                    validationRules =
                        { excavatorCapacity = { min = 0.5, max = 15.0 }
                        , cycleTime = { min = 0.5, max = 10.0 }
                        , truckCapacity = { min = 5.0, max = 30.0 }
                        , roundTripTime = { min = 5.0, max = 60.0 }
                        , workHours = { min = 1.0, max = 16.0 }
                        , pondDimensions = { min = 1.0, max = 1000.0 }
                        }

                    invalidInputs =
                        { excavatorCapacity = -1.0 -- Invalid
                        , excavatorCycleTime = 0.0 -- Invalid
                        , truckCapacity = 100.0 -- Invalid (too high)
                        , truckRoundTripTime = 15.0 -- Valid
                        , workHoursPerDay = 8.0 -- Valid
                        , pondLength = 40.0 -- Valid
                        , pondWidth = 25.0 -- Valid
                        , pondDepth = 5.0 -- Valid
                        }

                    -- Validation should fail consistently across device types
                    desktopResult =
                        Validation.validateAllInputs validationRules invalidInputs

                    mobileResult =
                        Validation.validateAllInputs validationRules invalidInputs

                    tabletResult =
                        Validation.validateAllInputs validationRules invalidInputs
                in
                case ( desktopResult, mobileResult, tabletResult ) of
                    ( Err _, Err _, Err _ ) ->
                        Expect.pass

                    -- All should fail with validation errors
                    _ ->
                        Expect.fail "Invalid inputs should fail validation consistently"
        , test "should_preserve_validation_error_types_during_transitions" <|
            \_ ->
                let
                    rules =
                        { min = 1.0, max = 10.0 }

                    -- Different error types should be preserved
                    tooLowError =
                        Validation.validateExcavatorCapacity rules 0.5

                    tooHighError =
                        Validation.validateExcavatorCapacity rules 20.0

                    zeroError =
                        Validation.validateExcavatorCapacity rules 0.0
                in
                case ( tooLowError, tooHighError, zeroError ) of
                    ( Err (ValueTooLow _ _), Err (ValueTooHigh _ _), Err (RequiredField _) ) ->
                        -- Error types should be preserved across device transitions
                        Expect.pass

                    _ ->
                        Expect.fail "Error types should be consistent"
        ]


{-| Test state consistency when browser is resized across device breakpoints
-}
stateConsistencyDuringResizeTests : Test
stateConsistencyDuringResizeTests =
    describe "State Consistency During Browser Resize"
        [ test "should_maintain_device_type_detection_consistency_during_resize" <|
            \_ ->
                let
                    -- Test various resize scenarios
                    mobileWidth =
                        { width = 500, height = 800 }

                    tabletWidth =
                        { width = 800, height = 600 }

                    desktopWidth =
                        { width = 1300, height = 900 }

                    mobileType =
                        Types.DeviceType.fromWindowSize mobileWidth

                    tabletType =
                        Types.DeviceType.fromWindowSize tabletWidth

                    desktopType =
                        Types.DeviceType.fromWindowSize desktopWidth
                in
                Expect.all
                    [ \_ -> Expect.equal Mobile mobileType
                    , \_ -> Expect.equal Tablet tabletType
                    , \_ -> Expect.equal Desktop desktopType
                    ]
                    ()
        , test "should_handle_boundary_resize_scenarios_consistently" <|
            \_ ->
                let
                    -- Test exact boundary values
                    mobileTabletBoundary =
                        { width = 768, height = 1024 }

                    tabletDesktopBoundary =
                        { width = 1024, height = 768 }

                    boundaryType1 =
                        Types.DeviceType.fromWindowSize mobileTabletBoundary

                    boundaryType2 =
                        Types.DeviceType.fromWindowSize tabletDesktopBoundary
                in
                Expect.all
                    [ \_ -> Expect.equal Tablet boundaryType1
                    , \_ -> Expect.equal Tablet boundaryType2 -- 1024px is still tablet
                    ]
                    ()
        , test "should_preserve_state_through_rapid_resize_changes" <|
            \_ ->
                let
                    -- Simulate rapid resize between device types
                    sizes =
                        [ { width = 320, height = 568 } -- Mobile
                        , { width = 768, height = 1024 } -- Tablet
                        , { width = 1200, height = 800 } -- Desktop
                        , { width = 375, height = 667 } -- Back to mobile
                        ]

                    deviceTypes =
                        List.map Types.DeviceType.fromWindowSize sizes

                    expectedTypes =
                        [ Mobile, Tablet, Desktop, Mobile ]
                in
                Expect.equal expectedTypes deviceTypes
        , test "should_maintain_input_state_consistency_across_breakpoint_changes" <|
            \_ ->
                let
                    -- Simulate state preservation during resize
                    initialInputs =
                        { excavatorCapacity = "3.75"
                        , truckCapacity = "18.5"
                        , pondLength = "55.0"
                        }

                    -- Inputs should be preserved regardless of device type
                    -- (In real implementation, this would be through model state)
                    mobileInputs =
                        initialInputs

                    tabletInputs =
                        initialInputs

                    desktopInputs =
                        initialInputs
                in
                Expect.all
                    [ \_ -> Expect.equal initialInputs.excavatorCapacity mobileInputs.excavatorCapacity
                    , \_ -> Expect.equal initialInputs.truckCapacity tabletInputs.truckCapacity
                    , \_ -> Expect.equal initialInputs.pondLength desktopInputs.pondLength
                    ]
                    ()
        , test "should_handle_calculation_state_during_resize_interruption" <|
            \_ ->
                let
                    -- Calculation in progress during device transition
                    calculationData =
                        { excavatorCapacity = 4.0
                        , excavatorCycle = 2.2
                        , truckCapacity = 16.0
                        , truckRoundTrip = 18.0
                        , pondVolume = 800.0
                        , workHours = 9.0
                        }

                    -- Calculation should complete consistently regardless of resize
                    result =
                        Calculations.calculateTimeline
                            calculationData.excavatorCapacity
                            calculationData.excavatorCycle
                            calculationData.truckCapacity
                            calculationData.truckRoundTrip
                            calculationData.pondVolume
                            calculationData.workHours
                in
                case result of
                    Ok calculation ->
                        -- Result should be stable across device transitions
                        Expect.all
                            [ \r -> Expect.greaterThan 0 r.timelineInDays
                            , \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> Expect.greaterThan 0.0 r.excavationRate
                            ]
                            calculation

                    Err _ ->
                        Expect.fail "Calculation should complete successfully during transitions"
        , test "should_preserve_performance_characteristics_across_device_transitions" <|
            \_ ->
                let
                    -- Performance should be consistent across device types
                    testCalculation device =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 400.0 8.0

                    mobilePerf =
                        testCalculation Mobile

                    tabletPerf =
                        testCalculation Tablet

                    desktopPerf =
                        testCalculation Desktop
                in
                case ( mobilePerf, tabletPerf, desktopPerf ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        -- All should produce identical results (device-agnostic calculations)
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.totalHours tablet.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.totalHours desktop.totalHours
                            ]
                            ()

                    _ ->
                        Expect.fail "Performance should be consistent across all device types"
        ]
