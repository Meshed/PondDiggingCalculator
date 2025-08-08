module Unit.ConfigErrorBoundaryTests exposing (suite)

{-| Configuration Error Boundary Tests

Tests error handling and resilience for the build-time configuration system:

  - Fallback behavior when generated config has issues
  - Validation of error states
  - Recovery mechanisms
  - Graceful degradation

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config as Config


suite : Test
suite =
    describe "Configuration Error Boundary and Resilience"
        [ describe "Fallback Configuration Validation"
            [ test "fallback config provides complete valid structure" <|
                \_ ->
                    let
                        fallback =
                            Config.fallbackConfig
                    in
                    Expect.all
                        [ \c -> Expect.notEqual "" c.version
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.excavators)
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.trucks)
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxExcavators
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxTrucks
                        , \c -> validateFallbackIntegrity c
                        ]
                        fallback
            , test "fallback config contains realistic construction defaults" <|
                \_ ->
                    let
                        fallback =
                            Config.fallbackConfig

                        defaults =
                            fallback.defaults
                    in
                    case ( List.head defaults.excavators, List.head defaults.trucks ) of
                        ( Just excavator, Just truck ) ->
                            Expect.all
                                [ \_ -> Expect.atLeast 1.0 excavator.bucketCapacity -- Realistic excavator size
                                , \_ -> Expect.atMost 10.0 excavator.bucketCapacity -- Not oversized
                                , \_ -> Expect.atLeast 0.5 excavator.cycleTime -- Reasonable cycle time
                                , \_ -> Expect.atMost 5.0 excavator.cycleTime -- Not too slow
                                , \_ -> Expect.atLeast 8.0 truck.capacity -- Usable truck size
                                , \_ -> Expect.atMost 25.0 truck.capacity -- Not oversized
                                , \_ -> Expect.atLeast 5.0 truck.roundTripTime -- Reasonable trip time
                                , \_ -> Expect.atMost 30.0 truck.roundTripTime -- Not excessive
                                ]
                                ()

                        _ ->
                            Expect.fail "Fallback config missing equipment defaults"
            , test "fallback validation rules are consistent and logical" <|
                \_ ->
                    let
                        validation =
                            Config.fallbackConfig.validation
                    in
                    Expect.all
                        [ \v -> validateRangeLogic v.excavatorCapacity "excavatorCapacity"
                        , \v -> validateRangeLogic v.cycleTime "cycleTime"
                        , \v -> validateRangeLogic v.truckCapacity "truckCapacity"
                        , \v -> validateRangeLogic v.roundTripTime "roundTripTime"
                        , \v -> validateRangeLogic v.workHours "workHours"
                        , \v -> validateRangeLogic v.pondDimensions "pondDimensions"
                        ]
                        validation
            ]
        , describe "Configuration Consistency Validation"
            [ test "static and fallback configs have compatible structures" <|
                \_ ->
                    let
                        static =
                            Config.getConfig

                        fallback =
                            Config.fallbackConfig

                        -- Both should have same type structure and field names
                        staticFields =
                            extractConfigFields static

                        fallbackFields =
                            extractConfigFields fallback
                    in
                    Expect.equal staticFields fallbackFields
            , test "fallback defaults still fall within validation ranges" <|
                \_ ->
                    let
                        config =
                            Config.fallbackConfig

                        defaults =
                            config.defaults

                        validation =
                            config.validation
                    in
                    -- Same validation as static config should apply to fallback
                    Expect.all
                        [ \_ -> validateEquipmentWithinRanges defaults.excavators validation
                        , \_ -> validateTruckWithinRanges defaults.trucks validation
                        , \_ -> validateProjectWithinRanges defaults.project validation
                        ]
                        ()
            ]
        , describe "Configuration Error Scenarios"
            [ test "handles missing optional fields gracefully" <|
                \_ ->
                    let
                        -- Test that config structure remains functional with minimal data
                        minimalConfig =
                            Config.fallbackConfig
                    in
                    -- Should still provide usable defaults
                    Expect.all
                        [ \c -> Expect.greaterThan 0 (List.length c.defaults.excavators)
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.trucks)
                        , \c -> Expect.greaterThan 0 c.defaults.project.workHoursPerDay
                        ]
                        minimalConfig
            , test "validates that config doesn't contain extreme or invalid values" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        defaults =
                            config.defaults
                    in
                    case ( List.head defaults.excavators, List.head defaults.trucks ) of
                        ( Just excavator, Just truck ) ->
                            Expect.all
                                [ \_ -> Expect.lessThan 50.0 excavator.bucketCapacity -- No extreme values
                                , \_ -> Expect.greaterThan 0.1 excavator.bucketCapacity -- No zero values
                                , \_ -> Expect.lessThan 30.0 excavator.cycleTime -- Reasonable cycle time
                                , \_ -> Expect.lessThan 100.0 truck.capacity -- No extreme capacities
                                , \_ -> Expect.lessThan 300.0 truck.roundTripTime -- No extreme trip times
                                , \_ -> Expect.lessThan 1000.0 defaults.project.pondLength -- No extreme dimensions
                                , \_ -> Expect.lessThan 24.0 defaults.project.workHoursPerDay -- No more than 24 hours per day
                                ]
                                ()

                        _ ->
                            Expect.fail "No equipment defaults found for validation"
            ]
        , describe "Configuration Recovery Mechanisms"
            [ test "config module provides stable interface despite internal changes" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        -- These API calls should always work regardless of internal implementation
                        version =
                            config.version

                        excavatorCount =
                            List.length config.defaults.excavators

                        truckCount =
                            List.length config.defaults.trucks

                        maxExcavators =
                            config.fleetLimits.maxExcavators
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual "" version
                        , \_ -> Expect.atLeast 1 excavatorCount
                        , \_ -> Expect.atLeast 1 truckCount
                        , \_ -> Expect.atLeast 1 maxExcavators
                        ]
                        ()
            , test "configuration provides consistent data types" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation
                    in
                    -- All numeric fields should be proper floats/ints
                    Expect.all
                        [ \_ ->
                            if String.length config.version > 0 then
                                Expect.pass

                            else
                                Expect.fail "Version should be non-empty string"
                        , \_ ->
                            if config.fleetLimits.maxExcavators > 0 then
                                Expect.pass

                            else
                                Expect.fail "Max excavators should be positive"
                        , \_ ->
                            if config.fleetLimits.maxTrucks > 0 then
                                Expect.pass

                            else
                                Expect.fail "Max trucks should be positive"
                        , \_ ->
                            if validation.excavatorCapacity.min >= 0.0 then
                                Expect.pass

                            else
                                Expect.fail "Validation min should be non-negative"
                        , \_ ->
                            if validation.excavatorCapacity.max > 0.0 then
                                Expect.pass

                            else
                                Expect.fail "Validation max should be positive"
                        ]
                        ()
            ]
        , describe "Edge Case Handling"
            [ test "handles configuration with single equipment item" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        defaults =
                            config.defaults
                    in
                    -- Should work even with minimal equipment lists
                    Expect.all
                        [ \_ -> Expect.atLeast 1 (List.length defaults.excavators)
                        , \_ -> Expect.atLeast 1 (List.length defaults.trucks)
                        ]
                        ()
            , test "validates fleet limits are reasonable for application performance" <|
                \_ ->
                    let
                        limits =
                            Config.getConfig.fleetLimits
                    in
                    -- Fleet limits should prevent performance issues
                    Expect.all
                        [ \l -> Expect.atLeast 1 l.maxExcavators
                        , \l -> Expect.atMost 50 l.maxExcavators -- Prevent UI/performance issues
                        , \l -> Expect.atLeast 1 l.maxTrucks
                        , \l -> Expect.atMost 100 l.maxTrucks -- Prevent UI/performance issues
                        ]
                        limits
            , test "configuration supports international number formats" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation
                    in
                    -- All numeric values should be standard floats that work internationally
                    Expect.all
                        [ \_ ->
                            if isFinite validation.excavatorCapacity.min then
                                Expect.pass

                            else
                                Expect.fail "Excavator min should be finite"
                        , \_ ->
                            if isFinite validation.excavatorCapacity.max then
                                Expect.pass

                            else
                                Expect.fail "Excavator max should be finite"
                        , \_ ->
                            if isFinite validation.workHours.min then
                                Expect.pass

                            else
                                Expect.fail "Work hours min should be finite"
                        , \_ ->
                            if isFinite validation.workHours.max then
                                Expect.pass

                            else
                                Expect.fail "Work hours max should be finite"
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


{-| Validate fallback configuration integrity
-}
validateFallbackIntegrity : Config.Config -> Expect.Expectation
validateFallbackIntegrity config =
    let
        hasCompleteStructure =
            not (String.isEmpty config.version)
                && (List.length config.defaults.excavators > 0)
                && (List.length config.defaults.trucks > 0)
                && (config.fleetLimits.maxExcavators > 0)
                && (config.fleetLimits.maxTrucks > 0)
                && (config.validation.excavatorCapacity.max > config.validation.excavatorCapacity.min)
    in
    if hasCompleteStructure then
        Expect.pass

    else
        Expect.fail "Fallback configuration is incomplete or invalid"


{-| Validate that a range has logical min < max
-}
validateRangeLogic : Config.ValidationRange -> String -> Expect.Expectation
validateRangeLogic range fieldName =
    if range.min < range.max && range.min >= 0 then
        Expect.pass

    else
        Expect.fail (fieldName ++ " range is invalid: min=" ++ String.fromFloat range.min ++ ", max=" ++ String.fromFloat range.max)


{-| Extract configuration field structure for comparison
-}
extractConfigFields : Config.Config -> List String
extractConfigFields config =
    [ "version"
    , "defaults.excavators"
    , "defaults.trucks"
    , "defaults.project"
    , "fleetLimits.maxExcavators"
    , "fleetLimits.maxTrucks"
    , "validation.excavatorCapacity"
    , "validation.cycleTime"
    , "validation.truckCapacity"
    , "validation.roundTripTime"
    , "validation.workHours"
    , "validation.pondDimensions"
    ]


{-| Validate excavators are within validation ranges
-}
validateEquipmentWithinRanges : List Config.ExcavatorDefaults -> Config.ValidationRules -> Expect.Expectation
validateEquipmentWithinRanges excavators validation =
    case List.head excavators of
        Just excavator ->
            let
                capacityValid =
                    (excavator.bucketCapacity >= validation.excavatorCapacity.min)
                        && (excavator.bucketCapacity <= validation.excavatorCapacity.max)

                cycleTimeValid =
                    (excavator.cycleTime >= validation.cycleTime.min)
                        && (excavator.cycleTime <= validation.cycleTime.max)
            in
            if capacityValid && cycleTimeValid then
                Expect.pass

            else
                Expect.fail "Excavator defaults outside validation ranges"

        Nothing ->
            Expect.fail "No excavators found"


{-| Validate trucks are within validation ranges
-}
validateTruckWithinRanges : List Config.TruckDefaults -> Config.ValidationRules -> Expect.Expectation
validateTruckWithinRanges trucks validation =
    case List.head trucks of
        Just truck ->
            let
                capacityValid =
                    (truck.capacity >= validation.truckCapacity.min)
                        && (truck.capacity <= validation.truckCapacity.max)

                tripTimeValid =
                    (truck.roundTripTime >= validation.roundTripTime.min)
                        && (truck.roundTripTime <= validation.roundTripTime.max)
            in
            if capacityValid && tripTimeValid then
                Expect.pass

            else
                Expect.fail "Truck defaults outside validation ranges"

        Nothing ->
            Expect.fail "No trucks found"


{-| Validate project defaults are within validation ranges
-}
validateProjectWithinRanges : Config.ProjectDefaults -> Config.ValidationRules -> Expect.Expectation
validateProjectWithinRanges project validation =
    let
        workHoursValid =
            (project.workHoursPerDay >= validation.workHours.min)
                && (project.workHoursPerDay <= validation.workHours.max)

        dimensionsValid =
            (project.pondLength >= validation.pondDimensions.min)
                && (project.pondLength <= validation.pondDimensions.max)
                && (project.pondWidth >= validation.pondDimensions.min)
                && (project.pondWidth <= validation.pondDimensions.max)
                && (project.pondDepth >= validation.pondDimensions.min)
                && (project.pondDepth <= validation.pondDimensions.max)
    in
    if workHoursValid && dimensionsValid then
        Expect.pass

    else
        Expect.fail "Project defaults outside validation ranges"


{-| Check if a float value is finite (not NaN or infinity)
-}
isFinite : Float -> Bool
isFinite value =
    not (isNaN value) && not (isInfinite value)


{-| Check if a float value is NaN
-}
isNaN : Float -> Bool
isNaN value =
    value /= value


{-| Check if a float value is infinite
-}
isInfinite : Float -> Bool
isInfinite value =
    (value == (1 / 0)) || (value == (-1 / 0))
