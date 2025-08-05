module Styles.Components exposing (getFormClasses, getEquipmentCardClasses, getResultsPanelClasses, getValidationMessageClasses)

{-| Component-specific responsive styling

@docs getFormClasses, getEquipmentCardClasses, getResultsPanelClasses, getValidationMessageClasses

-}

import Types.DeviceType exposing (DeviceType(..))


{-| Get device-specific form classes
-}
getFormClasses : DeviceType -> String
getFormClasses deviceType =
    let
        baseClasses =
            "bg-white rounded-lg shadow-md"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " p-4 space-y-4"

        Tablet ->
            baseClasses ++ " p-6 space-y-6"

        Desktop ->
            baseClasses ++ " p-8 space-y-6"


{-| Get device-specific equipment card classes
-}
getEquipmentCardClasses : DeviceType -> String
getEquipmentCardClasses deviceType =
    let
        baseClasses =
            "bg-white border border-gray-200 rounded-lg shadow-sm"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " p-4 mb-4 flex flex-col space-y-3"

        Tablet ->
            baseClasses ++ " p-5 mb-5 flex flex-row space-x-4 items-center"

        Desktop ->
            baseClasses ++ " p-6 mb-6 flex flex-row space-x-6 items-center"


{-| Get device-specific results panel classes
-}
getResultsPanelClasses : DeviceType -> String
getResultsPanelClasses deviceType =
    let
        baseClasses =
            "bg-blue-50 border border-blue-200 rounded-lg"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " p-4 space-y-3"

        Tablet ->
            baseClasses ++ " p-6 space-y-4"

        Desktop ->
            baseClasses ++ " p-8 space-y-6"


{-| Get device-specific validation message classes
-}
getValidationMessageClasses : DeviceType -> String
getValidationMessageClasses deviceType =
    let
        baseClasses =
            "text-red-500 font-medium"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " text-sm mt-2 p-2 bg-red-50 rounded border border-red-200"

        Tablet ->
            baseClasses ++ " text-sm mt-1"

        Desktop ->
            baseClasses ++ " text-xs mt-1"