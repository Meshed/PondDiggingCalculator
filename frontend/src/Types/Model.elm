module Types.Model exposing (Model, Flags)

{-| Core application state model

@docs Model, Flags

-}

import Utils.Config exposing (Config)


-- MODEL

type alias Model =
    { message : String
    , config : Maybe Config
    }


type alias Flags =
    ()