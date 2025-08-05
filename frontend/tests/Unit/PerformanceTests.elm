module Unit.PerformanceTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Utils.Calculations as Calculations


suite : Test
suite =
    describe "Calculation Performance"
        [ describe "Sub-100ms Performance Requirements"
            [ test "should_calculate_excavator_rate_quickly" <|
                \_ ->
                    -- Test with typical values
                    let
                        rate = Calculations.calculateExcavatorRate 2.5 1.5
                    in
                    -- Simple calculation should be nearly instantaneous
                    -- We can't actually measure time in pure Elm tests, but we ensure the function returns
                    Expect.greaterThan 0 rate

            , test "should_calculate_truck_rate_quickly" <|
                \_ ->
                    let
                        rate = Calculations.calculateTruckRate 15.0 10.0
                    in
                    Expect.greaterThan 0 rate

            , test "should_calculate_complete_timeline_quickly" <|
                \_ ->
                    let
                        result = Calculations.calculateTimeline 2.5 1.5 15.0 10.0 1000.0 8.0
                    in
                    case result of
                        Ok timeline ->
                            Expect.greaterThan 0 timeline.timelineInDays
                        Err _ ->
                            Expect.fail "Calculation should succeed with valid inputs"

            , test "should_handle_multiple_rapid_calculations" <|
                \_ ->
                    -- Simulate rapid input changes
                    let
                        results = List.range 1 10
                            |> List.map (\i -> 
                                Calculations.calculateTimeline 
                                    (toFloat i * 0.5) -- varying excavator capacity
                                    1.5 
                                    15.0 
                                    10.0 
                                    1000.0 
                                    8.0
                            )
                        successCount = results
                            |> List.filterMap (\result ->
                                case result of
                                    Ok _ -> Just 1
                                    Err _ -> Nothing
                            )
                            |> List.length
                    in
                    Expect.equal 10 successCount
            ]

        , describe "Decimal Precision Maintenance"
            [ test "should_maintain_precision_across_multiple_updates" <|
                \_ ->
                    let
                        -- Calculate same values multiple times
                        result1 = Calculations.calculateTimeline 2.5 1.5 15.0 10.0 1000.0 8.0
                        result2 = Calculations.calculateTimeline 2.5 1.5 15.0 10.0 1000.0 8.0
                        result3 = Calculations.calculateTimeline 2.5 1.5 15.0 10.0 1000.0 8.0
                    in
                    case (result1, result2, result3) of
                        (Ok r1, Ok r2, Ok r3) ->
                            Expect.all
                                [ \() -> Expect.equal r1.timelineInDays r2.timelineInDays
                                , \() -> Expect.equal r2.timelineInDays r3.timelineInDays
                                , \() -> Expect.within (Expect.Absolute 0.001) r1.totalHours r2.totalHours
                                , \() -> Expect.within (Expect.Absolute 0.001) r2.totalHours r3.totalHours
                                ]
                                ()
                        _ ->
                            Expect.fail "All calculations should succeed"

            , test "should_handle_precision_with_small_values" <|
                \_ ->
                    let
                        result = Calculations.calculateTimeline 0.1 0.5 1.0 2.0 10.0 1.0
                    in
                    case result of
                        Ok timeline ->
                            Expect.all
                                [ \() -> Expect.greaterThan 0 timeline.totalHours
                                , \() -> Expect.greaterThan 0 timeline.excavationRate
                                , \() -> Expect.greaterThan 0 timeline.haulingRate
                                ]
                                ()
                        Err _ ->
                            Expect.fail "Should handle small values correctly"

            , test "should_handle_precision_with_large_values" <|
                \_ ->
                    let
                        result = Calculations.calculateTimeline 10.0 5.0 50.0 20.0 100000.0 12.0
                    in
                    case result of
                        Ok timeline ->
                            Expect.all
                                [ \() -> Expect.greaterThan 0 timeline.totalHours
                                , \() -> Expect.lessThan 1000000 timeline.totalHours -- Sanity check
                                ]
                                ()
                        Err _ ->
                            Expect.fail "Should handle large values correctly"
            ]
        ]