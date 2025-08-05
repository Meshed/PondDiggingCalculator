module Main exposing (main)

import Browser
import Components.ProjectForm as ProjectForm
import Components.ResultsPanel as ResultsPanel
import Html exposing (Html, div, h1, h2, text)
import Html.Attributes exposing (class)
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Flags, Model)
import Utils.Calculations as Calculations
import Utils.Config exposing (fallbackConfig, loadConfig)
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
      }
    , loadConfig ConfigLoaded
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

        CalculateTimeline ->
            calculateAndUpdate model

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



-- CALCULATION HELPERS


{-| Calculate timeline based on current form data and update model
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
                            in
                            case calculationResult of
                                Ok result ->
                                    ( { model | calculationResult = Just result }, Cmd.none )

                                Err _ ->
                                    ( { model | calculationResult = Nothing }, Cmd.none )

                        Err _ ->
                            ( { model | calculationResult = Nothing }, Cmd.none )

                Err _ ->
                    ( { model | calculationResult = Nothing }, Cmd.none )

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
    Sub.none



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
                          ProjectForm.view formData FormUpdated
                        , -- Results Panel
                          case model.calculationResult of
                            Just result ->
                                ResultsPanel.view result

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
