module Styles.Responsive exposing (getLayoutClasses, getContainerClasses, getSpacingClasses, getGridClasses)

{-| Device-specific responsive styling constants

@docs getLayoutClasses, getContainerClasses, getSpacingClasses, getGridClasses

-}

import Types.DeviceType exposing (DeviceType(..))


{-| Get device-specific layout classes for main application structure
-}
getLayoutClasses : DeviceType -> String
getLayoutClasses deviceType =
    case deviceType of
        Mobile ->
            "flex flex-col space-y-4 px-4"

        Tablet ->
            "flex flex-col space-y-6 px-6"

        Desktop ->
            "flex flex-row space-x-8 px-8"


{-| Get device-specific container classes
-}
getContainerClasses : DeviceType -> String
getContainerClasses deviceType =
    case deviceType of
        Mobile ->
            "container mx-auto px-2 max-w-full"

        Tablet ->
            "container mx-auto px-4 max-w-4xl"

        Desktop ->
            "container mx-auto px-4 max-w-6xl"


{-| Get device-specific spacing classes
-}
getSpacingClasses : DeviceType -> { section : String, element : String, text : String }
getSpacingClasses deviceType =
    case deviceType of
        Mobile ->
            { section = "space-y-4 mb-6"
            , element = "space-y-2 mb-3"
            , text = "space-y-1 mb-2"
            }

        Tablet ->
            { section = "space-y-6 mb-8"
            , element = "space-y-3 mb-4"
            , text = "space-y-2 mb-3"
            }

        Desktop ->
            { section = "space-y-8 mb-10"
            , element = "space-y-4 mb-5"
            , text = "space-y-2 mb-3"
            }


{-| Get device-specific grid classes for form layouts
-}
getGridClasses : DeviceType -> String
getGridClasses deviceType =
    case deviceType of
        Mobile ->
            "grid grid-cols-1 gap-4"

        Tablet ->
            "grid grid-cols-2 gap-6"

        Desktop ->
            "grid grid-cols-3 gap-8"
