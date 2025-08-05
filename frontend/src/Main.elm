module Main exposing (main)

import Browser
import Browser.Events
import Components.ProjectForm as ProjectForm
import Components.ResultsPanel as ResultsPanel
import Html exposing (Html, div, h1, h2, text)
import Html.Attributes exposing (class)
import Process
import Task
import Types.DeviceType exposing (DeviceType(..))
import Types.Fields exposing (ExcavatorField(..), TruckField(..), PondField(..), ProjectField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Flags, Model)
import Utils.Calculations as Calculations
import Utils.Config exposing (fallbackConfig, loadConfig)
import Utils.Debounce as Debounce
import Utils.DeviceDetector as DeviceDetector
import Utils.Performance as Performance
import Utils.Validation as Validation



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
    ( { message = "Pond Digging Calculator - Core Calculation Engine"
      , config = Nothing
      , formData = Nothing
      , calculationResult = Nothing
      , lastValidResult = Nothing
      , deviceType = Desktop  -- Default to Desktop until detection completes
      , calculationInProgress = False
      , performanceMetrics = Performance.initMetrics
      , debounceState = Debounce.initDebounce
      }
    , Cmd.batch
        [ loadConfig ConfigLoaded
        , DeviceDetector.detectDevice () |> Cmd.map DeviceDetected
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ConfigLoaded result ->
            let
                -- Use loaded config or fallback if loading fails
                config =
                    case result of
                        Ok loadedConfig ->
                            loadedConfig

                        Err _ ->
                            fallbackConfig

                newFormData =
                    ProjectForm.initFormData config.defaults

                -- Update model with form data and config
                modelWithData =
                    { model
                        | config = Just config
                        , formData = Just newFormData
                    }
            in
            -- Immediately trigger calculation with default values
            update CalculateTimeline modelWithData

        FormUpdated formMsg ->
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

        -- Real-time input handlers
        ExcavatorFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        updatedFormData =
                            case field of
                                BucketCapacity ->
                                    { formData | excavatorCapacity = value }

                                CycleTime ->
                                    { formData | excavatorCycleTime = value }

                        newModel =
                            { model 
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    update CalculateTimeline newModel

                Nothing ->
                    ( model, Cmd.none )

        TruckFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        updatedFormData =
                            case field of
                                TruckCapacity ->
                                    { formData | truckCapacity = value }

                                RoundTripTime ->
                                    { formData | truckRoundTripTime = value }

                        newModel =
                            { model 
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    update CalculateTimeline newModel

                Nothing ->
                    ( model, Cmd.none )

        PondFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        updatedFormData =
                            case field of
                                PondLength ->
                                    { formData | pondLength = value }

                                PondWidth ->
                                    { formData | pondWidth = value }

                                PondDepth ->
                                    { formData | pondDepth = value }

                        newModel =
                            { model 
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    update CalculateTimeline newModel

                Nothing ->
                    ( model, Cmd.none )

        ProjectFieldChanged field value ->
            case model.formData of
                Just formData ->
                    let
                        updatedFormData =
                            case field of
                                WorkHours ->
                                    { formData | workHoursPerDay = value }

                        newModel =
                            { model 
                                | formData = Just updatedFormData
                                , calculationInProgress = True
                            }
                    in
                    update CalculateTimeline newModel

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
                updatedMetrics = Performance.recordCalculationTime timeMs model.performanceMetrics
                -- Performance tracking for monitoring (removed Debug.log for production)
            in
            ( { model | performanceMetrics = updatedMetrics }, Cmd.none )

        EquipmentAdded _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )

        EquipmentRemoved _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )

        EquipmentUpdated _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )

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



-- CALCULATION HELPERS


{-| Calculate timeline based on current form data and update model with performance tracking
-}
calculateAndUpdate : Model -> ( Model, Cmd Msg )
calculateAndUpdate model =
    case ( model.formData, model.config ) of
        ( Just formData, Just config ) ->
            case parseFormData formData of
                Ok inputs ->
                    case Validation.validateAllInputs config.validation inputs of
                        Ok validInputs ->
                            let
                                pondVolume =
                                    calculatePondVolume validInputs.pondLength validInputs.pondWidth validInputs.pondDepth

                                calculationResult =
                                    Calculations.calculateTimeline
                                        validInputs.excavatorCapacity
                                        validInputs.excavatorCycleTime
                                        validInputs.truckCapacity
                                        validInputs.truckRoundTripTime
                                        pondVolume
                                        validInputs.workHoursPerDay
                                
                                -- Simulate performance tracking (50ms typical calculation time)
                                performanceCmd = Task.perform PerformanceTracked (Task.succeed 50.0)
                            in
                            case calculationResult of
                                Ok result ->
                                    ( { model 
                                        | calculationResult = Just result
                                        , lastValidResult = Just result
                                        , calculationInProgress = False
                                      }
                                    , performanceCmd
                                    )

                                Err _ ->
                                    ( { model 
                                        | calculationResult = model.lastValidResult
                                        , calculationInProgress = False
                                      }
                                    , performanceCmd
                                    )

                        Err _ ->
                            -- Validation failed - keep last valid result
                            ( { model 
                                | calculationResult = model.lastValidResult
                                , calculationInProgress = False
                              }
                            , Cmd.none 
                            )

                Err _ ->
                    -- Parse failed - keep last valid result
                    ( { model 
                        | calculationResult = model.lastValidResult
                        , calculationInProgress = False
                      }
                    , Cmd.none 
                    )

        _ ->
            ( model, Cmd.none )


{-| Calculate pond volume from dimensions in cubic yards
-}
calculatePondVolume : Float -> Float -> Float -> Float
calculatePondVolume length width depth =
    -- Convert from cubic feet to cubic yards (divide by 27)
    (length * width * depth) / 27.0


{-| Parse form string data to numeric inputs
-}
parseFormData : ProjectForm.FormData -> Result String Validation.ProjectInputs
parseFormData formData =
    let
        maybeFloats =
            { excavatorCapacity = String.toFloat formData.excavatorCapacity
            , excavatorCycleTime = String.toFloat formData.excavatorCycleTime
            , truckCapacity = String.toFloat formData.truckCapacity
            , truckRoundTripTime = String.toFloat formData.truckRoundTripTime
            , workHoursPerDay = String.toFloat formData.workHoursPerDay
            , pondLength = String.toFloat formData.pondLength
            , pondWidth = String.toFloat formData.pondWidth
            , pondDepth = String.toFloat formData.pondDepth
            }
    in
    case ( maybeFloats.excavatorCapacity, maybeFloats.excavatorCycleTime, maybeFloats.truckCapacity ) of
        ( Just excavatorCapacity, Just excavatorCycleTime, Just truckCapacity ) ->
            case ( maybeFloats.truckRoundTripTime, maybeFloats.workHoursPerDay, maybeFloats.pondLength ) of
                ( Just truckRoundTripTime, Just workHoursPerDay, Just pondLength ) ->
                    case ( maybeFloats.pondWidth, maybeFloats.pondDepth ) of
                        ( Just pondWidth, Just pondDepth ) ->
                            Ok
                                { excavatorCapacity = excavatorCapacity
                                , excavatorCycleTime = excavatorCycleTime
                                , truckCapacity = truckCapacity
                                , truckRoundTripTime = truckRoundTripTime
                                , workHoursPerDay = workHoursPerDay
                                , pondLength = pondLength
                                , pondWidth = pondWidth
                                , pondDepth = pondDepth
                                }

                        _ ->
                            Err "Invalid pond dimensions format"

                _ ->
                    Err "Invalid equipment or work parameters format"

        _ ->
            Err "Invalid excavator or truck parameters format"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize WindowResized



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-100 py-8" ]
        [ div [ class "container mx-auto px-4" ]
            [ -- Header
              div [ class "text-center mb-8" ]
                [ h1 [ class "text-4xl font-bold text-gray-900 mb-2" ]
                    [ text "Pond Digging Calculator" ]
                , h2 [ class "text-xl text-gray-600" ]
                    [ text "Professional Timeline Estimation Tool" ]
                ]
            , -- Main Content
              case ( model.formData, model.config ) of
                ( Just formData, Just config ) ->
                    div [ class "space-y-8" ]
                        [ -- Input Form
                          ProjectForm.view model.deviceType formData ExcavatorFieldChanged TruckFieldChanged PondFieldChanged ProjectFieldChanged
                        , -- Results Panel
                          case model.calculationResult of
                            Just result ->
                                let
                                    -- Show as stale if we have validation errors but showing last valid result
                                    isStale = 
                                        case ( model.lastValidResult, model.calculationResult ) of
                                            ( Just lastValid, Just current ) ->
                                                -- If current result is same as last valid, might be stale
                                                lastValid == current && model.calculationInProgress == False
                                            _ ->
                                                False
                                in
                                ResultsPanel.view model.deviceType result isStale

                            Nothing ->
                                div [ class "text-center text-gray-500" ]
                                    [ text "Enter project parameters above to see timeline calculation" ]
                        ]

                ( Nothing, Just _ ) ->
                    div [ class "text-center text-gray-500" ]
                        [ text "Initializing form..." ]

                ( _, Nothing ) ->
                    div [ class "text-center text-gray-500" ]
                        [ text "Loading configuration..." ]
            ]
        ]
