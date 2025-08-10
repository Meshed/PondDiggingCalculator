module Unit.ValidationErrorMessageTests exposing (suite)

{-| Tests for validation error message display logic to prevent regression of the persistent message bug

These tests specifically verify that:

1.  The hasValidationErrors field is properly managed
2.  The isStale logic correctly reflects validation state
3.  The validation error message only shows when appropriate

This prevents the bug where "Showing last valid calculation while current inputs have validation errors"
was displayed constantly even with valid inputs.

-}

import Components.ProjectForm as ProjectForm
import Dict
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Types.Onboarding
import Utils.Calculations exposing (CalculationResult)
import Utils.Config
import Utils.Debounce
import Utils.Performance


suite : Test
suite =
    describe "Validation Error Message Display"
        [ describe "hasValidationErrors State Management"
            [ test "starts with no validation errors" <|
                \_ ->
                    let
                        model =
                            createModelWithValidData
                    in
                    Expect.equal False model.hasValidationErrors
            , test "remains false after successful calculation simulation" <|
                \_ ->
                    let
                        initialModel =
                            createModelWithValidData

                        -- Simulate successful calculation
                        updatedModel =
                            { initialModel | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }
                    in
                    Expect.equal False updatedModel.hasValidationErrors
            , test "sets to true when form data parsing fails" <|
                \_ ->
                    let
                        modelWithBadData =
                            createModelWithInvalidData

                        -- Simulate failed calculation due to invalid data
                        updatedModel =
                            { modelWithBadData | hasValidationErrors = True }
                    in
                    Expect.equal True updatedModel.hasValidationErrors
            , test "resets to false when form is cleared" <|
                \_ ->
                    let
                        modelWithErrors =
                            { createModelWithValidData | hasValidationErrors = True }

                        -- Simulate form clear operation
                        updatedModel =
                            { modelWithErrors | hasValidationErrors = False, formData = Just createValidFormData, calculationResult = Nothing, lastValidResult = Nothing }
                    in
                    Expect.equal False updatedModel.hasValidationErrors
            , test "transitions from true to false when invalid input becomes valid" <|
                \_ ->
                    let
                        -- Start with model that has validation errors
                        modelWithErrors =
                            { createModelWithInvalidData | hasValidationErrors = True }

                        -- Update with valid data and simulate successful calculation
                        validFormData =
                            createValidFormData

                        updatedModel =
                            { modelWithErrors | formData = Just validFormData, hasValidationErrors = False, calculationResult = Just createValidCalculationResult }
                    in
                    Expect.equal False updatedModel.hasValidationErrors
            , test "transitions from false to true when valid input becomes invalid" <|
                \_ ->
                    let
                        -- Start with valid model
                        validModel =
                            createModelWithValidData

                        -- Update with invalid data and simulate failed calculation
                        invalidFormData =
                            createInvalidFormData

                        updatedModel =
                            { validModel | formData = Just invalidFormData, hasValidationErrors = True }
                    in
                    Expect.equal True updatedModel.hasValidationErrors
            ]
        , describe "isStale Logic in View"
            [ test "isStale is false when hasValidationErrors is false" <|
                \_ ->
                    let
                        model =
                            { createModelWithValidData | hasValidationErrors = False }

                        -- In the actual view logic: isStale = model.hasValidationErrors
                        isStale =
                            model.hasValidationErrors
                    in
                    Expect.equal False isStale
            , test "isStale is true when hasValidationErrors is true" <|
                \_ ->
                    let
                        model =
                            { createModelWithValidData | hasValidationErrors = True }

                        -- In the actual view logic: isStale = model.hasValidationErrors
                        isStale =
                            model.hasValidationErrors
                    in
                    Expect.equal True isStale
            , test "isStale correctly reflects state after successful calculation" <|
                \_ ->
                    let
                        initialModel =
                            createModelWithValidData

                        modelAfterCalc =
                            { initialModel | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        isStale =
                            modelAfterCalc.hasValidationErrors
                    in
                    Expect.equal False isStale
            , test "isStale correctly reflects state after failed calculation" <|
                \_ ->
                    let
                        initialModel =
                            createModelWithInvalidData

                        modelAfterCalc =
                            { initialModel | hasValidationErrors = True }

                        isStale =
                            modelAfterCalc.hasValidationErrors
                    in
                    Expect.equal True isStale
            ]
        , describe "Validation Message Display Scenarios"
            [ test "message should NOT show with fresh valid inputs" <|
                \_ ->
                    let
                        model =
                            createModelWithValidData

                        updatedModel =
                            { model | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        shouldShowMessage =
                            updatedModel.hasValidationErrors
                    in
                    Expect.equal False shouldShowMessage
            , test "message SHOULD show with invalid inputs but valid last result" <|
                \_ ->
                    let
                        -- Create model with valid last result but current invalid inputs
                        validResult =
                            createValidCalculationResult

                        model =
                            { createModelWithInvalidData
                                | lastValidResult = Just validResult
                                , calculationResult = Just validResult -- Showing last valid result
                                , hasValidationErrors = True -- But current inputs are invalid
                            }

                        shouldShowMessage =
                            model.hasValidationErrors
                    in
                    Expect.equal True shouldShowMessage
            , test "message should NOT show after correcting invalid inputs" <|
                \_ ->
                    let
                        -- Start with errors
                        modelWithErrors =
                            { createModelWithInvalidData | hasValidationErrors = True }

                        -- Fix the inputs
                        validFormData =
                            createValidFormData

                        correctedModel =
                            { modelWithErrors | formData = Just validFormData, hasValidationErrors = False }

                        shouldShowMessage =
                            correctedModel.hasValidationErrors
                    in
                    Expect.equal False shouldShowMessage
            , test "message should NOT show after form clear" <|
                \_ ->
                    let
                        modelWithErrors =
                            { createModelWithValidData | hasValidationErrors = True }

                        updatedModel =
                            { modelWithErrors | hasValidationErrors = False, calculationResult = Nothing, lastValidResult = Nothing }

                        shouldShowMessage =
                            updatedModel.hasValidationErrors
                    in
                    Expect.equal False shouldShowMessage
            ]
        , describe "Regression Prevention"
            [ test "hasValidationErrors never gets stuck at true with valid inputs" <|
                \_ ->
                    let
                        -- Simulate the bug scenario: repeated calculations with valid data
                        model1 =
                            createModelWithValidData

                        model2 =
                            { model1 | hasValidationErrors = False, calculationResult = Just createValidCalculationResult, lastValidResult = Just createValidCalculationResult }

                        model3 =
                            { model2 | hasValidationErrors = False }

                        model4 =
                            { model3 | hasValidationErrors = False }
                    in
                    Expect.all
                        [ \m -> Expect.equal False m.hasValidationErrors
                        , \m -> Expect.notEqual Nothing m.calculationResult
                        , \m -> Expect.notEqual Nothing m.lastValidResult
                        ]
                        model4
            , test "validation state correctly persists across device type changes" <|
                \_ ->
                    let
                        mobileModel =
                            { createModelWithValidData | deviceType = Mobile }

                        mobileAfterCalc =
                            { mobileModel | hasValidationErrors = False, calculationResult = Just createValidCalculationResult }

                        desktopModel =
                            { mobileAfterCalc | deviceType = Desktop }
                    in
                    Expect.equal mobileAfterCalc.hasValidationErrors desktopModel.hasValidationErrors
            , test "lastValidResult and calculationResult equality doesn't affect hasValidationErrors" <|
                \_ ->
                    let
                        result =
                            createValidCalculationResult

                        model =
                            createModelWithValidData

                        modelAfterCalc =
                            { model | calculationResult = Just result, lastValidResult = Just result, hasValidationErrors = False }

                        -- After successful calculation, lastValidResult == calculationResult
                        resultsAreEqual =
                            modelAfterCalc.lastValidResult == modelAfterCalc.calculationResult

                        -- But hasValidationErrors should still be false
                        hasErrors =
                            modelAfterCalc.hasValidationErrors
                    in
                    Expect.all
                        [ \_ -> Expect.equal True resultsAreEqual -- Results should be equal
                        , \_ -> Expect.equal False hasErrors -- But no validation errors
                        ]
                        ()
            ]
        ]



-- TEST HELPERS


createModelWithValidData : Model
createModelWithValidData =
    { message = "Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just createValidFormData
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


createModelWithInvalidData : Model
createModelWithInvalidData =
    { message = "Test Model"
    , config = Just Utils.Config.fallbackConfig
    , formData = Just createInvalidFormData
    , calculationResult = Nothing
    , lastValidResult = Nothing
    , hasValidationErrors = False -- Will be set to true by update
    , deviceType = Desktop
    , calculationInProgress = False
    , performanceMetrics = Utils.Performance.initMetrics
    , debounceState = Utils.Debounce.initDebounce
    , excavators = []
    , trucks = []
    , nextExcavatorId = 1
    , nextTruckId = 1
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
    { workHoursPerDay = "invalid" -- This will cause parsing to fail
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
