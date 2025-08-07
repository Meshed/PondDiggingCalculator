module Unit.CalculationTests exposing (..)

import Expect
import Test exposing (..)
import Utils.Calculations as Calculations


suite : Test
suite =
    describe "Calculation Engine Tests"
        [ describe "calculateExcavatorRate"
            [ test "should_calculate_correct_rate_for_standard_excavator" <|
                \_ ->
                    let
                        bucketCapacity =
                            2.5

                        -- cubic yards
                        cycleTime =
                            2.0

                        -- minutes
                        expectedRate =
                            (60.0 / 2.0) * 2.5 * 0.85

                        -- 63.75 cy/hour
                    in
                    Calculations.calculateExcavatorRate bucketCapacity cycleTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            , test "should_calculate_correct_rate_for_large_excavator" <|
                \_ ->
                    let
                        bucketCapacity =
                            5.0

                        -- cubic yards
                        cycleTime =
                            3.0

                        -- minutes
                        expectedRate =
                            (60.0 / 3.0) * 5.0 * 0.85

                        -- 85 cy/hour
                    in
                    Calculations.calculateExcavatorRate bucketCapacity cycleTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            , test "should_handle_fast_cycle_time" <|
                \_ ->
                    let
                        bucketCapacity =
                            1.0

                        -- cubic yards
                        cycleTime =
                            0.5

                        -- minutes (30 seconds)
                        expectedRate =
                            (60.0 / 0.5) * 1.0 * 0.85

                        -- 102 cy/hour
                    in
                    Calculations.calculateExcavatorRate bucketCapacity cycleTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            ]
        , describe "calculateTruckRate"
            [ test "should_calculate_correct_rate_for_standard_truck" <|
                \_ ->
                    let
                        truckCapacity =
                            12.0

                        -- cubic yards
                        roundTripTime =
                            15.0

                        -- minutes
                        expectedRate =
                            (60.0 / 15.0) * 12.0 * 0.8

                        -- 38.4 cy/hour
                    in
                    Calculations.calculateTruckRate truckCapacity roundTripTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            , test "should_calculate_correct_rate_for_large_truck" <|
                \_ ->
                    let
                        truckCapacity =
                            20.0

                        -- cubic yards
                        roundTripTime =
                            20.0

                        -- minutes
                        expectedRate =
                            (60.0 / 20.0) * 20.0 * 0.8

                        -- 48 cy/hour
                    in
                    Calculations.calculateTruckRate truckCapacity roundTripTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            , test "should_handle_short_round_trip" <|
                \_ ->
                    let
                        truckCapacity =
                            8.0

                        -- cubic yards
                        roundTripTime =
                            5.0

                        -- minutes
                        expectedRate =
                            (60.0 / 5.0) * 8.0 * 0.8

                        -- 76.8 cy/hour
                    in
                    Calculations.calculateTruckRate truckCapacity roundTripTime
                        |> Expect.within (Expect.Absolute 0.01) expectedRate
            ]
        , describe "calculateTimeline"
            [ test "should_calculate_correct_timeline_for_balanced_equipment" <|
                \_ ->
                    let
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

                        -- cubic yards
                        workHours =
                            8.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            Expect.all
                                [ \r -> Expect.greaterThan 0 r.timelineInDays
                                , \r -> Expect.greaterThan 0.0 r.totalHours
                                , \r -> Expect.greaterThan 0.0 r.excavationRate
                                , \r -> Expect.greaterThan 0.0 r.haulingRate
                                ]
                                result

                        Err _ ->
                            Expect.fail "Calculation should succeed with valid inputs"
            , test "should_calculate_one_day_for_small_pond" <|
                \_ ->
                    let
                        excavatorCapacity =
                            2.5

                        excavatorCycle =
                            2.0

                        truckCapacity =
                            12.0

                        truckRoundTrip =
                            15.0

                        pondVolume =
                            300.0

                        -- cubic yards (small pond)
                        workHours =
                            8.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            result.timelineInDays
                                |> Expect.equal 1

                        Err _ ->
                            Expect.fail "Calculation should succeed"
            , test "should_round_up_to_whole_days" <|
                \_ ->
                    let
                        excavatorCapacity =
                            1.0

                        excavatorCycle =
                            3.0

                        truckCapacity =
                            6.0

                        truckRoundTrip =
                            20.0

                        pondVolume =
                            100.0

                        -- cubic yards
                        workHours =
                            8.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            Expect.all
                                [ \r -> Expect.greaterThan 0 r.timelineInDays
                                , \r -> Expect.greaterThan (toFloat (r.timelineInDays - 1) * workHours) r.totalHours
                                , \r -> Expect.atMost (toFloat r.timelineInDays * workHours) r.totalHours
                                ]
                                result

                        Err _ ->
                            Expect.fail "Calculation should succeed"
            , test "should_identify_excavation_bottleneck" <|
                \_ ->
                    let
                        excavatorCapacity =
                            1.0

                        -- Small excavator
                        excavatorCycle =
                            4.0

                        -- Slow cycle
                        truckCapacity =
                            20.0

                        -- Large truck
                        truckRoundTrip =
                            10.0

                        -- Fast round trip
                        pondVolume =
                            200.0

                        workHours =
                            8.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            result.bottleneck
                                |> Expect.equal Calculations.ExcavationBottleneck

                        Err _ ->
                            Expect.fail "Calculation should succeed"
            , test "should_identify_hauling_bottleneck" <|
                \_ ->
                    let
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
                            200.0

                        workHours =
                            8.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            result.bottleneck
                                |> Expect.equal Calculations.HaulingBottleneck

                        Err _ ->
                            Expect.fail "Calculation should succeed"
            , test "should_return_error_for_zero_pond_volume" <|
                \_ ->
                    let
                        result =
                            Calculations.calculateTimeline 2.5 2.0 12.0 15.0 0.0 8.0
                    in
                    case result of
                        Ok _ ->
                            Expect.fail "Should return error for zero pond volume"

                        Err error ->
                            Expect.pass
            , test "should_return_error_for_negative_work_hours" <|
                \_ ->
                    let
                        result =
                            Calculations.calculateTimeline 2.5 2.0 12.0 15.0 100.0 -1.0
                    in
                    case result of
                        Ok _ ->
                            Expect.fail "Should return error for negative work hours"

                        Err error ->
                            Expect.pass
            ]
        , describe "Edge Cases"
            [ test "should_handle_very_large_pond" <|
                \_ ->
                    let
                        excavatorCapacity =
                            5.0

                        excavatorCycle =
                            2.0

                        truckCapacity =
                            20.0

                        truckRoundTrip =
                            15.0

                        pondVolume =
                            10000.0

                        -- Very large pond
                        workHours =
                            10.0
                    in
                    case Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours of
                        Ok result ->
                            Expect.all
                                [ \r -> Expect.greaterThan 10 r.timelineInDays -- Should take many days
                                , \r -> Expect.greaterThan 0.0 r.excavationRate
                                , \r -> Expect.greaterThan 0.0 r.haulingRate
                                ]
                                result

                        Err _ ->
                            Expect.fail "Should handle large pond calculations"
            , test "should_handle_minimum_work_hours" <|
                \_ ->
                    let
                        result =
                            Calculations.calculateTimeline 2.5 2.0 12.0 15.0 100.0 1.0
                    in
                    case result of
                        Ok calculationResult ->
                            calculationResult.timelineInDays
                                |> Expect.greaterThan 0

                        Err _ ->
                            Expect.fail "Should handle minimum work hours"
            ]
        ]
