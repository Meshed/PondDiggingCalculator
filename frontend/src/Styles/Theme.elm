module Styles.Theme exposing
    ( container, textCenter, button, card, input, errorText, getButtonClasses, getCardClasses, getInputClasses, getTypographyScale, getMobileCalculatorClasses, getMobileTouchTarget
    , getMobileCardClasses, getMobileGridClasses, getMobileInputClasses
    )

{-| Tailwind CSS class constants for type-safe styling

@docs container, textCenter, button, card, input, errorText, getButtonClasses, getCardClasses, getInputClasses, getTypographyScale, getMobileCalculatorClasses, getMobileTouchTarget

-}

import Types.DeviceType exposing (DeviceType(..))



-- LAYOUT CLASSES


container : String
container =
    "container mx-auto p-4"


textCenter : String
textCenter =
    "text-center"



-- COMPONENT CLASSES


button : String
button =
    "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"


card : String
card =
    "bg-white shadow-md rounded-lg p-6 m-4"


input : String
input =
    "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"


errorText : String
errorText =
    "text-red-500 text-sm mt-1"



-- DEVICE-SPECIFIC RESPONSIVE CLASSES


{-| Get device-specific button classes with proper touch targets
-}
getButtonClasses : DeviceType -> String
getButtonClasses deviceType =
    let
        baseClasses =
            "bg-blue-500 hover:bg-blue-700 text-white font-bold rounded focus:outline-none focus:shadow-outline"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " py-3 px-6 text-lg min-h-11"

        -- 44px minimum touch target
        Tablet ->
            baseClasses ++ " py-3 px-5 text-base min-h-11"

        Desktop ->
            baseClasses ++ " py-2 px-4 text-sm"


{-| Get device-specific card classes
-}
getCardClasses : DeviceType -> String
getCardClasses deviceType =
    let
        baseClasses =
            "bg-white shadow-md rounded-lg"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " p-4 m-2"

        Tablet ->
            baseClasses ++ " p-5 m-3"

        Desktop ->
            baseClasses ++ " p-6 m-4"


{-| Get device-specific input classes with proper touch targets
-}
getInputClasses : DeviceType -> String
getInputClasses deviceType =
    let
        baseClasses =
            "shadow appearance-none border rounded w-full text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
    in
    case deviceType of
        Mobile ->
            baseClasses ++ " py-3 px-4 text-lg min-h-11"

        -- 44px minimum touch target
        Tablet ->
            baseClasses ++ " py-3 px-3 text-base min-h-11"

        Desktop ->
            baseClasses ++ " py-2 px-3 text-sm"


{-| Get device-specific typography scale classes
-}
getTypographyScale : DeviceType -> { heading : String, subheading : String, body : String }
getTypographyScale deviceType =
    case deviceType of
        Mobile ->
            { heading = "text-2xl font-bold"
            , subheading = "text-lg font-semibold"
            , body = "text-base"
            }

        Tablet ->
            { heading = "text-3xl font-bold"
            , subheading = "text-xl font-semibold"
            , body = "text-base"
            }

        Desktop ->
            { heading = "text-4xl font-bold"
            , subheading = "text-xl font-semibold"
            , body = "text-sm"
            }


{-| Get mobile-specific calculator interface classes
-}
getMobileCalculatorClasses : { header : String, results : String, inputs : String, actions : String }
getMobileCalculatorClasses =
    { header = "mobile-header"
    , results = "mobile-results"
    , inputs = "mobile-inputs"
    , actions = "mobile-actions"
    }


{-| Get minimum touch target size for mobile interfaces (44x44 pixels)
-}
getMobileTouchTarget : String
getMobileTouchTarget =
    "min-h-11 min-w-11"


{-| Get mobile-specific calculator input styling classes
-}
getMobileInputClasses : String
getMobileInputClasses =
    "w-full text-center text-lg font-semibold bg-gray-50 border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:bg-white transition-colors py-4 px-3 min-h-14"


{-| Get mobile calculator card styling classes
-}
getMobileCardClasses : String
getMobileCardClasses =
    "bg-white rounded-xl shadow-lg mx-4 my-2 p-4"


{-| Get mobile calculator grid classes for inputs
-}
getMobileGridClasses : String
getMobileGridClasses =
    "grid grid-cols-2 gap-3"
