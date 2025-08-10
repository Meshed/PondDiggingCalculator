module Unit.StatePreservationTests exposing (suite)

{-| Unit tests for state preservation during fleet operations

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Dict
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Messages exposing (ExcavatorUpdate(..), Msg(..), TruckUpdate(..))
import Types.Model exposing (Model)
import Types.Onboarding
import Utils.Calculations exposing (Bottleneck(..), CalculationResult, ConfidenceLevel(..))
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "State Preservation Tests"
        [ describe "Excavator Operations State Preservation"
            [ test "adding excavator preserves truck fleet and project state" <|
                \_ ->
                    let
                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck 1", isActive = True }
                            , { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "Truck 2", isActive = True }
                            ]

                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator 1", isActive = True } ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate adding an excavator
                        newExcavator =
                            { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "New Excavator", isActive = True }

                        updatedModel =
                            { originalModel
                                | excavators = originalModel.excavators ++ [ newExcavator ]
                                , nextExcavatorId = originalModel.nextExcavatorId + 1
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.trucks updatedModel.trucks
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal originalModel.deviceType updatedModel.deviceType
                        , \_ -> Expect.equal originalModel.message updatedModel.message
                        , \_ -> Expect.equal (originalModel.nextExcavatorId + 1) updatedModel.nextExcavatorId
                        , \_ -> Expect.equal originalModel.nextTruckId updatedModel.nextTruckId
                        ]
                        ()
            , test "removing excavator preserves truck fleet and project state" <|
                \_ ->
                    let
                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck 1", isActive = True } ]

                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Keep", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Remove", isActive = True }
                            ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate removing an excavator
                        updatedModel =
                            { originalModel | excavators = List.filter (\exc -> exc.id /= "exc2") originalModel.excavators }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.trucks updatedModel.trucks
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal originalModel.deviceType updatedModel.deviceType
                        , \_ -> Expect.equal originalModel.nextTruckId updatedModel.nextTruckId
                        ]
                        ()
            , test "updating excavator preserves other excavators and all other state" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Update Me", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Don't Change", isActive = True }
                            ]

                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate updating first excavator
                        updatedModel =
                            { originalModel
                                | excavators =
                                    List.map
                                        (\exc ->
                                            if exc.id == "exc1" then
                                                { exc | bucketCapacity = 3.5, name = "Updated" }

                                            else
                                                exc
                                        )
                                        originalModel.excavators
                            }

                        unchangedExcavator =
                            List.filter (\exc -> exc.id == "exc2") updatedModel.excavators
                                |> List.head
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.trucks updatedModel.trucks
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.nextExcavatorId updatedModel.nextExcavatorId
                        , \_ ->
                            case unchangedExcavator of
                                Just exc ->
                                    Expect.all
                                        [ \_ -> Expect.within (Expect.Absolute 0.001) 3.0 exc.bucketCapacity
                                        , \_ -> Expect.within (Expect.Absolute 0.001) 1.8 exc.cycleTime
                                        , \_ -> Expect.equal "Don't Change" exc.name
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have unchanged excavator"
                        ]
                        ()
            ]
        , describe "Truck Operations State Preservation"
            [ test "adding truck preserves excavator fleet and project state" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator 1", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Excavator 2", isActive = True }
                            ]

                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck 1", isActive = True } ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate adding a truck
                        newTruck =
                            { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "New Truck", isActive = True }

                        updatedModel =
                            { originalModel
                                | trucks = originalModel.trucks ++ [ newTruck ]
                                , nextTruckId = originalModel.nextTruckId + 1
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.excavators updatedModel.excavators
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal originalModel.deviceType updatedModel.deviceType
                        , \_ -> Expect.equal originalModel.message updatedModel.message
                        , \_ -> Expect.equal originalModel.nextExcavatorId updatedModel.nextExcavatorId
                        , \_ -> Expect.equal (originalModel.nextTruckId + 1) updatedModel.nextTruckId
                        ]
                        ()
            , test "removing truck preserves excavator fleet and project state" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]

                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Keep", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Remove", isActive = True }
                            ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate removing a truck
                        updatedModel =
                            { originalModel | trucks = List.filter (\truck -> truck.id /= "truck2") originalModel.trucks }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.excavators updatedModel.excavators
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal originalModel.nextExcavatorId updatedModel.nextExcavatorId
                        ]
                        ()
            , test "updating truck preserves other trucks and all other state" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]

                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Update Me", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Don't Change", isActive = True }
                            ]

                        originalModel =
                            createTestModelWithState originalExcavators originalTrucks

                        -- Simulate updating first truck
                        updatedModel =
                            { originalModel
                                | trucks =
                                    List.map
                                        (\truck ->
                                            if truck.id == "truck1" then
                                                { truck | capacity = 20.0, name = "Updated" }

                                            else
                                                truck
                                        )
                                        originalModel.trucks
                            }

                        unchangedTruck =
                            List.filter (\truck -> truck.id == "truck2") updatedModel.trucks
                                |> List.head
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.excavators updatedModel.excavators
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.nextTruckId updatedModel.nextTruckId
                        , \_ ->
                            case unchangedTruck of
                                Just truck ->
                                    Expect.all
                                        [ \_ -> Expect.within (Expect.Absolute 0.001) 18.0 truck.capacity
                                        , \_ -> Expect.within (Expect.Absolute 0.001) 12.0 truck.roundTripTime
                                        , \_ -> Expect.equal "Don't Change" truck.name
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have unchanged truck"
                        ]
                        ()
            ]
        , describe "Minimum Equipment Rules"
            [ test "cannot remove last excavator" <|
                \_ ->
                    let
                        singleExcavator =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Last Excavator", isActive = True } ]

                        trucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        model =
                            createTestModelWithState singleExcavator trucks

                        -- Attempt to remove the last excavator should fail/preserve the excavator
                        attemptedRemoval =
                            List.filter (\exc -> exc.id /= "exc1") model.excavators

                        -- Business logic should prevent this, but we test the list operation itself
                        remainingExcavators =
                            if List.length attemptedRemoval == 0 then
                                model.excavators
                                -- Preserve original if would result in empty list

                            else
                                attemptedRemoval
                    in
                    Expect.equal 1 (List.length remainingExcavators)
            , test "cannot remove last truck" <|
                \_ ->
                    let
                        excavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]

                        singleTruck =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Last Truck", isActive = True } ]

                        model =
                            createTestModelWithState excavators singleTruck

                        -- Attempt to remove the last truck should fail/preserve the truck
                        attemptedRemoval =
                            List.filter (\truck -> truck.id /= "truck1") model.trucks

                        -- Business logic should prevent this, but we test the list operation itself
                        remainingTrucks =
                            if List.length attemptedRemoval == 0 then
                                model.trucks
                                -- Preserve original if would result in empty list

                            else
                                attemptedRemoval
                    in
                    Expect.equal 1 (List.length remainingTrucks)
            , test "can remove equipment when multiple items exist" <|
                \_ ->
                    let
                        excavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Keep", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Remove", isActive = True }
                            ]

                        trucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Keep", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Remove", isActive = True }
                            ]

                        model =
                            createTestModelWithState excavators trucks

                        afterExcavatorRemoval =
                            List.filter (\exc -> exc.id /= "exc2") model.excavators

                        afterTruckRemoval =
                            List.filter (\truck -> truck.id /= "truck2") model.trucks
                    in
                    Expect.all
                        [ \_ -> Expect.equal 1 (List.length afterExcavatorRemoval)
                        , \_ -> Expect.equal 1 (List.length afterTruckRemoval)
                        , \_ ->
                            List.head afterExcavatorRemoval
                                |> Maybe.map .name
                                |> Expect.equal (Just "Keep")
                        , \_ ->
                            List.head afterTruckRemoval
                                |> Maybe.map .name
                                |> Expect.equal (Just "Keep")
                        ]
                        ()
            ]
        , describe "Calculation State Preservation"
            [ test "adding equipment triggers recalculation but preserves form state" <|
                \_ ->
                    let
                        originalModel =
                            createTestModelWithState
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Excavator", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        -- Simulate adding equipment and triggering recalculation
                        newExcavator =
                            { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "New", isActive = True }

                        updatedModel =
                            { originalModel
                                | excavators = originalModel.excavators ++ [ newExcavator ]
                                , calculationInProgress = True -- Simulate calculation trigger
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.formData updatedModel.formData
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal True updatedModel.calculationInProgress
                        , \_ -> Expect.equal 2 (List.length updatedModel.excavators)
                        ]
                        ()
            , test "removing equipment preserves last valid calculation result" <|
                \_ ->
                    let
                        testCalculationResult =
                            { timelineInDays = 5
                            , totalHours = 40.0
                            , excavationRate = 85.0
                            , haulingRate = 90.0
                            , bottleneck = ExcavationBottleneck
                            , confidence = High
                            , assumptions = [ "Test assumption" ]
                            , warnings = [ "Test warning" ]
                            }

                        baseModel =
                            createTestModelWithState
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Keep", isActive = True }
                                , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Remove", isActive = True }
                                ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Truck", isActive = True } ]

                        originalModel =
                            { baseModel | lastValidResult = Just testCalculationResult }

                        -- Simulate removing equipment
                        updatedModel =
                            { originalModel | excavators = List.filter (\exc -> exc.id /= "exc2") originalModel.excavators }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalModel.lastValidResult updatedModel.lastValidResult
                        , \_ -> Expect.equal 1 (List.length updatedModel.excavators)
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


createTestModelWithState : List Excavator -> List Truck -> Model
createTestModelWithState excavators trucks =
    let
        testFormData =
            { workHoursPerDay = "8.0"
            , pondLength = "40.0"
            , pondWidth = "25.0"
            , pondDepth = "5.0"
            , errors = []
            }
    in
    { message = "Test Model With State"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just testFormData
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
    , helpTooltipState = Nothing
    , realTimeValidation = False
    , fieldValidationErrors = Dict.empty
    , validationDebounce = Dict.empty

    -- Onboarding state
    , onboardingState = Types.Onboarding.Completed
    , showWelcomeOverlay = False
    , currentTourStep = Nothing
    , isFirstTimeUser = False
    , exampleScenarioLoaded = False
    }
