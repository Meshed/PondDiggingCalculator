module Unit.ExcavatorFleetTests exposing (suite)

{-| Unit tests for excavator fleet functionality

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.Equipment exposing (EquipmentId, Excavator)
import Utils.Calculations exposing (calculateExcavatorFleetProductivity, calculateExcavatorRate)


suite : Test
suite =
    describe "Excavator Fleet Tests"
        [ describe "Fleet Productivity Calculations"
            [ test "calculates productivity for single excavator fleet" <|
                \_ ->
                    let
                        singleExcavator =
                            [ { id = "exc1"
                              , bucketCapacity = 2.5
                              , cycleTime = 2.0
                              , name = "CAT 320"
                              , isActive = True
                              }
                            ]

                        expectedRate =
                            calculateExcavatorRate 2.5 2.0

                        actualRate =
                            calculateExcavatorFleetProductivity singleExcavator
                    in
                    Expect.within (Expect.Absolute 0.001) expectedRate actualRate
            , test "calculates productivity for multiple excavator fleet with same specs" <|
                \_ ->
                    let
                        uniformFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "CAT 320", isActive = True }
                            , { id = "exc2", bucketCapacity = 2.5, cycleTime = 2.0, name = "CAT 320", isActive = True }
                            , { id = "exc3", bucketCapacity = 2.5, cycleTime = 2.0, name = "CAT 320", isActive = True }
                            ]

                        singleExcavatorRate =
                            calculateExcavatorRate 2.5 2.0

                        expectedFleetRate =
                            singleExcavatorRate * 3

                        actualFleetRate =
                            calculateExcavatorFleetProductivity uniformFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedFleetRate actualFleetRate
            , test "calculates productivity for mixed excavator fleet with varying capacities" <|
                \_ ->
                    let
                        mixedFleet =
                            [ { id = "exc1", bucketCapacity = 1.5, cycleTime = 1.8, name = "Small Excavator", isActive = True }
                            , { id = "exc2", bucketCapacity = 2.5, cycleTime = 2.0, name = "Medium Excavator", isActive = True }
                            , { id = "exc3", bucketCapacity = 4.0, cycleTime = 2.5, name = "Large Excavator", isActive = True }
                            ]

                        expectedRate1 =
                            calculateExcavatorRate 1.5 1.8

                        expectedRate2 =
                            calculateExcavatorRate 2.5 2.0

                        expectedRate3 =
                            calculateExcavatorRate 4.0 2.5

                        expectedTotal =
                            expectedRate1 + expectedRate2 + expectedRate3

                        actualTotal =
                            calculateExcavatorFleetProductivity mixedFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "calculates productivity for mixed excavator fleet with varying cycle times" <|
                \_ ->
                    let
                        mixedCycleFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 1.5, name = "Fast Excavator", isActive = True }
                            , { id = "exc2", bucketCapacity = 2.5, cycleTime = 2.0, name = "Standard Excavator", isActive = True }
                            , { id = "exc3", bucketCapacity = 2.5, cycleTime = 3.0, name = "Slow Excavator", isActive = True }
                            ]

                        expectedFast =
                            calculateExcavatorRate 2.5 1.5

                        expectedStandard =
                            calculateExcavatorRate 2.5 2.0

                        expectedSlow =
                            calculateExcavatorRate 2.5 3.0

                        expectedTotal =
                            expectedFast + expectedStandard + expectedSlow

                        actualTotal =
                            calculateExcavatorFleetProductivity mixedCycleFleet
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "excludes inactive excavators from productivity calculation" <|
                \_ ->
                    let
                        fleetWithInactive =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Active Excavator", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.5, name = "Inactive Excavator", isActive = False }
                            , { id = "exc3", bucketCapacity = 2.0, cycleTime = 2.5, name = "Active Excavator 2", isActive = True }
                            ]

                        expectedActiveRate1 =
                            calculateExcavatorRate 2.5 2.0

                        expectedActiveRate2 =
                            calculateExcavatorRate 2.0 2.5

                        expectedTotal =
                            expectedActiveRate1 + expectedActiveRate2

                        actualTotal =
                            calculateExcavatorFleetProductivity fleetWithInactive
                    in
                    Expect.within (Expect.Absolute 0.001) expectedTotal actualTotal
            , test "returns zero productivity for empty excavator fleet" <|
                \_ ->
                    let
                        emptyFleet =
                            []

                        actualProductivity =
                            calculateExcavatorFleetProductivity emptyFleet
                    in
                    Expect.equal 0.0 actualProductivity
            , test "returns zero productivity for all-inactive excavator fleet" <|
                \_ ->
                    let
                        allInactiveFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Inactive 1", isActive = False }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.5, name = "Inactive 2", isActive = False }
                            ]

                        actualProductivity =
                            calculateExcavatorFleetProductivity allInactiveFleet
                    in
                    Expect.equal 0.0 actualProductivity
            ]
        , describe "Fleet Scale Testing"
            [ test "handles single excavator fleet correctly" <|
                \_ ->
                    let
                        singleFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Solo Excavator", isActive = True } ]

                        productivity =
                            calculateExcavatorFleetProductivity singleFleet
                    in
                    Expect.greaterThan 0 productivity
            , test "handles moderate fleet size (5 excavators)" <|
                \_ ->
                    let
                        moderateFleet =
                            List.range 1 5
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.5
                                        , cycleTime = 2.0
                                        , name = "Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        productivity =
                            calculateExcavatorFleetProductivity moderateFleet

                        expectedSingleRate =
                            calculateExcavatorRate 2.5 2.0

                        expectedFleetRate =
                            expectedSingleRate * 5
                    in
                    Expect.within (Expect.Absolute 0.001) expectedFleetRate productivity
            , test "handles maximum fleet size (10 excavators)" <|
                \_ ->
                    let
                        maxFleet =
                            List.range 1 10
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.5 + toFloat (modBy 3 i) * 0.5
                                        , cycleTime = 2.0 + toFloat (modBy 2 i) * 0.3
                                        , name = "Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        productivity =
                            calculateExcavatorFleetProductivity maxFleet
                    in
                    Expect.greaterThan 0 productivity
            ]
        , describe "Fleet Performance Characteristics"
            [ test "fleet productivity scales linearly with identical equipment" <|
                \_ ->
                    let
                        createFleet size =
                            List.range 1 size
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.5
                                        , cycleTime = 2.0
                                        , name = "Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        fleet2 =
                            createFleet 2

                        fleet4 =
                            createFleet 4

                        productivity2 =
                            calculateExcavatorFleetProductivity fleet2

                        productivity4 =
                            calculateExcavatorFleetProductivity fleet4

                        -- Fleet of 4 should have exactly 2x productivity of fleet of 2
                        expectedRatio =
                            2.0

                        actualRatio =
                            productivity4 / productivity2
                    in
                    Expect.within (Expect.Absolute 0.001) expectedRatio actualRatio
            , test "mixed fleet performance reflects individual equipment capabilities" <|
                \_ ->
                    let
                        highPerformanceExcavator =
                            { id = "exc1", bucketCapacity = 4.0, cycleTime = 1.5, name = "High Performance", isActive = True }

                        lowPerformanceExcavator =
                            { id = "exc2", bucketCapacity = 1.5, cycleTime = 3.0, name = "Low Performance", isActive = True }

                        mixedFleet =
                            [ highPerformanceExcavator, lowPerformanceExcavator ]

                        fleetProductivity =
                            calculateExcavatorFleetProductivity mixedFleet

                        highPerformanceRate =
                            calculateExcavatorRate 4.0 1.5

                        lowPerformanceRate =
                            calculateExcavatorRate 1.5 3.0

                        -- High performance excavator should contribute significantly more
                        highPerformanceContribution =
                            highPerformanceRate / fleetProductivity

                        lowPerformanceContribution =
                            lowPerformanceRate / fleetProductivity
                    in
                    Expect.greaterThan lowPerformanceContribution highPerformanceContribution
            ]
        ]
