module Components.ResultsPanel exposing (view)

{-| Results display component for pond digging timeline calculations

@docs view

-}

import Html exposing (Html, div, h3, h4, li, p, span, text, ul)
import Html.Attributes exposing (class)
import Styles.Components as Components
import Types.DeviceType exposing (DeviceType)
import Utils.Calculations exposing (Bottleneck(..), CalculationResult, ConfidenceLevel(..))



-- VIEW


{-| Render calculation results with detailed breakdown and error state indicators
-}
view : DeviceType -> CalculationResult -> Bool -> Html msg
view deviceType result isStale =
    div [ class (Components.getResultsPanelClasses deviceType) ]
        [ -- Stale result indicator
          if isStale then
            div [ class "mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-md" ]
                [ div [ class "flex items-center" ]
                    [ span [ class "text-yellow-400 mr-2" ] [ text "⚠️" ]
                    , div [ class "text-sm text-yellow-800" ]
                        [ text "Showing last valid calculation while current inputs have validation errors" ]
                    ]
                ]
          else
            text ""
        
        -- Main Result
        , div [ class "text-center mb-8" ]
            [ h3 [ class "text-3xl font-bold text-gray-900 mb-2" ]
                [ text "Project Timeline" ]
            , div [ class "text-6xl font-bold text-indigo-600 mb-2" ]
                [ text (String.fromInt result.timelineInDays) ]
            , div [ class "text-xl text-gray-600" ]
                [ text
                    (if result.timelineInDays == 1 then
                        "day"

                     else
                        "days"
                    )
                ]
            , div [ class "text-sm text-gray-500 mt-2" ]
                [ text ("(" ++ formatHours result.totalHours ++ " total hours)") ]
            ]

        -- Calculation Breakdown
        , div [ class "grid grid-cols-1 md:grid-cols-2 gap-6 mb-6" ]
            [ -- Equipment Rates
              div [ class "bg-gray-50 p-4 rounded-lg" ]
                [ h4 [ class "text-lg font-semibold text-gray-800 mb-3" ]
                    [ text "Equipment Productivity" ]
                , div [ class "space-y-2" ]
                    [ productivityRow "Excavation Rate" result.excavationRate "cy/hour"
                    , productivityRow "Hauling Rate" result.haulingRate "cy/hour"
                    , bottleneckIndicator result.bottleneck
                    ]
                ]

            -- Project Analysis
            , div [ class "bg-gray-50 p-4 rounded-lg" ]
                [ h4 [ class "text-lg font-semibold text-gray-800 mb-3" ]
                    [ text "Project Analysis" ]
                , div [ class "space-y-2" ]
                    [ confidenceIndicator result.confidence
                    , div [ class "text-sm text-gray-600" ]
                        [ text "Rounded up to whole days for scheduling" ]
                    ]
                ]
            ]

        -- Assumptions and Warnings
        , div [ class "space-y-4" ]
            [ if not (List.isEmpty result.assumptions) then
                assumptionsSection result.assumptions

              else
                text ""
            , if not (List.isEmpty result.warnings) then
                warningsSection result.warnings

              else
                text ""
            ]
        ]



-- HELPER FUNCTIONS


{-| Display a productivity rate with label and units
-}
productivityRow : String -> Float -> String -> Html msg
productivityRow label rate units =
    div [ class "flex justify-between items-center" ]
        [ span [ class "text-sm font-medium text-gray-700" ] [ text label ]
        , span [ class "text-sm text-gray-900" ]
            [ text (formatRate rate ++ " " ++ units) ]
        ]


{-| Display bottleneck indicator with appropriate styling
-}
bottleneckIndicator : Bottleneck -> Html msg
bottleneckIndicator bottleneck =
    let
        ( label, color ) =
            case bottleneck of
                ExcavationBottleneck ->
                    ( "Excavation Limited", "text-amber-600" )

                HaulingBottleneck ->
                    ( "Hauling Limited", "text-amber-600" )

                Balanced ->
                    ( "Well Balanced", "text-green-600" )
    in
    div [ class "flex justify-between items-center" ]
        [ span [ class "text-sm font-medium text-gray-700" ] [ text "Bottleneck" ]
        , span [ class ("text-sm font-medium " ++ color) ] [ text label ]
        ]


{-| Display confidence level indicator
-}
confidenceIndicator : ConfidenceLevel -> Html msg
confidenceIndicator confidence =
    let
        ( label, color, description ) =
            case confidence of
                High ->
                    ( "High", "text-green-600", "Equipment well balanced" )

                Medium ->
                    ( "Medium", "text-amber-600", "Minor equipment imbalance" )

                Low ->
                    ( "Low", "text-red-600", "Significant equipment imbalance" )
    in
    div [ class "space-y-1" ]
        [ div [ class "flex justify-between items-center" ]
            [ span [ class "text-sm font-medium text-gray-700" ] [ text "Confidence" ]
            , span [ class ("text-sm font-medium " ++ color) ] [ text label ]
            ]
        , div [ class "text-xs text-gray-500" ] [ text description ]
        ]


{-| Display assumptions section
-}
assumptionsSection : List String -> Html msg
assumptionsSection assumptions =
    div [ class "bg-blue-50 p-4 rounded-lg" ]
        [ h4 [ class "text-sm font-semibold text-blue-800 mb-2" ]
            [ text "Calculation Assumptions" ]
        , ul [ class "text-xs text-blue-700 space-y-1" ]
            (List.map
                (\assumption ->
                    li [ class "flex items-start" ]
                        [ span [ class "mr-2" ] [ text "•" ]
                        , text assumption
                        ]
                )
                assumptions
            )
        ]


{-| Display warnings section
-}
warningsSection : List String -> Html msg
warningsSection warnings =
    div [ class "bg-amber-50 p-4 rounded-lg" ]
        [ h4 [ class "text-sm font-semibold text-amber-800 mb-2" ]
            [ text "Recommendations" ]
        , ul [ class "text-xs text-amber-700 space-y-1" ]
            (List.map
                (\warning ->
                    li [ class "flex items-start" ]
                        [ span [ class "mr-2" ] [ text "⚠" ]
                        , text warning
                        ]
                )
                warnings
            )
        ]



-- FORMATTING HELPERS


{-| Format rate to 1 decimal place
-}
formatRate : Float -> String
formatRate rate =
    String.fromFloat (toFloat (round (rate * 10)) / 10)


{-| Format hours with appropriate precision
-}
formatHours : Float -> String
formatHours hours =
    if hours < 10 then
        String.fromFloat (toFloat (round (hours * 10)) / 10)

    else
        String.fromInt (round hours)
