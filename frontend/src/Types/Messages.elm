module Types.Messages exposing (Msg(..))

{-| Application messages for the Elm Architecture

@docs Msg

-}

import Browser.Dom as Dom
import Components.ProjectForm exposing (FormMsg)
import Types.Equipment exposing (Equipment)
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
    | CalculateTimeline
    | DeviceDetected (Result Dom.Error { width : Int, height : Int })
    | WindowResized Int Int
