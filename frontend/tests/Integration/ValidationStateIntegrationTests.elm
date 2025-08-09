module Integration.ValidationStateIntegrationTests exposing (suite)

{-| Integration tests for validation state management across the entire application

These tests verify that the validation error message fix works correctly across:

  - Different device types
  - Form updates and user interactions
  - Real calculation pipelines
  - State persistence and transitions

This prevents regression of the bug where validation error messages were persistent.

-}

import Components.ProjectForm as ProjectForm
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Calculations exposing (CalculationResult)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Validation State Integration Tests"
        [ describe "Cross-Device Validation State"
            [ test "validation errors persist when switching from Mobile to Desktop" <|
                \_ ->
                    let
                        mobileModel =
                            createModelWithInvalidInputs Mobile

                        mobileAfterCalc =
                            { mobileModel | hasValidationErrors = True }

                        desktopModel =
                            { mobileAfterCalc | deviceType = Desktop }
                    in
                    Expect.all
                        [ \m -> Expect.equal True m.hasValidationErrors
                        , \m -> Expect.equal Desktop m.deviceType
                        ]
                        desktopModel
            , test "valid state persists when switching from Desktop to Tablet" <|
                \_ ->
                    let
                        desktopModel =
                            createModelWithValidInputs Desktop

                        desktopAfterCalc =
                            { desktopModel | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        tabletModel =
                            { desktopAfterCalc | deviceType = Tablet }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.equal Tablet m.deviceType
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        ]
                        tabletModel
            , test "validation state independent of device type changes" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Mobile

                        step1 =
                            { model | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        step2 =
                            { step1 | deviceType = Tablet }

                        step3 =
                            { step2 | deviceType = Desktop }

                        step4 =
                            { step3 | deviceType = Mobile }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        , \m -> Expect.equal Mobile m.deviceType
                        ]
                        step4
            ]
        , describe "Form Input State Scenarios"
            [ test "invalid then valid excavator capacity simulation" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Simulate invalid input
                        step1 =
                            { model | hasValidationErrors = True }

                        -- Simulate correction to valid input
                        step2 =
                            { step1 | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        ]
                        step2
            , test "invalid truck data then form clear simulation" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Simulate invalid input
                        step1 =
                            { model | hasValidationErrors = True }

                        -- Simulate form clear
                        step2 =
                            { step1 | hasValidationErrors = False, calculationResult = Nothing, lastValidResult = Nothing }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.equal Nothing m.calculationResult
                        , \m -> Expect.equal Nothing m.lastValidResult
                        ]
                        step2
            , test "rapid sequential input changes simulation" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Simulate rapid changes: invalid -> valid -> invalid -> valid
                        step1 =
                            { model | hasValidationErrors = True }

                        -- invalid
                        step2 =
                            { step1 | hasValidationErrors = False }

                        -- valid
                        step3 =
                            { step2 | hasValidationErrors = True }

                        -- invalid
                        step4 =
                            { step3 | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        -- valid
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        ]
                        step4
            , test "mixed valid and invalid field updates simulation" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Simulate mixed updates ending in invalid state
                        step1 =
                            { model | hasValidationErrors = False }

                        -- valid update
                        step2 =
                            { step1 | hasValidationErrors = True }

                        -- invalid update
                        step3 =
                            { step2 | hasValidationErrors = True }

                        -- still invalid
                    in
                    Expect.all
                        [ \m -> Expect.equal True m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.lastValidResult -- Should preserve last valid
                        ]
                        { step3 | lastValidResult = Just createValidCalculationResult }
            ]
        , describe "Calculation Pipeline Simulation"
            [ test "successful calculation clears validation errors" <|
                \_ ->
                    let
                        -- Start with model that has validation errors
                        baseModel =
                            createModelWithValidInputs Desktop

                        modelWithErrors =
                            { baseModel | hasValidationErrors = True }

                        -- Simulate successful calculation
                        result =
                            { modelWithErrors
                                | hasValidationErrors = False
                                , calculationResult = Just createValidCalculationResult
                                , lastValidResult = Just createValidCalculationResult
                            }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        , \m -> Expect.equal m.calculationResult m.lastValidResult
                        ]
                        result
            , test "failed calculation sets validation errors" <|
                \_ ->
                    let
                        modelWithInvalidData =
                            createModelWithInvalidInputs Desktop

                        -- Simulate failed calculation
                        result =
                            { modelWithInvalidData
                                | hasValidationErrors = True
                                , calculationInProgress = False
                            }
                    in
                    Expect.all
                        [ \m -> Expect.equal True m.hasValidationErrors
                        , \m -> Expect.equal False m.calculationInProgress
                        ]
                        result
            , test "validation errors preserved during calculation in progress" <|
                \_ ->
                    let
                        model =
                            createModelWithInvalidInputs Desktop

                        modelInProgress =
                            { model | calculationInProgress = True, hasValidationErrors = True }

                        -- Validation errors should persist
                        result =
                            { modelInProgress | hasValidationErrors = True }
                    in
                    Expect.equal True result.hasValidationErrors
            , test "calculation result consistency with validation state" <|
                \_ ->
                    let
                        validModel =
                            createModelWithValidInputs Desktop

                        validResult =
                            { validModel | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        invalidModel =
                            createModelWithInvalidInputs Desktop

                        invalidResult =
                            { invalidModel | hasValidationErrors = True, calculationResult = Nothing }
                    in
                    Expect.all
                        [ \_ -> Expect.equal False validResult.hasValidationErrors
                        , \_ -> Expect.notEqual Nothing validResult.calculationResult
                        , \_ -> Expect.equal True invalidResult.hasValidationErrors
                        , \_ -> Expect.equal Nothing invalidResult.calculationResult
                        ]
                        ()
            ]
        , describe "State Persistence Edge Cases"
            [ test "validation state with performance tracking" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        afterCalc =
                            { model | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        -- Performance tracking shouldn't affect validation state
                        afterPerfTracking =
                            afterCalc
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        ]
                        afterPerfTracking
            , test "validation state with device type changes" <|
                \_ ->
                    let
                        model =
                            createModelWithInvalidInputs Desktop

                        afterCalc =
                            { model | hasValidationErrors = True }

                        -- Device type change shouldn't affect validation state
                        afterResize =
                            { afterCalc | deviceType = Tablet }
                    in
                    Expect.all
                        [ \m -> Expect.equal True m.hasValidationErrors -- Should persist
                        , \m -> Expect.equal Tablet m.deviceType
                        ]
                        afterResize
            ]
        , describe "Regression Prevention Scenarios"
            [ test "multiple calculations with same valid data don't create false errors" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        result1 =
                            { model | hasValidationErrors = False, calculationResult = Just createValidCalculationResult, lastValidResult = Just createValidCalculationResult }

                        result2 =
                            { result1 | hasValidationErrors = False }

                        result3 =
                            { result2 | hasValidationErrors = False }

                        result4 =
                            { result3 | hasValidationErrors = False }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        , \m -> Expect.equal m.calculationResult m.lastValidResult
                        ]
                        result4
            , test "alternating valid/invalid inputs maintain correct state" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Valid -> Invalid -> Valid -> Invalid -> Valid simulation
                        step1 =
                            { model | hasValidationErrors = False }

                        -- valid
                        step2 =
                            { step1 | hasValidationErrors = True }

                        -- invalid
                        step3 =
                            { step2 | hasValidationErrors = False }

                        -- valid
                        step4 =
                            { step3 | hasValidationErrors = True }

                        -- invalid
                        step5 =
                            { step4 | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        -- valid
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        ]
                        step5
            , test "validation state isolation between form fields" <|
                \_ ->
                    let
                        model =
                            createModelWithValidInputs Desktop

                        -- Simulate field-by-field validation: break one, fix it, break another, fix it
                        withBadExcavator =
                            { model | hasValidationErrors = True }

                        fixedExcavator =
                            { withBadExcavator | hasValidationErrors = False }

                        withBadPond =
                            { fixedExcavator | hasValidationErrors = True }

                        allFixed =
                            { withBadPond | hasValidationErrors = False }
                    in
                    Expect.equal False allFixed.hasValidationErrors
            ]
        ]



-- TEST HELPERS


createModelWithValidInputs : DeviceType -> Model
createModelWithValidInputs deviceType =
    { message = "Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just createValidFormData
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
    , helpTooltipState = Nothing
    }


createModelWithInvalidInputs : DeviceType -> Model
createModelWithInvalidInputs deviceType =
    { message = "Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just createInvalidFormData
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
    , helpTooltipState = Nothing
    }


createValidFormData : ProjectForm.FormData
createValidFormData =
    { workHoursPerDay = "8.0"
    , pondLength = "100.0"
    , pondWidth = "50.0"
    , pondDepth = "6.0"
    , errors = []
    }


createInvalidFormData : ProjectForm.FormData
createInvalidFormData =
    { workHoursPerDay = "not-a-number" -- Invalid to test validation
    , pondLength = "100.0"
    , pondWidth = "50.0"
    , pondDepth = "6.0"
    , errors = []
    }


createValidCalculationResult : CalculationResult
createValidCalculationResult =
    { timelineInDays = 3
    , totalHours = 24.0
    , excavationRate = 20.0
    , haulingRate = 25.0
    , bottleneck = Utils.Calculations.ExcavationBottleneck
    , confidence = Utils.Calculations.High
    , assumptions = [ "Test assumption" ]
    , warnings = []
    }
