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
    let
        panelClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    Components.getResultsPanelClasses deviceType ++ " p-6"

                Types.DeviceType.Tablet ->
                    Components.getResultsPanelClasses deviceType ++ " p-5"

                _ ->
                    Components.getResultsPanelClasses deviceType ++ " p-4"

        headingClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "text-4xl font-bold text-gray-900 mb-3"

                Types.DeviceType.Tablet ->
                    "text-3xl font-bold text-gray-900 mb-2"

                _ ->
                    "text-2xl font-bold text-gray-900 mb-2"

        mainNumberClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "text-7xl font-bold text-indigo-600 mb-3"

                Types.DeviceType.Tablet ->
                    "text-6xl font-bold text-indigo-600 mb-2"

                _ ->
                    "text-5xl font-bold text-indigo-600 mb-2"
    in
    div [ class panelClass ]
        [ -- Stale result indicator
          if isStale then
            div
                [ class "mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-md"
                , Html.Attributes.attribute "data-testid" "last-valid-result"
                ]
                [ div [ class "flex items-center" ]
                    [ span [ class "text-yellow-400 mr-2" ] [ text "⚠️" ]
                    , div [ class "text-sm text-yellow-800" ]
                        [ text "Showing last valid calculation while current inputs have validation errors" ]
                    ]
                ]

          else
            text ""

        -- Main Result with Enhanced Display
        , div
            [ class "text-center mb-8"
            , Html.Attributes.attribute "data-testid" "timeline-result"
            ]
            [ h3 [ class headingClass ]
                [ text "Estimated Completion Timeline" ]
            , div
                [ class mainNumberClass
                , Html.Attributes.attribute "data-testid" "timeline-days"
                ]
                [ text (String.fromInt result.timelineInDays) ]
            , div [ class "text-xl text-gray-600" ]
                [ text
                    (if result.timelineInDays == 1 then
                        "working day"

                     else
                        "working days"
                    )
                ]
            , div [ class "text-sm text-gray-500 mt-2" ]
                [ text ("(" ++ formatHours result.totalHours ++ " total hours)") ]
            , if deviceType /= Types.DeviceType.Mobile then
                viewAdditionalMetrics result

              else
                text ""
            ]

        -- Enhanced Calculation Breakdown
        , div [ class (getBreakdownGridClass deviceType) ]
            [ -- Equipment Rates with Visual Indicators
              div [ class "bg-gray-50 p-4 rounded-lg" ]
                [ h4 [ class "text-lg font-semibold text-gray-800 mb-3" ]
                    [ text "Equipment Productivity" ]
                , div [ class "space-y-2" ]
                    [ productivityRowWithTestId "Excavation Rate" result.excavationRate "cy/hour" "excavation-rate"
                    , productivityRowWithTestId "Hauling Rate" result.haulingRate "cy/hour" "hauling-rate"
                    , bottleneckIndicatorWithTestId result.bottleneck
                    , if deviceType /= Types.DeviceType.Mobile then
                        viewEfficiencyBar result.excavationRate result.haulingRate

                      else
                        text ""
                    ]
                ]

            -- Enhanced Project Analysis
            , div [ class "bg-gray-50 p-4 rounded-lg" ]
                [ h4 [ class "text-lg font-semibold text-gray-800 mb-3" ]
                    [ text "Project Analysis" ]
                , div [ class "space-y-2" ]
                    [ confidenceIndicator result.confidence
                    , if deviceType /= Types.DeviceType.Mobile then
                        viewProjectDetails result

                      else
                        text ""
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


{-| Display a productivity rate with label, units, and test ID
-}
productivityRowWithTestId : String -> Float -> String -> String -> Html msg
productivityRowWithTestId label rate units testId =
    div [ class "flex justify-between items-center" ]
        [ span [ class "text-sm font-medium text-gray-700" ] [ text label ]
        , span
            [ class "text-sm text-gray-900"
            , Html.Attributes.attribute "data-testid" testId
            ]
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


{-| Display bottleneck indicator with appropriate styling and test ID
-}
bottleneckIndicatorWithTestId : Bottleneck -> Html msg
bottleneckIndicatorWithTestId bottleneck =
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
        , span
            [ class ("text-sm font-medium " ++ color)
            , Html.Attributes.attribute "data-testid" "bottleneck"
            ]
            [ text label ]
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


{-| View additional metrics for desktop/tablet
-}
viewAdditionalMetrics : CalculationResult -> Html msg
viewAdditionalMetrics result =
    let
        totalVolume =
            result.totalHours * min result.excavationRate result.haulingRate

        truckTrips =
            if result.haulingRate > 0 then
                ceiling (totalVolume / 15.0)

            else
                0
    in
    div [ class "mt-4 pt-4 border-t border-gray-300" ]
        [ div [ class "grid grid-cols-3 gap-4 text-center" ]
            [ div []
                [ div [ class "text-2xl font-bold text-gray-700" ]
                    [ text (formatVolume totalVolume) ]
                , div [ class "text-xs text-gray-500" ] [ text "Total Dirt Moved (cu.yd)" ]
                ]
            , div []
                [ div [ class "text-2xl font-bold text-gray-700" ]
                    [ text (String.fromInt truckTrips) ]
                , div [ class "text-xs text-gray-500" ] [ text "Truck Trips Required" ]
                ]
            , div []
                [ div [ class "text-2xl font-bold text-gray-700" ]
                    [ text (formatDailyProgress result.totalHours result.timelineInDays) ]
                , div [ class "text-xs text-gray-500" ] [ text "Hours per Day" ]
                ]
            ]
        ]


{-| Format volume with commas
-}
formatVolume : Float -> String
formatVolume volume =
    let
        rounded =
            round volume

        formatted =
            if rounded >= 1000 then
                let
                    thousands =
                        rounded // 1000

                    remainder =
                        modBy 1000 rounded

                    remainderStr =
                        if remainder < 10 then
                            "00" ++ String.fromInt remainder

                        else if remainder < 100 then
                            "0" ++ String.fromInt remainder

                        else
                            String.fromInt remainder
                in
                String.fromInt thousands ++ "," ++ remainderStr

            else
                String.fromInt rounded
    in
    formatted


{-| Format daily progress
-}
formatDailyProgress : Float -> Int -> String
formatDailyProgress totalHours days =
    if days > 0 then
        String.fromFloat (toFloat (round ((totalHours / toFloat days) * 10)) / 10)

    else
        "0"


{-| View efficiency bar visualization
-}
viewEfficiencyBar : Float -> Float -> Html msg
viewEfficiencyBar excavationRate haulingRate =
    let
        maxRate =
            max excavationRate haulingRate

        excavationPercent =
            if maxRate > 0 then
                (excavationRate / maxRate) * 100

            else
                0

        haulingPercent =
            if maxRate > 0 then
                (haulingRate / maxRate) * 100

            else
                0
    in
    div [ class "mt-3 pt-3 border-t border-gray-200" ]
        [ div [ class "text-xs text-gray-600 mb-2" ] [ text "Equipment Balance" ]
        , div [ class "space-y-2" ]
            [ div [ class "flex items-center" ]
                [ span [ class "text-xs text-gray-500 w-20" ] [ text "Excavation" ]
                , div [ class "flex-1 bg-gray-200 rounded-full h-2 ml-2" ]
                    [ div
                        [ class "bg-yellow-500 h-2 rounded-full"
                        , Html.Attributes.style "width" (String.fromFloat excavationPercent ++ "%")
                        ]
                        []
                    ]
                ]
            , div [ class "flex items-center" ]
                [ span [ class "text-xs text-gray-500 w-20" ] [ text "Hauling" ]
                , div [ class "flex-1 bg-gray-200 rounded-full h-2 ml-2" ]
                    [ div
                        [ class "bg-blue-500 h-2 rounded-full"
                        , Html.Attributes.style "width" (String.fromFloat haulingPercent ++ "%")
                        ]
                        []
                    ]
                ]
            ]
        ]


{-| View project details for desktop/tablet
-}
viewProjectDetails : CalculationResult -> Html msg
viewProjectDetails result =
    div [ class "pt-2 space-y-1" ]
        [ div [ class "flex justify-between text-sm" ]
            [ span [ class "text-gray-600" ] [ text "Effective Rate" ]
            , span [ class "font-medium text-gray-900" ]
                [ text (formatRate (min result.excavationRate result.haulingRate) ++ " cy/hr") ]
            ]
        , div [ class "flex justify-between text-sm" ]
            [ span [ class "text-gray-600" ] [ text "Daily Output" ]
            , span [ class "font-medium text-gray-900" ]
                [ text (formatRate (min result.excavationRate result.haulingRate * 8.0) ++ " cy/day") ]
            ]
        ]


{-| Get breakdown grid class based on device type
-}
getBreakdownGridClass : DeviceType -> String
getBreakdownGridClass deviceType =
    case deviceType of
        Types.DeviceType.Desktop ->
            "grid grid-cols-2 gap-6 mb-6"

        Types.DeviceType.Tablet ->
            "grid grid-cols-2 gap-4 mb-6"

        _ ->
            "grid grid-cols-1 gap-4 mb-6"
