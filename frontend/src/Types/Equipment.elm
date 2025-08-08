module Types.Equipment exposing (Excavator, Truck, EquipmentId, CubicYards, Minutes)

{-| Equipment domain types for pond digging calculations

@docs Excavator, Truck, EquipmentId, CubicYards, Minutes

-}

-- EQUIPMENT TYPES


type alias EquipmentId =
    String


type alias CubicYards =
    Float


type alias Minutes =
    Float


type alias Excavator =
    { id : EquipmentId
    , bucketCapacity : CubicYards
    , cycleTime : Minutes
    , name : String
    , isActive : Bool
    }


type alias Truck =
    { id : EquipmentId
    , capacity : CubicYards
    , roundTripTime : Minutes
    , name : String
    , isActive : Bool
    }
