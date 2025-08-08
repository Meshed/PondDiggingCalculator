module Utils.Config exposing (Config, Defaults, ExcavatorDefaults, TruckDefaults, ProjectDefaults, FleetLimits, ValidationRules, ValidationRange, getConfig, configDecoder, fallbackConfig)

{-| Configuration utilities with build-time static configuration

@docs Config, Defaults, ExcavatorDefaults, TruckDefaults, ProjectDefaults, FleetLimits, ValidationRules, ValidationRange, getConfig, configDecoder, fallbackConfig

-}

import Json.Decode as Decode exposing (Decoder)
import Types.Validation exposing (ValidationError(..))
import Utils.ConfigGenerated exposing (staticConfig)



-- TYPES


type alias Config =
    { version : String
    , defaults : Defaults
    , fleetLimits : FleetLimits
    , validation : ValidationRules
    }


type alias Defaults =
    { excavators : List ExcavatorDefaults
    , trucks : List TruckDefaults
    , project : ProjectDefaults
    }


type alias FleetLimits =
    { maxExcavators : Int
    , maxTrucks : Int
    }


type alias ExcavatorDefaults =
    { bucketCapacity : Float
    , cycleTime : Float
    , name : String
    }


type alias TruckDefaults =
    { capacity : Float
    , roundTripTime : Float
    , name : String
    }


type alias ProjectDefaults =
    { workHoursPerDay : Float
    , pondLength : Float
    , pondWidth : Float
    , pondDepth : Float
    }


type alias ValidationRules =
    { excavatorCapacity : ValidationRange
    , cycleTime : ValidationRange
    , truckCapacity : ValidationRange
    , roundTripTime : ValidationRange
    , workHours : ValidationRange
    , pondDimensions : ValidationRange
    }


type alias ValidationRange =
    { min : Float
    , max : Float
    }



-- CONFIG LOADING


{-| Get configuration from build-time static data
Returns the configuration that was embedded at build time from /config/equipment-defaults.json
This eliminates HTTP requests and enables true offline-first behavior
-}
getConfig : Config
getConfig =
    staticConfig



-- JSON DECODERS


configDecoder : Decoder Config
configDecoder =
    Decode.map4 Config
        (Decode.field "version" Decode.string)
        (Decode.field "defaults" defaultsDecoder)
        (Decode.field "fleetLimits" fleetLimitsDecoder)
        (Decode.field "validation" validationRulesDecoder)


defaultsDecoder : Decoder Defaults
defaultsDecoder =
    Decode.map3 Defaults
        (Decode.field "excavators" (Decode.list excavatorDefaultsDecoder))
        (Decode.field "trucks" (Decode.list truckDefaultsDecoder))
        (Decode.field "project" projectDefaultsDecoder)


fleetLimitsDecoder : Decoder FleetLimits
fleetLimitsDecoder =
    Decode.map2 FleetLimits
        (Decode.field "maxExcavators" Decode.int)
        (Decode.field "maxTrucks" Decode.int)


excavatorDefaultsDecoder : Decoder ExcavatorDefaults
excavatorDefaultsDecoder =
    Decode.map3 ExcavatorDefaults
        (Decode.field "bucketCapacity" Decode.float)
        (Decode.field "cycleTime" Decode.float)
        (Decode.field "name" Decode.string)


truckDefaultsDecoder : Decoder TruckDefaults
truckDefaultsDecoder =
    Decode.map3 TruckDefaults
        (Decode.field "capacity" Decode.float)
        (Decode.field "roundTripTime" Decode.float)
        (Decode.field "name" Decode.string)


projectDefaultsDecoder : Decoder ProjectDefaults
projectDefaultsDecoder =
    Decode.map4 ProjectDefaults
        (Decode.field "workHoursPerDay" Decode.float)
        (Decode.field "pondLength" Decode.float)
        (Decode.field "pondWidth" Decode.float)
        (Decode.field "pondDepth" Decode.float)


validationRulesDecoder : Decoder ValidationRules
validationRulesDecoder =
    Decode.map6 ValidationRules
        (Decode.field "excavatorCapacity" validationRangeDecoder)
        (Decode.field "cycleTime" validationRangeDecoder)
        (Decode.field "truckCapacity" validationRangeDecoder)
        (Decode.field "roundTripTime" validationRangeDecoder)
        (Decode.field "workHours" validationRangeDecoder)
        (Decode.field "pondDimensions" validationRangeDecoder)


validationRangeDecoder : Decoder ValidationRange
validationRangeDecoder =
    Decode.map2 ValidationRange
        (Decode.field "min" Decode.float)
        (Decode.field "max" Decode.float)



-- FALLBACK DEFAULTS


{-| Fallback configuration used when HTTP loading fails
-}
fallbackConfig : Config
fallbackConfig =
    { version = "1.0.0"
    , defaults = fallbackDefaults
    , fleetLimits = fallbackFleetLimits
    , validation = fallbackValidationRules
    }


fallbackDefaults : Defaults
fallbackDefaults =
    { excavators =
        [ { bucketCapacity = 2.5
          , cycleTime = 2.0
          , name = "CAT 320 Excavator"
          }
        ]
    , trucks =
        [ { capacity = 12.0
          , roundTripTime = 15.0
          , name = "Standard Dump Truck"
          }
        ]
    , project =
        { workHoursPerDay = 8.0
        , pondLength = 40.0
        , pondWidth = 25.0
        , pondDepth = 5.0
        }
    }


fallbackFleetLimits : FleetLimits
fallbackFleetLimits =
    { maxExcavators = 10
    , maxTrucks = 20
    }


fallbackValidationRules : ValidationRules
fallbackValidationRules =
    { excavatorCapacity = { min = 0.5, max = 15.0 }
    , cycleTime = { min = 0.5, max = 10.0 }
    , truckCapacity = { min = 5.0, max = 30.0 }
    , roundTripTime = { min = 5.0, max = 60.0 }
    , workHours = { min = 1.0, max = 16.0 }
    , pondDimensions = { min = 1.0, max = 1000.0 }
    }
