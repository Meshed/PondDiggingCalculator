module Styles.Theme exposing (container, textCenter, button, card, input, errorText)

{-| Tailwind CSS class constants for type-safe styling

@docs container, textCenter, button, card, input, errorText

-}

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
