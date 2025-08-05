module Utils.Config exposing (Config, Defaults, ExcavatorDefaults, TruckDefaults, ValidationRules, ValidationRange, loadConfig, configDecoder)

{-| Configuration loading and JSON decoding utilities

@docs Config, Defaults, ExcavatorDefaults, TruckDefaults, ValidationRules, ValidationRange, loadConfig, configDecoder

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Types.Validation exposing (ValidationError(..))


-- TYPES

type alias Config =
    { version : String
    , defaults : Defaults
    , validation : ValidationRules
    }


type alias Defaults =
    { excavator : ExcavatorDefaults
    , truck : TruckDefaults
    , project : ProjectDefaults
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

loadConfig : (Result ValidationError Config -> msg) -> Cmd msg
loadConfig toMsg =
    Http.get
        { url = "/config.json"
        , expect = Http.expectJson (resultToValidationError >> toMsg) configDecoder
        }


resultToValidationError : Result Http.Error Config -> Result ValidationError Config
resultToValidationError result =
    case result of
        Ok config ->
            Ok config

        Err httpError ->
            Err (ConfigurationError (httpErrorToString httpError))


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Invalid URL: " ++ url

        Http.Timeout ->
            "Request timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "HTTP error: " ++ String.fromInt status

        Http.BadBody message ->
            "Invalid JSON: " ++ message


-- JSON DECODERS

configDecoder : Decoder Config
configDecoder =
    Decode.map3 Config
        (Decode.field "version" Decode.string)
        (Decode.field "defaults" defaultsDecoder)
        (Decode.field "validation" validationRulesDecoder)


defaultsDecoder : Decoder Defaults
defaultsDecoder =
    Decode.map3 Defaults
        (Decode.field "excavator" excavatorDefaultsDecoder)
        (Decode.field "truck" truckDefaultsDecoder)
        (Decode.field "project" projectDefaultsDecoder)


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