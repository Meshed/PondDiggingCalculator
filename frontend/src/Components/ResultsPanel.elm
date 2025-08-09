module Components.ResultsPanel exposing (view)

{-| Results display component for pond digging timeline calculations

@docs view

-}

import Html exposing (Html, div, h3, h4, h5, li, p, span, text, ul)
import Html.Attributes exposing (class)
import Styles.Components as Components
import Styles.Theme as Theme
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
            Theme.getProfessionalHeadingClass deviceType ++ " mb-4"

        mainNumberClass =
            Theme.getProfessionalNumberDisplayClass deviceType ++ " mb-3"

        professionalResultContainer =
            Theme.getProfessionalResultSpacing deviceType
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

        -- Professional Main Result Display
        , div
            [ class ("text-center " ++ professionalResultContainer)
            , Html.Attributes.attribute "data-testid" "timeline-result"
            ]
            [ h3 [ class headingClass ]
                [ text "Project Completion Timeline" ]
            , div
                [ class mainNumberClass
                , Html.Attributes.attribute "data-testid" "timeline-days"
                ]
                [ text (String.fromInt result.timelineInDays) ]
            , div [ class ("text-2xl " ++ Theme.professionalSecondaryColor ++ " font-medium mb-2") ]
                [ text
                    (if result.timelineInDays == 1 then
                        "Working Day"

                     else
                        "Working Days"
                    )
                ]
            , div [ class ("text-base " ++ Theme.professionalNeutralColor ++ " mb-4") ]
                [ text ("Total Project Hours: " ++ formatHours result.totalHours) ]
            , if deviceType /= Types.DeviceType.Mobile then
                viewAdditionalMetrics result

              else
                text ""
            ]

        -- Professional Calculation Breakdown
        , div [ class (getBreakdownGridClass deviceType ++ " " ++ Theme.professionalSectionSpacing) ]
            [ -- Equipment Performance Analysis
              div [ class "bg-white border border-gray-200 p-6 rounded-xl shadow-sm" ]
                [ h4 [ class (Theme.getProfessionalSubheadingClass deviceType ++ " mb-4") ]
                    [ text "Equipment Performance" ]
                , div [ class Theme.professionalElementSpacing ]
                    [ professionalProductivityRow "Excavator Rate" result.excavationRate "cubic yards/hour" "excavation-rate" deviceType
                    , professionalProductivityRow "Truck Hauling Rate" result.haulingRate "cubic yards/hour" "hauling-rate" deviceType
                    , professionalBottleneckIndicator result.bottleneck deviceType
                    , if deviceType /= Types.DeviceType.Mobile then
                        viewEfficiencyBar result.excavationRate result.haulingRate

                      else
                        text ""
                    ]
                ]

            -- Professional Project Analysis
            , div [ class "bg-white border border-gray-200 p-6 rounded-xl shadow-sm" ]
                [ h4 [ class (Theme.getProfessionalSubheadingClass deviceType ++ " mb-4") ]
                    [ text "Project Analysis" ]
                , div [ class Theme.professionalElementSpacing ]
                    [ professionalConfidenceIndicator result.confidence deviceType
                    , if deviceType /= Types.DeviceType.Mobile then
                        viewProfessionalProjectDetails result deviceType

                      else
                        text ""
                    , div [ class ("text-sm " ++ Theme.professionalNeutralColor ++ " italic") ]
                        [ text "Timeline rounded to complete working days for scheduling precision" ]
                    ]
                ]
            ]

        -- Methodology Explanation
        , calculationMethodologySection result deviceType

        -- Professional Assumptions and Recommendations
        , div [ class Theme.professionalSectionSpacing ]
            [ if not (List.isEmpty result.assumptions) then
                professionalAssumptionsSection result.assumptions deviceType

              else
                text ""
            , if not (List.isEmpty result.warnings) then
                professionalRecommendationsSection result.warnings deviceType

              else
                text ""
            ]
        ]



-- HELPER FUNCTIONS


{-| Display a productivity rate with label, units, and optional test ID
-}
productivityRow : String -> Float -> String -> Maybe String -> Html msg
productivityRow label rate units maybeTestId =
    div [ class "flex justify-between items-center" ]
        [ span [ class "text-sm font-medium text-gray-700" ] [ text label ]
        , span
            ([ class "text-sm text-gray-900" ]
                ++ (case maybeTestId of
                        Just testId ->
                            [ Html.Attributes.attribute "data-testid" testId ]

                        Nothing ->
                            []
                   )
            )
            [ text (formatRate rate ++ " " ++ units) ]
        ]


{-| Display professional productivity rate with enhanced formatting
-}
professionalProductivityRow : String -> Float -> String -> String -> DeviceType -> Html msg
professionalProductivityRow label rate units testId deviceType =
    div [ class "flex justify-between items-center py-2" ]
        [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ]
            [ text label ]
        , span
            [ class ("font-semibold " ++ Theme.professionalPrimaryColor)
            , Html.Attributes.attribute "data-testid" testId
            ]
            [ text (formatRate rate ++ " " ++ units) ]
        ]


{-| Display bottleneck indicator with appropriate styling and optional test ID
-}
bottleneckIndicator : Bottleneck -> Maybe String -> Html msg
bottleneckIndicator bottleneck maybeTestId =
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
            ([ class ("text-sm font-medium " ++ color) ]
                ++ (case maybeTestId of
                        Just testId ->
                            [ Html.Attributes.attribute "data-testid" testId ]

                        Nothing ->
                            []
                   )
            )
            [ text label ]
        ]


{-| Get confidence level information
-}
getConfidenceInfo : ConfidenceLevel -> { label : String, color : String, description : String }
getConfidenceInfo confidence =
    case confidence of
        High ->
            { label = "High", color = "text-green-600", description = "Equipment well balanced" }

        Medium ->
            { label = "Medium", color = "text-amber-600", description = "Minor equipment imbalance" }

        Low ->
            { label = "Low", color = "text-red-600", description = "Significant equipment imbalance" }


{-| Display confidence level indicator
-}
confidenceIndicator : ConfidenceLevel -> Html msg
confidenceIndicator confidence =
    let
        info =
            getConfidenceInfo confidence
    in
    div [ class "space-y-1" ]
        [ div [ class "flex justify-between items-center" ]
            [ span [ class "text-sm font-medium text-gray-700" ] [ text "Confidence" ]
            , span [ class ("text-sm font-medium " ++ info.color) ] [ text info.label ]
            ]
        , div [ class "text-xs text-gray-500" ] [ text info.description ]
        ]


{-| Display professional confidence indicator with enhanced detail
-}
professionalConfidenceIndicator : ConfidenceLevel -> DeviceType -> Html msg
professionalConfidenceIndicator confidence deviceType =
    let
        confidenceInfo =
            case confidence of
                High ->
                    { label = "High Confidence", color = "text-green-600", description = "Equipment rates are well-balanced for optimal efficiency", icon = "✓" }

                Medium ->
                    { label = "Medium Confidence", color = "text-amber-600", description = "Minor equipment imbalance may affect timeline precision", icon = "⚡" }

                Low ->
                    { label = "Low Confidence", color = "text-red-600", description = "Significant equipment imbalance requires attention", icon = "⚠" }
    in
    div [ class "py-3 px-4 bg-gray-50 rounded-lg" ]
        [ div [ class "flex justify-between items-center mb-2" ]
            [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ] [ text "Estimate Confidence" ]
            , div [ class "flex items-center" ]
                [ span [ class "mr-2" ] [ text confidenceInfo.icon ]
                , span [ class ("font-semibold " ++ confidenceInfo.color) ] [ text confidenceInfo.label ]
                ]
            ]
        , div [ class ("text-sm " ++ Theme.getProfessionalBodyTextClass) ] [ text confidenceInfo.description ]
        ]


{-| Display professional bottleneck indicator with enhanced formatting
-}
professionalBottleneckIndicator : Bottleneck -> DeviceType -> Html msg
professionalBottleneckIndicator bottleneck deviceType =
    let
        bottleneckInfo =
            case bottleneck of
                ExcavationBottleneck ->
                    { label = "Excavation Limited", color = Theme.professionalAccentColor, icon = "🏗️", explanation = "Excavator is the limiting factor in project timeline" }

                HaulingBottleneck ->
                    { label = "Hauling Limited", color = Theme.professionalAccentColor, icon = "🚛", explanation = "Truck hauling capacity limits project progress" }

                Balanced ->
                    { label = "Well Balanced", color = "text-green-600", icon = "⚖️", explanation = "Equipment rates are optimally matched" }
    in
    div [ class "py-3 px-4 bg-gray-50 rounded-lg" ]
        [ div [ class "flex justify-between items-center mb-2" ]
            [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ] [ text "Project Bottleneck" ]
            , div [ class "flex items-center" ]
                [ span [ class "mr-2" ] [ text bottleneckInfo.icon ]
                , span [ class ("font-semibold " ++ bottleneckInfo.color) ] [ text bottleneckInfo.label ]
                ]
            ]
        , div [ class ("text-sm " ++ Theme.getProfessionalBodyTextClass) ] [ text bottleneckInfo.explanation ]
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


{-| Display calculation methodology explanation section
-}
calculationMethodologySection : CalculationResult -> DeviceType -> Html msg
calculationMethodologySection result deviceType =
    let
        effectiveRate =
            min result.excavationRate result.haulingRate

        bottleneckEquipment =
            case result.bottleneck of
                ExcavationBottleneck ->
                    "excavator"

                HaulingBottleneck ->
                    "truck"

                Balanced ->
                    "both equipment types"
    in
    div [ class "bg-white border border-gray-200 p-6 rounded-xl shadow-sm mb-6" ]
        [ h4 [ class (Theme.getProfessionalSubheadingClass deviceType ++ " mb-4 flex items-center") ]
            [ span [ class "mr-2 text-gray-600" ] [ text "🔍" ]
            , text "How This Timeline Was Calculated"
            ]
        , div [ class "space-y-4" ]
            [ div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
                [ div [ class "bg-gray-50 p-4 rounded-lg" ]
                    [ h5 [ class ("font-semibold mb-2 " ++ Theme.professionalSecondaryColor) ]
                        [ text "Equipment Analysis" ]
                    , p [ class ("text-sm mb-2 " ++ Theme.getProfessionalBodyTextClass) ]
                        [ text ("Your project's timeline is determined by the " ++ bottleneckEquipment ++ ", which sets the pace of work.") ]
                    , div [ class ("text-sm " ++ Theme.professionalNeutralColor) ]
                        [ text ("Effective rate: " ++ formatRate effectiveRate ++ " cubic yards/hour") ]
                    ]
                , div [ class "bg-gray-50 p-4 rounded-lg" ]
                    [ h5 [ class ("font-semibold mb-2 " ++ Theme.professionalSecondaryColor) ]
                        [ text "Timeline Calculation" ]
                    , p [ class ("text-sm mb-2 " ++ Theme.getProfessionalBodyTextClass) ]
                        [ text "Total work hours are divided by daily working hours, then rounded up to complete days." ]
                    , div [ class ("text-sm " ++ Theme.professionalNeutralColor) ]
                        [ text ("Total hours: " ++ formatHours result.totalHours ++ " → " ++ String.fromInt result.timelineInDays ++ " working days") ]
                    ]
                ]
            , div [ class "border-l-4 border-indigo-500 pl-4" ]
                [ p [ class ("text-sm italic " ++ Theme.getProfessionalBodyTextClass) ]
                    [ text "This estimate uses industry-standard productivity rates and accounts for real-world construction conditions. The final timeline provides a reliable scheduling foundation for project planning." ]
                ]
            ]
        ]


{-| Display professional assumptions section with enhanced formatting
-}
professionalAssumptionsSection : List String -> DeviceType -> Html msg
professionalAssumptionsSection assumptions deviceType =
    div [ class "bg-white border border-blue-200 p-6 rounded-xl shadow-sm" ]
        [ h4 [ class (Theme.getProfessionalSubheadingClass deviceType ++ " mb-4 flex items-center") ]
            [ span [ class "mr-2 text-blue-600" ] [ text "📋" ]
            , text "Project Assumptions"
            ]
        , div [ class "text-sm" ]
            [ p [ class ("mb-3 " ++ Theme.getProfessionalBodyTextClass) ]
                [ text "This timeline estimate is based on the following industry-standard assumptions:" ]
            , ul [ class ("space-y-2 " ++ Theme.professionalSecondaryColor) ]
                (List.map
                    (\assumption ->
                        li [ class "flex items-start" ]
                            [ span [ class ("mr-3 mt-1 " ++ Theme.professionalPrimaryColor) ] [ text "•" ]
                            , span [ class "leading-relaxed" ] [ text assumption ]
                            ]
                    )
                    assumptions
                )
            ]
        ]


{-| Display professional recommendations section with enhanced formatting
-}
professionalRecommendationsSection : List String -> DeviceType -> Html msg
professionalRecommendationsSection recommendations deviceType =
    div [ class "bg-white border border-amber-200 p-6 rounded-xl shadow-sm" ]
        [ h4 [ class (Theme.getProfessionalSubheadingClass deviceType ++ " mb-4 flex items-center") ]
            [ span [ class "mr-2 text-amber-600" ] [ text "💡" ]
            , text "Professional Recommendations"
            ]
        , div [ class "text-sm" ]
            [ p [ class ("mb-3 " ++ Theme.getProfessionalBodyTextClass) ]
                [ text "To optimize project efficiency and timeline accuracy, consider these recommendations:" ]
            , ul [ class ("space-y-2 " ++ Theme.professionalSecondaryColor) ]
                (List.map
                    (\recommendation ->
                        li [ class "flex items-start" ]
                            [ span [ class ("mr-3 mt-1 " ++ Theme.professionalAccentColor) ] [ text "⚠" ]
                            , span [ class "leading-relaxed" ] [ text recommendation ]
                            ]
                    )
                    recommendations
                )
            ]
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


{-| Format volume with commas using a more efficient approach
-}
formatVolume : Float -> String
formatVolume volume =
    let
        rounded =
            round volume

        str =
            String.fromInt rounded

        len =
            String.length str
    in
    if len <= 3 then
        str

    else
        let
            thousands =
                String.dropRight 3 str

            remainder =
                String.right 3 str
        in
        thousands ++ "," ++ remainder


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


{-| View professional project details with enhanced formatting
-}
viewProfessionalProjectDetails : CalculationResult -> DeviceType -> Html msg
viewProfessionalProjectDetails result deviceType =
    let
        effectiveRate =
            min result.excavationRate result.haulingRate

        dailyOutput =
            effectiveRate * 8.0
    in
    div [ class "pt-3 space-y-3" ]
        [ div [ class "flex justify-between items-center py-2 border-b border-gray-100" ]
            [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ] [ text "Effective Production Rate" ]
            , span [ class ("font-semibold " ++ Theme.professionalPrimaryColor) ]
                [ text (formatRate effectiveRate ++ " cubic yards/hour") ]
            ]
        , div [ class "flex justify-between items-center py-2 border-b border-gray-100" ]
            [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ] [ text "Expected Daily Output" ]
            , span [ class ("font-semibold " ++ Theme.professionalPrimaryColor) ]
                [ text (formatRate dailyOutput ++ " cubic yards/day") ]
            ]
        , div [ class "flex justify-between items-center py-2" ]
            [ span [ class ("font-medium " ++ Theme.professionalSecondaryColor) ] [ text "Hours per Working Day" ]
            , span [ class ("font-semibold " ++ Theme.professionalPrimaryColor) ]
                [ text (formatDailyProgress result.totalHours result.timelineInDays ++ " hours") ]
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
