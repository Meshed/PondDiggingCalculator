module Types.Fields exposing (ExcavatorField(..), TruckField(..), PondField(..), ProjectField(..))

{-| Field types for real-time input handling

@docs ExcavatorField, TruckField, PondField, ProjectField

-}


-- FIELD TYPES FOR REAL-TIME UPDATES


type ExcavatorField
    = BucketCapacity
    | CycleTime


type TruckField
    = TruckCapacity
    | RoundTripTime


type PondField
    = PondLength
    | PondWidth
    | PondDepth


type ProjectField
    = WorkHours