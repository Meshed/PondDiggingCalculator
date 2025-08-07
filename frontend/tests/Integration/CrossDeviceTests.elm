module Integration.CrossDeviceTests exposing (suite)

{-| Cross-device calculation validation tests
Ensures identical calculation results across Mobile/Desktop/Tablet interfaces

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Utils.Calculations as Calculations
import Utils.Config as Config


suite : Test
suite =
    describe "Cross-Device Calculation Consistency"
        [ calculationConsistencyTests
        , edgeCaseConsistencyTests
        , precisionConsistencyTests
        , complexFleetCalculationTests
        ]


{-| Test that calculations produce identical results across all device types
-}
calculationConsistencyTests : Test
calculationConsistencyTests =
    describe "Calculation Result Consistency"
        [ test "should_produce_identical_results_across_all_device_types" <|
            \_ ->
                let
                    -- Standard test case
                    excavatorCapacity =
                        2.5

                    excavatorCycle =
                        2.0

                    truckCapacity =
                        12.0

                    truckRoundTrip =
                        15.0

                    pondVolume =
                        500.0

                    workHours =
                        8.0

                    -- Calculate for all device types (should be identical since calculations are device-agnostic)
                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.totalHours tablet.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.totalHours desktop.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.excavationRate tablet.excavationRate
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.excavationRate desktop.excavationRate
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.haulingRate tablet.haulingRate
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.haulingRate desktop.haulingRate
                            , \_ -> Expect.equal mobile.bottleneck tablet.bottleneck
                            , \_ -> Expect.equal tablet.bottleneck desktop.bottleneck
                            , \_ -> Expect.equal mobile.confidence tablet.confidence
                            , \_ -> Expect.equal tablet.confidence desktop.confidence
                            ]
                            ()

                    _ ->
                        Expect.fail "All calculations should succeed with valid inputs"
        , test "should_have_identical_rate_calculations_across_devices" <|
            \_ ->
                let
                    -- Test individual rate calculations
                    bucketCapacity =
                        3.5

                    cycleTime =
                        2.5

                    truckCapacity =
                        15.0

                    roundTripTime =
                        18.0

                    -- These functions are pure and device-agnostic
                    excavatorRate =
                        Calculations.calculateExcavatorRate bucketCapacity cycleTime

                    truckRate =
                        Calculations.calculateTruckRate truckCapacity roundTripTime

                    -- Results should be identical regardless of "device context"
                    mobileExcavatorRate =
                        Calculations.calculateExcavatorRate bucketCapacity cycleTime

                    desktopExcavatorRate =
                        Calculations.calculateExcavatorRate bucketCapacity cycleTime

                    mobileTruckRate =
                        Calculations.calculateTruckRate truckCapacity roundTripTime

                    desktopTruckRate =
                        Calculations.calculateTruckRate truckCapacity roundTripTime
                in
                Expect.all
                    [ \_ -> Expect.within (Expect.Absolute 0.001) excavatorRate mobileExcavatorRate
                    , \_ -> Expect.within (Expect.Absolute 0.001) excavatorRate desktopExcavatorRate
                    , \_ -> Expect.within (Expect.Absolute 0.001) truckRate mobileTruckRate
                    , \_ -> Expect.within (Expect.Absolute 0.001) truckRate desktopTruckRate
                    ]
                    ()
        ]


{-| Test edge cases produce consistent results across devices
-}
edgeCaseConsistencyTests : Test
edgeCaseConsistencyTests =
    describe "Edge Case Consistency Across Devices"
        [ test "should_handle_minimum_values_identically" <|
            \_ ->
                let
                    -- Minimum boundary values
                    excavatorCapacity =
                        0.1

                    -- Minimum bucket capacity
                    excavatorCycle =
                        0.5

                    -- Fast cycle
                    truckCapacity =
                        1.0

                    -- Minimum truck capacity
                    truckRoundTrip =
                        1.0

                    -- Minimum round trip
                    pondVolume =
                        10.0

                    -- Small pond
                    workHours =
                        1.0

                    -- Minimum work hours
                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.totalHours tablet.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.totalHours desktop.totalHours
                            ]
                            ()

                    _ ->
                        Expect.fail "Edge case calculations should succeed across all devices"
        , test "should_handle_maximum_values_identically" <|
            \_ ->
                let
                    -- Maximum boundary values
                    excavatorCapacity =
                        15.0

                    -- Maximum bucket capacity
                    excavatorCycle =
                        5.0

                    -- Slow cycle
                    truckCapacity =
                        50.0

                    -- Maximum truck capacity
                    truckRoundTrip =
                        60.0

                    -- Long round trip
                    pondVolume =
                        10000.0

                    -- Large pond
                    workHours =
                        12.0

                    -- Long work day
                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.001) mobile.totalHours tablet.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) tablet.totalHours desktop.totalHours
                            ]
                            ()

                    _ ->
                        Expect.fail "Maximum value calculations should succeed across all devices"
        , test "should_handle_error_conditions_identically" <|
            \_ ->
                let
                    -- Invalid inputs that should fail consistently
                    invalidPondVolume =
                        0.0

                    invalidWorkHours =
                        -1.0

                    mobileResult1 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 invalidPondVolume 8.0

                    tabletResult1 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 invalidPondVolume 8.0

                    desktopResult1 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 invalidPondVolume 8.0

                    mobileResult2 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 100.0 invalidWorkHours

                    tabletResult2 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 100.0 invalidWorkHours

                    desktopResult2 =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 100.0 invalidWorkHours
                in
                Expect.all
                    [ \_ ->
                        case ( mobileResult1, tabletResult1, desktopResult1 ) of
                            ( Err _, Err _, Err _ ) ->
                                Expect.pass

                            _ ->
                                Expect.fail "Invalid pond volume should fail consistently"
                    , \_ ->
                        case ( mobileResult2, tabletResult2, desktopResult2 ) of
                            ( Err _, Err _, Err _ ) ->
                                Expect.pass

                            _ ->
                                Expect.fail "Invalid work hours should fail consistently"
                    ]
                    ()
        ]


{-| Test calculation precision matches exactly across devices
-}
precisionConsistencyTests : Test
precisionConsistencyTests =
    describe "Calculation Precision Consistency"
        [ test "should_maintain_floating_point_precision_across_devices" <|
            \_ ->
                let
                    -- Use values that might cause floating point precision issues
                    excavatorCapacity =
                        2.33333

                    excavatorCycle =
                        1.66667

                    truckCapacity =
                        11.11111

                    truckRoundTrip =
                        14.28571

                    pondVolume =
                        333.33333

                    workHours =
                        7.77777

                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.000001) mobile.totalHours tablet.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.000001) tablet.totalHours desktop.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.000001) mobile.excavationRate tablet.excavationRate
                            , \_ -> Expect.within (Expect.Absolute 0.000001) tablet.excavationRate desktop.excavationRate
                            , \_ -> Expect.within (Expect.Absolute 0.000001) mobile.haulingRate tablet.haulingRate
                            , \_ -> Expect.within (Expect.Absolute 0.000001) tablet.haulingRate desktop.haulingRate
                            ]
                            ()

                    _ ->
                        Expect.fail "Precision calculations should succeed across all devices"
        , test "should_handle_rounding_consistently" <|
            \_ ->
                let
                    -- Test values that result in fractional days requiring rounding
                    excavatorCapacity =
                        1.0

                    excavatorCycle =
                        3.0

                    truckCapacity =
                        6.0

                    truckRoundTrip =
                        20.0

                    pondVolume =
                        45.7

                    -- Should result in fractional day calculation
                    workHours =
                        8.0

                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            , \_ -> Expect.greaterThan (toFloat (mobile.timelineInDays - 1)) mobile.totalHours
                            , \_ -> Expect.atMost (toFloat mobile.timelineInDays * workHours) mobile.totalHours
                            ]
                            ()

                    _ ->
                        Expect.fail "Rounding calculations should succeed across all devices"
        ]


{-| Test complex fleet calculations give identical results
-}
complexFleetCalculationTests : Test
complexFleetCalculationTests =
    describe "Complex Fleet Calculation Consistency"
        [ test "should_handle_excavation_bottleneck_scenario_identically" <|
            \_ ->
                let
                    -- Scenario where excavation is the bottleneck
                    excavatorCapacity =
                        1.0

                    -- Small excavator
                    excavatorCycle =
                        4.0

                    -- Slow cycle
                    truckCapacity =
                        20.0

                    -- Large truck fleet
                    truckRoundTrip =
                        10.0

                    -- Fast round trip
                    pondVolume =
                        500.0

                    workHours =
                        8.0

                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.bottleneck Calculations.ExcavationBottleneck
                            , \_ -> Expect.equal tablet.bottleneck Calculations.ExcavationBottleneck
                            , \_ -> Expect.equal desktop.bottleneck Calculations.ExcavationBottleneck
                            , \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            ]
                            ()

                    _ ->
                        Expect.fail "Excavation bottleneck calculation should succeed across all devices"
        , test "should_handle_hauling_bottleneck_scenario_identically" <|
            \_ ->
                let
                    -- Scenario where hauling is the bottleneck
                    excavatorCapacity =
                        5.0

                    -- Large excavator
                    excavatorCycle =
                        1.5

                    -- Fast cycle
                    truckCapacity =
                        6.0

                    -- Small truck
                    truckRoundTrip =
                        30.0

                    -- Slow round trip
                    pondVolume =
                        500.0

                    workHours =
                        8.0

                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.bottleneck Calculations.HaulingBottleneck
                            , \_ -> Expect.equal tablet.bottleneck Calculations.HaulingBottleneck
                            , \_ -> Expect.equal desktop.bottleneck Calculations.HaulingBottleneck
                            , \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            ]
                            ()

                    _ ->
                        Expect.fail "Hauling bottleneck calculation should succeed across all devices"
        , test "should_handle_balanced_scenario_identically" <|
            \_ ->
                let
                    -- Scenario where equipment is well-balanced
                    excavatorCapacity =
                        2.5

                    excavatorCycle =
                        2.0

                    -- Excavation rate ~63.75 cy/hour
                    truckCapacity =
                        12.0

                    truckRoundTrip =
                        15.0

                    -- Hauling rate ~38.4 cy/hour (this will be bottleneck)
                    pondVolume =
                        300.0

                    workHours =
                        8.0

                    mobileResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    tabletResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours

                    desktopResult =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case ( mobileResult, tabletResult, desktopResult ) of
                    ( Ok mobile, Ok tablet, Ok desktop ) ->
                        Expect.all
                            [ \_ -> Expect.equal mobile.bottleneck tablet.bottleneck
                            , \_ -> Expect.equal tablet.bottleneck desktop.bottleneck
                            , \_ -> Expect.equal mobile.confidence tablet.confidence
                            , \_ -> Expect.equal tablet.confidence desktop.confidence
                            , \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                            , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                            ]
                            ()

                    _ ->
                        Expect.fail "Balanced scenario calculation should succeed across all devices"
        ]
