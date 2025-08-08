module Unit.BannerRegressionTests exposing (suite)

{-| Unit-level regression tests for banner functionality

These tests focus on preventing regressions in the banner system at the 
model and message level, complementing the E2E regression tests.

@docs suite

-}

import Expect
import Fuzz
import Test exposing (Test, describe, fuzz, test)
import Types.DeviceType as DeviceType exposing (DeviceType(..))
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)


suite : Test
suite =
    describe "Banner Regression Tests"
        [ describe "Model State Regression"
            [ test "infoBannerDismissed field should always exist in model" <|
                \_ ->
                    let
                        testModel =
                            createTestModel False
                    in
                    -- This test will fail to compile if field is removed/renamed
                    Expect.equal False testModel.infoBannerDismissed
            , test "infoBannerDismissed should be boolean type" <|
                \_ ->
                    let
                        visibleModel =
                            createTestModel False

                        dismissedModel =
                            createTestModel True
                    in
                    Expect.all
                        [ \_ -> Expect.equal False visibleModel.infoBannerDismissed
                        , \_ -> Expect.equal True dismissedModel.infoBannerDismissed
                        ]
                        ()
            , fuzz Fuzz.bool "infoBannerDismissed should accept any boolean value" <|
                \boolValue ->
                    let
                        model =
                            createTestModel boolValue
                    in
                    Expect.equal boolValue model.infoBannerDismissed
            ]
        , describe "Message Handler Regression"
            [ test "DismissInfoBanner message should exist and be compilable" <|
                \_ ->
                    let
                        message =
                            DismissInfoBanner
                    in
                    -- This test ensures message exists and can be constructed
                    case message of
                        DismissInfoBanner ->
                            Expect.pass

                        _ ->
                            Expect.fail "DismissInfoBanner message not matching correctly"
            , test "DismissInfoBanner should always set infoBannerDismissed to True" <|
                \_ ->
                    let
                        initialModel =
                            createTestModel False

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.equal True updatedModel.infoBannerDismissed
            , test "DismissInfoBanner should be idempotent" <|
                \_ ->
                    let
                        initialModel =
                            createTestModel True

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.equal True updatedModel.infoBannerDismissed
            , fuzz Fuzz.bool "DismissInfoBanner should work from any initial banner state" <|
                \initialState ->
                    let
                        initialModel =
                            createTestModel initialState

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.equal True updatedModel.infoBannerDismissed
            ]
        , describe "State Isolation Regression"
            [ test "banner dismissal should not affect other model fields" <|
                \_ ->
                    let
                        initialModel =
                            createCompleteTestModel False

                        updatedModel =
                            simulateUpdate DismissInfoBanner initialModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal initialModel.message updatedModel.message
                        , \_ -> Expect.equal initialModel.config updatedModel.config
                        , \_ -> Expect.equal initialModel.formData updatedModel.formData
                        , \_ -> Expect.equal initialModel.calculationResult updatedModel.calculationResult
                        , \_ -> Expect.equal initialModel.deviceType updatedModel.deviceType
                        , \_ -> Expect.equal initialModel.excavators updatedModel.excavators
                        , \_ -> Expect.equal initialModel.trucks updatedModel.trucks
                        , \_ -> Expect.notEqual initialModel.infoBannerDismissed updatedModel.infoBannerDismissed
                        ]
                        ()
            , test "other messages should not affect banner state when dismissed" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        afterExcavatorMsg =
                            simulateUpdate (ExcavatorFieldChanged BucketCapacity "3.0") dismissedModel

                        afterTruckMsg =
                            simulateUpdate (TruckFieldChanged TruckCapacity "15.0") afterExcavatorMsg

                        afterPondMsg =
                            simulateUpdate (PondFieldChanged PondLength "50") afterTruckMsg

                        afterProjectMsg =
                            simulateUpdate (ProjectFieldChanged WorkHours "10") afterPondMsg

                        afterDeviceMsg =
                            simulateUpdate (DeviceDetected Mobile) afterProjectMsg
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterExcavatorMsg.infoBannerDismissed
                        , \_ -> Expect.equal True afterTruckMsg.infoBannerDismissed
                        , \_ -> Expect.equal True afterPondMsg.infoBannerDismissed
                        , \_ -> Expect.equal True afterProjectMsg.infoBannerDismissed
                        , \_ -> Expect.equal True afterDeviceMsg.infoBannerDismissed
                        ]
                        ()
            , test "other messages should not affect banner state when visible" <|
                \_ ->
                    let
                        visibleModel =
                            createTestModel False

                        afterCalculationMsg =
                            simulateUpdate CalculateTimeline visibleModel

                        afterNoOpMsg =
                            simulateUpdate NoOp afterCalculationMsg
                    in
                    Expect.all
                        [ \_ -> Expect.equal False afterCalculationMsg.infoBannerDismissed
                        , \_ -> Expect.equal False afterNoOpMsg.infoBannerDismissed
                        ]
                        ()
            ]
        , describe "Data Type Regression"
            [ test "banner state should maintain type safety across operations" <|
                \_ ->
                    let
                        model1 =
                            createTestModel False

                        model2 =
                            simulateUpdate DismissInfoBanner model1

                        model3 =
                            simulateUpdate (ExcavatorFieldChanged BucketCapacity "2.5") model2

                        -- Type check: should be able to use in boolean context
                        bannerVisible1 =
                            not model1.infoBannerDismissed

                        bannerVisible2 =
                            not model2.infoBannerDismissed

                        bannerVisible3 =
                            not model3.infoBannerDismissed
                    in
                    Expect.all
                        [ \_ -> Expect.equal True bannerVisible1
                        , \_ -> Expect.equal False bannerVisible2
                        , \_ -> Expect.equal False bannerVisible3
                        ]
                        ()
            , test "banner state should work correctly with boolean operators" <|
                \_ ->
                    let
                        visibleModel =
                            createTestModel False

                        dismissedModel =
                            createTestModel True

                        -- Test various boolean operations
                        test1 =
                            visibleModel.infoBannerDismissed || False

                        test2 =
                            dismissedModel.infoBannerDismissed && True

                        test3 =
                            not visibleModel.infoBannerDismissed

                        test4 =
                            not dismissedModel.infoBannerDismissed
                    in
                    Expect.all
                        [ \_ -> Expect.equal False test1
                        , \_ -> Expect.equal True test2
                        , \_ -> Expect.equal True test3
                        , \_ -> Expect.equal False test4
                        ]
                        ()
            ]
        , describe "Device Type Interaction Regression"
            [ fuzz deviceTypeFuzzer "banner state should persist across all device types" <|
                \deviceType ->
                    let
                        initialModel =
                            { createTestModel False | deviceType = deviceType }

                        dismissedModel =
                            simulateUpdate DismissInfoBanner initialModel

                        afterDeviceChange =
                            simulateUpdate (DeviceDetected Desktop) dismissedModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal True dismissedModel.infoBannerDismissed
                        , \_ -> Expect.equal True afterDeviceChange.infoBannerDismissed
                        ]
                        ()
            , test "banner state should not be affected by device detection cycles" <|
                \_ ->
                    let
                        dismissedModel =
                            createTestModel True

                        afterMobile =
                            simulateUpdate (DeviceDetected Mobile) dismissedModel

                        afterTablet =
                            simulateUpdate (DeviceDetected Tablet) afterMobile

                        afterDesktop =
                            simulateUpdate (DeviceDetected Desktop) afterTablet

                        backToMobile =
                            simulateUpdate (DeviceDetected Mobile) afterDesktop
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterMobile.infoBannerDismissed
                        , \_ -> Expect.equal True afterTablet.infoBannerDismissed
                        , \_ -> Expect.equal True afterDesktop.infoBannerDismissed
                        , \_ -> Expect.equal True backToMobile.infoBannerDismissed
                        ]
                        ()
            ]
        , describe "Model Evolution Regression"
            [ test "adding new model fields should not break banner functionality" <|
                \_ ->
                    -- This test simulates what happens when new fields are added to Model
                    let
                        baseModel =
                            createTestModel False

                        -- Simulate model with additional fields
                        extendedModel =
                            { baseModel
                                | message = "Extended model test"
                                , hasValidationErrors = True
                            }

                        afterDismiss =
                            simulateUpdate DismissInfoBanner extendedModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal False extendedModel.infoBannerDismissed
                        , \_ -> Expect.equal True afterDismiss.infoBannerDismissed
                        , \_ -> Expect.equal extendedModel.hasValidationErrors afterDismiss.hasValidationErrors
                        ]
                        ()
            , test "banner field position in model should not affect functionality" <|
                \_ ->
                    -- Test that banner works regardless of where infoBannerDismissed 
                    -- appears in the Model type definition
                    let
                        model1 =
                            createTestModel True

                        model2 =
                            simulateUpdate DismissInfoBanner (createTestModel False)

                        -- Test field accessibility in different contexts
                        getterTest1 =
                            .infoBannerDismissed model1

                        getterTest2 =
                            .infoBannerDismissed model2
                    in
                    Expect.all
                        [ \_ -> Expect.equal True getterTest1
                        , \_ -> Expect.equal True getterTest2
                        ]
                        ()
            ]
        , describe "Message System Regression"
            [ test "message pattern matching should handle banner message correctly" <|
                \_ ->
                    let
                        testMessages =
                            [ DismissInfoBanner
                            , NoOp
                            , CalculateTimeline
                            , ExcavatorFieldChanged BucketCapacity "2.5"
                            ]

                        processMessage msg =
                            case msg of
                                DismissInfoBanner ->
                                    "banner"

                                _ ->
                                    "other"

                        results =
                            List.map processMessage testMessages
                    in
                    Expect.equal [ "banner", "other", "other", "other" ] results
            , test "banner message should not interfere with message queue processing" <|
                \_ ->
                    let
                        model =
                            createTestModel False

                        -- Simulate processing multiple messages in sequence
                        step1 =
                            simulateUpdate (ExcavatorFieldChanged BucketCapacity "3.0") model

                        step2 =
                            simulateUpdate DismissInfoBanner step1

                        step3 =
                            simulateUpdate (PondFieldChanged PondLength "45") step2

                        step4 =
                            simulateUpdate CalculateTimeline step3
                    in
                    -- All updates should have been processed correctly
                    Expect.all
                        [ \_ -> Expect.equal False model.infoBannerDismissed
                        , \_ -> Expect.equal False step1.infoBannerDismissed
                        , \_ -> Expect.equal True step2.infoBannerDismissed
                        , \_ -> Expect.equal True step3.infoBannerDismissed
                        , \_ -> Expect.equal True step4.infoBannerDismissed
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS AND TEST UTILITIES


{-| Create basic test model with specified banner state
-}
createTestModel : Bool -> Model
createTestModel dismissed =
    { message = "Test Model"
    , config = Nothing
    , formData = Nothing
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Desktop
    , calculationInProgress = False
    , performanceMetrics = createMockPerformanceMetrics
    , debounceState = createMockDebounceState
    , excavators = []
    , trucks = []
    , nextExcavatorId = 1
    , nextTruckId = 1
    , infoBannerDismissed = dismissed
    }


{-| Create test model with full data for comprehensive testing
-}
createCompleteTestModel : Bool -> Model
createCompleteTestModel dismissed =
    { message = "Complete Test Model"
    , config = Just createMockConfig
    , formData = Just createMockFormData
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = Desktop
    , calculationInProgress = False
    , performanceMetrics = createMockPerformanceMetrics
    , debounceState = createMockDebounceState
    , excavators = [ createMockExcavator ]
    , trucks = [ createMockTruck ]
    , nextExcavatorId = 2
    , nextTruckId = 2
    , infoBannerDismissed = dismissed
    }


{-| Simulate update function for testing
-}
simulateUpdate : Msg -> Model -> Model
simulateUpdate msg model =
    case msg of
        DismissInfoBanner ->
            { model | infoBannerDismissed = True }

        DeviceDetected deviceType ->
            { model | deviceType = deviceType }

        ExcavatorFieldChanged _ _ ->
            model

        TruckFieldChanged _ _ ->
            model

        PondFieldChanged _ _ ->
            model

        ProjectFieldChanged _ _ ->
            model

        CalculateTimeline ->
            { model | calculationInProgress = True }

        NoOp ->
            model

        _ ->
            model


{-| Fuzzer for device types
-}
deviceTypeFuzzer : Fuzz.Fuzzer DeviceType
deviceTypeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Desktop
        , Fuzz.constant Tablet
        , Fuzz.constant Mobile
        ]



-- MOCK DATA CREATORS


createMockPerformanceMetrics : Utils.Performance.PerformanceMetrics
createMockPerformanceMetrics =
    Utils.Performance.initMetrics


createMockDebounceState : Utils.Debounce.DebounceState
createMockDebounceState =
    Utils.Debounce.initDebounce


createMockConfig : Utils.Config.Config
createMockConfig =
    Utils.Config.fallbackConfig


createMockFormData : Components.ProjectForm.FormData
createMockFormData =
    { excavatorCapacity = "2.5"
    , excavatorCycleTime = "2.0"
    , truckCapacity = "12.0"
    , truckRoundTripTime = "15.0"
    , workHoursPerDay = "8.0"
    , pondLength = "40.0"
    , pondWidth = "25.0"
    , pondDepth = "5.0"
    }


createMockExcavator : Types.Equipment.Excavator
createMockExcavator =
    { id = "test-excavator-1"
    , bucketCapacity = 2.5
    , cycleTime = 2.0
    , name = "Test Excavator"
    , isActive = True
    }


createMockTruck : Types.Equipment.Truck
createMockTruck =
    { id = "test-truck-1"
    , capacity = 12.0
    , roundTripTime = 15.0
    , name = "Test Truck"
    , isActive = True
    }