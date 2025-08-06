module Components.EquipmentCard exposing (view, viewIcon, EquipmentCardMsg(..), EquipmentCardConfig)

{-| Equipment card component for responsive equipment display with visual representations

@docs view, viewIcon, EquipmentCardMsg, EquipmentCardConfig

-}

import Html exposing (Html, button, div, h4, span, text)
import Svg exposing (svg, path, circle)
import Svg.Attributes
import Html.Attributes exposing (class, disabled, attribute)
import Html.Events exposing (onClick)
import Styles.Components as Components
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType)
import Types.Equipment exposing (Equipment)


-- TYPES


type EquipmentCardMsg
    = AddEquipment Equipment
    | RemoveEquipment String
    | EditEquipment Equipment


type alias EquipmentCardConfig =
    { equipment : Equipment
    , isActive : Bool
    , showAdvanced : Bool
    , fleetCount : Int
    }


-- VIEW


{-| Render equipment card with device-responsive layout and visual icons
-}
view : DeviceType -> EquipmentCardConfig -> (EquipmentCardMsg -> msg) -> Html msg
view deviceType config toMsg =
    let
        cardPadding =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "p-6"
                
                Types.DeviceType.Tablet ->
                    "p-5"
                
                _ ->
                    "p-4"
        
        baseCardClass =
            Components.getEquipmentCardClasses deviceType
        
        enhancedCardClass =
            baseCardClass ++ " " ++ cardPadding ++ " bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow"
    in
    div [ class enhancedCardClass ]
        [ -- Header with Icon and Fleet Count
          div [ class "flex items-start justify-between mb-4" ]
            [ div [ class "flex items-center space-x-3" ]
                [ viewIcon deviceType config.equipment.equipmentType
                , div []
                    [ h4 [ class "font-semibold text-gray-800 text-lg" ]
                        [ text config.equipment.name ]
                    , viewStatusBadge config.isActive deviceType
                    ]
                ]
            , viewFleetBadge config.fleetCount deviceType
            ]
        
        -- Equipment Info Section
        , div [ class "space-y-2 mb-4" ]
            [ equipmentDetail "Type" (equipmentTypeToString config.equipment.equipmentType)
            , equipmentDetail "Capacity" (formatCapacity config.equipment.bucketCapacity)
            , if config.showAdvanced then
                equipmentDetail "Cycle Time" (formatCycleTime config.equipment.cycleTime)
              else
                text ""
            , if config.showAdvanced && config.equipment.equipmentType == Types.Equipment.Excavator then
                viewProductivityIndicator config.equipment deviceType
              else
                text ""
            ]
        
        -- Action Buttons Section
        , div [ class (getButtonSectionClasses deviceType) ]
            [ button
                [ class (Theme.getButtonClasses deviceType ++ " bg-green-500 hover:bg-green-700")
                , onClick (toMsg (AddEquipment config.equipment))
                , disabled (not config.isActive)
                ]
                [ text "Add" ]
            , button
                [ class (Theme.getButtonClasses deviceType ++ " bg-red-500 hover:bg-red-700")
                , onClick (toMsg (RemoveEquipment config.equipment.id))
                ]
                [ text "Remove" ]
            , if config.showAdvanced then
                button
                    [ class (Theme.getButtonClasses deviceType ++ " bg-blue-500 hover:bg-blue-700")
                    , onClick (toMsg (EditEquipment config.equipment))
                    ]
                    [ text "Edit" ]
              else
                text ""
            ]
        ]


-- HELPER FUNCTIONS


{-| Get button section layout classes based on device type
-}
getButtonSectionClasses : DeviceType -> String
getButtonSectionClasses deviceType =
    case deviceType of
        Types.DeviceType.Mobile ->
            "flex flex-col space-y-2 w-full"

        Types.DeviceType.Tablet ->
            "flex flex-row space-x-2"

        Types.DeviceType.Desktop ->
            "flex flex-row space-x-3"


{-| Display a key-value equipment detail
-}
equipmentDetail : String -> String -> Html msg
equipmentDetail label value =
    div [ class "flex justify-between text-sm" ]
        [ span [ class "text-gray-600" ] [ text (label ++ ":") ]
        , span [ class "text-gray-900 font-medium" ] [ text value ]
        ]


{-| Convert equipment type to display string
-}
equipmentTypeToString : Types.Equipment.EquipmentType -> String
equipmentTypeToString equipmentType =
    case equipmentType of
        Types.Equipment.Excavator ->
            "Excavator"

        Types.Equipment.Truck ->
            "Truck"


{-| Format capacity for display
-}
formatCapacity : Float -> String
formatCapacity capacity =
    String.fromFloat capacity ++ " cy"


{-| Format cycle time for display
-}
formatCycleTime : Float -> String
formatCycleTime cycleTime =
    String.fromFloat cycleTime ++ " min"


{-| Render equipment type icon
-}
viewIcon : DeviceType -> Types.Equipment.EquipmentType -> Html msg
viewIcon deviceType equipmentType =
    let
        iconSize =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "w-10 h-10"
                
                Types.DeviceType.Tablet ->
                    "w-9 h-9"
                
                _ ->
                    "w-8 h-8"
        
        iconColor =
            case equipmentType of
                Types.Equipment.Excavator ->
                    "text-yellow-600"
                
                Types.Equipment.Truck ->
                    "text-blue-600"
        
        svgElements =
            case equipmentType of
                Types.Equipment.Excavator ->
                    [ path [ Svg.Attributes.d "M4 7h16v10H4z" ] []
                    , path [ Svg.Attributes.d "M7 11h10" ] []
                    , path [ Svg.Attributes.d "M2 7l2-3h16l2 3" ] []
                    , path [ Svg.Attributes.d "M9 17v2" ] []
                    , path [ Svg.Attributes.d "M15 17v2" ] []
                    , path [ Svg.Attributes.d "M8 7V4h2l1-2h2l1 2h2v3" ] []
                    ]
                
                Types.Equipment.Truck ->
                    [ path [ Svg.Attributes.d "M3 9h14v8H3z" ] []
                    , path [ Svg.Attributes.d "M17 11h3v4h-3z" ] []
                    , path [ Svg.Attributes.d "M7 17v2" ] []
                    , path [ Svg.Attributes.d "M13 17v2" ] []
                    , circle [ Svg.Attributes.cx "7", Svg.Attributes.cy "18", Svg.Attributes.r "1" ] []
                    , circle [ Svg.Attributes.cx "13", Svg.Attributes.cy "18", Svg.Attributes.r "1" ] []
                    ]
    in
    svg
        [ class (iconSize ++ " " ++ iconColor)
        , Svg.Attributes.viewBox "0 0 24 24"
        , Svg.Attributes.fill "none"
        , Svg.Attributes.stroke "currentColor"
        , Svg.Attributes.strokeWidth "2"
        , Svg.Attributes.strokeLinecap "round"
        , Svg.Attributes.strokeLinejoin "round"
        ]
        svgElements


{-| Display fleet count badge
-}
viewFleetBadge : Int -> DeviceType -> Html msg
viewFleetBadge count deviceType =
    let
        badgeClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-bold"
                
                Types.DeviceType.Tablet ->
                    "px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-bold"
                
                _ ->
                    "px-2 py-1 bg-indigo-100 text-indigo-700 rounded-full text-xs font-bold"
    in
    if count > 0 then
        div [ class badgeClass ]
            [ text ("Fleet: " ++ String.fromInt count) ]
    else
        text ""


{-| Display status badge
-}
viewStatusBadge : Bool -> DeviceType -> Html msg
viewStatusBadge isActive deviceType =
    let
        statusClass =
            if isActive then
                "px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium"
            else
                "px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600 font-medium"
    in
    span [ class statusClass ]
        [ text
            (if isActive then
                "Active"
             else
                "Inactive"
            )
        ]


{-| Display productivity indicator for excavators
-}
viewProductivityIndicator : Equipment -> DeviceType -> Html msg
viewProductivityIndicator equipment deviceType =
    let
        cyclesPerHour =
            60.0 / equipment.cycleTime
        
        excavatorEfficiencyFactor =
            0.85
        
        ratePerHour =
            cyclesPerHour * equipment.bucketCapacity * excavatorEfficiencyFactor
        
        formattedRate =
            String.fromFloat (toFloat (round (ratePerHour * 10)) / 10)
    in
    div [ class "pt-2 mt-2 border-t border-gray-200" ]
        [ equipmentDetail "Productivity" (formattedRate ++ " cu.yd/hr") ]