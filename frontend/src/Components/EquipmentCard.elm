module Components.EquipmentCard exposing (view, EquipmentCardMsg(..), EquipmentCardConfig)

{-| Equipment card component for responsive equipment display

@docs view, EquipmentCardMsg, EquipmentCardConfig

-}

import Html exposing (Html, button, div, h4, span, text)
import Html.Attributes exposing (class, disabled)
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
    }


-- VIEW


{-| Render equipment card with device-responsive layout
-}
view : DeviceType -> EquipmentCardConfig -> (EquipmentCardMsg -> msg) -> Html msg
view deviceType config toMsg =
    div [ class (Components.getEquipmentCardClasses deviceType) ]
        [ -- Equipment Info Section
          div [ class "flex-1" ]
            [ h4 [ class "font-semibold text-gray-800 mb-2" ]
                [ text config.equipment.name ]
            , div [ class "space-y-1" ]
                [ equipmentDetail "Type" (equipmentTypeToString config.equipment.equipmentType)
                , equipmentDetail "Capacity" (formatCapacity config.equipment.bucketCapacity)
                , if config.showAdvanced then
                    equipmentDetail "Cycle Time" (formatCycleTime config.equipment.cycleTime)
                  else
                    text ""
                ]
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