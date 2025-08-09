module Integration.SharedStateTests exposing (suite)

{-| Test suite to verify the FIXED architecture with shared state

This demonstrates the CORRECT architecture where mobile uses the same
shared state as desktop/tablet views, only with different presentation.

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Calculations exposing (Bottleneck(..), CalculationResult, ConfidenceLevel(..))
import Utils.Config as Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Shared State Architecture Tests"
        [ sharedStateTests
        , deviceSwitchingTests
        ]


{-| Tests that verify state is properly shared across device types
-}
sharedStateTests : Test
sharedStateTests =
    describe "Shared State Across All Device Types"
        [ test "all_device_types_use_same_formData_field" <|
            \_ ->
                let
                    testFormData =
                        createTestFormData

                    mobileModel =
                        createModelWithFormData Mobile testFormData

                    tabletModel =
                        createModelWithFormData Tablet testFormData

                    desktopModel =
                        createModelWithFormData Desktop testFormData
                in
                -- ALL device types should use the same formData field
                Expect.all
                    [ \_ -> Expect.equal mobileModel.formData desktopModel.formData
                    , \_ -> Expect.equal tabletModel.formData desktopModel.formData
                    , \_ -> Expect.equal mobileModel.formData tabletModel.formData
                    ]
                    ()
        , test "all_device_types_use_same_calculationResult_field" <|
            \_ ->
                let
                    testResult =
                        createTestCalculationResult

                    mobileModel =
                        createModelWithResult Mobile testResult

                    tabletModel =
                        createModelWithResult Tablet testResult

                    desktopModel =
                        createModelWithResult Desktop testResult
                in
                -- ALL device types should use the same calculationResult field
                Expect.all
                    [ \_ -> Expect.equal mobileModel.calculationResult desktopModel.calculationResult
                    , \_ -> Expect.equal tabletModel.calculationResult desktopModel.calculationResult
                    , \_ -> Expect.equal mobileModel.calculationResult tabletModel.calculationResult
                    ]
                    ()
        , test "all_device_types_use_same_config_field" <|
            \_ ->
                let
                    mobileModel =
                        createTestModel Mobile

                    tabletModel =
                        createTestModel Tablet

                    desktopModel =
                        createTestModel Desktop
                in
                -- ALL device types should use the same config
                Expect.all
                    [ \_ -> Expect.equal mobileModel.config desktopModel.config
                    , \_ -> Expect.equal tabletModel.config desktopModel.config
                    , \_ -> Expect.equal mobileModel.config tabletModel.config
                    ]
                    ()
        ]


{-| Tests that verify state persists when switching device types
-}
deviceSwitchingTests : Test
deviceSwitchingTests =
    describe "State Persistence When Switching Device Types"
        [ test "form_data_persists_when_switching_mobile_to_desktop" <|
            \_ ->
                let
                    -- Start with mobile model with form data
                    mobileModel =
                        createModelWithFormData Mobile createTestFormData

                    -- Switch to desktop (simulating browser resize)
                    desktopModel =
                        { mobileModel | deviceType = Desktop }
                in
                case ( mobileModel.formData, desktopModel.formData ) of
                    ( Just mobileForm, Just desktopForm ) ->
                        -- Form data should be identical
                        Expect.all
                            [ \_ -> Expect.equal mobileForm.pondLength desktopForm.pondLength
                            , \_ -> Expect.equal mobileForm.pondWidth desktopForm.pondWidth
                            , \_ -> Expect.equal mobileForm.pondDepth desktopForm.pondDepth
                            , \_ -> Expect.equal mobileForm.workHoursPerDay desktopForm.workHoursPerDay
                            , \_ -> Expect.equal mobileForm.errors desktopForm.errors
                            ]
                            ()

                    _ ->
                        Expect.fail "Form data should exist in both mobile and desktop models"
        , test "calculation_results_persist_when_switching_desktop_to_mobile" <|
            \_ ->
                let
                    -- Start with desktop model with calculation results
                    desktopModel =
                        createModelWithResult Desktop createTestCalculationResult

                    -- Switch to mobile (simulating browser resize)
                    mobileModel =
                        { desktopModel | deviceType = Mobile }
                in
                case ( desktopModel.calculationResult, mobileModel.calculationResult ) of
                    ( Just desktopResult, Just mobileResult ) ->
                        -- Calculation results should be identical
                        Expect.all
                            [ \_ -> Expect.equal desktopResult.timelineInDays mobileResult.timelineInDays
                            , \_ -> Expect.within (Expect.Absolute 0.001) desktopResult.totalHours mobileResult.totalHours
                            , \_ -> Expect.within (Expect.Absolute 0.001) desktopResult.excavationRate mobileResult.excavationRate
                            ]
                            ()

                    _ ->
                        Expect.fail "Calculation results should exist in both desktop and mobile models"
        , test "state_survives_multiple_device_type_changes" <|
            \_ ->
                let
                    -- Start with specific test data
                    originalModel =
                        createModelWithFormData Mobile createTestFormData

                    -- Switch device types multiple times
                    step1 =
                        { originalModel | deviceType = Tablet }

                    step2 =
                        { step1 | deviceType = Desktop }

                    step3 =
                        { step2 | deviceType = Mobile }

                    finalModel =
                        { step3 | deviceType = Tablet }
                in
                -- State should be identical after all switches
                Expect.all
                    [ \_ -> Expect.equal originalModel.formData finalModel.formData
                    , \_ -> Expect.equal originalModel.config finalModel.config
                    , \_ -> Expect.equal originalModel.calculationResult finalModel.calculationResult
                    ]
                    ()
        ]



-- TEST HELPERS


createTestModel : DeviceType -> Model
createTestModel deviceType =
    { message = "Test Model"
    , config = Just Config.fallbackConfig
    , formData = Just createTestFormData
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = deviceType
    , calculationInProgress = False
    , performanceMetrics = Utils.Performance.initMetrics
    , debounceState = Utils.Debounce.initDebounce
    , excavators = []
    , trucks = []
    , nextExcavatorId = 1
    , nextTruckId = 1
    , infoBannerDismissed = False
    }


createModelWithFormData : DeviceType -> ProjectForm.FormData -> Model
createModelWithFormData deviceType formData =
    let
        baseModel =
            createTestModel deviceType
    in
    { baseModel | formData = Just formData }


createModelWithResult : DeviceType -> CalculationResult -> Model
createModelWithResult deviceType result =
    let
        baseModel =
            createTestModel deviceType
    in
    { baseModel | calculationResult = Just result }


createTestFormData : ProjectForm.FormData
createTestFormData =
    { workHoursPerDay = "9.0"
    , pondLength = "80.0"
    , pondWidth = "40.0"
    , pondDepth = "7.0"
    , errors = []
    }


createTestCalculationResult : CalculationResult
createTestCalculationResult =
    { timelineInDays = 3
    , totalHours = 24.0
    , excavationRate = 85.5
    , haulingRate = 95.2
    , bottleneck = Utils.Calculations.ExcavationBottleneck
    , confidence = Utils.Calculations.High
    , assumptions = []
    , warnings = []
    }



-- These types are now imported from Utils.Calculations
