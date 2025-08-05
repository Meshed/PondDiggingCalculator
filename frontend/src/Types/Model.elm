module Types.Model exposing (Model, Flags)

{-| Core application state model

@docs Model, Flags

-}

import Components.ProjectForm exposing (FormData)
import Types.DeviceType exposing (DeviceType)
import Utils.Calculations exposing (CalculationResult)
import Utils.Config exposing (Config)
import Utils.Debounce exposing (DebounceState)
import Utils.Performance exposing (PerformanceMetrics)



-- MODEL


type alias Model =
    { message : String
    , config : Maybe Config
    , formData : Maybe FormData
    , calculationResult : Maybe CalculationResult
    , lastValidResult : Maybe CalculationResult -- Preserve during validation errors
    , deviceType : DeviceType
    , calculationInProgress : Bool -- Prevent race conditions
    , performanceMetrics : PerformanceMetrics -- Track calculation performance
    , debounceState : DebounceState -- For input debouncing
    }


type alias Flags =
    ()
