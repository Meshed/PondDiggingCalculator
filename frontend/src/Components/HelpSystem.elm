module Components.HelpSystem exposing (view, helpButton, contextualTooltip, helpPanel)

{-| Help System Component

Provides comprehensive help integration including:

  - Visible but non-intrusive help button
  - Contextual tooltips for complex features
  - Help modal with FAQ and tips
  - Integration with onboarding tour for repeat access

@docs view, helpButton, contextualTooltip, helpPanel

-}

import Html exposing (Html, a, button, div, h3, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, target, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave, stopPropagationOn)
import Json.Decode as Decode
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg(..))



-- MAIN HELP BUTTON


{-| Main help button - visible but non-intrusive placement
-}
helpButton : DeviceType -> Bool -> Html Msg
helpButton deviceType isHelpPanelVisible =
    let
        buttonClasses =
            case deviceType of
                Mobile ->
                    "fixed bottom-4 right-4 z-30 bg-blue-600 hover:bg-blue-700 text-white p-3 rounded-full shadow-lg transition-all duration-200"

                Tablet ->
                    "fixed bottom-6 right-6 z-30 bg-blue-600 hover:bg-blue-700 text-white p-3 rounded-full shadow-lg transition-all duration-200"

                Desktop ->
                    "fixed bottom-8 right-8 z-30 bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-full shadow-lg transition-all duration-200 hover:shadow-xl"

        buttonContent =
            case deviceType of
                Mobile ->
                    "?"

                Tablet ->
                    "?"

                Desktop ->
                    if isHelpPanelVisible then
                        "✕"

                    else
                        "?"
    in
    button
        [ class buttonClasses
        , onClick ToggleHelpPanel
        , title
            (if isHelpPanelVisible then
                "Close Help"

             else
                "Get Help"
            )
        ]
        [ text buttonContent ]



-- CONTEXTUAL TOOLTIPS


{-| Contextual help tooltip for complex features
-}
contextualTooltip : String -> String -> Maybe String -> Html Msg
contextualTooltip fieldId helpText activeTooltip =
    let
        isActive =
            activeTooltip == Just fieldId

        tooltipClasses =
            if isActive then
                "absolute z-40 bg-gray-800 text-white text-sm rounded-lg p-3 shadow-lg max-w-xs -top-2 left-full ml-2 opacity-100 visible transition-all duration-200"

            else
                "absolute z-40 bg-gray-800 text-white text-sm rounded-lg p-3 shadow-lg max-w-xs -top-2 left-full ml-2 opacity-0 invisible transition-all duration-200"
    in
    div [ class "relative inline-block" ]
        [ span
            [ class "text-blue-500 hover:text-blue-700 cursor-help text-sm ml-1"
            , onMouseEnter (ShowHelpTooltip fieldId)
            , onMouseLeave (HideHelpTooltip fieldId)
            , title "Click for help"
            , onClick (ShowContextualHelp fieldId)
            ]
            [ text "?" ]
        , div [ class tooltipClasses ]
            [ text helpText
            , div [ class "absolute -left-2 top-3 w-0 h-0 border-t-4 border-b-4 border-r-4 border-transparent border-r-gray-800" ] []
            ]
        ]



-- HELP PANEL/MODAL


{-| Main help panel with FAQ and tips
-}
helpPanel : DeviceType -> Bool -> Html Msg
helpPanel deviceType isVisible =
    if not isVisible then
        text ""

    else
        let
            overlayClasses =
                "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 backdrop-blur-sm"

            panelClasses =
                case deviceType of
                    Mobile ->
                        "bg-white rounded-lg shadow-xl max-w-sm w-full m-4 max-h-[90vh] overflow-y-auto"

                    Tablet ->
                        "bg-white rounded-lg shadow-xl max-w-md w-full m-6 max-h-[80vh] overflow-y-auto"

                    Desktop ->
                        "bg-white rounded-lg shadow-xl max-w-2xl w-full m-8 max-h-[80vh] overflow-y-auto"
        in
        div [ class overlayClasses, onClick ToggleHelpPanel ]
            [ div
                [ class panelClasses
                , stopPropagationOn "click" (Decode.map (\_ -> ( NoOp, True )) (Decode.succeed ()))
                ]
                [ helpPanelContent deviceType ]
            ]


helpPanelContent : DeviceType -> Html Msg
helpPanelContent deviceType =
    div [ class "p-6" ]
        [ div [ class "flex justify-between items-center mb-6" ]
            [ h3 [ class "text-xl font-bold text-gray-900" ] [ text "Help & Tips" ]
            , button
                [ class "text-gray-400 hover:text-gray-600 text-xl"
                , onClick ToggleHelpPanel
                ]
                [ text "×" ]
            ]
        , div [ class "space-y-6" ]
            [ helpSection "Quick Start" quickStartContent
            , helpSection "Calculations" calculationsContent
            , helpSection "Equipment Setup" equipmentContent
            , helpSection "Troubleshooting" troubleshootingContent
            , restartTourSection
            ]
        ]


helpSection : String -> List (Html Msg) -> Html Msg
helpSection title content =
    div [ class "border-b border-gray-200 pb-4" ]
        [ h3 [ class "text-lg font-semibold text-gray-800 mb-3" ] [ text title ]
        , div [ class "space-y-2" ] content
        ]


quickStartContent : List (Html Msg)
quickStartContent =
    [ p [ class "text-gray-600" ] [ text "Get started with your pond excavation calculation:" ]
    , ul [ class "list-disc ml-5 text-gray-600 space-y-1" ]
        [ li [] [ text "Enter your pond dimensions (length, width, depth)" ]
        , li [] [ text "Add excavators and trucks to your fleet" ]
        , li [] [ text "Set project parameters like work hours per day" ]
        , li [] [ text "View your timeline estimate and optimization suggestions" ]
        ]
    ]


calculationsContent : List (Html Msg)
calculationsContent =
    [ p [ class "text-gray-600" ] [ text "Understanding your results:" ]
    , ul [ class "list-disc ml-5 text-gray-600 space-y-1" ]
        [ li [] [ text "Timeline shows total days needed for excavation" ]
        , li [] [ text "Volume is calculated automatically from dimensions" ]
        , li [] [ text "Equipment efficiency affects overall timeline" ]
        , li [] [ text "Multiple equipment pieces can work simultaneously" ]
        ]
    ]


equipmentContent : List (Html Msg)
equipmentContent =
    [ p [ class "text-gray-600" ] [ text "Setting up your equipment fleet:" ]
    , ul [ class "list-disc ml-5 text-gray-600 space-y-1" ]
        [ li [] [ text "Bucket capacity: Volume the excavator can move per cycle" ]
        , li [] [ text "Cycle time: How long each dig-load-dump cycle takes" ]
        , li [] [ text "Truck capacity: How much material each truck can carry" ]
        , li [] [ text "Round trip time: Complete loading and dumping cycle" ]
        ]
    ]


troubleshootingContent : List (Html Msg)
troubleshootingContent =
    [ p [ class "text-gray-600" ] [ text "Common issues and solutions:" ]
    , ul [ class "list-disc ml-5 text-gray-600 space-y-1" ]
        [ li [] [ text "Red validation errors: Check input values are positive numbers" ]
        , li [] [ text "Long timelines: Consider adding more equipment or increasing efficiency" ]
        , li [] [ text "Calculations not updating: Ensure all required fields are filled" ]
        ]
    ]


restartTourSection : Html Msg
restartTourSection =
    div [ class "pt-4 border-t border-gray-200" ]
        [ h3 [ class "text-lg font-semibold text-gray-800 mb-3" ] [ text "Need a Refresher?" ]
        , p [ class "text-gray-600 mb-3" ] [ text "Take the guided tour again to review all features." ]
        , button
            [ class "bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
            , onClick RestartGuidedTour
            ]
            [ text "Restart Guided Tour" ]
        ]



-- COMBINED VIEW


{-| Complete help system view combining all components
-}
view : DeviceType -> Maybe String -> Bool -> Maybe String -> Html Msg
view deviceType activeTooltip showPanel currentContextualHelp =
    div []
        [ helpButton deviceType showPanel
        , helpPanel deviceType showPanel
        ]
