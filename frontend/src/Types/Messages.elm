module Types.Messages exposing (Msg(..), ExcavatorUpdate(..), TruckUpdate(..))

{-| Application messages for the Elm Architecture

@docs Msg, ExcavatorUpdate, TruckUpdate

-}

import Browser.Dom as Dom
import Components.ProjectForm exposing (FormMsg)
import Types.Equipment exposing (EquipmentId)
import Types.Fields exposing (ExcavatorField, PondField, ProjectField, TruckField)
import Types.Validation exposing (ValidationError)
import Utils.Config exposing (Config)



-- APPLICATION MESSAGES


type ExcavatorUpdate
    = UpdateExcavatorBucketCapacity Float
    | UpdateExcavatorCycleTime Float
    | UpdateExcavatorName String
    | UpdateExcavatorActive Bool


type TruckUpdate
    = UpdateTruckCapacity Float
    | UpdateTruckRoundTripTime Float
    | UpdateTruckName String
    | UpdateTruckActive Bool


type Msg
    = NoOp
    | ConfigLoaded (Result ValidationError Config)
      -- Fleet Management Messages
    | AddExcavator
    | RemoveExcavator EquipmentId
    | UpdateExcavator EquipmentId ExcavatorUpdate
    | AddTruck
    | RemoveTruck EquipmentId
    | UpdateTruck EquipmentId TruckUpdate
    | ValidationFailed ValidationError
    | FormUpdated FormMsg
      -- Real-time input change messages
    | ExcavatorFieldChanged ExcavatorField String
    | TruckFieldChanged TruckField String
    | PondFieldChanged PondField String
      -- UI Messages
    | DismissInfoBanner
    | ProjectFieldChanged ProjectField String
    | CalculateTimeline
    | CalculateTimelineDebounced Float -- Current time in millis
    | CalculationCompleted (Result String String) -- Result CalculationError CalculationResult
    | PerformanceTracked Float -- milliseconds
    | DeviceDetected (Result Dom.Error { width : Int, height : Int })
    | WindowResized Int Int



-- REMOVED: MobileMsg - Mobile now uses same messages as desktop!
