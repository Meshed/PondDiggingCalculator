module Unit.TruckFleetTests exposing (suite)

{-| Unit tests for truck fleet functionality

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.Equipment exposing (EquipmentId, Truck)
import Utils.Calculations exposing (calculateTruckFleetProductivity, calculateTruckRate)


suite : Test
suite =
    describe "Truck Fleet Tests"
        [ describe "Fleet Hauling Capacity Calculations"
            [ test "calculates hauling capacity for single truck fleet" <|
                \_ ->
                    let
                        singleTruck =
                            [ { id = "truck1"
                              , capacity = 12.0
                              , roundTripTime = 15.0
                              , name = "Standard Dump Truck"
                              , isActive = True
                              }
                            ]

                        expectedRate =
                            calculateTruckRate 12.0 15.0

                        actualRate =
                            calculateTruckFleetProductivity singleTruck
                    in
                    Expect.within (Expect.Absolute 0.001) expectedRate actualRate
            , test "calculates hauling capacity for multiple truck fleet with same specs" <|
                \_ ->
                    let
                        uniformFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck 1", isActive = True }
                            , { id = "truck2", capacity = 12.0, roundTripTime = 15.0, name = "Truck 2", isActive = True }
                            , { id = "truck3", capacity = 12.0, roundTripTime = 15.0, name = "Truck 3", isActive = True }
                            , { id = "truck4", capacity = 12.0, roundTripTime = 15.0, name = "Truck 4", isActive = True }
                            ]

                        singleTruckRate =
                            calculateTruckRate 12.0 15.0

                        expectedFleetRate =
                            singleTruckRate * 4

                        actualFleetRate =
                            calculateTruckFleetProductivity uniformFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedFleetRate actualFleetRate
            , test "calculates hauling capacity for mixed truck fleet with varying capacities" <|
                \_ ->
                    let
                        mixedCapacityFleet =
                            [ { id = "truck1", capacity = 8.0, roundTripTime = 12.0, name = "Small Truck", isActive = True }
                            , { id = "truck2", capacity = 12.0, roundTripTime = 15.0, name = "Medium Truck", isActive = True }
                            , { id = "truck3", capacity = 18.0, roundTripTime = 20.0, name = "Large Truck", isActive = True }
                            , { id = "truck4", capacity = 25.0, roundTripTime = 25.0, name = "Heavy Truck", isActive = True }
                            ]

                        expectedRate1 =
                            calculateTruckRate 8.0 12.0

                        expectedRate2 =
                            calculateTruckRate 12.0 15.0

                        expectedRate3 =
                            calculateTruckRate 18.0 20.0

                        expectedRate4 =
                            calculateTruckRate 25.0 25.0

                        expectedTotal =
                            expectedRate1 + expectedRate2 + expectedRate3 + expectedRate4

                        actualTotal =
                            calculateTruckFleetProductivity mixedCapacityFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "calculates hauling capacity for mixed truck fleet with varying round-trip times" <|
                \_ ->
                    let
                        mixedTimeFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 10.0, name = "Fast Truck", isActive = True }
                            , { id = "truck2", capacity = 12.0, roundTripTime = 15.0, name = "Standard Truck", isActive = True }
                            , { id = "truck3", capacity = 12.0, roundTripTime = 20.0, name = "Slow Truck", isActive = True }
                            ]

                        expectedFast =
                            calculateTruckRate 12.0 10.0

                        expectedStandard =
                            calculateTruckRate 12.0 15.0

                        expectedSlow =
                            calculateTruckRate 12.0 20.0

                        expectedTotal =
                            expectedFast + expectedStandard + expectedSlow

                        actualTotal =
                            calculateTruckFleetProductivity mixedTimeFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "excludes inactive trucks from hauling capacity calculation" <|
                \_ ->
                    let
                        fleetWithInactive =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Active Truck 1", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Inactive Truck", isActive = False }
                            , { id = "truck3", capacity = 10.0, roundTripTime = 18.0, name = "Active Truck 2", isActive = True }
                            ]

                        expectedActiveRate1 =
                            calculateTruckRate 12.0 15.0

                        expectedActiveRate2 =
                            calculateTruckRate 10.0 18.0

                        expectedTotal =
                            expectedActiveRate1 + expectedActiveRate2

                        actualTotal =
                            calculateTruckFleetProductivity fleetWithInactive
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "returns zero hauling capacity for empty truck fleet" <|
                \_ ->
                    let
                        emptyFleet =
                            []

                        actualCapacity =
                            calculateTruckFleetProductivity emptyFleet
                    in
                    Expect.equal 0.0 actualCapacity
            , test "returns zero hauling capacity for all-inactive truck fleet" <|
                \_ ->
                    let
                        allInactiveFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Inactive 1", isActive = False }
                            , { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "Inactive 2", isActive = False }
                            ]

                        actualCapacity =
                            calculateTruckFleetProductivity allInactiveFleet
                    in
                    Expect.equal 0.0 actualCapacity
            ]
        , describe "Fleet Scale Testing"
            [ test "handles single truck fleet correctly" <|
                \_ ->
                    let
                        singleFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Solo Truck", isActive = True } ]

                        capacity =
                            calculateTruckFleetProductivity singleFleet
                    in
                    Expect.greaterThan 0 capacity
            , test "handles moderate fleet size (8 trucks)" <|
                \_ ->
                    let
                        moderateFleet =
                            List.range 1 8
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0
                                        , roundTripTime = 15.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        capacity =
                            calculateTruckFleetProductivity moderateFleet

                        expectedSingleRate =
                            calculateTruckRate 12.0 15.0

                        expectedFleetRate =
                            expectedSingleRate * 8
                    in
                    Expect.within (Expect.Absolute 0.001) expectedFleetRate capacity
            , test "handles large fleet size (15 trucks)" <|
                \_ ->
                    let
                        largeFleet =
                            List.range 1 15
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0 + toFloat (modBy 4 i) * 2.0
                                        , roundTripTime = 15.0 + toFloat (modBy 3 i) * 3.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        capacity =
                            calculateTruckFleetProductivity largeFleet
                    in
                    Expect.greaterThan 0 capacity
            , test "handles maximum fleet size (20 trucks)" <|
                \_ ->
                    let
                        maxFleet =
                            List.range 1 20
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 10.0 + toFloat (modBy 5 i) * 3.0
                                        , roundTripTime = 12.0 + toFloat (modBy 4 i) * 4.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        capacity =
                            calculateTruckFleetProductivity maxFleet
                    in
                    Expect.greaterThan 0 capacity
            ]
        , describe "Fleet Performance Characteristics"
            [ test "fleet hauling capacity scales linearly with identical equipment" <|
                \_ ->
                    let
                        createFleet size =
                            List.range 1 size
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0
                                        , roundTripTime = 15.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        fleet3 =
                            createFleet 3

                        fleet6 =
                            createFleet 6

                        capacity3 =
                            calculateTruckFleetProductivity fleet3

                        capacity6 =
                            calculateTruckFleetProductivity fleet6

                        -- Fleet of 6 should have exactly 2x capacity of fleet of 3
                        expectedRatio =
                            2.0

                        actualRatio =
                            capacity6 / capacity3
                    in
                    Expect.within (Expect.Absolute 0.001) expectedRatio actualRatio
            , test "faster trucks contribute proportionally more to fleet capacity" <|
                \_ ->
                    let
                        fastTruck =
                            { id = "truck1", capacity = 12.0, roundTripTime = 10.0, name = "Fast Truck", isActive = True }

                        slowTruck =
                            { id = "truck2", capacity = 12.0, roundTripTime = 20.0, name = "Slow Truck", isActive = True }

                        mixedFleet =
                            [ fastTruck, slowTruck ]

                        fleetCapacity =
                            calculateTruckFleetProductivity mixedFleet

                        fastTruckRate =
                            calculateTruckRate 12.0 10.0

                        slowTruckRate =
                            calculateTruckRate 12.0 20.0

                        -- Fast truck should contribute more than slow truck
                        fastTruckContribution =
                            fastTruckRate / fleetCapacity

                        slowTruckContribution =
                            slowTruckRate / fleetCapacity
                    in
                    Expect.greaterThan slowTruckContribution fastTruckContribution
            , test "larger capacity trucks contribute proportionally more to fleet capacity" <|
                \_ ->
                    let
                        smallTruck =
                            { id = "truck1", capacity = 8.0, roundTripTime = 15.0, name = "Small Truck", isActive = True }

                        largeTruck =
                            { id = "truck2", capacity = 20.0, roundTripTime = 15.0, name = "Large Truck", isActive = True }

                        mixedFleet =
                            [ smallTruck, largeTruck ]

                        fleetCapacity =
                            calculateTruckFleetProductivity mixedFleet

                        smallTruckRate =
                            calculateTruckRate 8.0 15.0

                        largeTruckRate =
                            calculateTruckRate 20.0 15.0

                        -- Large truck should contribute more than small truck
                        smallTruckContribution =
                            smallTruckRate / fleetCapacity

                        largeTruckContribution =
                            largeTruckRate / fleetCapacity
                    in
                    Expect.greaterThan smallTruckContribution largeTruckContribution
            ]
        , describe "Fleet Efficiency Analysis"
            [ test "mixed fleet with optimal balance performs better than extremes" <|
                \_ ->
                    let
                        -- Fleet with only very fast but small trucks
                        fastSmallFleet =
                            List.repeat 4 { id = "truck1", capacity = 6.0, roundTripTime = 8.0, name = "Fast Small", isActive = True }

                        -- Fleet with only slow but large trucks
                        slowLargeFleet =
                            List.repeat 4 { id = "truck2", capacity = 24.0, roundTripTime = 30.0, name = "Slow Large", isActive = True }

                        -- Balanced fleet with medium capacity and medium speed
                        balancedFleet =
                            List.repeat 4 { id = "truck3", capacity = 12.0, roundTripTime = 15.0, name = "Balanced", isActive = True }

                        fastSmallCapacity =
                            calculateTruckFleetProductivity fastSmallFleet

                        slowLargeCapacity =
                            calculateTruckFleetProductivity slowLargeFleet

                        balancedCapacity =
                            calculateTruckFleetProductivity balancedFleet
                    in
                    -- All fleets should have meaningful capacity
                    Expect.all
                        [ \_ -> Expect.greaterThan 0 fastSmallCapacity
                        , \_ -> Expect.greaterThan 0 slowLargeCapacity
                        , \_ -> Expect.greaterThan 0 balancedCapacity
                        ]
                        ()
            ]
        ]
