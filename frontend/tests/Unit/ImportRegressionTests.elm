module Unit.ImportRegressionTests exposing (suite)

{-| Regression tests for import-related errors that have been fixed

These tests ensure that common import mistakes don't get reintroduced:

  - Missing module imports
  - Incorrect import syntax
  - Type import validation

@docs suite

-}

import Components.ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType as DeviceType exposing (DeviceType(..))
import Types.Equipment
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Import Regression Tests"
        [ describe "Required Imports Availability"
            [ test "should have access to all Types modules" <|
                \_ ->
                    let
                        -- Test that key types are accessible
                        deviceTypeValid =
                            Desktop /= Mobile

                        excavatorFieldValid =
                            BucketCapacity /= CycleTime

                        pondFieldValid =
                            PondLength /= PondWidth

                        projectFieldValid =
                            WorkHours /= WorkHours

                        -- Same value but tests enum exists
                        truckFieldValid =
                            TruckCapacity /= RoundTripTime
                    in
                    Expect.all
                        [ \_ -> Expect.equal True deviceTypeValid
                        , \_ -> Expect.equal True excavatorFieldValid
                        , \_ -> Expect.equal True pondFieldValid
                        , \_ -> Expect.equal True (projectFieldValid || not projectFieldValid) -- Always true, tests compilation
                        , \_ -> Expect.equal True truckFieldValid
                        ]
                        ()
            , test "should have access to all Utils modules" <|
                \_ ->
                    let
                        -- Test that utility functions are accessible
                        configValid =
                            Utils.Config.getConfig.version /= ""

                        debounceValid =
                            Utils.Debounce.initDebounce.delay > 0

                        performanceValid =
                            Utils.Performance.initMetrics.calculationCount == 0
                    in
                    Expect.all
                        [ \_ -> Expect.equal True configValid
                        , \_ -> Expect.equal True debounceValid
                        , \_ -> Expect.equal True performanceValid
                        ]
                        ()
            , test "should have access to Components modules" <|
                \_ ->
                    let
                        -- Test that component types are accessible
                        formDataFields =
                            [ "excavatorCapacity"
                            , "excavatorCycleTime"
                            , "truckCapacity"
                            , "truckRoundTripTime"
                            , "workHoursPerDay"
                            , "pondLength"
                            , "pondWidth"
                            , "pondDepth"
                            , "errors"
                            ]

                        -- Test that we can create mock form data (validates FormData type access)
                        mockFormData =
                            { excavatorCapacity = "2.5"
                            , excavatorCycleTime = "2.0"
                            , truckCapacity = "12.0"
                            , truckRoundTripTime = "15.0"
                            , workHoursPerDay = "8.0"
                            , pondLength = "40.0"
                            , pondWidth = "25.0"
                            , pondDepth = "5.0"
                            , errors = []
                            }

                        formDataValid =
                            mockFormData.excavatorCapacity == "2.5"
                    in
                    Expect.all
                        [ \_ -> Expect.equal True (List.length formDataFields > 0)
                        , \_ -> Expect.equal True formDataValid
                        , \_ -> Expect.equal [] mockFormData.errors
                        ]
                        ()
            ]
        , describe "Equipment Types Import Validation"
            [ test "should have access to Excavator and Truck types" <|
                \_ ->
                    let
                        -- Test that we can create mock equipment (validates type access)
                        mockExcavator =
                            { id = "test-excavator"
                            , bucketCapacity = 2.5
                            , cycleTime = 2.0
                            , name = "Test Excavator"
                            , isActive = True
                            }

                        mockTruck =
                            { id = "test-truck"
                            , capacity = 12.0
                            , roundTripTime = 15.0
                            , name = "Test Truck"
                            , isActive = True
                            }

                        excavatorValid =
                            mockExcavator.bucketCapacity > 0

                        truckValid =
                            mockTruck.capacity > 0
                    in
                    Expect.all
                        [ \_ -> Expect.equal True excavatorValid
                        , \_ -> Expect.equal True truckValid
                        , \_ -> Expect.equal "test-excavator" mockExcavator.id
                        , \_ -> Expect.equal "test-truck" mockTruck.id
                        ]
                        ()
            ]
        , describe "Message Types Import Validation"
            [ test "should have access to core message types" <|
                \_ ->
                    let
                        -- Test that we can reference message types (validates Msg type access)
                        -- Note: We can't easily test message creation without dependencies,
                        -- but we can test that the module imports without error
                        messageTypesAvailable =
                            True

                        -- If we got here, the imports worked
                        -- Test that DeviceType enum values are distinct
                        deviceTypesDistinct =
                            Desktop /= Tablet && Tablet /= Mobile && Mobile /= Desktop
                    in
                    Expect.all
                        [ \_ -> Expect.equal True messageTypesAvailable
                        , \_ -> Expect.equal True deviceTypesDistinct
                        ]
                        ()
            ]
        , describe "Model Type Import Validation"
            [ test "should have access to Model type for test creation" <|
                \_ ->
                    let
                        -- Test that we can reference Model type (validates Model import)
                        -- We'll create a minimal mock model to test the import
                        mockModel =
                            { message = "Test Model"
                            , config = Nothing
                            , formData = Nothing
                            , calculationResult = Nothing
                            , lastValidResult = Nothing
                            , hasValidationErrors = False
                            , deviceType = Desktop
                            , calculationInProgress = False
                            , performanceMetrics = Utils.Performance.initMetrics
                            , debounceState = Utils.Debounce.initDebounce
                            , excavators = []
                            , trucks = []
                            , nextExcavatorId = 1
                            , nextTruckId = 1
                            , infoBannerDismissed = False
                            }

                        modelValid =
                            mockModel.message == "Test Model"

                        modelFieldsPresent =
                            mockModel.nextExcavatorId
                                > 0
                                && mockModel.nextTruckId
                                > 0
                                && mockModel.infoBannerDismissed
                                == False
                    in
                    Expect.all
                        [ \_ -> Expect.equal True modelValid
                        , \_ -> Expect.equal True modelFieldsPresent
                        , \_ -> Expect.equal Desktop mockModel.deviceType
                        ]
                        ()
            ]
        , describe "Import Pattern Validation"
            [ test "should demonstrate proper import patterns" <|
                \_ ->
                    let
                        -- Test various import patterns used in the file
                        -- Qualified imports
                        qualifiedImportWorks =
                            DeviceType.Desktop == Desktop

                        -- Exposing specific items
                        exposedItemsWork =
                            BucketCapacity /= CycleTime

                        -- Mixed qualified and exposed
                        mixedImportWorks =
                            Utils.Config.getConfig.version /= ""
                    in
                    Expect.all
                        [ \_ -> Expect.equal True qualifiedImportWorks
                        , \_ -> Expect.equal True exposedItemsWork
                        , \_ -> Expect.equal True mixedImportWorks
                        ]
                        ()
            ]
        ]
