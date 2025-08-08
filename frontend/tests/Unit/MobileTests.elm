module Unit.MobileTests exposing (suite)

import Expect
import Pages.Mobile as Mobile
import Test exposing (..)
import Types.Validation
import Utils.Calculations
import Utils.Config as Config


suite : Test
suite =
    describe "Mobile Calculator Tests"
        [ describe "initialization"
            [ test "initializes with config default values" <|
                \_ ->
                    let
                        ( model, _ ) =
                            Mobile.init

                        defaults =
                            Config.fallbackConfig.defaults
                    in
                    Expect.all
                        [ \m -> Expect.equal (String.fromFloat (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0)) m.excavatorCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 0.0)) m.excavatorCycleTime
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0)) m.truckCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 0.0)) m.truckRoundTripTime
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondLength) m.pondLength
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondWidth) m.pondWidth
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondDepth) m.pondDepth
                        , \m -> Expect.equal (String.fromFloat defaults.project.workHoursPerDay) m.workHours
                        ]
                        model
            ]
        , describe "real-time calculation"
            [ test "calculates result when excavator capacity changes" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        modelWithConfig =
                            { initialModel | config = Just Config.fallbackConfig }

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.ExcavatorCapacityChanged "4.0") modelWithConfig
                    in
                    case updatedModel.result of
                        Just result ->
                            Expect.greaterThan 0 result.totalHours

                        Nothing ->
                            Expect.fail "Should have calculated a result"
            , test "calculates result when pond dimensions change" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        modelWithConfig =
                            { initialModel | config = Just Config.fallbackConfig }

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.PondLengthChanged "150") modelWithConfig
                    in
                    case updatedModel.result of
                        Just result ->
                            Expect.greaterThan 0 result.totalHours

                        Nothing ->
                            Expect.fail "Should have calculated a result"
            ]
        , describe "clear functionality"
            [ test "resets all fields to config defaults when clear button is pressed" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        defaults =
                            Config.fallbackConfig.defaults

                        modelWithValues =
                            { initialModel
                                | excavatorCapacity = "5.0"
                                , pondLength = "200"
                                , config = Just Config.fallbackConfig -- Ensure config is loaded
                                , result =
                                    Just
                                        { timelineInDays = 10
                                        , totalHours = 80.0
                                        , excavationRate = 100.0
                                        , haulingRate = 100.0
                                        , bottleneck = Utils.Calculations.ExcavationBottleneck
                                        , confidence = Utils.Calculations.High
                                        , assumptions = []
                                        , warnings = []
                                        }
                            }

                        ( clearedModel, _ ) =
                            Mobile.update Mobile.ClearAll modelWithValues
                    in
                    Expect.all
                        [ \m -> Expect.equal (String.fromFloat (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0)) m.excavatorCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 0.0)) m.excavatorCycleTime
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0)) m.truckCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 0.0)) m.truckRoundTripTime
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondLength) m.pondLength
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondWidth) m.pondWidth
                        , \m -> Expect.equal (String.fromFloat defaults.project.pondDepth) m.pondDepth
                        , \m -> Expect.equal (String.fromFloat defaults.project.workHoursPerDay) m.workHours
                        , \m -> Expect.equal Nothing m.result
                        ]
                        clearedModel
            ]
        , describe "input validation"
            [ test "handles invalid numeric input gracefully" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        modelWithConfig =
                            { initialModel | config = Just Config.fallbackConfig }

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.ExcavatorCapacityChanged "abc") modelWithConfig
                    in
                    -- Should preserve previous result or show nothing
                    Expect.equal initialModel.result updatedModel.result
            , test "handles negative values" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.PondDepthChanged "-5") initialModel
                    in
                    -- Should preserve previous valid result when invalid input is entered
                    Expect.equal initialModel.result updatedModel.result
            ]
        , describe "config loading"
            [ test "loads default values from config when available" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        config =
                            Config.fallbackConfig

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.ConfigLoaded (Ok config)) initialModel
                    in
                    Expect.all
                        [ \m -> Expect.equal (String.fromFloat (List.head config.defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0)) m.excavatorCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head config.defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 0.0)) m.excavatorCycleTime
                        , \m -> Expect.equal (String.fromFloat (List.head config.defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0)) m.truckCapacity
                        , \m -> Expect.equal (String.fromFloat (List.head config.defaults.trucks |> Maybe.map .roundTripTime |> Maybe.withDefault 0.0)) m.truckRoundTripTime
                        , \m -> Expect.equal (String.fromFloat config.defaults.project.workHoursPerDay) m.workHours
                        ]
                        updatedModel
            , test "uses fallback config on load error" <|
                \_ ->
                    let
                        ( initialModel, _ ) =
                            Mobile.init

                        ( updatedModel, _ ) =
                            Mobile.update (Mobile.ConfigLoaded (Err (Types.Validation.ConfigurationError "Load failed"))) initialModel
                    in
                    Expect.equal (Just Config.fallbackConfig) updatedModel.config
            ]
        ]
