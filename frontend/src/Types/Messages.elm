module Types.Messages exposing (Msg(..))

{-| Application messages for the Elm Architecture

@docs Msg

-}

import Browser.Dom as Dom
import Components.ProjectForm exposing (FormMsg)
import Types.Equipment exposing (Equipment)
import Types.Fields exposing (ExcavatorField, PondField, ProjectField, TruckField)
import Types.Validation exposing (ValidationError)
import Utils.Config exposing (Config)



-- APPLICATION MESSAGES


type Msg
    = NoOp
    | ConfigLoaded (Result ValidationError Config)
    | EquipmentAdded Equipment
    | EquipmentRemoved String
    | EquipmentUpdated Equipment
    | ValidationFailed ValidationError
    | FormUpdated FormMsg
      -- Real-time input change messages
    | ExcavatorFieldChanged ExcavatorField String
    | TruckFieldChanged TruckField String
    | PondFieldChanged PondField String
    | ProjectFieldChanged ProjectField String
    | CalculateTimeline
    | CalculateTimelineDebounced Float -- Current time in millis
    | CalculationCompleted (Result String String) -- Result CalculationError CalculationResult
    | PerformanceTracked Float -- milliseconds
    | DeviceDetected (Result Dom.Error { width : Int, height : Int })
    | WindowResized Int Int



-- REMOVED: MobileMsg - Mobile now uses same messages as desktop!
