module Types.Model exposing (Model, Flags)

{-| Core application state model

@docs Model, Flags

-}

import Components.ProjectForm exposing (FormData)
import Types.DeviceType exposing (DeviceType)
import Utils.Calculations exposing (CalculationResult)
import Utils.Config exposing (Config)



-- MODEL


type alias Model =
    { message : String
    , config : Maybe Config
    , formData : Maybe FormData
    , calculationResult : Maybe CalculationResult
    , deviceType : DeviceType
    }


type alias Flags =
    ()
