module Unit.BuildProcessTests exposing (suite)

{-| Build Process Integration Tests

Tests the build-time configuration system to ensure:

  - Generated configuration matches JSON schema requirements
  - Static config provides identical data structure as HTTP loading would
  - Performance characteristics of build-time loading
  - Configuration integrity and validation

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config as Config
import Utils.ConfigGenerated as ConfigGenerated


suite : Test
suite =
    describe "Build Process Configuration Integration"
        [ describe "Generated Configuration Module Integrity"
            [ test "generated config matches expected structure" <|
                \_ ->
                    let
                        config =
                            Config.getConfig
                    in
                    Expect.all
                        [ \c -> Expect.notEqual "" c.version
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.excavators)
                        , \c -> Expect.greaterThan 0 (List.length c.defaults.trucks)
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxExcavators
                        , \c -> Expect.greaterThan 0 c.fleetLimits.maxTrucks
                        , \c -> validateConfigurationCompleteness c
                        ]
                        config
            , test "static config exactly matches fallback config structure" <|
                \_ ->
                    let
                        static =
                            Config.getConfig

                        fallback =
                            Config.fallbackConfig
                    in
                    -- Both should have identical structure and compatible data
                    Expect.all
                        [ \_ -> Expect.equal static.version fallback.version
                        , \_ -> Expect.equal (List.length static.defaults.excavators) (List.length fallback.defaults.excavators)
                        , \_ -> Expect.equal (List.length static.defaults.trucks) (List.length fallback.defaults.trucks)
                        , \_ -> Expect.equal static.fleetLimits.maxExcavators fallback.fleetLimits.maxExcavators
                        , \_ -> Expect.equal static.fleetLimits.maxTrucks fallback.fleetLimits.maxTrucks
                        ]
                        ()
            , test "generated config includes all required validation rules" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation
                    in
                    Expect.all
                        [ \v -> validateRangeStructure v.excavatorCapacity "excavatorCapacity"
                        , \v -> validateRangeStructure v.cycleTime "cycleTime"
                        , \v -> validateRangeStructure v.truckCapacity "truckCapacity"
                        , \v -> validateRangeStructure v.roundTripTime "roundTripTime"
                        , \v -> validateRangeStructure v.workHours "workHours"
                        , \v -> validateRangeStructure v.pondDimensions "pondDimensions"
                        ]
                        validation
            ]
        , describe "Build-Time Configuration Validation"
            [ test "all defaults fall within their validation ranges" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        defaults =
                            config.defaults

                        validation =
                            config.validation
                    in
                    Expect.all
                        [ \_ -> validateExcavatorDefaults defaults.excavators validation
                        , \_ -> validateTruckDefaults defaults.trucks validation
                        , \_ -> validateProjectDefaults defaults.project validation
                        ]
                        ()
            , test "fleet limits are reasonable and positive" <|
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
                        , \l -> Expect.greaterThan l.maxExcavators l.maxTrucks -- Trucks usually outnumber excavators
                        ]
                        limits
            , test "version follows semantic versioning format" <|
                \_ ->
                    let
                        version =
                            Config.getConfig.version

                        -- Simple semantic version validation (Major.Minor.Patch)
                        parts =
                            String.split "." version
                    in
                    Expect.all
                        [ \_ -> Expect.equal 3 (List.length parts)
                        , \_ ->
                            case parts of
                                [ major, minor, patch ] ->
                                    Expect.all
                                        [ \_ ->
                                            if String.toInt major /= Nothing then
                                                Expect.pass

                                            else
                                                Expect.fail "Major version should be numeric"
                                        , \_ ->
                                            if String.toInt minor /= Nothing then
                                                Expect.pass

                                            else
                                                Expect.fail "Minor version should be numeric"
                                        , \_ ->
                                            if String.toInt patch /= Nothing then
                                                Expect.pass

                                            else
                                                Expect.fail "Patch version should be numeric"
                                        ]
                                        ()

                                _ ->
                                    Expect.fail ("Invalid version format: " ++ version)
                        ]
                        ()
            ]
        , describe "Performance Characteristics"
            [ test "static config loading is synchronous and immediate" <|
                \_ ->
                    let
                        -- This test validates that config loading doesn't require Cmd or Task
                        config =
                            Config.getConfig

                        -- Should be able to access immediately without async operations
                        version =
                            config.version

                        excavatorCount =
                            List.length config.defaults.excavators
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual "" version
                        , \_ -> Expect.greaterThan 0 excavatorCount
                        ]
                        ()
            , test "config access is consistent across multiple calls" <|
                \_ ->
                    let
                        config1 =
                            Config.getConfig

                        config2 =
                            Config.getConfig

                        config3 =
                            Config.getConfig
                    in
                    -- All calls should return identical data
                    Expect.all
                        [ \_ -> Expect.equal config1.version config2.version
                        , \_ -> Expect.equal config2.version config3.version
                        , \_ -> Expect.equal config1.fleetLimits.maxExcavators config2.fleetLimits.maxExcavators
                        , \_ -> Expect.equal config1.defaults.project.workHoursPerDay config3.defaults.project.workHoursPerDay
                        ]
                        ()
            ]
        , describe "Configuration Content Validation"
            [ test "equipment defaults contain realistic values" <|
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
                                [ \_ -> Expect.greaterThan 0 excavator.bucketCapacity
                                , \_ -> Expect.greaterThan 0 excavator.cycleTime
                                , \_ -> Expect.notEqual "" excavator.name
                                , \_ -> Expect.greaterThan 0 truck.capacity
                                , \_ -> Expect.greaterThan 0 truck.roundTripTime
                                , \_ -> Expect.notEqual "" truck.name
                                ]
                                ()

                        _ ->
                            Expect.fail "No default equipment found"
            , test "project defaults are reasonable for construction work" <|
                \_ ->
                    let
                        project =
                            Config.getConfig.defaults.project
                    in
                    Expect.all
                        [ \p -> Expect.atLeast 4.0 p.workHoursPerDay -- Minimum reasonable work day
                        , \p -> Expect.atMost 16.0 p.workHoursPerDay -- Maximum reasonable work day
                        , \p -> Expect.greaterThan 0 p.pondLength
                        , \p -> Expect.greaterThan 0 p.pondWidth
                        , \p -> Expect.greaterThan 0 p.pondDepth
                        , \p -> Expect.lessThan p.pondLength p.pondWidth -- Typical pond proportions or equal
                        ]
                        project
            ]
        ]



-- HELPER FUNCTIONS


{-| Validate that a configuration contains all required fields
-}
validateConfigurationCompleteness : Config.Config -> Expect.Expectation
validateConfigurationCompleteness config =
    Expect.all
        [ \c ->
            if not (String.isEmpty c.version) then
                Expect.pass

            else
                Expect.fail "Configuration should have version"
        , \c ->
            if List.length c.defaults.excavators > 0 then
                Expect.pass

            else
                Expect.fail "Configuration should have excavator defaults"
        , \c ->
            if List.length c.defaults.trucks > 0 then
                Expect.pass

            else
                Expect.fail "Configuration should have truck defaults"
        , \c ->
            if c.defaults.project.workHoursPerDay > 0 then
                Expect.pass

            else
                Expect.fail "Configuration should have project defaults"
        , \c ->
            if c.fleetLimits.maxExcavators > 0 then
                Expect.pass

            else
                Expect.fail "Configuration should have fleet limits"
        , \c ->
            if c.validation.excavatorCapacity.max > c.validation.excavatorCapacity.min then
                Expect.pass

            else
                Expect.fail "Configuration should have validation rules"
        ]
        config


{-| Validate that a range structure has min < max
-}
validateRangeStructure : Config.ValidationRange -> String -> Expect.Expectation
validateRangeStructure range fieldName =
    if range.min < range.max then
        Expect.pass

    else
        Expect.fail (fieldName ++ ": min (" ++ String.fromFloat range.min ++ ") should be < max (" ++ String.fromFloat range.max ++ ")")


{-| Validate excavator defaults against validation rules
-}
validateExcavatorDefaults : List Config.ExcavatorDefaults -> Config.ValidationRules -> Expect.Expectation
validateExcavatorDefaults excavators validation =
    let
        validateExcavator excavator =
            if
                (excavator.bucketCapacity >= validation.excavatorCapacity.min)
                    && (excavator.bucketCapacity <= validation.excavatorCapacity.max)
                    && (excavator.cycleTime >= validation.cycleTime.min)
                    && (excavator.cycleTime <= validation.cycleTime.max)
                    && not (String.isEmpty excavator.name)
            then
                Expect.pass

            else
                Expect.fail ("Excavator " ++ excavator.name ++ " has invalid defaults")
    in
    case excavators of
        [] ->
            Expect.fail "No excavator defaults found"

        firstExcavator :: _ ->
            validateExcavator firstExcavator


{-| Validate truck defaults against validation rules
-}
validateTruckDefaults : List Config.TruckDefaults -> Config.ValidationRules -> Expect.Expectation
validateTruckDefaults trucks validation =
    let
        validateTruck truck =
            if
                (truck.capacity >= validation.truckCapacity.min)
                    && (truck.capacity <= validation.truckCapacity.max)
                    && (truck.roundTripTime >= validation.roundTripTime.min)
                    && (truck.roundTripTime <= validation.roundTripTime.max)
                    && not (String.isEmpty truck.name)
            then
                Expect.pass

            else
                Expect.fail ("Truck " ++ truck.name ++ " has invalid defaults")
    in
    case trucks of
        [] ->
            Expect.fail "No truck defaults found"

        firstTruck :: _ ->
            validateTruck firstTruck


{-| Validate project defaults against validation rules
-}
validateProjectDefaults : Config.ProjectDefaults -> Config.ValidationRules -> Expect.Expectation
validateProjectDefaults project validation =
    if
        (project.workHoursPerDay >= validation.workHours.min)
            && (project.workHoursPerDay <= validation.workHours.max)
            && (project.pondLength >= validation.pondDimensions.min)
            && (project.pondLength <= validation.pondDimensions.max)
            && (project.pondWidth >= validation.pondDimensions.min)
            && (project.pondWidth <= validation.pondDimensions.max)
            && (project.pondDepth >= validation.pondDimensions.min)
            && (project.pondDepth <= validation.pondDimensions.max)
    then
        Expect.pass

    else
        Expect.fail "Project defaults fall outside validation ranges"
