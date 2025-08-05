module Types.Model exposing (Model, Flags)

{-| Core application state model

@docs Model, Flags

-}

import Utils.Config exposing (Config)
import Components.ProjectForm exposing (FormData)
import Utils.Calculations exposing (CalculationResult)


-- MODEL

type alias Model =
    { message : String
    , config : Maybe Config
    , formData : Maybe FormData
    , calculationResult : Maybe CalculationResult
    }


type alias Flags =
    ()