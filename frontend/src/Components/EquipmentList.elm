module Components.EquipmentList exposing (viewExcavatorFleet, viewTruckFleet)

{-| Fleet management components for displaying and managing multiple equipment items

@docs viewExcavatorFleet, viewTruckFleet

-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Messages exposing (ExcavatorUpdate(..), Msg(..), TruckUpdate(..))
import Utils.DeviceDetector as DeviceDetector



-- EXCAVATOR FLEET VIEW


viewExcavatorFleet : DeviceType -> List Excavator -> Int -> Html Msg
viewExcavatorFleet deviceType excavators nextId =
    let
        canAddMore =
            List.length excavators < 10

        -- Fleet limit from config
        showAdvancedFeatures =
            DeviceDetector.shouldShowAdvancedFeatures deviceType
    in
    div [ class "space-y-4" ]
        [ if showAdvancedFeatures && canAddMore then
            viewAddExcavatorButton deviceType

          else
            text ""
        , div [ class "space-y-3" ]
            (List.indexedMap (viewExcavatorItem deviceType (List.length excavators > 1)) excavators)
        ]


viewAddExcavatorButton : DeviceType -> Html Msg
viewAddExcavatorButton deviceType =
    let
        buttonClass =
            case deviceType of
                Desktop ->
                    "w-full bg-yellow-600 hover:bg-yellow-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 flex items-center justify-center space-x-2"

                Tablet ->
                    "w-full bg-yellow-600 hover:bg-yellow-700 text-white font-medium py-2 px-3 rounded-lg transition-colors duration-200 flex items-center justify-center space-x-2"

                Mobile ->
                    "hidden"

        -- Hidden on mobile
    in
    button
        [ class buttonClass
        , onClick AddExcavator
        , type_ "button"
        ]
        [ span [ class "text-lg" ] [ text "🚛" ]
        , text "Add Excavator"
        ]


viewExcavatorItem : DeviceType -> Bool -> Int -> Excavator -> Html Msg
viewExcavatorItem deviceType canRemove index excavator =
    let
        itemClass =
            case deviceType of
                Desktop ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-4"

                Tablet ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-3"

                Mobile ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-3"

        typography =
            Theme.getTypographyScale deviceType

        labelClass =
            typography.body

        inputClass =
            "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent"

        equipmentNumber =
            index + 1
    in
    div [ class itemClass ]
        [ div [ class "flex items-center justify-between mb-3" ]
            [ h4 [ class (labelClass ++ " font-medium text-gray-800") ]
                [ span [ class "text-yellow-600 mr-2" ] [ text "🚛" ]
                , text ("Excavator " ++ String.fromInt equipmentNumber)
                ]
            , if canRemove && DeviceDetector.shouldShowAdvancedFeatures deviceType then
                button
                    [ class "text-red-600 hover:text-red-800 font-medium px-2 py-1 rounded"
                    , onClick (RemoveExcavator excavator.id)
                    , type_ "button"
                    ]
                    [ text "Remove" ]

              else
                text ""
            ]
        , div [ class "grid grid-cols-2 gap-3" ]
            [ div []
                [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                    [ text "Bucket Capacity (yd³)" ]
                , input
                    [ type_ "number"
                    , class inputClass
                    , value (String.fromFloat excavator.bucketCapacity)
                    , onInput
                        (\val ->
                            case String.toFloat val of
                                Just f ->
                                    UpdateExcavator excavator.id (UpdateExcavatorBucketCapacity f)

                                Nothing ->
                                    NoOp
                        )
                    , step "0.1"
                    , Html.Attributes.min "0.1"
                    ]
                    []
                ]
            , div []
                [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                    [ text "Cycle Time (min)" ]
                , input
                    [ type_ "number"
                    , class inputClass
                    , value (String.fromFloat excavator.cycleTime)
                    , onInput
                        (\val ->
                            case String.toFloat val of
                                Just f ->
                                    UpdateExcavator excavator.id (UpdateExcavatorCycleTime f)

                                Nothing ->
                                    NoOp
                        )
                    , step "0.1"
                    , Html.Attributes.min "0.1"
                    ]
                    []
                ]
            ]
        , div [ class "mt-3" ]
            [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                [ text "Equipment Name" ]
            , input
                [ type_ "text"
                , class inputClass
                , value excavator.name
                , onInput (\val -> UpdateExcavator excavator.id (UpdateExcavatorName val))
                , placeholder ("Excavator " ++ String.fromInt equipmentNumber)
                ]
                []
            ]
        , div [ class "mt-3 flex items-center" ]
            [ input
                [ type_ "checkbox"
                , class "h-4 w-4 text-yellow-600 focus:ring-yellow-500 border-gray-300 rounded"
                , checked excavator.isActive
                , onCheck (\val -> UpdateExcavator excavator.id (UpdateExcavatorActive val))
                ]
                []
            , label [ class (labelClass ++ " ml-2 text-gray-700") ]
                [ text "Equipment Active" ]
            ]
        ]



-- TRUCK FLEET VIEW


viewTruckFleet : DeviceType -> List Truck -> Int -> Html Msg
viewTruckFleet deviceType trucks nextId =
    let
        canAddMore =
            List.length trucks < 20

        -- Fleet limit from config
        showAdvancedFeatures =
            DeviceDetector.shouldShowAdvancedFeatures deviceType
    in
    div [ class "space-y-4" ]
        [ if showAdvancedFeatures && canAddMore then
            viewAddTruckButton deviceType

          else
            text ""
        , div [ class "space-y-3" ]
            (List.indexedMap (viewTruckItem deviceType (List.length trucks > 1)) trucks)
        ]


viewAddTruckButton : DeviceType -> Html Msg
viewAddTruckButton deviceType =
    let
        buttonClass =
            case deviceType of
                Desktop ->
                    "w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 flex items-center justify-center space-x-2"

                Tablet ->
                    "w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-3 rounded-lg transition-colors duration-200 flex items-center justify-center space-x-2"

                Mobile ->
                    "hidden"

        -- Hidden on mobile
    in
    button
        [ class buttonClass
        , onClick AddTruck
        , type_ "button"
        ]
        [ span [ class "text-lg" ] [ text "🚚" ]
        , text "Add Truck"
        ]


viewTruckItem : DeviceType -> Bool -> Int -> Truck -> Html Msg
viewTruckItem deviceType canRemove index truck =
    let
        itemClass =
            case deviceType of
                Desktop ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-4"

                Tablet ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-3"

                Mobile ->
                    "bg-gray-50 border border-gray-200 rounded-lg p-3"

        typography =
            Theme.getTypographyScale deviceType

        labelClass =
            typography.body

        inputClass =
            "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"

        equipmentNumber =
            index + 1
    in
    div [ class itemClass ]
        [ div [ class "flex items-center justify-between mb-3" ]
            [ h4 [ class (labelClass ++ " font-medium text-gray-800") ]
                [ span [ class "text-blue-600 mr-2" ] [ text "🚚" ]
                , text ("Truck " ++ String.fromInt equipmentNumber)
                ]
            , if canRemove && DeviceDetector.shouldShowAdvancedFeatures deviceType then
                button
                    [ class "text-red-600 hover:text-red-800 font-medium px-2 py-1 rounded"
                    , onClick (RemoveTruck truck.id)
                    , type_ "button"
                    ]
                    [ text "Remove" ]

              else
                text ""
            ]
        , div [ class "grid grid-cols-2 gap-3" ]
            [ div []
                [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                    [ text "Capacity (yd³)" ]
                , input
                    [ type_ "number"
                    , class inputClass
                    , value (String.fromFloat truck.capacity)
                    , onInput
                        (\val ->
                            case String.toFloat val of
                                Just f ->
                                    UpdateTruck truck.id (UpdateTruckCapacity f)

                                Nothing ->
                                    NoOp
                        )
                    , step "0.1"
                    , Html.Attributes.min "0.1"
                    ]
                    []
                ]
            , div []
                [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                    [ text "Round Trip Time (min)" ]
                , input
                    [ type_ "number"
                    , class inputClass
                    , value (String.fromFloat truck.roundTripTime)
                    , onInput
                        (\val ->
                            case String.toFloat val of
                                Just f ->
                                    UpdateTruck truck.id (UpdateTruckRoundTripTime f)

                                Nothing ->
                                    NoOp
                        )
                    , step "0.1"
                    , Html.Attributes.min "0.1"
                    ]
                    []
                ]
            ]
        , div [ class "mt-3" ]
            [ label [ class (labelClass ++ " block text-gray-700 mb-1") ]
                [ text "Equipment Name" ]
            , input
                [ type_ "text"
                , class inputClass
                , value truck.name
                , onInput (\val -> UpdateTruck truck.id (UpdateTruckName val))
                , placeholder ("Truck " ++ String.fromInt equipmentNumber)
                ]
                []
            ]
        , div [ class "mt-3 flex items-center" ]
            [ input
                [ type_ "checkbox"
                , class "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                , checked truck.isActive
                , onCheck (\val -> UpdateTruck truck.id (UpdateTruckActive val))
                ]
                []
            , label [ class (labelClass ++ " ml-2 text-gray-700") ]
                [ text "Equipment Active" ]
            ]
        ]
