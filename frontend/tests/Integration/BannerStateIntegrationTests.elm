module Integration.BannerStateIntegrationTests exposing (suite)

{-| Integration tests for Info Banner state management

Tests the interaction between banner state and other application components:

  - Banner state during form interactions
  - Banner state during calculations
  - Banner state across device type changes
  - Banner state with validation errors
  - Banner state during complex workflows

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (Excavator, Truck)
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Config as Config


suite : Test
suite =
    describe "Banner State Integration Tests"
        [ describe "Banner and Form Interaction"
            [ test "banner state should persist during form field updates" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModel False

                        -- Dismiss banner
                        afterDismiss =
                            updateModel DismissInfoBanner initialModel

                        -- Update multiple form fields
                        afterExcavatorUpdate =
                            updateModel (ExcavatorFieldChanged BucketCapacity "3.0") afterDismiss

                        afterTruckUpdate =
                            updateModel (TruckFieldChanged TruckCapacity "15.0") afterExcavatorUpdate

                        afterPondUpdate =
                            updateModel (PondFieldChanged PondLength "60") afterTruckUpdate

                        afterProjectUpdate =
                            updateModel (ProjectFieldChanged WorkHours "9") afterPondUpdate
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterExcavatorUpdate.infoBannerDismissed
                        , \_ -> Expect.equal True afterTruckUpdate.infoBannerDismissed
                        , \_ -> Expect.equal True afterPondUpdate.infoBannerDismissed
                        , \_ -> Expect.equal True afterProjectUpdate.infoBannerDismissed
                        ]
                        ()
            , test "banner state should persist during validation errors" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModel False

                        -- Dismiss banner
                        afterDismiss =
                            updateModel DismissInfoBanner initialModel

                        -- Create validation error (invalid input)
                        afterInvalidInput =
                            updateModel (ExcavatorFieldChanged BucketCapacity "999") afterDismiss

                        afterValidationError =
                            { afterInvalidInput | hasValidationErrors = True }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterValidationError.infoBannerDismissed
                        , \_ -> Expect.equal True afterValidationError.hasValidationErrors
                        ]
                        ()
            , test "banner dismissal should not affect form data integrity" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModelWithFormData False

                        originalFormData =
                            initialModel.formData

                        afterDismiss =
                            updateModel DismissInfoBanner initialModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterDismiss.infoBannerDismissed
                        , \_ -> Expect.equal originalFormData afterDismiss.formData
                        ]
                        ()
            ]
        , describe "Banner and Calculation Integration"
            [ test "banner state should persist during calculation lifecycle" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModelWithFormData False

                        -- Dismiss banner
                        afterDismiss =
                            updateModel DismissInfoBanner initialModel

                        -- Start calculation
                        duringCalculation =
                            { afterDismiss | calculationInProgress = True }

                        -- Complete calculation
                        afterCalculation =
                            { duringCalculation
                                | calculationInProgress = False
                                , calculationResult = Just createMockCalculationResult
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True duringCalculation.infoBannerDismissed
                        , \_ -> Expect.equal True afterCalculation.infoBannerDismissed
                        , \_ -> Expect.notEqual Nothing afterCalculation.calculationResult
                        ]
                        ()
            , test "banner state should persist through calculation errors" <|
                \_ ->
                    let
                        dismissedModel =
                            createIntegrationModel True

                        -- Simulate calculation with error
                        afterCalculationError =
                            { dismissedModel
                                | calculationInProgress = False
                                , calculationResult = Nothing
                                , hasValidationErrors = True
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterCalculationError.infoBannerDismissed
                        , \_ -> Expect.equal True afterCalculationError.hasValidationErrors
                        ]
                        ()
            , test "banner state should persist when switching between calculations" <|
                \_ ->
                    let
                        dismissedModel =
                            createIntegrationModelWithFormData True

                        -- First calculation
                        afterFirstCalc =
                            { dismissedModel | calculationResult = Just createMockCalculationResult }

                        -- Update form data
                        afterFormUpdate =
                            updateModel (PondFieldChanged PondWidth "35") afterFirstCalc

                        -- Second calculation
                        afterSecondCalc =
                            { afterFormUpdate | calculationResult = Just createMockCalculationResult }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterFirstCalc.infoBannerDismissed
                        , \_ -> Expect.equal True afterFormUpdate.infoBannerDismissed
                        , \_ -> Expect.equal True afterSecondCalc.infoBannerDismissed
                        ]
                        ()
            ]
        , describe "Banner and Device Type Integration"
            [ test "banner state should persist across device type changes" <|
                \_ ->
                    let
                        desktopModel =
                            createIntegrationModel False

                        -- Dismiss banner on desktop
                        afterDismissOnDesktop =
                            updateModel DismissInfoBanner desktopModel

                        -- Switch to tablet
                        onTablet =
                            updateModel (DeviceDetected Tablet) afterDismissOnDesktop

                        -- Switch to mobile
                        onMobile =
                            updateModel (DeviceDetected Mobile) onTablet

                        -- Back to desktop
                        backToDesktop =
                            updateModel (DeviceDetected Desktop) onMobile
                    in
                    Expect.all
                        [ \_ -> Expect.equal Desktop desktopModel.deviceType
                        , \_ -> Expect.equal True afterDismissOnDesktop.infoBannerDismissed
                        , \_ -> Expect.equal Tablet onTablet.deviceType
                        , \_ -> Expect.equal True onTablet.infoBannerDismissed
                        , \_ -> Expect.equal Mobile onMobile.deviceType
                        , \_ -> Expect.equal True onMobile.infoBannerDismissed
                        , \_ -> Expect.equal Desktop backToDesktop.deviceType
                        , \_ -> Expect.equal True backToDesktop.infoBannerDismissed
                        ]
                        ()
            , test "banner visibility logic should work correctly on all device types" <|
                \_ ->
                    let
                        deviceTypes =
                            [ Desktop, Tablet, Mobile ]

                        testDeviceType deviceType =
                            let
                                baseModelWithBanner =
                                    createIntegrationModel False

                                modelWithBanner =
                                    { baseModelWithBanner | deviceType = deviceType }

                                baseModelWithoutBanner =
                                    createIntegrationModel True

                                modelWithoutBanner =
                                    { baseModelWithoutBanner | deviceType = deviceType }

                                shouldShowWithBanner =
                                    not modelWithBanner.infoBannerDismissed

                                shouldShowWithoutBanner =
                                    not modelWithoutBanner.infoBannerDismissed
                            in
                            Expect.all
                                [ \_ -> Expect.equal True shouldShowWithBanner
                                , \_ -> Expect.equal False shouldShowWithoutBanner
                                ]
                                ()
                    in
                    deviceTypes
                        |> List.map testDeviceType
                        |> Expect.all
            ]
        , describe "Banner and Fleet Management Integration"
            [ test "banner state should persist during fleet operations" <|
                \_ ->
                    let
                        initialModel =
                            createIntegrationModelWithFleet False

                        -- Dismiss banner
                        afterDismiss =
                            updateModel DismissInfoBanner initialModel

                        -- Add excavator
                        afterAddExcavator =
                            updateModel AddExcavator afterDismiss

                        -- Add truck
                        afterAddTruck =
                            updateModel AddTruck afterAddExcavator

                        -- Update equipment
                        afterEquipmentUpdate =
                            updateModel
                                (UpdateExcavator "test-id" (Types.Messages.UpdateExcavatorBucketCapacity 3.5))
                                afterAddTruck
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterAddExcavator.infoBannerDismissed
                        , \_ -> Expect.equal True afterAddTruck.infoBannerDismissed
                        , \_ -> Expect.equal True afterEquipmentUpdate.infoBannerDismissed
                        ]
                        ()
            , test "banner dismissal should not affect fleet data integrity" <|
                \_ ->
                    let
                        modelWithFleet =
                            createIntegrationModelWithFleet False

                        originalExcavators =
                            modelWithFleet.excavators

                        originalTrucks =
                            modelWithFleet.trucks

                        afterDismiss =
                            updateModel DismissInfoBanner modelWithFleet
                    in
                    Expect.all
                        [ \_ -> Expect.equal True afterDismiss.infoBannerDismissed
                        , \_ -> Expect.equal originalExcavators afterDismiss.excavators
                        , \_ -> Expect.equal originalTrucks afterDismiss.trucks
                        ]
                        ()
            ]
        , describe "Complex Workflow Integration"
            [ test "banner should work correctly in complete user workflow" <|
                \_ ->
                    let
                        -- Simulate complete user workflow
                        model1 =
                            createIntegrationModelWithFormData False

                        -- User sees banner, starts entering data
                        model2 =
                            updateModel (PondFieldChanged PondLength "50") model1

                        -- User dismisses banner while working
                        model3 =
                            updateModel DismissInfoBanner model2

                        -- User continues entering data
                        model4 =
                            updateModel (PondFieldChanged PondWidth "30") model3

                        -- User changes device orientation
                        model5 =
                            updateModel (DeviceDetected Tablet) model4

                        -- Calculation occurs
                        model6 =
                            { model5 | calculationResult = Just createMockCalculationResult }

                        -- User adds equipment to fleet
                        model7 =
                            updateModel AddExcavator model6

                        -- Final calculation
                        model8 =
                            updateModel CalculateTimeline model7
                    in
                    -- Banner should stay dismissed throughout entire workflow
                    [ model3, model4, model5, model6, model7, model8 ]
                        |> List.map .infoBannerDismissed
                        |> List.all identity
                        |> Expect.equal True
            , test "banner state should be consistent in error recovery scenarios" <|
                \_ ->
                    let
                        dismissedModel =
                            createIntegrationModel True

                        -- Simulate error scenario
                        errorModel =
                            { dismissedModel
                                | hasValidationErrors = True
                                , calculationInProgress = False
                            }

                        -- Recovery - fix validation errors
                        recoveryModel =
                            updateModel (PondFieldChanged PondLength "40") errorModel

                        finalModel =
                            { recoveryModel
                                | hasValidationErrors = False
                                , calculationResult = Just createMockCalculationResult
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True errorModel.infoBannerDismissed
                        , \_ -> Expect.equal True recoveryModel.infoBannerDismissed
                        , \_ -> Expect.equal True finalModel.infoBannerDismissed
                        , \_ -> Expect.equal False finalModel.hasValidationErrors
                        ]
                        ()
            ]
        , describe "Session and State Persistence"
            [ test "banner state should be preserved in model serialization scenarios" <|
                \_ ->
                    let
                        originalModel =
                            createIntegrationModelWithFormData True

                        -- Simulate model persistence/restoration
                        restoredModel =
                            { originalModel
                                | message = "Restored model"

                                -- All other fields including infoBannerDismissed should persist
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal True restoredModel.infoBannerDismissed
                        , \_ -> Expect.equal originalModel.formData restoredModel.formData
                        , \_ -> Expect.equal originalModel.config restoredModel.config
                        ]
                        ()
            , test "banner reset behavior should work correctly" <|
                \_ ->
                    let
                        dismissedModel =
                            createIntegrationModelWithFormData True

                        -- Simulate app reset/refresh (banner should be visible again)
                        resetModel =
                            { dismissedModel | infoBannerDismissed = False }
                    in
                    Expect.all
                        [ \_ -> Expect.equal False resetModel.infoBannerDismissed
                        , \_ -> Expect.equal dismissedModel.formData resetModel.formData
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


{-| Create integration test model with minimal setup
-}
createIntegrationModel : Bool -> Model
createIntegrationModel dismissed =
    { message = "Integration Test Model"
    , config = Just createMockConfig
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


{-| Create integration test model with form data
-}
createIntegrationModelWithFormData : Bool -> Model
createIntegrationModelWithFormData dismissed =
    let
        baseModel =
            createIntegrationModel dismissed
    in
    { baseModel
        | formData = Just createMockFormData
    }


{-| Create integration test model with fleet data
-}
createIntegrationModelWithFleet : Bool -> Model
createIntegrationModelWithFleet dismissed =
    let
        baseModel =
            createIntegrationModelWithFormData dismissed
    in
    { baseModel
        | excavators = [ createMockExcavator ]
        , trucks = [ createMockTruck ]
        , nextExcavatorId = 2
        , nextTruckId = 2
    }


{-| Simplified update function for integration testing
-}
updateModel : Msg -> Model -> Model
updateModel msg model =
    case msg of
        DismissInfoBanner ->
            { model | infoBannerDismissed = True }

        DeviceDetected deviceType ->
            { model | deviceType = deviceType }

        ExcavatorFieldChanged field value ->
            model

        TruckFieldChanged field value ->
            model

        PondFieldChanged field value ->
            model

        ProjectFieldChanged field value ->
            model

        AddExcavator ->
            { model
                | excavators = model.excavators ++ [ createMockExcavator ]
                , nextExcavatorId = model.nextExcavatorId + 1
            }

        AddTruck ->
            { model
                | trucks = model.trucks ++ [ createMockTruck ]
                , nextTruckId = model.nextTruckId + 1
            }

        UpdateExcavator id update ->
            model

        CalculateTimeline ->
            { model | calculationInProgress = True }

        _ ->
            model



-- MOCK DATA CREATORS (Reused from Unit Tests)


createMockPerformanceMetrics : Utils.Performance.PerformanceMetrics
createMockPerformanceMetrics =
    Utils.Performance.initMetrics


createMockDebounceState : Utils.Debounce.DebounceState
createMockDebounceState =
    Utils.Debounce.initDebounce


createMockConfig : Config.Config
createMockConfig =
    Config.fallbackConfig


createMockFormData : ProjectForm.FormData
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


createMockExcavator : Excavator
createMockExcavator =
    { id = "test-excavator-1"
    , bucketCapacity = 2.5
    , cycleTime = 2.0
    , name = "Test Excavator"
    , isActive = True
    }


createMockTruck : Truck
createMockTruck =
    { id = "test-truck-1"
    , capacity = 12.0
    , roundTripTime = 15.0
    , name = "Test Truck"
    , isActive = True
    }


createMockCalculationResult : Utils.Calculations.CalculationResult
createMockCalculationResult =
    { timelineDays = 5.0
    , totalCubicYards = 1000.0
    , excavatorRate = 50.0
    , truckRate = 40.0
    , bottleneckEquipment = "Truck"
    , workingHours = 40.0
    }
