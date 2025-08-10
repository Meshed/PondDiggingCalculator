module Main exposing (main)

import Browser
import Browser.Events
import Components.HelpSystem as HelpSystem
import Components.OnboardingManager as OnboardingManager
import Components.ProjectForm as ProjectForm
import Components.ResultsPanel as ResultsPanel
import Dict
import Html exposing (Html, div, h1, h2, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Pages.Desktop as Desktop
import Process
import Task
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (ExcavatorUpdate(..), Msg(..), TruckUpdate(..))
import Types.Model exposing (Flags, Model)
import Types.Onboarding exposing (OnboardingState(..))
import Types.Validation exposing (ValidationError(..))
import Utils.Calculations as Calculations
import Utils.Config exposing (Config, fallbackConfig, getConfig)
import Utils.Debounce as Debounce
import Utils.DeviceDetector as DeviceDetector
import Utils.ExampleScenario as ExampleScenario
import Utils.Performance as Performance
import Utils.Storage as Storage
import Utils.Validation as Validation
import Views.MobileView as MobileView



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


init : Flags -> ( Model, Cmd Msg )
init _ =
    let
        -- Load configuration at build time (no HTTP request needed)
        config =
            getConfig

        newFormData =
            ProjectForm.initFormData config.defaults

        -- Initialize fleet from configuration defaults
        initialExcavators =
            initExcavatorsFromConfig config.defaults.excavators 1

        initialTrucks =
            initTrucksFromConfig config.defaults.trucks 1

        modelWithData =
            { message = "Pond Digging Calculator - Core Calculation Engine"
            , config = Just config
            , formData = Just newFormData
            , calculationResult = Nothing
            , lastValidResult = Nothing
            , hasValidationErrors = False -- Start with no validation errors
            , deviceType = Desktop -- Default to Desktop until detection completes
            , calculationInProgress = False
            , performanceMetrics = Performance.initMetrics
            , debounceState = Debounce.initDebounce
            , excavators = initialExcavators
            , trucks = initialTrucks
            , nextExcavatorId = 1 + List.length initialExcavators -- Start ID counter after initial fleet
            , nextTruckId = 1 + List.length initialTrucks -- Start ID counter after initial fleet
            , helpTooltipState = Nothing -- No active tooltip initially
            , showHelpPanel = False -- Help panel hidden initially
            , currentContextualHelp = Nothing -- No contextual help shown initially
            , realTimeValidation = True -- Enable real-time validation by default
            , fieldValidationErrors = Dict.empty -- No validation errors initially
            , validationDebounce = Dict.empty -- No debounce state initially

            -- Initialize onboarding state
            , onboardingState = NotStarted
            , showWelcomeOverlay = True -- Show welcome overlay for first-time users
            , currentTourStep = Nothing
            , isFirstTimeUser = True -- Will be updated based on storage
            , exampleScenarioLoaded = False
            }
    in
    -- Initialize with data and immediately trigger calculation with default values
    update CalculateTimeline modelWithData
        |> Tuple.mapSecond
            (\cmd ->
                Cmd.batch
                    [ cmd
                    , DeviceDetector.detectDevice () |> Cmd.map DeviceDetected
                    , Storage.loadOnboardingState OnboardingStateLoaded
                    ]
            )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ConfigLoaded _ ->
            -- Configuration is now loaded at build time, this message is obsolete
            -- Keeping for backward compatibility with Mobile.elm
            ( model, Cmd.none )

        FormUpdated formMsg ->
            case formMsg of
                ProjectForm.ClearForm ->
                    -- Reset form to config defaults
                    case model.config of
                        Just config ->
                            let
                                resetFormData =
                                    ProjectForm.initFormData config.defaults

                                newModel =
                                    { model
                                        | formData = Just resetFormData
                                        , calculationResult = Nothing
                                        , lastValidResult = Nothing
                                        , hasValidationErrors = False -- Clear validation errors
                                    }
                            in
                            ( newModel, Cmd.none )

                        Nothing ->
                            let
                                fallbackFormData =
                                    ProjectForm.initFormData fallbackConfig.defaults

                                newModel =
                                    { model
                                        | formData = Just fallbackFormData
                                        , calculationResult = Nothing
                                        , lastValidResult = Nothing
                                        , hasValidationErrors = False -- Clear validation errors
                                    }
                            in
                            ( newModel, Cmd.none )

                _ ->
                    -- Handle normal form updates
                    case model.formData of
                        Just formData ->
                            let
                                updatedFormData =
                                    ProjectForm.updateFormData formMsg formData

                                newModel =
                                    { model | formData = Just updatedFormData }
                            in
                            -- Trigger calculation when form changes
                            update CalculateTimeline newModel

                        Nothing ->
                            ( model, Cmd.none )

        -- Equipment field handlers removed - equipment now managed via fleet system (UpdateExcavator, UpdateTruck)
        ExcavatorFieldChanged _ _ ->
            -- Equipment field changes now handled by fleet system - this is a no-op for compatibility
            ( model, Cmd.none )

        TruckFieldChanged _ _ ->
            -- Equipment field changes now handled by fleet system - this is a no-op for compatibility
            ( model, Cmd.none )

        PondFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        ( updatedFormData, fieldName ) =
                            case field of
                                PondLength ->
                                    ( { formData | pondLength = value }, "pondLength" )

                                PondWidth ->
                                    ( { formData | pondWidth = value }, "pondWidth" )

                                PondDepth ->
                                    ( { formData | pondDepth = value }, "pondDepth" )

                        newModel =
                            { model
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    -- Chain validation and calculation updates
                    update CalculateTimeline newModel
                        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Task.perform (ValidateField fieldName) (Task.succeed value) ])

                Nothing ->
                    ( model, Cmd.none )

        ProjectFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        ( updatedFormData, fieldName ) =
                            case field of
                                WorkHours ->
                                    ( { formData | workHoursPerDay = value }, "workHours" )

                        newModel =
                            { model
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    -- Chain validation and calculation updates
                    update CalculateTimeline newModel
                        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Task.perform (ValidateField fieldName) (Task.succeed value) ])

                Nothing ->
                    ( model, Cmd.none )

        CalculateTimeline ->
            -- For real-time updates, calculate immediately for now
            -- TODO: Implement proper debouncing with Process.sleep in future iteration
            calculateAndUpdate model

        CalculateTimelineDebounced _ ->
            -- Simplified debouncing - for now just calculate
            calculateAndUpdate model

        CalculationCompleted result ->
            case result of
                Ok resultString ->
                    -- In a real implementation, this would handle calculation results
                    -- For now, calculations are handled synchronously in calculateAndUpdate
                    ( model, Cmd.none )

                Err errorString ->
                    -- Log calculation errors but preserve last valid result
                    ( { model | calculationResult = model.lastValidResult }, Cmd.none )

        PerformanceTracked timeMs ->
            let
                updatedMetrics =
                    Performance.recordCalculationTime timeMs model.performanceMetrics

                -- Performance tracking for monitoring (removed Debug.log for production)
            in
            ( { model | performanceMetrics = updatedMetrics }, Cmd.none )

        -- Fleet Management Messages
        AddExcavator ->
            addExcavator model

        RemoveExcavator equipmentId ->
            removeExcavator equipmentId model

        UpdateExcavator equipmentId excavatorUpdate ->
            updateExcavator equipmentId excavatorUpdate model

        AddTruck ->
            addTruck model

        RemoveTruck equipmentId ->
            removeTruck equipmentId model

        UpdateTruck equipmentId truckUpdate ->
            updateTruck equipmentId truckUpdate model

        ValidationFailed _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )

        DeviceDetected result ->
            case result of
                Ok windowSize ->
                    let
                        deviceType =
                            Types.DeviceType.fromWindowSize windowSize
                    in
                    ( { model | deviceType = deviceType }, Cmd.none )

                Err _ ->
                    -- Keep default device type on error
                    ( model, Cmd.none )

        WindowResized width height ->
            let
                deviceType =
                    Types.DeviceType.fromWindowSize { width = width, height = height }
            in
            ( { model | deviceType = deviceType }, Cmd.none )

        ShowHelpTooltip fieldId ->
            ( { model | helpTooltipState = Just fieldId }, Cmd.none )

        HideHelpTooltip fieldId ->
            ( { model | helpTooltipState = Nothing }, Cmd.none )

        ToggleHelpPanel ->
            ( { model | showHelpPanel = not model.showHelpPanel }, Cmd.none )

        ShowContextualHelp sectionId ->
            ( { model | currentContextualHelp = Just sectionId, showHelpPanel = True }, Cmd.none )

        RestartGuidedTour ->
            let
                updatedModel =
                    { model
                        | showHelpPanel = False
                        , onboardingState = NotStarted
                        , currentTourStep = Nothing
                        , showWelcomeOverlay = True
                    }
            in
            ( updatedModel, Cmd.none )

        KeyPressed key ->
            case key of
                "Escape" ->
                    ( { model | helpTooltipState = Nothing }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ValidateField fieldName value ->
            if model.realTimeValidation then
                case model.config of
                    Just config ->
                        let
                            validationResult =
                                validateFieldValue fieldName value config

                            updatedErrors =
                                case validationResult of
                                    Ok _ ->
                                        Dict.remove fieldName model.fieldValidationErrors

                                    Err error ->
                                        Dict.insert fieldName error model.fieldValidationErrors

                            updatedModel =
                                { model | fieldValidationErrors = updatedErrors }
                        in
                        ( updatedModel, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        ValidationComplete fieldName result ->
            let
                updatedErrors =
                    case result of
                        Ok _ ->
                            Dict.remove fieldName model.fieldValidationErrors

                        Err error ->
                            Dict.insert fieldName error model.fieldValidationErrors
            in
            ( { model | fieldValidationErrors = updatedErrors }, Cmd.none )

        ToggleRealTimeValidation enabled ->
            let
                updatedModel =
                    { model
                        | realTimeValidation = enabled
                        , fieldValidationErrors =
                            if enabled then
                                model.fieldValidationErrors

                            else
                                Dict.empty
                    }
            in
            ( updatedModel, Cmd.none )

        -- Onboarding Messages
        OnboardingStateLoaded maybeJsonState ->
            case maybeJsonState of
                Just jsonString ->
                    let
                        loadedState =
                            Storage.decodeOnboardingState jsonString

                        updatedModel =
                            { model
                                | onboardingState = loadedState
                                , isFirstTimeUser = False
                                , showWelcomeOverlay = loadedState == NotStarted
                            }
                    in
                    ( updatedModel, Cmd.none )

                Nothing ->
                    -- First-time user - keep initial onboarding state
                    ( model, Cmd.none )

        StartGuidedTour ->
            let
                updatedModel =
                    { model
                        | onboardingState = TourInProgress 0
                        , currentTourStep = Just Types.Onboarding.IntroStep
                        , showWelcomeOverlay = False
                    }
            in
            ( updatedModel, Storage.saveOnboardingState (TourInProgress 0) )

        NextTourStep ->
            case model.onboardingState of
                TourInProgress currentStepIndex ->
                    let
                        config =
                            Types.Onboarding.defaultOnboardingConfig model.deviceType

                        nextStepIndex =
                            currentStepIndex + 1

                        maxStepIndex =
                            List.length config.tourSteps - 1
                    in
                    if nextStepIndex <= maxStepIndex then
                        let
                            nextStep =
                                List.drop nextStepIndex config.tourSteps
                                    |> List.head
                                    |> Maybe.withDefault Types.Onboarding.CompletionStep

                            updatedModel =
                                { model
                                    | onboardingState = TourInProgress nextStepIndex
                                    , currentTourStep = Just nextStep
                                }
                        in
                        ( updatedModel, Storage.saveOnboardingState (TourInProgress nextStepIndex) )

                    else
                        -- Tour completed
                        update CompleteTour model

                _ ->
                    ( model, Cmd.none )

        PreviousTourStep ->
            case model.onboardingState of
                TourInProgress currentStepIndex ->
                    if currentStepIndex > 0 then
                        let
                            config =
                                Types.Onboarding.defaultOnboardingConfig model.deviceType

                            prevStepIndex =
                                currentStepIndex - 1

                            prevStep =
                                List.drop prevStepIndex config.tourSteps
                                    |> List.head
                                    |> Maybe.withDefault Types.Onboarding.IntroStep

                            updatedModel =
                                { model
                                    | onboardingState = TourInProgress prevStepIndex
                                    , currentTourStep = Just prevStep
                                }
                        in
                        ( updatedModel, Storage.saveOnboardingState (TourInProgress prevStepIndex) )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CompleteTour ->
            let
                updatedModel =
                    { model
                        | onboardingState = Completed
                        , currentTourStep = Nothing
                        , showWelcomeOverlay = False
                    }
            in
            ( updatedModel, Storage.saveOnboardingState Completed )

        SkipOnboarding ->
            let
                updatedModel =
                    { model
                        | onboardingState = Completed
                        , showWelcomeOverlay = False
                        , currentTourStep = Nothing
                    }
            in
            ( updatedModel, Storage.saveOnboardingState Completed )

        LoadExampleScenario ->
            let
                ( updatedModel, cmd ) =
                    ExampleScenario.loadExampleScenario model
            in
            -- Trigger calculation after loading example
            update CalculateTimeline updatedModel
                |> Tuple.mapSecond (\calcCmd -> Cmd.batch [ cmd, calcCmd ])

        ClearExampleScenario ->
            let
                ( updatedModel, cmd ) =
                    ExampleScenario.clearExampleScenario model
            in
            -- Trigger calculation after clearing example
            update CalculateTimeline updatedModel
                |> Tuple.mapSecond (\calcCmd -> Cmd.batch [ cmd, calcCmd ])

        DismissWelcomeOverlay ->
            ( { model | showWelcomeOverlay = False }, Cmd.none )



-- FLEET MANAGEMENT HELPERS


{-| Initialize excavators from configuration defaults with generated IDs
-}
initExcavatorsFromConfig : List Utils.Config.ExcavatorDefaults -> Int -> List Excavator
initExcavatorsFromConfig excavatorDefaults startId =
    List.indexedMap
        (\index defaults ->
            { id = "excavator-" ++ String.fromInt (startId + index)
            , bucketCapacity = defaults.bucketCapacity
            , cycleTime = defaults.cycleTime
            , name = defaults.name
            , isActive = True
            }
        )
        excavatorDefaults


{-| Initialize trucks from configuration defaults with generated IDs
-}
initTrucksFromConfig : List Utils.Config.TruckDefaults -> Int -> List Truck
initTrucksFromConfig truckDefaults startId =
    List.indexedMap
        (\index defaults ->
            { id = "truck-" ++ String.fromInt (startId + index)
            , capacity = defaults.capacity
            , roundTripTime = defaults.roundTripTime
            , name = defaults.name
            , isActive = True
            }
        )
        truckDefaults


{-| Add a new excavator to the fleet (immutable)
-}
addExcavator : Model -> ( Model, Cmd Msg )
addExcavator model =
    case model.config of
        Just config ->
            -- Check fleet size limits
            if List.length model.excavators >= config.fleetLimits.maxExcavators then
                ( model, Cmd.none )

            else
                let
                    -- Use first excavator defaults as template
                    defaults =
                        List.head config.defaults.excavators
                            |> Maybe.withDefault
                                { bucketCapacity = 2.5
                                , cycleTime = 2.0
                                , name = "New Excavator"
                                }

                    newExcavator =
                        { id = "excavator-" ++ String.fromInt model.nextExcavatorId
                        , bucketCapacity = defaults.bucketCapacity
                        , cycleTime = defaults.cycleTime
                        , name = defaults.name ++ " " ++ String.fromInt model.nextExcavatorId
                        , isActive = True
                        }

                    updatedModel =
                        { model
                            | excavators = model.excavators ++ [ newExcavator ]
                            , nextExcavatorId = model.nextExcavatorId + 1
                        }
                in
                update CalculateTimeline updatedModel

        Nothing ->
            ( model, Cmd.none )


{-| Remove an excavator from the fleet (immutable)
-}
removeExcavator : EquipmentId -> Model -> ( Model, Cmd Msg )
removeExcavator equipmentId model =
    -- Enforce minimum one excavator rule
    if List.length model.excavators <= 1 then
        ( model, Cmd.none )

    else
        let
            updatedExcavators =
                List.filter (\excavator -> excavator.id /= equipmentId) model.excavators

            updatedModel =
                { model | excavators = updatedExcavators }
        in
        update CalculateTimeline updatedModel


{-| Update an excavator in the fleet (immutable)
-}
updateExcavator : EquipmentId -> ExcavatorUpdate -> Model -> ( Model, Cmd Msg )
updateExcavator equipmentId excavatorUpdate model =
    let
        updateExcavatorItem excavator =
            if excavator.id == equipmentId then
                case excavatorUpdate of
                    UpdateExcavatorBucketCapacity capacity ->
                        { excavator | bucketCapacity = capacity }

                    UpdateExcavatorCycleTime cycleTime ->
                        { excavator | cycleTime = cycleTime }

                    UpdateExcavatorName name ->
                        { excavator | name = name }

                    UpdateExcavatorActive active ->
                        { excavator | isActive = active }

            else
                excavator

        updatedExcavators =
            List.map updateExcavatorItem model.excavators

        updatedModel =
            { model | excavators = updatedExcavators }
    in
    update CalculateTimeline updatedModel


{-| Add a new truck to the fleet (immutable)
-}
addTruck : Model -> ( Model, Cmd Msg )
addTruck model =
    case model.config of
        Just config ->
            -- Check fleet size limits
            if List.length model.trucks >= config.fleetLimits.maxTrucks then
                ( model, Cmd.none )

            else
                let
                    -- Use first truck defaults as template
                    defaults =
                        List.head config.defaults.trucks
                            |> Maybe.withDefault
                                { capacity = 12.0
                                , roundTripTime = 15.0
                                , name = "New Truck"
                                }

                    newTruck =
                        { id = "truck-" ++ String.fromInt model.nextTruckId
                        , capacity = defaults.capacity
                        , roundTripTime = defaults.roundTripTime
                        , name = defaults.name ++ " " ++ String.fromInt model.nextTruckId
                        , isActive = True
                        }

                    updatedModel =
                        { model
                            | trucks = model.trucks ++ [ newTruck ]
                            , nextTruckId = model.nextTruckId + 1
                        }
                in
                update CalculateTimeline updatedModel

        Nothing ->
            ( model, Cmd.none )


{-| Remove a truck from the fleet (immutable)
-}
removeTruck : EquipmentId -> Model -> ( Model, Cmd Msg )
removeTruck equipmentId model =
    -- Enforce minimum one truck rule
    if List.length model.trucks <= 1 then
        ( model, Cmd.none )

    else
        let
            updatedTrucks =
                List.filter (\truck -> truck.id /= equipmentId) model.trucks

            updatedModel =
                { model | trucks = updatedTrucks }
        in
        update CalculateTimeline updatedModel


{-| Update a truck in the fleet (immutable)
-}
updateTruck : EquipmentId -> TruckUpdate -> Model -> ( Model, Cmd Msg )
updateTruck equipmentId truckUpdate model =
    let
        updateTruckItem truck =
            if truck.id == equipmentId then
                case truckUpdate of
                    UpdateTruckCapacity capacity ->
                        { truck | capacity = capacity }

                    UpdateTruckRoundTripTime roundTripTime ->
                        { truck | roundTripTime = roundTripTime }

                    UpdateTruckName name ->
                        { truck | name = name }

                    UpdateTruckActive active ->
                        { truck | isActive = active }

            else
                truck

        updatedTrucks =
            List.map updateTruckItem model.trucks

        updatedModel =
            { model | trucks = updatedTrucks }
    in
    update CalculateTimeline updatedModel



-- CALCULATION HELPERS


{-| Calculate timeline based on current form data and update model with performance tracking
-}
calculateAndUpdate : Model -> ( Model, Cmd Msg )
calculateAndUpdate model =
    case model.config of
        Just config ->
            case parseModelData model of
                Ok inputs ->
                    case Validation.validateAllInputs config.validation inputs of
                        Ok validInputs ->
                            let
                                pondVolume =
                                    calculatePondVolume validInputs.pondLength validInputs.pondWidth validInputs.pondDepth

                                calculationResult =
                                    Calculations.performCalculation
                                        model.excavators
                                        model.trucks
                                        pondVolume
                                        validInputs.workHoursPerDay

                                -- Simulate performance tracking (50ms typical calculation time)
                                performanceCmd =
                                    Task.perform PerformanceTracked (Task.succeed 50.0)
                            in
                            case calculationResult of
                                Ok result ->
                                    ( { model
                                        | calculationResult = Just result
                                        , lastValidResult = Just result
                                        , hasValidationErrors = False -- Calculation succeeded
                                        , calculationInProgress = False
                                      }
                                    , performanceCmd
                                    )

                                Err _ ->
                                    ( { model
                                        | calculationResult = model.lastValidResult
                                        , hasValidationErrors = True -- Calculation failed
                                        , calculationInProgress = False
                                      }
                                    , performanceCmd
                                    )

                        Err _ ->
                            -- Validation failed - keep last valid result
                            ( { model
                                | calculationResult = model.lastValidResult
                                , hasValidationErrors = True -- Validation failed
                                , calculationInProgress = False
                              }
                            , Cmd.none
                            )

                Err _ ->
                    -- Parse failed - keep last valid result
                    ( { model
                        | calculationResult = model.lastValidResult
                        , hasValidationErrors = True -- Parse failed
                        , calculationInProgress = False
                      }
                    , Cmd.none
                    )

        Nothing ->
            ( model, Cmd.none )


{-| Validate a field value in real-time
-}
validateFieldValue : String -> String -> Config -> Result ValidationError Float
validateFieldValue fieldName value config =
    case fieldName of
        "workHours" ->
            Validation.validateStringInput "Work Hours" config.validation.workHours value

        "pondLength" ->
            Validation.validateStringInput "Pond Dimension" config.validation.pondDimensions value

        "pondWidth" ->
            Validation.validateStringInput "Pond Dimension" config.validation.pondDimensions value

        "pondDepth" ->
            Validation.validateStringInput "Pond Dimension" config.validation.pondDimensions value

        "excavatorCapacity" ->
            Validation.validateStringInput "Excavator Capacity" config.validation.excavatorCapacity value

        "cycleTime" ->
            Validation.validateStringInput "Cycle Time" config.validation.cycleTime value

        "truckCapacity" ->
            Validation.validateStringInput "Truck Capacity" config.validation.truckCapacity value

        "roundTripTime" ->
            Validation.validateStringInput "Round Trip Time" config.validation.roundTripTime value

        _ ->
            Err (ConfigurationError ("Unknown field: " ++ fieldName))


{-| Calculate pond volume from dimensions in cubic yards
-}
calculatePondVolume : Float -> Float -> Float -> Float
calculatePondVolume length width depth =
    -- Convert from cubic feet to cubic yards (divide by 27)
    (length * width * depth) / 27.0


{-| Parse model data to numeric inputs using fleet system
-}
parseModelData : Model -> Result String Validation.ProjectInputs
parseModelData model =
    case model.formData of
        Just formData ->
            let
                -- Get first excavator and truck for calculation (mobile compatibility)
                firstExcavator =
                    List.head model.excavators

                firstTruck =
                    List.head model.trucks

                -- Parse project parameters from form
                maybeProjectFloats =
                    { workHoursPerDay = String.toFloat formData.workHoursPerDay
                    , pondLength = String.toFloat formData.pondLength
                    , pondWidth = String.toFloat formData.pondWidth
                    , pondDepth = String.toFloat formData.pondDepth
                    }
            in
            case ( firstExcavator, firstTruck ) of
                ( Just excavator, Just truck ) ->
                    case ( maybeProjectFloats.workHoursPerDay, maybeProjectFloats.pondLength ) of
                        ( Just workHoursPerDay, Just pondLength ) ->
                            case ( maybeProjectFloats.pondWidth, maybeProjectFloats.pondDepth ) of
                                ( Just pondWidth, Just pondDepth ) ->
                                    Ok
                                        { excavatorCapacity = excavator.bucketCapacity
                                        , excavatorCycleTime = excavator.cycleTime
                                        , truckCapacity = truck.capacity
                                        , truckRoundTripTime = truck.roundTripTime
                                        , workHoursPerDay = workHoursPerDay
                                        , pondLength = pondLength
                                        , pondWidth = pondWidth
                                        , pondDepth = pondDepth
                                        }

                                _ ->
                                    Err "Invalid pond dimensions format"

                        _ ->
                            Err "Invalid work parameters format"

                _ ->
                    Err "No equipment available for calculation"

        Nothing ->
            Err "No form data available"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize WindowResized
        , if model.helpTooltipState /= Nothing then
            Browser.Events.onKeyDown keyDecoder

          else
            Sub.none
        ]


{-| Decode keyboard events
-}
keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map KeyPressed (Decode.field "key" Decode.string)



-- VIEW


view : Model -> Html Msg
view model =
    let
        mainView =
            -- Route to mobile view for mobile devices (now using SHARED state!)
            case model.deviceType of
                Mobile ->
                    MobileView.view model

                _ ->
                    -- Desktop/Tablet view - Use the full Desktop page with fleet management
                    Desktop.view model
    in
    div []
        [ mainView

        -- Show onboarding components (welcome overlay, guided tour, etc.)
        , OnboardingManager.view model

        -- Show help system only when welcome overlay is not active (prevents question marks in overlay)
        , if not model.showWelcomeOverlay then
            HelpSystem.view model.deviceType model.helpTooltipState model.showHelpPanel model.currentContextualHelp

          else
            text ""
        ]
