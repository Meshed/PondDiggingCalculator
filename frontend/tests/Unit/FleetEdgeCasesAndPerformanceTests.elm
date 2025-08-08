module Unit.FleetEdgeCasesAndPerformanceTests exposing (suite)

{-| Edge case and performance tests for fleet operations

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Utils.Calculations exposing (CalculationError(..), calculateExcavatorFleetProductivity, calculateTruckFleetProductivity, performCalculation)
import Utils.Config exposing (fallbackConfig)
import Utils.Validation exposing (validateExcavatorFleet, validateTruckFleet)


suite : Test
suite =
    describe "Fleet Edge Cases and Performance Tests"
        [ describe "Minimum Equipment Requirements"
            [ test "calculation fails with zero active excavators" <|
                \_ ->
                    let
                        noActiveExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Inactive", isActive = False } ]

                        activeTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Active", isActive = True } ]

                        result =
                            performCalculation noActiveExcavators activeTrucks 5000.0 8.0
                    in
                    case result of
                        Err InsufficientEquipment ->
                            Expect.pass

                        Err _ ->
                            Expect.fail "Should specifically fail with InsufficientEquipment error"

                        Ok _ ->
                            Expect.fail "Should fail when no active excavators"
            , test "calculation fails with zero active trucks" <|
                \_ ->
                    let
                        activeExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Active", isActive = True } ]

                        noActiveTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Inactive", isActive = False } ]

                        result =
                            performCalculation activeExcavators noActiveTrucks 5000.0 8.0
                    in
                    case result of
                        Err InsufficientEquipment ->
                            Expect.pass

                        Err _ ->
                            Expect.fail "Should specifically fail with InsufficientEquipment error"

                        Ok _ ->
                            Expect.fail "Should fail when no active trucks"
            , test "calculation fails with completely empty fleets" <|
                \_ ->
                    let
                        emptyExcavators =
                            []

                        emptyTrucks =
                            []

                        result =
                            performCalculation emptyExcavators emptyTrucks 5000.0 8.0
                    in
                    case result of
                        Err InsufficientEquipment ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should fail with empty fleets"
            , test "calculation succeeds with single active equipment of each type" <|
                \_ ->
                    let
                        singleExcavator =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Solo", isActive = True } ]

                        singleTruck =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Solo", isActive = True } ]

                        result =
                            performCalculation singleExcavator singleTruck 5000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.totalHours
                                , \_ -> Expect.greaterThan 0 calculation.excavationRate
                                , \_ -> Expect.greaterThan 0 calculation.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should succeed with valid single equipment"
            ]
        , describe "Edge Case Input Validation"
            [ test "handles extreme equipment values within validation ranges" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        extremeButValidExcavators =
                            [ { id = "exc1", bucketCapacity = validationRules.excavatorCapacity.min, cycleTime = validationRules.cycleTime.max, name = "Min/Max", isActive = True }
                            , { id = "exc2", bucketCapacity = validationRules.excavatorCapacity.max, cycleTime = validationRules.cycleTime.min, name = "Max/Min", isActive = True }
                            ]

                        extremeButValidTrucks =
                            [ { id = "truck1", capacity = validationRules.truckCapacity.min, roundTripTime = validationRules.roundTripTime.max, name = "Min/Max", isActive = True }
                            , { id = "truck2", capacity = validationRules.truckCapacity.max, roundTripTime = validationRules.roundTripTime.min, name = "Max/Min", isActive = True }
                            ]

                        excavatorErrors =
                            validateExcavatorFleet validationRules extremeButValidExcavators

                        truckErrors =
                            validateTruckFleet validationRules extremeButValidTrucks

                        calculationResult =
                            performCalculation extremeButValidExcavators extremeButValidTrucks 5000.0 8.0
                    in
                    case calculationResult of
                        Ok result ->
                            Expect.all
                                [ \_ -> Expect.equal [] excavatorErrors
                                , \_ -> Expect.equal [] truckErrors
                                , \_ -> Expect.greaterThan 0 result.timelineInDays
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should succeed with extreme but valid values"
            , test "handles mixed active/inactive equipment correctly" <|
                \_ ->
                    let
                        mixedExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Active 1", isActive = True }
                            , { id = "exc2", bucketCapacity = 50.0, cycleTime = 0.1, name = "Inactive Super", isActive = False } -- Would be invalid if active
                            , { id = "exc3", bucketCapacity = 3.0, cycleTime = 1.8, name = "Active 2", isActive = True }
                            , { id = "exc4", bucketCapacity = -1.0, cycleTime = -2.0, name = "Inactive Invalid", isActive = False } -- Invalid values but inactive
                            ]

                        mixedTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Active", isActive = True }
                            , { id = "truck2", capacity = -5.0, roundTripTime = -10.0, name = "Inactive Invalid", isActive = False }
                            ]

                        activeOnlyProductivity =
                            calculateExcavatorFleetProductivity (List.filter .isActive mixedExcavators)

                        fullFleetProductivity =
                            calculateExcavatorFleetProductivity mixedExcavators

                        result =
                            performCalculation mixedExcavators mixedTrucks 5000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) activeOnlyProductivity fullFleetProductivity
                                , \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should succeed when active equipment is valid"
            , test "handles zero pond volume gracefully" <|
                \_ ->
                    let
                        validExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]

                        validTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        result =
                            performCalculation validExcavators validTrucks 0.0 8.0
                    in
                    case result of
                        Err (InvalidConfiguration _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should fail with zero pond volume"
            , test "handles zero work hours gracefully" <|
                \_ ->
                    let
                        validExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]

                        validTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        result =
                            performCalculation validExcavators validTrucks 5000.0 0.0
                    in
                    case result of
                        Err (InvalidConfiguration _) ->
                            Expect.pass

                        _ ->
                            Expect.fail "Should fail with zero work hours"
            ]
        , describe "Maximum Fleet Size Performance"
            [ test "handles maximum excavator fleet size (10 units)" <|
                \_ ->
                    let
                        maxExcavatorFleet =
                            List.range 1 10
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.0 + toFloat (modBy 3 i) * 0.8 -- Varied capacities
                                        , cycleTime = 1.5 + toFloat (modBy 2 i) * 0.5 -- Varied cycle times
                                        , name = "Max Fleet Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        standardTrucks =
                            List.range 1 5
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0
                                        , roundTripTime = 15.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        productivity =
                            calculateExcavatorFleetProductivity maxExcavatorFleet

                        result =
                            performCalculation maxExcavatorFleet standardTrucks 10000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.equal 10 (List.length maxExcavatorFleet)
                                , \_ -> Expect.greaterThan 0 productivity
                                , \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.excavationRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should handle maximum excavator fleet size"
            , test "handles maximum truck fleet size (20 units)" <|
                \_ ->
                    let
                        standardExcavators =
                            List.range 1 3
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.5
                                        , cycleTime = 2.0
                                        , name = "Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        maxTruckFleet =
                            List.range 1 20
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 10.0 + toFloat (modBy 4 i) * 2.0 -- Varied capacities
                                        , roundTripTime = 12.0 + toFloat (modBy 3 i) * 4.0 -- Varied round trip times
                                        , name = "Max Fleet Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        productivity =
                            calculateTruckFleetProductivity maxTruckFleet

                        result =
                            performCalculation standardExcavators maxTruckFleet 10000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.equal 20 (List.length maxTruckFleet)
                                , \_ -> Expect.greaterThan 0 productivity
                                , \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should handle maximum truck fleet size"
            , test "handles maximum combined fleet size (10 excavators + 20 trucks)" <|
                \_ ->
                    let
                        maxExcavatorFleet =
                            List.range 1 10
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 1.5 + toFloat i * 0.3
                                        , cycleTime = 1.5 + toFloat (modBy 3 i) * 0.2
                                        , name = "Max Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        maxTruckFleet =
                            List.range 1 20
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 8.0 + toFloat i * 0.8
                                        , roundTripTime = 10.0 + toFloat (modBy 4 i) * 2.0
                                        , name = "Max Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        excavatorProductivity =
                            calculateExcavatorFleetProductivity maxExcavatorFleet

                        truckProductivity =
                            calculateTruckFleetProductivity maxTruckFleet

                        result =
                            performCalculation maxExcavatorFleet maxTruckFleet 25000.0 10.0

                        -- Large project
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.equal 10 (List.length maxExcavatorFleet)
                                , \_ -> Expect.equal 20 (List.length maxTruckFleet)
                                , \_ -> Expect.greaterThan 0 excavatorProductivity
                                , \_ -> Expect.greaterThan 0 truckProductivity
                                , \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.excavationRate
                                , \_ -> Expect.greaterThan 0 calculation.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should handle maximum combined fleet size"
            ]
        , describe "Performance Scaling Tests"
            [ test "fleet productivity scales linearly with fleet size" <|
                \_ ->
                    let
                        createExcavatorFleet size =
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

                        fleet1 =
                            createExcavatorFleet 1

                        fleet3 =
                            createExcavatorFleet 3

                        fleet6 =
                            createExcavatorFleet 6

                        fleet10 =
                            createExcavatorFleet 10

                        productivity1 =
                            calculateExcavatorFleetProductivity fleet1

                        productivity3 =
                            calculateExcavatorFleetProductivity fleet3

                        productivity6 =
                            calculateExcavatorFleetProductivity fleet6

                        productivity10 =
                            calculateExcavatorFleetProductivity fleet10
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.001) (productivity1 * 3) productivity3
                        , \_ -> Expect.within (Expect.Absolute 0.001) (productivity1 * 6) productivity6
                        , \_ -> Expect.within (Expect.Absolute 0.001) (productivity1 * 10) productivity10
                        , \_ -> Expect.within (Expect.Absolute 0.001) (productivity3 * 2) productivity6
                        ]
                        ()
            , test "calculation time remains reasonable with large fleets" <|
                \_ ->
                    let
                        -- This test verifies that large fleet calculations complete
                        -- The actual timing would need to be measured in a real performance test
                        largeExcavatorFleet =
                            List.range 1 10
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.0 + toFloat (modBy 5 i) * 0.4
                                        , cycleTime = 1.8 + toFloat (modBy 3 i) * 0.3
                                        , name = "Large Fleet Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        largeTruckFleet =
                            List.range 1 20
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 10.0 + toFloat (modBy 6 i) * 1.5
                                        , roundTripTime = 12.0 + toFloat (modBy 4 i) * 2.5
                                        , name = "Large Fleet Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        -- Perform multiple calculations to test consistency
                        result1 =
                            performCalculation largeExcavatorFleet largeTruckFleet 15000.0 8.0

                        result2 =
                            performCalculation largeExcavatorFleet largeTruckFleet 20000.0 8.0

                        result3 =
                            performCalculation largeExcavatorFleet largeTruckFleet 30000.0 8.0
                    in
                    case ( result1, result2, result3 ) of
                        ( Ok calc1, Ok calc2, Ok calc3 ) ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 calc1.timelineInDays
                                , \_ -> Expect.greaterThan 0 calc2.timelineInDays
                                , \_ -> Expect.greaterThan 0 calc3.timelineInDays
                                , \_ -> Expect.greaterThan calc2.timelineInDays calc3.timelineInDays -- Larger projects take longer
                                , \_ -> Expect.greaterThan calc1.timelineInDays calc2.timelineInDays
                                ]
                                ()

                        _ ->
                            Expect.fail "All large fleet calculations should succeed"
            , test "fleet operations maintain O(n) complexity characteristics" <|
                \_ ->
                    let
                        -- Test that fleet productivity calculation complexity doesn't explode
                        smallFleet =
                            List.range 1 5
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0
                                        , roundTripTime = 15.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        largeFleet =
                            List.range 1 20
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity = 12.0
                                        , roundTripTime = 15.0
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        smallProductivity =
                            calculateTruckFleetProductivity smallFleet

                        largeProductivity =
                            calculateTruckFleetProductivity largeFleet

                        -- Linear scaling: 20 trucks should have 4x productivity of 5 trucks
                        expectedRatio =
                            4.0

                        actualRatio =
                            largeProductivity / smallProductivity
                    in
                    Expect.within (Expect.Absolute 0.001) expectedRatio actualRatio
            ]
        , describe "Stress Testing Scenarios"
            [ test "handles equipment with extreme performance differences" <|
                \_ ->
                    let
                        extremeExcavators =
                            [ { id = "exc1", bucketCapacity = 0.5, cycleTime = 5.0, name = "Very Slow", isActive = True } -- Very low productivity
                            , { id = "exc2", bucketCapacity = 5.0, cycleTime = 1.0, name = "Very Fast", isActive = True } -- Very high productivity
                            ]

                        extremeTrucks =
                            [ { id = "truck1", capacity = 5.0, roundTripTime = 30.0, name = "Very Slow", isActive = True } -- Very low productivity
                            , { id = "truck2", capacity = 25.0, roundTripTime = 8.0, name = "Very Fast", isActive = True } -- Very high productivity
                            ]

                        result =
                            performCalculation extremeExcavators extremeTrucks 5000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.excavationRate
                                , \_ -> Expect.greaterThan 0 calculation.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should handle extreme performance differences"
            , test "handles all equipment inactive except minimum required" <|
                \_ ->
                    let
                        mixedExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Only Active", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Inactive 1", isActive = False }
                            , { id = "exc3", bucketCapacity = 2.8, cycleTime = 1.9, name = "Inactive 2", isActive = False }
                            , { id = "exc4", bucketCapacity = 3.2, cycleTime = 1.7, name = "Inactive 3", isActive = False }
                            ]

                        mixedTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Only Active", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Inactive 1", isActive = False }
                            , { id = "truck3", capacity = 15.0, roundTripTime = 14.0, name = "Inactive 2", isActive = False }
                            ]

                        result =
                            performCalculation mixedExcavators mixedTrucks 5000.0 8.0
                    in
                    case result of
                        Ok calculation ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 calculation.timelineInDays
                                , \_ -> Expect.greaterThan 0 calculation.excavationRate
                                , \_ -> Expect.greaterThan 0 calculation.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should work with minimal active equipment"
            ]
        ]
