module Unit.ImmutabilityTests exposing (suite)

{-| Unit tests for immutability in fleet operations

@docs suite

-}

import Dict
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Messages exposing (ExcavatorUpdate(..), Msg(..), TruckUpdate(..))
import Types.Model exposing (Model)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Immutability Tests"
        [ describe "Excavator Fleet Immutability"
            [ test "adding excavator creates new list without modifying original" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Original", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Original 2", isActive = True }
                            ]

                        originalModel =
                            createTestModel originalExcavators []

                        -- Simulate adding an excavator
                        newExcavator =
                            { id = "exc3", bucketCapacity = 2.2, cycleTime = 2.1, name = "New Excavator", isActive = True }

                        updatedModel =
                            { originalModel | excavators = originalModel.excavators ++ [ newExcavator ] }
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length originalModel.excavators)
                        , \_ -> Expect.equal 3 (List.length updatedModel.excavators)
                        , \_ -> Expect.notEqual originalModel.excavators updatedModel.excavators
                        , \_ ->
                            -- Original excavators should still be in the new list
                            List.take 2 updatedModel.excavators
                                |> Expect.equal originalModel.excavators
                        ]
                        ()
            , test "removing excavator creates new list without modifying original" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Keep", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Remove", isActive = True }
                            , { id = "exc3", bucketCapacity = 2.2, cycleTime = 2.1, name = "Keep 2", isActive = True }
                            ]

                        originalModel =
                            createTestModel originalExcavators []

                        -- Simulate removing middle excavator
                        updatedModel =
                            { originalModel | excavators = List.filter (\exc -> exc.id /= "exc2") originalModel.excavators }
                    in
                    Expect.all
                        [ \_ -> Expect.equal 3 (List.length originalModel.excavators)
                        , \_ -> Expect.equal 2 (List.length updatedModel.excavators)
                        , \_ -> Expect.notEqual originalModel.excavators updatedModel.excavators
                        , \_ ->
                            -- Original list should still contain removed item
                            originalModel.excavators
                                |> List.any (\exc -> exc.id == "exc2")
                                |> Expect.equal True
                        , \_ ->
                            -- New list should not contain removed item
                            updatedModel.excavators
                                |> List.any (\exc -> exc.id == "exc2")
                                |> Expect.equal False
                        ]
                        ()
            , test "updating excavator creates new list without modifying original" <|
                \_ ->
                    let
                        originalExcavators =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Original Name", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Unchanged", isActive = True }
                            ]

                        originalModel =
                            createTestModel originalExcavators []

                        -- Simulate updating first excavator's name
                        updatedModel =
                            { originalModel
                                | excavators =
                                    List.map
                                        (\exc ->
                                            if exc.id == "exc1" then
                                                { exc | name = "Updated Name" }

                                            else
                                                exc
                                        )
                                        originalModel.excavators
                            }

                        originalFirstExc =
                            List.head originalModel.excavators

                        updatedFirstExc =
                            List.head updatedModel.excavators
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual originalModel.excavators updatedModel.excavators
                        , \_ ->
                            case originalFirstExc of
                                Just exc ->
                                    Expect.equal "Original Name" exc.name

                                Nothing ->
                                    Expect.fail "Should have original excavator"
                        , \_ ->
                            case updatedFirstExc of
                                Just exc ->
                                    Expect.equal "Updated Name" exc.name

                                Nothing ->
                                    Expect.fail "Should have updated excavator"
                        ]
                        ()
            ]
        , describe "Truck Fleet Immutability"
            [ test "adding truck creates new list without modifying original" <|
                \_ ->
                    let
                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Original", isActive = True }
                            ]

                        originalModel =
                            createTestModel [] originalTrucks

                        -- Simulate adding a truck
                        newTruck =
                            { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "New Truck", isActive = True }

                        updatedModel =
                            { originalModel | trucks = originalModel.trucks ++ [ newTruck ] }
                    in
                    Expect.all
                        [ \_ -> Expect.equal 1 (List.length originalModel.trucks)
                        , \_ -> Expect.equal 2 (List.length updatedModel.trucks)
                        , \_ -> Expect.notEqual originalModel.trucks updatedModel.trucks
                        ]
                        ()
            , test "removing truck creates new list without modifying original" <|
                \_ ->
                    let
                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Keep", isActive = True }
                            , { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "Remove", isActive = True }
                            ]

                        originalModel =
                            createTestModel [] originalTrucks

                        -- Simulate removing second truck
                        updatedModel =
                            { originalModel | trucks = List.filter (\truck -> truck.id /= "truck2") originalModel.trucks }
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length originalModel.trucks)
                        , \_ -> Expect.equal 1 (List.length updatedModel.trucks)
                        , \_ -> Expect.notEqual originalModel.trucks updatedModel.trucks
                        , \_ ->
                            -- Original list should still contain removed item
                            originalModel.trucks
                                |> List.any (\truck -> truck.id == "truck2")
                                |> Expect.equal True
                        ]
                        ()
            , test "updating truck creates new list without modifying original" <|
                \_ ->
                    let
                        originalTrucks =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Original", isActive = True }
                            ]

                        originalModel =
                            createTestModel [] originalTrucks

                        -- Simulate updating truck capacity
                        updatedModel =
                            { originalModel
                                | trucks =
                                    List.map
                                        (\truck ->
                                            if truck.id == "truck1" then
                                                { truck | capacity = 18.0 }

                                            else
                                                truck
                                        )
                                        originalModel.trucks
                            }

                        originalFirstTruck =
                            List.head originalModel.trucks

                        updatedFirstTruck =
                            List.head updatedModel.trucks
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual originalModel.trucks updatedModel.trucks
                        , \_ ->
                            case originalFirstTruck of
                                Just truck ->
                                    Expect.equal 12.0 truck.capacity

                                Nothing ->
                                    Expect.fail "Should have original truck"
                        , \_ ->
                            case updatedFirstTruck of
                                Just truck ->
                                    Expect.equal 18.0 truck.capacity

                                Nothing ->
                                    Expect.fail "Should have updated truck"
                        ]
                        ()
            ]
        , describe "Model State Immutability"
            [ test "fleet operations preserve other model fields" <|
                \_ ->
                    let
                        originalModel =
                            createTestModel
                                [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Test", isActive = True } ]
                                [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Test", isActive = True } ]

                        originalMessage =
                            originalModel.message

                        originalDeviceType =
                            originalModel.deviceType

                        originalCalculationInProgress =
                            originalModel.calculationInProgress

                        -- Simulate adding equipment
                        updatedModel =
                            { originalModel
                                | excavators = originalModel.excavators ++ [ { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "New", isActive = True } ]
                                , trucks = originalModel.trucks ++ [ { id = "truck2", capacity = 15.0, roundTripTime = 12.0, name = "New", isActive = True } ]
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalMessage updatedModel.message
                        , \_ -> Expect.equal originalDeviceType updatedModel.deviceType
                        , \_ -> Expect.equal originalCalculationInProgress updatedModel.calculationInProgress
                        , \_ -> Expect.equal originalModel.config updatedModel.config
                        , \_ -> Expect.equal originalModel.formData updatedModel.formData
                        ]
                        ()
            , test "ID counters increment without affecting equipment lists" <|
                \_ ->
                    let
                        originalModel =
                            createTestModel [] []

                        originalExcavators =
                            originalModel.excavators

                        originalTrucks =
                            originalModel.trucks

                        -- Simulate incrementing ID counters
                        updatedModel =
                            { originalModel
                                | nextExcavatorId = originalModel.nextExcavatorId + 1
                                , nextTruckId = originalModel.nextTruckId + 1
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal originalExcavators updatedModel.excavators
                        , \_ -> Expect.equal originalTrucks updatedModel.trucks
                        , \_ -> Expect.equal (originalModel.nextExcavatorId + 1) updatedModel.nextExcavatorId
                        , \_ -> Expect.equal (originalModel.nextTruckId + 1) updatedModel.nextTruckId
                        ]
                        ()
            ]
        , describe "Deep Immutability Verification"
            [ test "nested equipment property changes don't affect original equipment" <|
                \_ ->
                    let
                        originalExcavator =
                            { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Original", isActive = True }

                        originalList =
                            [ originalExcavator ]

                        -- Create updated equipment with changed properties
                        updatedExcavator =
                            { originalExcavator | bucketCapacity = 3.0, name = "Updated" }

                        updatedList =
                            [ updatedExcavator ]
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.001) 2.5 originalExcavator.bucketCapacity
                        , \_ -> Expect.equal "Original" originalExcavator.name
                        , \_ -> Expect.within (Expect.Absolute 0.001) 3.0 updatedExcavator.bucketCapacity
                        , \_ -> Expect.equal "Updated" updatedExcavator.name
                        , \_ -> Expect.notEqual originalList updatedList
                        ]
                        ()
            , test "list operations preserve original equipment objects" <|
                \_ ->
                    let
                        equipment1 =
                            { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Equipment 1", isActive = True }

                        equipment2 =
                            { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Equipment 2", isActive = True }

                        originalList =
                            [ equipment1, equipment2 ]

                        -- Various list operations
                        filteredList =
                            List.filter (\exc -> exc.bucketCapacity > 2.7) originalList

                        mappedList =
                            List.map (\exc -> { exc | isActive = False }) originalList

                        appendedList =
                            originalList ++ [ { id = "exc3", bucketCapacity = 2.2, cycleTime = 2.1, name = "Equipment 3", isActive = True } ]
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length originalList)
                        , \_ -> Expect.equal 1 (List.length filteredList)
                        , \_ -> Expect.equal 2 (List.length mappedList)
                        , \_ -> Expect.equal 3 (List.length appendedList)
                        , \_ ->
                            -- Original equipment objects should still have original values
                            List.all (\exc -> exc.isActive == True) originalList
                                |> Expect.equal True
                        , \_ ->
                            -- Mapped list should have updated values
                            List.all (\exc -> exc.isActive == False) mappedList
                                |> Expect.equal True
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


createTestModel : List Excavator -> List Truck -> Model
createTestModel excavators trucks =
    { message = "Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Nothing
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Desktop
    , calculationInProgress = False
    , performanceMetrics = Utils.Performance.initMetrics
    , debounceState = Utils.Debounce.initDebounce
    , excavators = excavators
    , trucks = trucks
    , nextExcavatorId = 1
    , nextTruckId = 1
    , infoBannerDismissed = False
    , helpTooltipState = Nothing
    , realTimeValidation = False
    , fieldValidationErrors = Dict.empty
    , validationDebounce = Dict.empty
    }
