module Unit.RealTimeTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Types.Fields exposing (ExcavatorField(..), TruckField(..), PondField(..), ProjectField(..))
import Types.Messages exposing (Msg(..))
import Utils.Performance as Performance


suite : Test
suite =
    describe "Real-time Updates"
        [ describe "Input Field Messages"
            [ test "should_create_excavator_field_messages" <|
                \_ ->
                    let
                        msg = ExcavatorFieldChanged BucketCapacity "2.5"
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
                        msg = TruckFieldChanged TruckCapacity "15.0"
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
                        msg = PondFieldChanged PondLength "100.0"
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
                        msg = ProjectFieldChanged WorkHours "8.0"
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
                        metrics = Performance.initMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal metrics.lastCalculationTime 0.0
                        , \() -> Expect.equal metrics.averageTime 0.0
                        , \() -> Expect.equal metrics.maxTime 0.0
                        , \() -> Expect.equal metrics.calculationCount 0
                        ]
                        ()

            , test "should_record_calculation_time" <|
                \_ ->
                    let
                        initialMetrics = Performance.initMetrics
                        updatedMetrics = Performance.recordCalculationTime 50.0 initialMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal updatedMetrics.lastCalculationTime 50.0
                        , \() -> Expect.equal updatedMetrics.averageTime 50.0
                        , \() -> Expect.equal updatedMetrics.maxTime 50.0
                        , \() -> Expect.equal updatedMetrics.calculationCount 1
                        ]
                        ()

            , test "should_warn_when_performance_exceeds_threshold" <|
                \_ ->
                    let
                        metrics = Performance.initMetrics
                        slowMetrics = Performance.recordCalculationTime 150.0 metrics
                    in
                    Performance.shouldWarn slowMetrics
                        |> Expect.equal True

            , test "should_not_warn_when_performance_within_threshold" <|
                \_ ->
                    let
                        metrics = Performance.initMetrics
                        fastMetrics = Performance.recordCalculationTime 50.0 metrics
                    in
                    Performance.shouldWarn fastMetrics
                        |> Expect.equal False

            , test "should_calculate_rolling_average_performance" <|
                \_ ->
                    let
                        metrics = Performance.initMetrics
                        firstUpdate = Performance.recordCalculationTime 100.0 metrics
                        secondUpdate = Performance.recordCalculationTime 50.0 firstUpdate
                    in
                    -- Rolling average: (100 * 0.8) + (50 * 0.2) = 80 + 10 = 90
                    Expect.within (Expect.Absolute 0.1) 90.0 secondUpdate.averageTime
            ]
        ]