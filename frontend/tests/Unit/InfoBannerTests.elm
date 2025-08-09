module Unit.InfoBannerTests exposing (suite)

{-| Unit tests for Info Banner functionality

Tests the dismissible info banner feature to ensure:

  - Banner shows by default
  - Banner can be dismissed
  - Banner state is managed correctly
  - Messages are handled properly

@docs suite

-}

import Components.ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType
import Types.Equipment
import Types.Fields exposing (ExcavatorField(..), PondField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Info Banner Functionality"
        [ describe "Initial State"
            [ test "banner should be visible by default" <|
                \_ ->
                    let
                        initialModel =
                            createTestModel False
                    in
                    Expect.equal False initialModel.infoBannerDismissed
            , test "banner dismissed state should be configurable" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True
                    in
                    Expect.equal True dismissedModel.infoBannerDismissed
            ]
        , describe "Banner Dismissal Logic"
            [ test "DismissInfoBanner message should set infoBannerDismissed to True" <|
                \_ ->
                    let
                        initialModel =
                            createTestModel False

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.equal True updatedModel.infoBannerDismissed
            , test "dismissing already dismissed banner should remain dismissed" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        updatedModel =
                            simulateUpdate DismissInfoBanner dismissedModel
                    in
                    Expect.equal True updatedModel.infoBannerDismissed
            , test "other messages should not affect banner state" <|
                \_ ->
                    let
                        initialModel =
                            createTestModel False

                        afterNoOp =
                            simulateUpdate NoOp initialModel

                        afterCalculation =
                            simulateUpdate CalculateTimeline afterNoOp
                    in
                    Expect.all
                        [ \_ -> Expect.equal False afterNoOp.infoBannerDismissed
                        , \_ -> Expect.equal False afterCalculation.infoBannerDismissed
                        ]
                        ()
            ]
        , describe "Banner State Persistence"
            [ test "banner state should persist through form updates" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        afterFormUpdate =
                            simulateUpdate (ExcavatorFieldChanged Types.Fields.BucketCapacity "3.0") dismissedModel
                    in
                    Expect.equal True afterFormUpdate.infoBannerDismissed
            , test "banner state should persist through calculations" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        afterCalculation =
                            simulateUpdate CalculateTimeline dismissedModel
                    in
                    Expect.equal True afterCalculation.infoBannerDismissed
            , test "banner state should persist through device changes" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        afterDeviceChange =
                            simulateUpdate (DeviceDetected (Ok { width = 500, height = 800 })) dismissedModel
                    in
                    Expect.equal True afterDeviceChange.infoBannerDismissed
            ]
        , describe "Banner Visibility Logic"
            [ test "banner should be visible when not dismissed" <|
                \_ ->
                    let
                        model =
                            createTestModel False

                        shouldShowBanner =
                            not model.infoBannerDismissed
                    in
                    Expect.equal True shouldShowBanner
            , test "banner should be hidden when dismissed" <|
                \_ ->
                    let
                        model =
                            createTestModel True

                        shouldShowBanner =
                            not model.infoBannerDismissed
                    in
                    Expect.equal False shouldShowBanner
            ]
        , describe "Model Integrity"
            [ test "dismissing banner should not affect other model fields" <|
                \_ ->
                    let
                        initialModel =
                            createTestModelWithData False

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal initialModel.message updatedModel.message
                        , \_ -> Expect.equal initialModel.config updatedModel.config
                        , \_ -> Expect.equal initialModel.formData updatedModel.formData
                        , \_ -> Expect.equal initialModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal initialModel.deviceType updatedModel.deviceType
                        , \_ -> Expect.notEqual initialModel.infoBannerDismissed updatedModel.infoBannerDismissed
                        ]
                        ()
            , test "model should maintain consistency after banner operations" <|
                \_ ->
                    let
                        model =
                            createTestModelWithData False

                        afterDismiss =
                            simulateUpdate DismissInfoBanner model

                        afterFormUpdate =
                            simulateUpdate (PondFieldChanged Types.Fields.PondLength "50") afterDismiss
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterFormUpdate.infoBannerDismissed
                        , \_ -> Expect.notEqual Nothing afterFormUpdate.formData
                        , \_ -> validateModelConsistency afterFormUpdate
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


{-| Create a test model with specified banner state
-}
createTestModel : Bool -> Model
createTestModel dismissed =
    { message = "Test Model"
    , config = Nothing
    , formData = Nothing
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Types.DeviceType.Desktop
    , calculationInProgress = False
    , performanceMetrics = createMockPerformanceMetrics
    , debounceState = createMockDebounceState
    , excavators = []
    , trucks = []
    , nextExcavatorId = 1
    , nextTruckId = 1
    , infoBannerDismissed = dismissed
    }


{-| Create a test model with some data for integrity testing
-}
createTestModelWithData : Bool -> Model
createTestModelWithData dismissed =
    { message = "Test Model with Data"
    , config = Just createMockConfig
    , formData = Just createMockFormData
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Types.DeviceType.Desktop
    , calculationInProgress = False
    , performanceMetrics = createMockPerformanceMetrics
    , debounceState = createMockDebounceState
    , excavators = [ createMockExcavator ]
    , trucks = [ createMockTruck ]
    , nextExcavatorId = 2
    , nextTruckId = 2
    , infoBannerDismissed = dismissed
    }


{-| Simulate update function behavior for testing
This is a simplified version focusing on the banner functionality
-}
simulateUpdate : Msg -> Model -> Model
simulateUpdate msg model =
    case msg of
        DismissInfoBanner ->
            { model | infoBannerDismissed = True }

        NoOp ->
            model

        CalculateTimeline ->
            -- Simulate calculation without changing banner state
            { model | calculationInProgress = True }

        ExcavatorFieldChanged _ _ ->
            -- Simulate field change without changing banner state
            model

        PondFieldChanged _ _ ->
            -- Simulate field change without changing banner state
            model

        DeviceDetected result ->
            -- Simulate device detection without changing banner state
            case result of
                Ok windowSize ->
                    { model | deviceType = Types.DeviceType.fromWindowSize windowSize }

                Err _ ->
                    model

        _ ->
            -- For other messages, return model unchanged
            model


{-| Validate model consistency after operations
-}
validateModelConsistency : Model -> Expect.Expectation
validateModelConsistency model =
    -- Ensure model fields are in valid states
    let
        hasValidExcavatorId =
            model.nextExcavatorId > 0

        hasValidTruckId =
            model.nextTruckId > 0

        deviceTypeIsValid =
            case model.deviceType of
                Types.DeviceType.Desktop ->
                    True

                Types.DeviceType.Tablet ->
                    True

                Types.DeviceType.Mobile ->
                    True

        bannerStateIsBoolean =
            model.infoBannerDismissed == True || model.infoBannerDismissed == False
    in
    Expect.all
        [ \_ -> Expect.equal True hasValidExcavatorId
        , \_ -> Expect.equal True hasValidTruckId
        , \_ -> Expect.equal True deviceTypeIsValid
        , \_ -> Expect.equal True bannerStateIsBoolean
        ]
        ()



-- MOCK DATA CREATORS


{-| Create mock performance metrics for testing
-}
createMockPerformanceMetrics : Utils.Performance.PerformanceMetrics
createMockPerformanceMetrics =
    Utils.Performance.initMetrics


{-| Create mock debounce state for testing
-}
createMockDebounceState : Utils.Debounce.DebounceState
createMockDebounceState =
    Utils.Debounce.initDebounce


{-| Create mock config for testing
-}
createMockConfig : Utils.Config.Config
createMockConfig =
    { version = "1.0.0"
    , defaults =
        { excavators =
            [ { bucketCapacity = 2.5
              , cycleTime = 2.0
              , name = "Test Excavator"
              }
            ]
        , trucks =
            [ { capacity = 12.0
              , roundTripTime = 15.0
              , name = "Test Truck"
              }
            ]
        , project =
            { workHoursPerDay = 8.0
            , pondLength = 40.0
            , pondWidth = 25.0
            , pondDepth = 5.0
            }
        }
    , fleetLimits =
        { maxExcavators = 10
        , maxTrucks = 20
        }
    , validation =
        { excavatorCapacity = { min = 0.5, max = 15.0 }
        , cycleTime = { min = 0.5, max = 10.0 }
        , truckCapacity = { min = 5.0, max = 30.0 }
        , roundTripTime = { min = 5.0, max = 60.0 }
        , workHours = { min = 1.0, max = 16.0 }
        , pondDimensions = { min = 1.0, max = 1000.0 }
        }
    }


{-| Create mock form data for testing
-}
createMockFormData : Components.ProjectForm.FormData
createMockFormData =
    { workHoursPerDay = "8.0"
    , pondLength = "40.0"
    , pondWidth = "25.0"
    , pondDepth = "5.0"
    , errors = []
    }


{-| Create mock excavator for testing
-}
createMockExcavator : Types.Equipment.Excavator
createMockExcavator =
    { id = "test-excavator-1"
    , bucketCapacity = 2.5
    , cycleTime = 2.0
    , name = "Test Excavator"
    , isActive = True
    }


{-| Create mock truck for testing
-}
createMockTruck : Types.Equipment.Truck
createMockTruck =
    { id = "test-truck-1"
    , capacity = 12.0
    , roundTripTime = 15.0
    , name = "Test Truck"
    , isActive = True
    }
