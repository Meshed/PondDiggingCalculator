module Pages.Desktop exposing (view)

import Components.EquipmentList as EquipmentList
import Components.HelpTooltip as HelpTooltip
import Components.ProjectForm as ProjectForm
import Components.ResultsPanel as ResultsPanel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Svg exposing (path, svg)
import Svg.Attributes
import Types.DeviceType as DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg)
import Types.Model exposing (Model)
import Utils.HelpContent exposing (getHelpContent)


view : Model -> Html Msg
view model =
    let
        deviceType =
            model.deviceType

        containerClass =
            case deviceType of
                Desktop ->
                    "min-h-screen bg-gray-50 px-8 py-8"

                Tablet ->
                    "min-h-screen bg-gray-50 px-6 py-6"

                Mobile ->
                    "min-h-screen bg-gray-50 px-4 py-4"

        maxWidthClass =
            case deviceType of
                Desktop ->
                    "max-w-7xl mx-auto"

                Tablet ->
                    "max-w-5xl mx-auto"

                Mobile ->
                    "max-w-lg mx-auto"

        layoutClass =
            case deviceType of
                Desktop ->
                    "grid grid-cols-3 gap-8"

                Tablet ->
                    "grid grid-cols-2 gap-6"

                Mobile ->
                    "flex flex-col space-y-4"
    in
    div
        [ class containerClass
        , Html.Attributes.attribute "data-testid" "device-type"
        ]
        [ div [ class maxWidthClass ]
            [ viewHeader deviceType
            , viewInfoBanner model.infoBannerDismissed
            , div [ class layoutClass ]
                [ viewExcavatorSection model deviceType
                , viewProjectSection model deviceType
                , viewTruckSection model deviceType
                ]
            , viewResultsSection model deviceType
            ]
        ]


viewInfoBanner : Bool -> Html Msg
viewInfoBanner infoBannerDismissed =
    if not infoBannerDismissed then
        div
            [ class "mb-8 p-4 bg-blue-50 border border-blue-200 rounded-md"
            , Html.Attributes.attribute "data-testid" "info-banner"
            ]
            [ div [ class "flex items-start" ]
                [ div [ class "flex-shrink-0" ]
                    [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                , div [ class "ml-3 flex-1" ]
                    [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                , div [ class "ml-3 flex-shrink-0" ]
                    [ button
                        [ onClick Types.Messages.DismissInfoBanner
                        , class "text-blue-400 hover:text-blue-600 font-bold text-lg leading-none"
                        , title "Dismiss this message"
                        , Html.Attributes.attribute "data-testid" "dismiss-banner-button"
                        ]
                        [ text "×" ]
                    ]
                ]
            ]

    else
        text ""


viewHeader : DeviceType -> Html Msg
viewHeader deviceType =
    let
        typography =
            Theme.getTypographyScale deviceType

        headingClass =
            typography.heading

        subtitleClass =
            typography.subheading
    in
    header [ class "mb-8 text-center" ]
        [ h1 [ class headingClass ]
            [ text "Pond Digging Calculator" ]
        , p [ class (subtitleClass ++ " text-gray-600 mt-2") ]
            [ text "Professional excavation timeline estimator" ]
        ]


viewExcavatorSection : Model -> DeviceType -> Html Msg
viewExcavatorSection model deviceType =
    let
        sectionClass =
            case deviceType of
                Desktop ->
                    "bg-white rounded-lg shadow-md p-6"

                Tablet ->
                    "bg-white rounded-lg shadow-md p-5"

                Mobile ->
                    "bg-white rounded-lg shadow-sm p-4"

        typography =
            Theme.getTypographyScale deviceType

        headerClass =
            typography.subheading
    in
    div [ class sectionClass ]
        [ h2 [ class (headerClass ++ " mb-4 text-gray-800 border-b pb-2") ]
            [ text "Excavator Fleet" ]
        , EquipmentList.viewExcavatorFleet deviceType model.excavators model.nextExcavatorId Types.Messages.ShowHelpTooltip Types.Messages.HideHelpTooltip model.helpTooltipState
        ]


viewProjectSection : Model -> DeviceType -> Html Msg
viewProjectSection model deviceType =
    let
        sectionClass =
            case deviceType of
                Desktop ->
                    "bg-white rounded-lg shadow-md p-6"

                Tablet ->
                    "bg-white rounded-lg shadow-md p-5 col-span-2"

                Mobile ->
                    "bg-white rounded-lg shadow-sm p-4"

        typography =
            Theme.getTypographyScale deviceType

        headerClass =
            typography.subheading
    in
    div [ class sectionClass ]
        [ h2 [ class (headerClass ++ " mb-4 text-gray-800 border-b pb-2") ]
            [ text "Project Configuration" ]
        , case model.formData of
            Just formData ->
                ProjectForm.view deviceType
                    formData
                    (\field value -> Types.Messages.PondFieldChanged field value)
                    (\field value -> Types.Messages.ProjectFieldChanged field value)
                    Types.Messages.ShowHelpTooltip
                    Types.Messages.HideHelpTooltip
                    model.helpTooltipState

            Nothing ->
                text "Loading form..."
        ]


viewTruckSection : Model -> DeviceType -> Html Msg
viewTruckSection model deviceType =
    let
        sectionClass =
            case deviceType of
                Desktop ->
                    "bg-white rounded-lg shadow-md p-6"

                Tablet ->
                    "bg-white rounded-lg shadow-md p-5"

                Mobile ->
                    "bg-white rounded-lg shadow-sm p-4"

        typography =
            Theme.getTypographyScale deviceType

        headerClass =
            typography.subheading
    in
    div [ class sectionClass ]
        [ h2 [ class (headerClass ++ " mb-4 text-gray-800 border-b pb-2") ]
            [ text "Truck Fleet" ]
        , EquipmentList.viewTruckFleet deviceType model.trucks model.nextTruckId Types.Messages.ShowHelpTooltip Types.Messages.HideHelpTooltip model.helpTooltipState
        ]


viewResultsSection : Model -> DeviceType -> Html Msg
viewResultsSection model deviceType =
    let
        sectionClass =
            case deviceType of
                Desktop ->
                    "bg-white rounded-lg shadow-md p-6 mt-8"

                Tablet ->
                    "bg-white rounded-lg shadow-md p-5 mt-6 col-span-2"

                Mobile ->
                    "bg-white rounded-lg shadow-sm p-4 mt-4"
    in
    div [ class sectionClass ]
        [ case model.calculationResult of
            Just result ->
                ResultsPanel.view model.deviceType result False

            Nothing ->
                text "No calculation results yet"
        ]
