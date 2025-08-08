module Pages.Mobile exposing (Model, Msg(..), init, update, view)

import Html exposing (Html, button, div, h1, input, span, text)
import Html.Attributes exposing (class, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType(..))
import Types.Validation
import Utils.Calculations as Calculations
import Utils.Config as Config
import Utils.Validation as Validation


type alias Model =
    { excavatorCapacity : String
    , excavatorCycleTime : String
    , truckCapacity : String
    , truckRoundTripTime : String
    , pondLength : String
    , pondWidth : String
    , pondDepth : String
    , workHours : String
    , result : Maybe Calculations.CalculationResult
    , config : Maybe Config.Config
    }


type Msg
    = ExcavatorCapacityChanged String
    | ExcavatorCycleTimeChanged String
    | TruckCapacityChanged String
    | TruckRoundTripTimeChanged String
    | PondLengthChanged String
    | PondWidthChanged String
    | PondDepthChanged String
    | WorkHoursChanged String
    | ClearAll
    | ConfigLoaded (Result Types.Validation.ValidationError Config.Config)


init : ( Model, Cmd Msg )
init =
    let
        -- Use fallback config defaults to ensure consistency with desktop
        defaults =
            Config.fallbackConfig.defaults
    in
    ( { excavatorCapacity = String.fromFloat (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
      , excavatorCycleTime = String.fromFloat (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
      , truckCapacity = String.fromFloat (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
      , truckRoundTripTime = String.fromFloat (List.head defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 15.0)
      , pondLength = String.fromFloat defaults.project.pondLength
      , pondWidth = String.fromFloat defaults.project.pondWidth
      , pondDepth = String.fromFloat defaults.project.pondDepth
      , workHours = String.fromFloat defaults.project.workHoursPerDay
      , result = Nothing
      , config = Nothing
      }
    , Config.loadConfig ConfigLoaded
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ExcavatorCapacityChanged value ->
            let
                newModel =
                    { model | excavatorCapacity = value }
            in
            ( calculateResult newModel, Cmd.none )

        ExcavatorCycleTimeChanged value ->
            let
                newModel =
                    { model | excavatorCycleTime = value }
            in
            ( calculateResult newModel, Cmd.none )

        TruckCapacityChanged value ->
            let
                newModel =
                    { model | truckCapacity = value }
            in
            ( calculateResult newModel, Cmd.none )

        TruckRoundTripTimeChanged value ->
            let
                newModel =
                    { model | truckRoundTripTime = value }
            in
            ( calculateResult newModel, Cmd.none )

        PondLengthChanged value ->
            let
                newModel =
                    { model | pondLength = value }
            in
            ( calculateResult newModel, Cmd.none )

        PondWidthChanged value ->
            let
                newModel =
                    { model | pondWidth = value }
            in
            ( calculateResult newModel, Cmd.none )

        PondDepthChanged value ->
            let
                newModel =
                    { model | pondDepth = value }
            in
            ( calculateResult newModel, Cmd.none )

        WorkHoursChanged value ->
            let
                newModel =
                    { model | workHours = value }
            in
            ( calculateResult newModel, Cmd.none )

        ClearAll ->
            let
                -- Reset to config defaults, not empty strings
                defaults =
                    case model.config of
                        Just config ->
                            config.defaults

                        Nothing ->
                            Config.fallbackConfig.defaults
            in
            ( { model
                | excavatorCapacity = String.fromFloat (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                , excavatorCycleTime = String.fromFloat (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                , truckCapacity = String.fromFloat (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                , truckRoundTripTime = String.fromFloat (List.head defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 15.0)
                , pondLength = String.fromFloat defaults.project.pondLength
                , pondWidth = String.fromFloat defaults.project.pondWidth
                , pondDepth = String.fromFloat defaults.project.pondDepth
                , workHours = String.fromFloat defaults.project.workHoursPerDay
                , result = Nothing
              }
            , Cmd.none
            )

        ConfigLoaded result ->
            case result of
                Ok config ->
                    let
                        newModel =
                            { model
                                | config = Just config
                                , excavatorCapacity = String.fromFloat (List.head config.defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                                , excavatorCycleTime = String.fromFloat (List.head config.defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                                , truckCapacity = String.fromFloat (List.head config.defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                                , truckRoundTripTime = String.fromFloat (List.head config.defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 15.0)
                                , pondLength = String.fromFloat config.defaults.project.pondLength
                                , pondWidth = String.fromFloat config.defaults.project.pondWidth
                                , pondDepth = String.fromFloat config.defaults.project.pondDepth
                                , workHours = String.fromFloat config.defaults.project.workHoursPerDay
                            }
                    in
                    ( calculateResult newModel, Cmd.none )

                Err _ ->
                    let
                        fallbackDefaults =
                            Config.fallbackConfig.defaults

                        newModel =
                            { model
                                | config = Just Config.fallbackConfig
                                , excavatorCapacity = String.fromFloat (List.head fallbackDefaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                                , excavatorCycleTime = String.fromFloat (List.head fallbackDefaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                                , truckCapacity = String.fromFloat (List.head fallbackDefaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                                , truckRoundTripTime = String.fromFloat (List.head fallbackDefaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 15.0)
                                , pondLength = String.fromFloat fallbackDefaults.project.pondLength
                                , pondWidth = String.fromFloat fallbackDefaults.project.pondWidth
                                , pondDepth = String.fromFloat fallbackDefaults.project.pondDepth
                                , workHours = String.fromFloat fallbackDefaults.project.workHoursPerDay
                            }
                    in
                    ( calculateResult newModel, Cmd.none )


calculateResult : Model -> Model
calculateResult model =
    let
        maybeResult =
            case parseInputs model of
                Ok inputs ->
                    case model.config of
                        Just config ->
                            case Validation.validateAllInputs config.validation inputs of
                                Ok validInputs ->
                                    let
                                        pondVolume =
                                            (validInputs.pondLength * validInputs.pondWidth * validInputs.pondDepth) / 27.0
                                    in
                                    case
                                        Calculations.calculateTimeline
                                            validInputs.excavatorCapacity
                                            validInputs.excavatorCycleTime
                                            validInputs.truckCapacity
                                            validInputs.truckRoundTripTime
                                            pondVolume
                                            validInputs.workHoursPerDay
                                    of
                                        Ok result ->
                                            Just result

                                        Err _ ->
                                            model.result

                                Err _ ->
                                    model.result

                        Nothing ->
                            model.result

                Err _ ->
                    model.result
    in
    { model | result = maybeResult }


parseInputs : Model -> Result String Validation.ProjectInputs
parseInputs model =
    case ( String.toFloat model.excavatorCapacity, String.toFloat model.excavatorCycleTime ) of
        ( Just excCap, Just excCycle ) ->
            case ( String.toFloat model.truckCapacity, String.toFloat model.truckRoundTripTime ) of
                ( Just truckCap, Just truckRound ) ->
                    case ( String.toFloat model.pondLength, String.toFloat model.pondWidth ) of
                        ( Just pondL, Just pondW ) ->
                            case ( String.toFloat model.pondDepth, String.toFloat model.workHours ) of
                                ( Just pondD, Just workH ) ->
                                    Ok
                                        { excavatorCapacity = excCap
                                        , excavatorCycleTime = excCycle
                                        , truckCapacity = truckCap
                                        , truckRoundTripTime = truckRound
                                        , pondLength = pondL
                                        , pondWidth = pondW
                                        , pondDepth = pondD
                                        , workHoursPerDay = workH
                                        }

                                _ ->
                                    Err "Invalid depth or work hours"

                        _ ->
                            Err "Invalid pond dimensions"

                _ ->
                    Err "Invalid truck parameters"

        _ ->
            Err "Invalid excavator parameters"


view : Model -> Html Msg
view model =
    div [ class "min-h-screen bg-gray-50 flex flex-col" ]
        [ viewHeader
        , viewResults model.result
        , viewInputSection model
        , viewClearButton
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "bg-blue-600 text-white p-4 shadow-md" ]
        [ h1 [ class "text-2xl font-bold text-center" ] [ text "Pond Calculator" ]
        ]


viewResults : Maybe Calculations.CalculationResult -> Html Msg
viewResults maybeResult =
    div [ class "bg-gradient-to-r from-blue-500 to-blue-600 mx-4 mt-4 rounded-xl shadow-xl p-6 text-white" ]
        [ case maybeResult of
            Just result ->
                div [ class "text-center" ]
                    [ div [ class "mb-4" ]
                        [ div [ class "text-blue-100 text-sm mb-2" ] [ text "Project Timeline" ]
                        , div [ class "text-5xl font-bold mb-2" ]
                            [ text (String.fromInt result.timelineInDays) ]
                        , div [ class "text-xl font-light" ] [ text "days" ]
                        ]
                    , div [ class "grid grid-cols-2 gap-4 pt-4 border-t border-blue-400" ]
                        [ div [ class "text-center" ]
                            [ div [ class "text-2xl font-bold" ] [ text (String.fromInt (round result.totalHours)) ]
                            , div [ class "text-blue-100 text-sm" ] [ text "Total Hours" ]
                            ]
                        , div [ class "text-center" ]
                            [ div [ class "text-2xl font-bold" ] [ text (String.fromInt (round result.excavationRate)) ]
                            , div [ class "text-blue-100 text-sm" ] [ text "Yd³/Hour" ]
                            ]
                        ]
                    ]

            Nothing ->
                div [ class "text-center text-blue-100 py-8" ]
                    [ div [ class "text-lg" ] [ text "Enter values to calculate" ]
                    , div [ class "text-sm mt-2 opacity-75" ] [ text "Project timeline will appear here" ]
                    ]
        ]


viewInputSection : Model -> Html Msg
viewInputSection model =
    div [ class "flex-1 p-4 space-y-6 overflow-y-auto" ]
        [ viewInputGroup "Pond Dimensions"
            [ viewNumberInput "Length" "ft" model.pondLength PondLengthChanged
            , viewNumberInput "Width" "ft" model.pondWidth PondWidthChanged
            , viewNumberInput "Depth" "ft" model.pondDepth PondDepthChanged
            ]
        , viewInputGroup "Equipment"
            [ viewNumberInput "Bucket" "yd³" model.excavatorCapacity ExcavatorCapacityChanged
            , viewNumberInput "Cycle" "min" model.excavatorCycleTime ExcavatorCycleTimeChanged
            , viewNumberInput "Truck" "yd³" model.truckCapacity TruckCapacityChanged
            , viewNumberInput "Trip" "min" model.truckRoundTripTime TruckRoundTripTimeChanged
            ]
        , viewInputGroup "Work Schedule"
            [ viewNumberInput "Hours/Day" "hrs" model.workHours WorkHoursChanged
            ]
        ]


viewInputGroup : String -> List (Html Msg) -> Html Msg
viewInputGroup title inputs =
    div [ class Theme.getMobileCardClasses ]
        [ div [ class "text-sm font-semibold text-gray-700 mb-4 uppercase tracking-wide" ]
            [ text title ]
        , div [ class (Theme.getMobileGridClasses ++ " gap-y-8") ] inputs
        ]


viewNumberInput : String -> String -> String -> (String -> Msg) -> Html Msg
viewNumberInput label unit currentValue onChange =
    div [ class "relative" ]
        [ input
            [ type_ "number"
            , placeholder "0"
            , value currentValue
            , onInput onChange
            , class Theme.getMobileInputClasses
            ]
            []
        , div [ class "absolute inset-x-0 -bottom-6 text-xs text-center text-gray-500" ]
            [ text (label ++ " (" ++ unit ++ ")") ]
        ]


viewClearButton : Html Msg
viewClearButton =
    div [ class "p-4 bg-white border-t border-gray-200" ]
        [ button
            [ onClick ClearAll
            , class (Theme.getButtonClasses Mobile ++ " w-full bg-red-500 hover:bg-red-600 text-white font-bold rounded-xl shadow-lg active:scale-95 transition-all")
            , style "min-height" "56px"
            ]
            [ text "Clear All" ]
        ]
