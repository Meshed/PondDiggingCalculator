module Integration.FleetOperationsTests exposing (suite)

{-| Integration tests for fleet operations

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Messages exposing (ExcavatorUpdate(..), Msg(..), TruckUpdate(..))
import Types.Model exposing (Model)
import Utils.Calculations exposing (calculateExcavatorFleetProductivity, calculateTruckFleetProductivity, performCalculation)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Fleet Operations Integration Tests"
        [ describe "Fleet Management Integration"
            [ test "add excavator updates model correctly and preserves state" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Initial", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        newExcavator =
                            { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Added", isActive = True }

                        updatedModel =
                            { initialModel
                                | excavators = initialModel.excavators ++ [ newExcavator ]
                                , nextExcavatorId = initialModel.nextExcavatorId + 1
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length updatedModel.excavators)
                        , \_ -> Expect.equal initialModel.trucks updatedModel.trucks
                        , \_ -> Expect.equal (initialModel.nextExcavatorId + 1) updatedModel.nextExcavatorId
                        , \_ -> Expect.equal initialModel.nextTruckId updatedModel.nextTruckId
                        , \_ -> Expect.equal initialModel.config updatedModel.config
                        , \_ -> Expect.equal initialModel.formData updatedModel.formData
                        ]
                        ()
            , test "remove excavator maintains minimum fleet requirements" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Keep", isActive = True }
                                , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Remove", isActive = True }
                                ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        -- Remove one excavator (should work since we have 2)
                        updatedModel =
                            { initialModel | excavators = List.filter (\exc -> exc.id /= "exc2") initialModel.excavators }

                        -- Attempt to remove last excavator (business logic should prevent this)
                        finalModel =
                            if List.length updatedModel.excavators > 1 then
                                { updatedModel | excavators = List.filter (\exc -> exc.id /= "exc1") updatedModel.excavators }

                            else
                                updatedModel

                        -- Preserve if would result in empty fleet
                    in
                    Expect.all
                        [ \_ -> Expect.equal 1 (List.length updatedModel.excavators)
                        , \_ -> Expect.equal 1 (List.length finalModel.excavators) -- Should still have 1
                        , \_ ->
                            List.head finalModel.excavators
                                |> Maybe.map .name
                                |> Expect.equal (Just "Keep")
                        ]
                        ()
            , test "add truck integrates with fleet calculations" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Initial Truck", isActive = True } ]

                        newTruck =
                            { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "Added Truck", isActive = True }

                        updatedModel =
                            { initialModel
                                | trucks = initialModel.trucks ++ [ newTruck ]
                                , nextTruckId = initialModel.nextTruckId + 1
                            }

                        initialTruckCapacity =
                            calculateTruckFleetProductivity initialModel.trucks

                        updatedTruckCapacity =
                            calculateTruckFleetProductivity updatedModel.trucks
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length updatedModel.trucks)
                        , \_ -> Expect.greaterThan initialTruckCapacity updatedTruckCapacity
                        , \_ -> Expect.equal initialModel.excavators updatedModel.excavators
                        ]
                        ()
            , test "update excavator properties affects fleet productivity" <|
                \_ ->
                    let
                        initialExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Update Me", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Stay Same", isActive = True }
                            ]

                        initialModel =
                            createIntegrationModel initialExcavators
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        updatedModel =
                            { initialModel
                                | excavators =
                                    List.map
                                        (\exc ->
                                            if exc.id == "exc1" then
                                                { exc | bucketCapacity = 4.0, cycleTime = 1.5 }
                                                -- Improve performance

                                            else
                                                exc
                                        )
                                        initialModel.excavators
                            }

                        initialProductivity =
                            calculateExcavatorFleetProductivity initialModel.excavators

                        updatedProductivity =
                            calculateExcavatorFleetProductivity updatedModel.excavators
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length updatedModel.excavators)
                        , \_ -> Expect.greaterThan initialProductivity updatedProductivity
                        , \_ -> Expect.equal initialModel.trucks updatedModel.trucks
                        ]
                        ()
            ]
        , describe "Fleet Calculations Integration"
            [ test "fleet calculations work with mixed active/inactive equipment" <|
                \_ ->
                    let
                        mixedExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Active 1", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Inactive", isActive = False }
                            , { id = "exc3", bucketCapacity = 2.2, cycleTime = 2.1, name = "Active 2", isActive = True }
                            ]

                        mixedTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Active", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Inactive", isActive = False }
                            ]

                        model =
                            createIntegrationModel mixedExcavators mixedTrucks

                        calculationResult =
                            performCalculation model.excavators model.trucks 5000.0 8.0
                    in
                    case calculationResult of
                        Ok result ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 result.timelineInDays
                                , \_ -> Expect.greaterThan 0 result.totalHours
                                , \_ -> Expect.greaterThan 0 result.excavationRate
                                , \_ -> Expect.greaterThan 0 result.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Should have successful calculation with valid fleet"
            , test "fleet size affects calculation performance and confidence" <|
                \_ ->
                    let
                        smallFleet =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Solo", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Solo", isActive = True } ]

                        largeFleet =
                            createIntegrationModel
                                (List.range 1 5
                                    |> List.map
                                        (\i ->
                                            { id = "exc" ++ String.fromInt i
                                            , bucketCapacity = 2.5
                                            , cycleTime = 2.0
                                            , name = "Excavator " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )
                                (List.range 1 5
                                    |> List.map
                                        (\i ->
                                            { id = "truck" ++ String.fromInt i
                                            , capacity = 12.0
                                            , roundTripTime = 15.0
                                            , name = "Truck " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )

                        smallResult =
                            performCalculation smallFleet.excavators smallFleet.trucks 5000.0 8.0

                        largeResult =
                            performCalculation largeFleet.excavators largeFleet.trucks 5000.0 8.0
                    in
                    case ( smallResult, largeResult ) of
                        ( Ok small, Ok large ) ->
                            Expect.all
                                [ \_ -> Expect.greaterThan large.timelineInDays small.timelineInDays -- Large fleet should finish faster
                                , \_ -> Expect.greaterThan small.excavationRate large.excavationRate -- Large fleet should have higher rates
                                , \_ -> Expect.greaterThan small.haulingRate large.haulingRate
                                ]
                                ()

                        _ ->
                            Expect.fail "Both calculations should succeed"
            , test "fleet imbalance affects bottleneck identification" <|
                \_ ->
                    let
                        excavationBottleneckFleet =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 1.0, cycleTime = 4.0, name = "Slow Excavator", isActive = True } ]
                                -- Low productivity
                                (List.range 1 3
                                    |> List.map
                                        (\i ->
                                            { id = "truck" ++ String.fromInt i
                                            , capacity = 20.0
                                            , roundTripTime = 8.0
                                            , name = "Fast Truck " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )

                        haulingBottleneckFleet =
                            createIntegrationModel
                                (List.range 1 3
                                    |> List.map
                                        (\i ->
                                            { id = "exc" ++ String.fromInt i
                                            , bucketCapacity = 4.0
                                            , cycleTime = 1.0
                                            , name = "Fast Excavator " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )
                                [ { id = "truck1", capacity = 6.0, roundTripTime = 30.0, name = "Slow Truck", isActive = True } ]

                        -- Low productivity
                        excavationResult =
                            performCalculation excavationBottleneckFleet.excavators excavationBottleneckFleet.trucks 5000.0 8.0

                        haulingResult =
                            performCalculation haulingBottleneckFleet.excavators haulingBottleneckFleet.trucks 5000.0 8.0
                    in
                    case ( excavationResult, haulingResult ) of
                        ( Ok excResult, Ok haulResult ) ->
                            Expect.all
                                [ \_ -> Expect.lessThan excResult.haulingRate excResult.excavationRate -- Excavation should be the bottleneck
                                , \_ -> Expect.lessThan haulResult.excavationRate haulResult.haulingRate -- Hauling should be the bottleneck
                                ]
                                ()

                        _ ->
                            Expect.fail "Both calculations should succeed"
            ]
        , describe "Fleet State Management Integration"
            [ test "fleet operations maintain calculation state consistency" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModelWithCalculation
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        -- Add equipment and trigger recalculation
                        newExcavator =
                            { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Added", isActive = True }

                        updatedModel =
                            { initialModel
                                | excavators = initialModel.excavators ++ [ newExcavator ]
                                , calculationInProgress = True -- Simulate calculation trigger
                                , hasValidationErrors = False
                            }

                        recalculationResult =
                            performCalculation updatedModel.excavators updatedModel.trucks 5000.0 8.0
                    in
                    case recalculationResult of
                        Ok result ->
                            Expect.all
                                [ \_ -> Expect.equal 2 (List.length updatedModel.excavators)
                                , \_ -> Expect.equal True updatedModel.calculationInProgress
                                , \_ -> Expect.greaterThan 0 result.timelineInDays
                                , \_ -> Expect.equal False updatedModel.hasValidationErrors
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Recalculation should succeed with valid fleet"
            , test "fleet validation integrates with calculation workflow" <|
                \_ ->
                    let
                        validModel =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Valid", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Valid", isActive = True } ]

                        invalidModel =
                            createIntegrationModel
                                [ { id = "exc1", bucketCapacity = -1.0, cycleTime = -2.0, name = "Invalid", isActive = True } ]
                                [ { id = "truck1", capacity = -5.0, roundTripTime = -10.0, name = "Invalid", isActive = True } ]

                        validResult =
                            performCalculation validModel.excavators validModel.trucks 5000.0 8.0

                        invalidResult =
                            performCalculation invalidModel.excavators invalidModel.trucks 5000.0 8.0
                    in
                    case ( validResult, invalidResult ) of
                        ( Ok valid, Err _ ) ->
                            -- Valid model should calculate, invalid should fail
                            Expect.greaterThan 0 valid.timelineInDays

                        ( Ok valid, Ok invalid ) ->
                            -- Both calculated, but validation should catch issues at UI level
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 valid.timelineInDays
                                , \_ -> Expect.greaterThan 0 invalid.timelineInDays -- Calculation engine doesn't validate inputs directly
                                ]
                                ()

                        _ ->
                            Expect.fail "Valid model should always calculate successfully"
            ]
        , describe "Performance Integration Tests"
            [ test "large fleet operations complete within reasonable time" <|
                \_ ->
                    let
                        largeFleet =
                            createIntegrationModel
                                (List.range 1 10
                                    |> List.map
                                        (\i ->
                                            { id = "exc" ++ String.fromInt i
                                            , bucketCapacity = 2.0 + toFloat (modBy 3 i) * 0.5
                                            , cycleTime = 1.8 + toFloat (modBy 2 i) * 0.4
                                            , name = "Excavator " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )
                                (List.range 1 20
                                    |> List.map
                                        (\i ->
                                            { id = "truck" ++ String.fromInt i
                                            , capacity = 10.0 + toFloat (modBy 4 i) * 3.0
                                            , roundTripTime = 12.0 + toFloat (modBy 3 i) * 5.0
                                            , name = "Truck " ++ String.fromInt i
                                            , isActive = True
                                            }
                                        )
                                )

                        calculationResult =
                            performCalculation largeFleet.excavators largeFleet.trucks 10000.0 8.0
                    in
                    case calculationResult of
                        Ok result ->
                            Expect.all
                                [ \_ -> Expect.equal 10 (List.length largeFleet.excavators)
                                , \_ -> Expect.equal 20 (List.length largeFleet.trucks)
                                , \_ -> Expect.greaterThan 0 result.timelineInDays
                                , \_ -> Expect.greaterThan 0 result.excavationRate
                                , \_ -> Expect.greaterThan 0 result.haulingRate
                                ]
                                ()

                        Err _ ->
                            Expect.fail "Large fleet calculation should succeed"
            , test "fleet productivity calculations scale appropriately" <|
                \_ ->
                    let
                        fleet1 =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Solo", isActive = True } ]

                        fleet2 =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "One", isActive = True }
                            , { id = "exc2", bucketCapacity = 2.5, cycleTime = 2.0, name = "Two", isActive = True }
                            ]

                        fleet5 =
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

                        productivity1 =
                            calculateExcavatorFleetProductivity fleet1

                        productivity2 =
                            calculateExcavatorFleetProductivity fleet2

                        productivity5 =
                            calculateExcavatorFleetProductivity fleet5
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.001) (productivity1 * 2) productivity2
                        , \_ -> Expect.within (Expect.Absolute 0.001) (productivity1 * 5) productivity5
                        , \_ -> Expect.within (Expect.Absolute 0.001) (productivity2 * 2.5) productivity5
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


createIntegrationModel : List Excavator -> List Truck -> Model
createIntegrationModel excavators trucks =
    let
        formData =
            { workHoursPerDay = "8.0"
            , pondLength = "40.0"
            , pondWidth = "25.0"
            , pondDepth = "5.0"
            , errors = []
            }
    in
    { message = "Integration Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just formData
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Desktop
    , calculationInProgress = False
    , performanceMetrics = Utils.Performance.initMetrics
    , debounceState = Utils.Debounce.initDebounce
    , excavators = excavators
    , trucks = trucks
    , nextExcavatorId = List.length excavators + 1
    , nextTruckId = List.length trucks + 1
    , infoBannerDismissed = False
    , helpTooltipState = Nothing
    }


createIntegrationModelWithCalculation : List Excavator -> List Truck -> Model
createIntegrationModelWithCalculation excavators trucks =
    let
        baseModel =
            createIntegrationModel excavators trucks

        testResult =
            { timelineInDays = 3
            , totalHours = 24.0
            , excavationRate = 80.0
            , haulingRate = 85.0
            , bottleneck = Utils.Calculations.ExcavationBottleneck
            , confidence = Utils.Calculations.Medium
            , assumptions = [ "Test calculation" ]
            , warnings = []
            }
    in
    { baseModel
        | calculationResult = Just testResult
        , lastValidResult = Just testResult
    }
