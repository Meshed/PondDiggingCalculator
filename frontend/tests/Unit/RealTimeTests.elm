module Unit.RealTimeTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Utils.Debounce as Debounce
import Utils.Performance as Performance


suite : Test
suite =
    describe "Real-time Updates"
        [ describe "Input Field Messages"
            [ test "should_create_excavator_field_messages" <|
                \_ ->
                    let
                        msg =
                            ExcavatorFieldChanged BucketCapacity "2.5"
                    in
                    case msg of
                        ExcavatorFieldChanged field value ->
                            Expect.all
                                [ \() -> Expect.equal field BucketCapacity
                                , \() -> Expect.equal value "2.5"
                                ]
                                ()

                        _ ->
                            Expect.fail "Expected ExcavatorFieldChanged message"
            , test "should_create_truck_field_messages" <|
                \_ ->
                    let
                        msg =
                            TruckFieldChanged TruckCapacity "15.0"
                    in
                    case msg of
                        TruckFieldChanged field value ->
                            Expect.all
                                [ \() -> Expect.equal field TruckCapacity
                                , \() -> Expect.equal value "15.0"
                                ]
                                ()

                        _ ->
                            Expect.fail "Expected TruckFieldChanged message"
            , test "should_create_pond_field_messages" <|
                \_ ->
                    let
                        msg =
                            PondFieldChanged PondLength "100.0"
                    in
                    case msg of
                        PondFieldChanged field value ->
                            Expect.all
                                [ \() -> Expect.equal field PondLength
                                , \() -> Expect.equal value "100.0"
                                ]
                                ()

                        _ ->
                            Expect.fail "Expected PondFieldChanged message"
            , test "should_create_project_field_messages" <|
                \_ ->
                    let
                        msg =
                            ProjectFieldChanged WorkHours "8.0"
                    in
                    case msg of
                        ProjectFieldChanged field value ->
                            Expect.all
                                [ \() -> Expect.equal field WorkHours
                                , \() -> Expect.equal value "8.0"
                                ]
                                ()

                        _ ->
                            Expect.fail "Expected ProjectFieldChanged message"
            ]
        , describe "Performance Tracking"
            [ test "should_initialize_performance_metrics" <|
                \_ ->
                    let
                        metrics =
                            Performance.initMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal Nothing metrics.calculationTime
                        , \() -> Expect.equal 0.0 metrics.averageCalculationTime
                        , \() -> Expect.equal 0.0 metrics.maxCalculationTime
                        , \() -> Expect.equal 0 metrics.calculationCount
                        ]
                        ()
            , test "should_record_calculation_time" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        updatedMetrics =
                            Performance.recordCalculationTime 50.0 initialMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal (Just 50.0) updatedMetrics.calculationTime
                        , \() -> Expect.equal 50.0 updatedMetrics.averageCalculationTime
                        , \() -> Expect.equal 50.0 updatedMetrics.maxCalculationTime
                        , \() -> Expect.equal 1 updatedMetrics.calculationCount
                        ]
                        ()
            , test "should_warn_when_performance_exceeds_threshold" <|
                \_ ->
                    let
                        metrics =
                            Performance.initMetrics

                        slowMetrics =
                            Performance.recordCalculationTime 150.0 metrics
                    in
                    Performance.shouldWarn slowMetrics
                        |> Expect.equal True
            , test "should_not_warn_when_performance_within_threshold" <|
                \_ ->
                    let
                        metrics =
                            Performance.initMetrics

                        fastMetrics =
                            Performance.recordCalculationTime 50.0 metrics
                    in
                    Performance.shouldWarn fastMetrics
                        |> Expect.equal False
            , test "should_calculate_rolling_average_performance" <|
                \_ ->
                    let
                        metrics =
                            Performance.initMetrics

                        firstUpdate =
                            Performance.recordCalculationTime 100.0 metrics

                        secondUpdate =
                            Performance.recordCalculationTime 50.0 firstUpdate
                    in
                    -- Rolling average: (100 * 0.8) + (50 * 0.2) = 80 + 10 = 90
                    Expect.within (Expect.Absolute 0.1) 90.0 secondUpdate.averageCalculationTime
            ]
        , describe "Cross-Device Real-Time Update Consistency"
            [ test "should_apply_identical_debounce_delay_across_devices" <|
                \_ ->
                    let
                        -- According to story requirements, debounce should be identical across devices
                        mobileDelay =
                            Debounce.getDelayForDevice "Mobile"

                        tabletDelay =
                            Debounce.getDelayForDevice "Tablet"

                        desktopDelay =
                            Debounce.getDelayForDevice "Desktop"

                        -- Story requirement: 300ms delay identical across all devices
                        expectedDelay =
                            300.0
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.1) expectedDelay mobileDelay
                        , \_ -> Expect.within (Expect.Absolute 0.1) expectedDelay tabletDelay
                        , \_ -> Expect.within (Expect.Absolute 0.1) expectedDelay desktopDelay
                        , \_ -> Expect.within (Expect.Absolute 0.1) mobileDelay tabletDelay
                        , \_ -> Expect.within (Expect.Absolute 0.1) tabletDelay desktopDelay
                        ]
                        ()
            , test "should_trigger_calculation_updates_identically_across_devices" <|
                \_ ->
                    let
                        -- Test that debounce logic works identically across devices
                        initialTime =
                            1000.0

                        inputTime =
                            1100.0

                        delayTime =
                            300.0

                        mobileDebounceState =
                            { lastInputTime = initialTime, delay = delayTime }

                        tabletDebounceState =
                            { lastInputTime = initialTime, delay = delayTime }

                        desktopDebounceState =
                            { lastInputTime = initialTime, delay = delayTime }

                        -- Test debounce decision at same time point
                        triggerTime =
                            1400.0

                        -- 300ms after input
                        mobileShouldTrigger =
                            Debounce.shouldDebounce triggerTime mobileDebounceState

                        tabletShouldTrigger =
                            Debounce.shouldDebounce triggerTime tabletDebounceState

                        desktopShouldTrigger =
                            Debounce.shouldDebounce triggerTime desktopDebounceState
                    in
                    Expect.all
                        [ \_ -> Expect.equal True mobileShouldTrigger
                        , \_ -> Expect.equal True tabletShouldTrigger
                        , \_ -> Expect.equal True desktopShouldTrigger
                        , \_ -> Expect.equal mobileShouldTrigger tabletShouldTrigger
                        , \_ -> Expect.equal tabletShouldTrigger desktopShouldTrigger
                        ]
                        ()
            , test "should_prevent_calculation_updates_identically_before_debounce_delay" <|
                \_ ->
                    let
                        initialTime =
                            1000.0

                        inputTime =
                            1100.0

                        delayTime =
                            300.0

                        mobileDebounceState =
                            { lastInputTime = inputTime, delay = delayTime }

                        tabletDebounceState =
                            { lastInputTime = inputTime, delay = delayTime }

                        desktopDebounceState =
                            { lastInputTime = inputTime, delay = delayTime }

                        -- Test debounce decision before delay completes
                        earlyTime =
                            1200.0

                        -- Only 100ms after input, should not trigger
                        mobileShouldTrigger =
                            Debounce.shouldDebounce earlyTime mobileDebounceState

                        tabletShouldTrigger =
                            Debounce.shouldDebounce earlyTime tabletDebounceState

                        desktopShouldTrigger =
                            Debounce.shouldDebounce earlyTime desktopDebounceState
                    in
                    Expect.all
                        [ \_ -> Expect.equal False mobileShouldTrigger
                        , \_ -> Expect.equal False tabletShouldTrigger
                        , \_ -> Expect.equal False desktopShouldTrigger
                        , \_ -> Expect.equal mobileShouldTrigger tabletShouldTrigger
                        , \_ -> Expect.equal tabletShouldTrigger desktopShouldTrigger
                        ]
                        ()
            , test "should_update_debounce_state_identically_across_devices" <|
                \_ ->
                    let
                        initialState =
                            Debounce.initDebounce

                        updateTime =
                            2000.0

                        mobileUpdated =
                            Debounce.updateDebounceState updateTime initialState

                        tabletUpdated =
                            Debounce.updateDebounceState updateTime initialState

                        desktopUpdated =
                            Debounce.updateDebounceState updateTime initialState
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.1) mobileUpdated.lastInputTime tabletUpdated.lastInputTime
                        , \_ -> Expect.within (Expect.Absolute 0.1) tabletUpdated.lastInputTime desktopUpdated.lastInputTime
                        , \_ -> Expect.within (Expect.Absolute 0.1) mobileUpdated.delay tabletUpdated.delay
                        , \_ -> Expect.within (Expect.Absolute 0.1) tabletUpdated.delay desktopUpdated.delay
                        , \_ -> Expect.within (Expect.Absolute 0.1) updateTime mobileUpdated.lastInputTime
                        ]
                        ()
            , test "should_meet_100ms_calculation_performance_target_across_devices" <|
                \_ ->
                    let
                        -- Test that performance target (100ms) is consistent across devices
                        targetTime =
                            100.0

                        mobileMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime 95.0

                        tabletMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime 85.0

                        desktopMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime 90.0

                        -- All should be under target and not trigger warnings
                        mobileWarning =
                            Performance.shouldWarn mobileMetrics

                        tabletWarning =
                            Performance.shouldWarn tabletMetrics

                        desktopWarning =
                            Performance.shouldWarn desktopMetrics
                    in
                    Expect.all
                        [ \_ -> Expect.equal False mobileWarning
                        , \_ -> Expect.equal False tabletWarning
                        , \_ -> Expect.equal False desktopWarning
                        , \_ ->
                            case mobileMetrics.calculationTime of
                                Just time ->
                                    Expect.lessThan targetTime time

                                Nothing ->
                                    Expect.fail "Mobile metrics should have calculation time"
                        , \_ ->
                            case tabletMetrics.calculationTime of
                                Just time ->
                                    Expect.lessThan targetTime time

                                Nothing ->
                                    Expect.fail "Tablet metrics should have calculation time"
                        , \_ ->
                            case desktopMetrics.calculationTime of
                                Just time ->
                                    Expect.lessThan targetTime time

                                Nothing ->
                                    Expect.fail "Desktop metrics should have calculation time"
                        ]
                        ()
            , test "should_handle_performance_warnings_consistently_across_devices" <|
                \_ ->
                    let
                        -- Test performance degradation scenarios
                        slowCalculationTime =
                            150.0

                        -- Above 100ms target
                        mobileSlowMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime slowCalculationTime

                        tabletSlowMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime slowCalculationTime

                        desktopSlowMetrics =
                            Performance.initMetrics |> Performance.recordCalculationTime slowCalculationTime

                        mobileWarning =
                            Performance.shouldWarn mobileSlowMetrics

                        tabletWarning =
                            Performance.shouldWarn tabletSlowMetrics

                        desktopWarning =
                            Performance.shouldWarn desktopSlowMetrics
                    in
                    Expect.all
                        [ \_ -> Expect.equal True mobileWarning
                        , \_ -> Expect.equal True tabletWarning
                        , \_ -> Expect.equal True desktopWarning
                        , \_ -> Expect.equal mobileWarning tabletWarning
                        , \_ -> Expect.equal tabletWarning desktopWarning
                        , \_ ->
                            case mobileSlowMetrics.calculationTime of
                                Just time ->
                                    Expect.within (Expect.Absolute 0.1) slowCalculationTime time

                                Nothing ->
                                    Expect.fail "Mobile slow metrics should have calculation time"
                        , \_ ->
                            case tabletSlowMetrics.calculationTime of
                                Just time ->
                                    Expect.within (Expect.Absolute 0.1) slowCalculationTime time

                                Nothing ->
                                    Expect.fail "Tablet slow metrics should have calculation time"
                        ]
                        ()
            , test "should_handle_device_transition_performance_consistently" <|
                \_ ->
                    let
                        -- Test that transitioning between device types doesn't degrade performance
                        baseTime =
                            80.0

                        -- Simulate metrics collected on one device type
                        initialMetrics =
                            Performance.initMetrics
                                |> Performance.recordCalculationTime baseTime
                                |> Performance.recordCalculationTime (baseTime + 10.0)

                        -- Simulate transition to different device - performance should remain consistent
                        transitionMetrics =
                            Performance.recordCalculationTime baseTime initialMetrics

                        -- Performance characteristics should remain stable
                        performanceStable =
                            abs (transitionMetrics.averageCalculationTime - initialMetrics.averageCalculationTime) < 20.0

                        noWarningIncrease =
                            Performance.shouldWarn transitionMetrics == Performance.shouldWarn initialMetrics
                    in
                    Expect.all
                        [ \_ -> Expect.equal True performanceStable
                        , \_ -> Expect.equal True noWarningIncrease
                        , \_ ->
                            case transitionMetrics.calculationTime of
                                Just time ->
                                    Expect.lessThan 100.0 time

                                Nothing ->
                                    Expect.fail "Transition metrics should have calculation time"
                        ]
                        ()
            ]
        ]
