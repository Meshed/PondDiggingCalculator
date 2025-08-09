module Views.MobileView exposing (view)

{-| Mobile view using shared application state

This is the CORRECT architecture - mobile is just a different presentation
of the same shared state used by desktop and tablet views.

@docs view

-}

import Components.ProjectForm exposing (FormData)
import Html exposing (Html, button, div, h1, input, span, text)
import Html.Attributes exposing (class, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (Excavator, Truck)
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Utils.Calculations exposing (CalculationResult)
import Utils.Config exposing (Config)


{-| Mobile view that uses shared application state
-}
view : Model -> Html Msg
view model =
    case model.formData of
        Just formData ->
            div
                [ class "min-h-screen bg-gray-100 flex flex-col"
                , Html.Attributes.attribute "data-testid" "device-type"
                ]
                [ viewHeader
                , viewInfoBanner model.infoBannerDismissed
                , viewResults model.calculationResult
                , viewInputSection formData model
                , viewClearButton
                ]

        Nothing ->
            div [ class "min-h-screen bg-gray-100 flex flex-col items-center justify-center" ]
                [ div [ class "text-center text-gray-500" ]
                    [ text "Loading calculator..." ]
                ]


viewHeader : Html Msg
viewHeader =
    div [ class "bg-white shadow-sm border-b border-gray-200 p-4" ]
        [ h1 [ class "text-2xl font-bold text-gray-900 text-center" ] [ text "Pond Calculator" ]
        , div [ class "text-sm text-gray-600 text-center mt-1" ] [ text "Professional Timeline Estimation Tool" ]
        ]


viewInfoBanner : Bool -> Html Msg
viewInfoBanner infoBannerDismissed =
    if not infoBannerDismissed then
        div [ class "mx-4 mt-4 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
            [ div [ class "flex items-start" ]
                [ div [ class "flex-shrink-0" ]
                    [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                , div [ class "ml-3 flex-1" ]
                    [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                , div [ class "ml-3 flex-shrink-0" ]
                    [ button
                        [ onClick DismissInfoBanner
                        , class "text-blue-400 hover:text-blue-600 font-bold text-lg leading-none"
                        , Html.Attributes.attribute "data-testid" "dismiss-banner-button"
                        ]
                        [ text "×" ]
                    ]
                ]
            ]

    else
        text ""


viewResults : Maybe CalculationResult -> Html Msg
viewResults maybeResult =
    div [ class "bg-blue-50 mx-4 mt-4 rounded-lg border border-blue-200 p-6" ]
        [ case maybeResult of
            Just result ->
                div [ class "text-center" ]
                    [ div [ class "mb-4" ]
                        [ div [ class "text-blue-700 text-sm font-medium mb-2" ] [ text "Project Timeline" ]
                        , div [ class "text-4xl font-bold text-blue-900 mb-1" ]
                            [ text (String.fromInt result.timelineInDays) ]
                        , div [ class "text-lg text-blue-700" ] [ text "days" ]
                        ]
                    , div [ class "grid grid-cols-2 gap-4 pt-4 border-t border-blue-200" ]
                        [ div [ class "text-center" ]
                            [ div [ class "text-xl font-bold text-gray-900" ] [ text (String.fromInt (round result.totalHours)) ]
                            , div [ class "text-blue-600 text-sm" ] [ text "Total Hours" ]
                            ]
                        , div [ class "text-center" ]
                            [ div [ class "text-xl font-bold text-gray-900" ] [ text (String.fromInt (round result.excavationRate)) ]
                            , div [ class "text-blue-600 text-sm" ] [ text "Yd³/Hour" ]
                            ]
                        ]
                    ]

            Nothing ->
                div [ class "text-center text-gray-500 py-8" ]
                    [ div [ class "text-lg" ] [ text "Enter values to calculate" ]
                    , div [ class "text-sm mt-2" ] [ text "Project timeline will appear here" ]
                    ]
        ]


viewInputSection : FormData -> Model -> Html Msg
viewInputSection formData model =
    div [ class "flex-1 p-4 space-y-6 overflow-y-auto" ]
        [ viewInputGroup "Pond Dimensions"
            [ viewMobileInputWithHelp "Pond Length" "ft" formData.pondLength "e.g., 100 (10-500 typical)" (PondFieldChanged PondLength)
            , viewMobileInputWithHelp "Pond Width" "ft" formData.pondWidth "e.g., 50 (8-300 typical)" (PondFieldChanged PondWidth)
            , viewMobileInputWithHelp "Pond Depth" "ft" formData.pondDepth "e.g., 10 (3-25 typical)" (PondFieldChanged PondDepth)
            ]
        , viewEquipmentSection model
        , viewInputGroup "Project Configuration"
            [ viewMobileInputWithHelp "Work Hours per Day" "hrs" formData.workHoursPerDay "e.g., 8 (6-12 typical)" (ProjectFieldChanged WorkHours)
            ]
        ]


viewEquipmentSection : Model -> Html Msg
viewEquipmentSection model =
    let
        -- Mobile shows only the first excavator and truck (simplified fleet view)
        firstExcavator =
            List.head model.excavators

        firstTruck =
            List.head model.trucks
    in
    case ( firstExcavator, firstTruck ) of
        ( Just excavator, Just truck ) ->
            viewInputGroup "Equipment Specifications"
                [ viewMobileInputWithHelp "Excavator Bucket Capacity"
                    "yd³"
                    (String.fromFloat excavator.bucketCapacity)
                    "e.g., 2.5 (0.5-15 typical)"
                    (\val ->
                        case String.toFloat val of
                            Just f ->
                                UpdateExcavator excavator.id (Types.Messages.UpdateExcavatorBucketCapacity f)

                            Nothing ->
                                NoOp
                    )
                , viewMobileInputWithHelp "Excavator Cycle Time"
                    "min"
                    (String.fromFloat excavator.cycleTime)
                    "e.g., 2.0 (0.5-10 typical)"
                    (\val ->
                        case String.toFloat val of
                            Just f ->
                                UpdateExcavator excavator.id (Types.Messages.UpdateExcavatorCycleTime f)

                            Nothing ->
                                NoOp
                    )
                , viewMobileInputWithHelp "Truck Capacity"
                    "yd³"
                    (String.fromFloat truck.capacity)
                    "e.g., 12 (5-50 typical)"
                    (\val ->
                        case String.toFloat val of
                            Just f ->
                                UpdateTruck truck.id (Types.Messages.UpdateTruckCapacity f)

                            Nothing ->
                                NoOp
                    )
                , viewMobileInputWithHelp "Truck Round Trip Time"
                    "min"
                    (String.fromFloat truck.roundTripTime)
                    "e.g., 15 (5-60 typical)"
                    (\val ->
                        case String.toFloat val of
                            Just f ->
                                UpdateTruck truck.id (Types.Messages.UpdateTruckRoundTripTime f)

                            Nothing ->
                                NoOp
                    )
                ]

        _ ->
            viewInputGroup "Equipment Specifications"
                [ div [ class "text-gray-500 text-center py-4" ]
                    [ text "Loading equipment data..." ]
                ]


viewInputGroup : String -> List (Html Msg) -> Html Msg
viewInputGroup title inputs =
    div [ class "bg-white shadow-md rounded-lg p-6 space-y-4" ]
        [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
            [ text title ]
        , div [ class "space-y-4" ] inputs
        ]


viewNumberInput : String -> String -> String -> (String -> Msg) -> Html Msg
viewNumberInput label unit currentValue onChange =
    div [ class "space-y-2" ]
        [ -- Label with unit, following desktop pattern
          div [ class "block text-sm font-semibold text-gray-700" ]
            [ text label
            , span [ class "ml-2 text-xs font-normal text-gray-500" ]
                [ text ("(" ++ unit ++ ")") ]
            ]
        , -- Input field with proper mobile sizing
          input
            [ type_ "number"
            , placeholder "0"
            , value currentValue
            , onInput onChange
            , class "w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 focus:outline-none"
            , style "min-height" "56px" -- Ensure 44px+ touch target
            ]
            []
        ]


{-| Enhanced mobile input with helpful placeholder and typical ranges
-}
viewMobileInputWithHelp : String -> String -> String -> String -> (String -> Msg) -> Html Msg
viewMobileInputWithHelp label unit currentValue helpfulPlaceholder onChange =
    div [ class "space-y-2" ]
        [ -- Enhanced label with unit
          div [ class "block text-sm font-semibold text-gray-700" ]
            [ text label
            , span [ class "ml-2 text-xs font-normal text-gray-500" ]
                [ text ("(" ++ unit ++ ")") ]
            ]
        , -- Input field with helpful placeholder
          input
            [ type_ "number"
            , placeholder helpfulPlaceholder
            , value currentValue
            , onInput onChange
            , class "w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-1 focus:ring-blue-500 focus:outline-none"
            , style "min-height" "56px" -- Ensure 44px+ touch target
            ]
            []
        ]


viewClearButton : Html Msg
viewClearButton =
    div [ class "p-4 bg-gray-50 border-t border-gray-200" ]
        [ button
            [ onClick (FormUpdated Components.ProjectForm.ClearForm)
            , class "w-full px-6 py-3 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg shadow-md active:bg-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors"
            , style "min-height" "56px"
            ]
            [ text "Reset to Defaults" ]
        ]
