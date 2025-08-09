module Components.HelpTooltip exposing (view, helpIcon)

{-| Help tooltip component for contextual help system

@docs view, helpIcon

-}

import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (class, style, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Styles.Theme exposing (getHelpIconClasses, getTooltipClasses)
import Types.DeviceType exposing (DeviceType(..))
import Utils.Config exposing (ValidationRules)
import Utils.HelpContent exposing (HelpContent, getHelpContent)


{-| Renders the help icon with tooltip container
-}
helpIcon : ValidationRules -> DeviceType -> String -> (String -> msg) -> (String -> msg) -> Maybe String -> Html msg
helpIcon validationRules deviceType fieldId onShow onHide activeTooltipId =
    case deviceType of
        Mobile ->
            -- No help icons on mobile - help is provided through enhanced labels
            text ""

        _ ->
            div [ class "relative inline-block z-[9999]" ]
                [ button
                    [ type_ "button"
                    , class getHelpIconClasses
                    , title "Click for help"
                    , onClick (onShow fieldId)
                    , onMouseEnter (onShow fieldId)
                    , onMouseLeave (onHide fieldId)
                    ]
                    [ text "?" ]
                , if activeTooltipId == Just fieldId then
                    case getHelpContent validationRules fieldId of
                        Just content ->
                            viewTooltipContent content

                        Nothing ->
                            text ""

                  else
                    text ""
                ]


{-| Renders the tooltip content when visible
-}
viewTooltipContent : HelpContent -> Html msg
viewTooltipContent content =
    div
        [ class getTooltipClasses
        , style "top" "100%"
        , style "right" "0"
        , style "margin-top" "4px"
        , style "min-width" "280px"
        ]
        [ p [ class "font-semibold text-gray-900 mb-2" ]
            [ text content.title ]
        , p [ class "text-gray-700 mb-3" ]
            [ text content.description ]
        , div [ class "mb-3" ]
            [ p [ class "font-medium text-gray-800 mb-1" ]
                [ text "Typical Range:" ]
            , p [ class "text-gray-600" ]
                [ text content.typicalRange ]
            ]
        , if not (List.isEmpty content.examples) then
            div [ class "mb-3" ]
                [ p [ class "font-medium text-gray-800 mb-1" ]
                    [ text "Examples:" ]
                , div [ class "text-gray-600" ]
                    (List.map (\example -> p [ class "mb-1" ] [ text ("• " ++ example) ]) content.examples)
                ]

          else
            text ""
        , if String.length content.tips > 0 then
            div [ class "mt-3 pt-3 border-t border-gray-200" ]
                [ p [ class "font-medium text-gray-800 mb-1" ]
                    [ text "Tip:" ]
                , p [ class "text-gray-600 text-xs" ]
                    [ text content.tips ]
                ]

          else
            text ""
        ]


{-| Legacy view function for backward compatibility
-}
view : String -> HelpContent -> Html msg
view fieldId content =
    viewTooltipContent content
