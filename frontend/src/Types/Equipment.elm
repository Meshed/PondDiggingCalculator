module Types.Equipment exposing (Equipment, EquipmentType(..), EquipmentId, CubicYards, Minutes)

{-| Equipment domain types for pond digging calculations

@docs Equipment, EquipmentType, EquipmentId, CubicYards, Minutes

-}


-- EQUIPMENT TYPES

type alias EquipmentId =
    String


type alias CubicYards =
    Float


type alias Minutes =
    Float


type EquipmentType
    = Excavator
    | Truck


type alias Equipment =
    { id : EquipmentId
    , equipmentType : EquipmentType
    , name : String
    , bucketCapacity : CubicYards
    , cycleTime : Minutes
    , isActive : Bool
    }