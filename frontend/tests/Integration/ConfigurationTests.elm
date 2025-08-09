module Integration.ConfigurationTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Utils.Config as Config
import Utils.ConfigGenerated exposing (staticConfig)


suite : Test
suite =
    describe "Build-Time Configuration Integration"
        [ describe "Static Configuration Loading"
            [ test "should load configuration from generated module" <|
                \_ ->
                    let
                        config =
                            Config.getConfig
                    in
                    Expect.equal config.version "1.0.0"
            , test "should have excavator defaults from configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        excavators =
                            config.defaults.excavators
                    in
                    Expect.greaterThan 0 (List.length excavators)
            , test "should have truck defaults from configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        trucks =
                            config.defaults.trucks
                    in
                    Expect.greaterThan 0 (List.length trucks)
            , test "should have project defaults from configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        project =
                            config.defaults.project
                    in
                    Expect.all
                        [ .workHoursPerDay >> Expect.greaterThan 0
                        , .pondLength >> Expect.greaterThan 0
                        , .pondWidth >> Expect.greaterThan 0
                        , .pondDepth >> Expect.greaterThan 0
                        ]
                        project
            ]
        , describe "Validation Rules Integration"
            [ test "should have validation rules from configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation
                    in
                    Expect.all
                        [ .excavatorCapacity >> .min >> Expect.greaterThan 0
                        , .excavatorCapacity >> .max >> Expect.greaterThan 0
                        , .cycleTime >> .min >> Expect.greaterThan 0
                        , .cycleTime >> .max >> Expect.greaterThan 0
                        , .truckCapacity >> .min >> Expect.greaterThan 0
                        , .truckCapacity >> .max >> Expect.greaterThan 0
                        , .roundTripTime >> .min >> Expect.greaterThan 0
                        , .roundTripTime >> .max >> Expect.greaterThan 0
                        , .workHours >> .min >> Expect.greaterThan 0
                        , .workHours >> .max >> Expect.greaterThan 0
                        , .pondDimensions >> .min >> Expect.greaterThan 0
                        , .pondDimensions >> .max >> Expect.greaterThan 0
                        ]
                        validation
            ]
        , describe "Fleet Limits Integration"
            [ test "should have fleet limits from configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        limits =
                            config.fleetLimits
                    in
                    Expect.all
                        [ .maxExcavators >> Expect.greaterThan 0
                        , .maxTrucks >> Expect.greaterThan 0
                        ]
                        limits
            ]
        , describe "Build-Time vs Runtime Configuration"
            [ test "should use static configuration instead of fallback" <|
                \_ ->
                    let
                        staticConfigData =
                            staticConfig

                        dynamicConfig =
                            Config.getConfig
                    in
                    Expect.equal staticConfigData dynamicConfig
            ]
        ]
