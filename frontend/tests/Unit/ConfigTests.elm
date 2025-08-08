module Unit.ConfigTests exposing (suite)

import Expect
import Test exposing (..)
import Utils.Config as Config
import Utils.ConfigGenerated as ConfigGenerated


suite : Test
suite =
    describe "Configuration Tests"
        [ describe "Static Configuration Loading"
            [ test "getConfig returns valid configuration" <|
                \_ ->
                    let
                        config =
                            Config.getConfig
                    in
                    Expect.all
                        [ \c -> Expect.equal "1.0.0" c.version
                        , \c -> Expect.atLeast 1 (List.length c.defaults.excavators)
                        , \c -> Expect.atLeast 1 (List.length c.defaults.trucks)
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxExcavators
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxTrucks
                        ]
                        config
            , test "static configuration matches expected structure" <|
                \_ ->
                    let
                        config =
                            ConfigGenerated.staticConfig
                    in
                    Expect.all
                        [ \c -> Expect.equal "1.0.0" c.version
                        , \c -> Expect.equal 1 (List.length c.defaults.excavators)
                        , \c -> Expect.equal 1 (List.length c.defaults.trucks)
                        , \c -> Expect.equal 10 c.fleetLimits.maxExcavators
                        , \c -> Expect.equal 20 c.fleetLimits.maxTrucks
                        ]
                        config
            , test "excavator defaults are valid" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        firstExcavator =
                            List.head config.defaults.excavators
                    in
                    case firstExcavator of
                        Just excavator ->
                            Expect.all
                                [ \e -> Expect.greaterThan 0 e.bucketCapacity
                                , \e -> Expect.greaterThan 0 e.cycleTime
                                , \e -> Expect.notEqual "" e.name
                                , \e -> Expect.atMost config.validation.excavatorCapacity.max e.bucketCapacity
                                , \e -> Expect.atLeast config.validation.excavatorCapacity.min e.bucketCapacity
                                , \e -> Expect.atMost config.validation.cycleTime.max e.cycleTime
                                , \e -> Expect.atLeast config.validation.cycleTime.min e.cycleTime
                                ]
                                excavator

                        Nothing ->
                            Expect.fail "No excavator defaults found"
            , test "truck defaults are valid" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        firstTruck =
                            List.head config.defaults.trucks
                    in
                    case firstTruck of
                        Just truck ->
                            Expect.all
                                [ \t -> Expect.greaterThan 0 t.capacity
                                , \t -> Expect.greaterThan 0 t.roundTripTime
                                , \t -> Expect.notEqual "" t.name
                                , \t -> Expect.atMost config.validation.truckCapacity.max t.capacity
                                , \t -> Expect.atLeast config.validation.truckCapacity.min t.capacity
                                , \t -> Expect.atMost config.validation.roundTripTime.max t.roundTripTime
                                , \t -> Expect.atLeast config.validation.roundTripTime.min t.roundTripTime
                                ]
                                truck

                        Nothing ->
                            Expect.fail "No truck defaults found"
            , test "project defaults are within validation ranges" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        project =
                            config.defaults.project
                    in
                    Expect.all
                        [ \p -> Expect.atLeast config.validation.workHours.min p.workHoursPerDay
                        , \p -> Expect.atMost config.validation.workHours.max p.workHoursPerDay
                        , \p -> Expect.atLeast config.validation.pondDimensions.min p.pondLength
                        , \p -> Expect.atMost config.validation.pondDimensions.max p.pondLength
                        , \p -> Expect.atLeast config.validation.pondDimensions.min p.pondWidth
                        , \p -> Expect.atMost config.validation.pondDimensions.max p.pondWidth
                        , \p -> Expect.atLeast config.validation.pondDimensions.min p.pondDepth
                        , \p -> Expect.atMost config.validation.pondDimensions.max p.pondDepth
                        ]
                        project
            ]
        , describe "Build-time Integration"
            [ test "no HTTP requests needed for configuration" <|
                \_ ->
                    let
                        -- This test verifies that configuration is available immediately
                        -- without any async operations (Cmd.none scenario)
                        config =
                            Config.getConfig
                    in
                    -- If we can access all properties synchronously, no HTTP was needed
                    Expect.all
                        [ \c -> Expect.notEqual "" c.version
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.excavators)
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.trucks)
                        ]
                        config
            , test "fallback config remains available for compatibility" <|
                \_ ->
                    let
                        fallback =
                            Config.fallbackConfig

                        static =
                            Config.getConfig
                    in
                    -- Fallback should have same structure as static config
                    Expect.all
                        [ \_ -> Expect.equal static.version fallback.version
                        , \_ -> Expect.equal (List.length static.defaults.excavators) (List.length fallback.defaults.excavators)
                        , \_ -> Expect.equal (List.length static.defaults.trucks) (List.length fallback.defaults.trucks)
                        ]
                        ()
            ]
        , describe "Validation Rules Consistency"
            [ test "all validation ranges have min less than max" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation
                    in
                    -- Test each validation range individually - ensuring min < max
                    Expect.all
                        [ \_ ->
                            if validation.excavatorCapacity.min < validation.excavatorCapacity.max then
                                Expect.pass

                            else
                                Expect.fail ("excavatorCapacity: min=" ++ String.fromFloat validation.excavatorCapacity.min ++ " should be < max=" ++ String.fromFloat validation.excavatorCapacity.max)
                        , \_ ->
                            if validation.cycleTime.min < validation.cycleTime.max then
                                Expect.pass

                            else
                                Expect.fail ("cycleTime: min=" ++ String.fromFloat validation.cycleTime.min ++ " should be < max=" ++ String.fromFloat validation.cycleTime.max)
                        , \_ ->
                            if validation.truckCapacity.min < validation.truckCapacity.max then
                                Expect.pass

                            else
                                Expect.fail ("truckCapacity: min=" ++ String.fromFloat validation.truckCapacity.min ++ " should be < max=" ++ String.fromFloat validation.truckCapacity.max)
                        , \_ ->
                            if validation.roundTripTime.min < validation.roundTripTime.max then
                                Expect.pass

                            else
                                Expect.fail ("roundTripTime: min=" ++ String.fromFloat validation.roundTripTime.min ++ " should be < max=" ++ String.fromFloat validation.roundTripTime.max)
                        , \_ ->
                            if validation.workHours.min < validation.workHours.max then
                                Expect.pass

                            else
                                Expect.fail ("workHours: min=" ++ String.fromFloat validation.workHours.min ++ " should be < max=" ++ String.fromFloat validation.workHours.max)
                        , \_ ->
                            if validation.pondDimensions.min < validation.pondDimensions.max then
                                Expect.pass

                            else
                                Expect.fail ("pondDimensions: min=" ++ String.fromFloat validation.pondDimensions.min ++ " should be < max=" ++ String.fromFloat validation.pondDimensions.max)
                        ]
                        ()
            , test "fleet limits are reasonable" <|
                \_ ->
                    let
                        limits =
                            Config.getConfig.fleetLimits
                    in
                    Expect.all
                        [ \l -> Expect.atLeast 1 l.maxExcavators
                        , \l -> Expect.atMost 100 l.maxExcavators -- Reasonable upper bound
                        , \l -> Expect.atLeast 1 l.maxTrucks
                        , \l -> Expect.atMost 200 l.maxTrucks -- Reasonable upper bound
                        ]
                        limits
            ]
        ]
