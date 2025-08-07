module Pages.Desktop exposing (view)

import Components.EquipmentCard as EquipmentCard
import Components.ProjectForm as ProjectForm
import Components.ResultsPanel as ResultsPanel
import Html exposing (..)
import Html.Attributes exposing (..)
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Svg exposing (path, svg)
import Svg.Attributes
import Types.DeviceType as DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg)
import Types.Model exposing (Model)


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
    div [ class containerClass ]
        [ div [ class maxWidthClass ]
            [ viewHeader deviceType
            , div [ class layoutClass ]
                [ viewExcavatorSection model deviceType
                , viewProjectSection model deviceType
                , viewTruckSection model deviceType
                ]
            , viewResultsSection model deviceType
            ]
        ]


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
        , div [ class "space-y-4" ]
            [ viewExcavatorInputs model deviceType
            , viewFleetIndicator "Excavators" 2 deviceType
            ]
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
                    (\field value -> Types.Messages.ExcavatorFieldChanged field value)
                    (\field value -> Types.Messages.TruckFieldChanged field value)
                    (\field value -> Types.Messages.PondFieldChanged field value)
                    (\field value -> Types.Messages.ProjectFieldChanged field value)

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
        , div [ class "space-y-4" ]
            [ viewTruckInputs model deviceType
            , viewFleetIndicator "Trucks" 3 deviceType
            ]
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


viewExcavatorInputs : Model -> DeviceType -> Html Msg
viewExcavatorInputs model deviceType =
    div []
        [ text "Excavator configuration inputs will be populated from ProjectForm" ]


viewTruckInputs : Model -> DeviceType -> Html Msg
viewTruckInputs model deviceType =
    div []
        [ text "Truck configuration inputs will be populated from ProjectForm" ]


viewFleetIndicator : String -> Int -> DeviceType -> Html Msg
viewFleetIndicator fleetType count deviceType =
    let
        iconSize =
            case deviceType of
                Desktop ->
                    "w-8 h-8"

                Tablet ->
                    "w-7 h-7"

                Mobile ->
                    "w-6 h-6"

        typography =
            Theme.getTypographyScale deviceType

        textClass =
            typography.body
    in
    div [ class "flex items-center space-x-2 mt-4 p-3 bg-gray-50 rounded" ]
        [ div [ class "flex space-x-1" ]
            (List.repeat (Basics.min count 5) (viewEquipmentIcon fleetType iconSize))
        , if count > 5 then
            span [ class (textClass ++ " text-gray-600 ml-2") ]
                [ text ("+" ++ String.fromInt (count - 5) ++ " more") ]

          else
            text ""
        , span [ class (textClass ++ " text-gray-700 ml-auto") ]
            [ text (String.fromInt count ++ " " ++ fleetType) ]
        ]


viewEquipmentIcon : String -> String -> Html Msg
viewEquipmentIcon equipmentType sizeClass =
    let
        iconColor =
            if equipmentType == "Excavators" then
                "text-yellow-600"

            else
                "text-blue-600"

        iconPath =
            if equipmentType == "Excavators" then
                "M4 7h16v10H4z M7 11h10 M2 7l2-3h16l2 3 M9 17v2 M15 17v2"

            else
                "M3 9h14v8H3z M17 11h3v4h-3z M7 17v2 M13 17v2"
    in
    svg
        [ class (sizeClass ++ " " ++ iconColor)
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "none"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.strokeWidth "2"
        ]
        [ path [ Svg.Attributes.d iconPath ] []
        ]
