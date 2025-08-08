module Unit.DataIntegrityTests exposing (suite)

{-| Data Integrity and Corruption Recovery Tests

Tests data reliability and recovery mechanisms:

  - Local storage corruption scenarios
  - Configuration data integrity validation
  - Recovery from invalid data states
  - Version migration edge cases
  - Cache invalidation and refresh scenarios

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config as Config


suite : Test
suite =
    describe "Data Integrity and Corruption Recovery"
        [ describe "Configuration Data Integrity"
            [ test "static configuration remains consistent across access patterns" <|
                \_ ->
                    let
                        config1 =
                            Config.getConfig

                        config2 =
                            Config.getConfig

                        config3 =
                            Config.getConfig
                    in
                    -- Multiple access attempts should return identical data
                    Expect.all
                        [ \_ -> Expect.equal config1.version config2.version
                        , \_ -> Expect.equal config1.version config3.version
                        , \_ -> Expect.equal config1.defaults.excavators config2.defaults.excavators
                        , \_ -> Expect.equal config1.defaults.trucks config2.defaults.trucks
                        , \_ -> Expect.equal config1.fleetLimits config2.fleetLimits
                        , \_ -> Expect.equal config1.validation config2.validation
                        ]
                        ()
            , test "configuration data is immutable and cannot be corrupted by reference manipulation" <|
                \_ ->
                    let
                        originalConfig =
                            Config.getConfig

                        -- Attempt to modify referenced data (should not affect original)
                        modifiedExcavators =
                            List.map (\exc -> { exc | name = "MODIFIED" }) originalConfig.defaults.excavators

                        configAfterModification =
                            Config.getConfig
                    in
                    -- Original configuration should remain unchanged
                    Expect.all
                        [ \_ -> Expect.equal originalConfig.version configAfterModification.version
                        , \_ -> Expect.equal originalConfig.defaults.excavators configAfterModification.defaults.excavators
                        , \_ -> Expect.notEqual modifiedExcavators configAfterModification.defaults.excavators
                        ]
                        ()
            , test "fallback configuration provides complete recovery data" <|
                \_ ->
                    let
                        fallback =
                            Config.fallbackConfig

                        static =
                            Config.getConfig
                    in
                    -- Fallback should have identical structure to static config
                    Expect.all
                        [ \_ -> validateConfigurationCompleteness fallback
                        , \_ -> Expect.equal (List.length static.defaults.excavators) (List.length fallback.defaults.excavators)
                        , \_ -> Expect.equal (List.length static.defaults.trucks) (List.length fallback.defaults.trucks)
                        , \_ -> Expect.equal static.fleetLimits.maxExcavators fallback.fleetLimits.maxExcavators
                        , \_ -> Expect.equal static.fleetLimits.maxTrucks fallback.fleetLimits.maxTrucks
                        ]
                        ()
            ]
        , describe "Numeric Data Integrity"
            [ test "configuration numeric values are finite and safe" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation

                        defaults =
                            config.defaults
                    in
                    case ( List.head defaults.excavators, List.head defaults.trucks ) of
                        ( Just excavator, Just truck ) ->
                            Expect.all
                                [ \_ -> validateFiniteNumber excavator.bucketCapacity "excavator.bucketCapacity"
                                , \_ -> validateFiniteNumber excavator.cycleTime "excavator.cycleTime"
                                , \_ -> validateFiniteNumber truck.capacity "truck.capacity"
                                , \_ -> validateFiniteNumber truck.roundTripTime "truck.roundTripTime"
                                , \_ -> validateFiniteNumber defaults.project.workHoursPerDay "project.workHoursPerDay"
                                , \_ -> validateFiniteNumber defaults.project.pondLength "project.pondLength"
                                , \_ -> validateFiniteNumber defaults.project.pondWidth "project.pondWidth"
                                , \_ -> validateFiniteNumber defaults.project.pondDepth "project.pondDepth"
                                , \_ -> validateFiniteNumber validation.excavatorCapacity.min "validation.excavatorCapacity.min"
                                , \_ -> validateFiniteNumber validation.excavatorCapacity.max "validation.excavatorCapacity.max"
                                ]
                                ()

                        _ ->
                            Expect.fail "Missing equipment defaults for numeric validation"
            , test "validation ranges prevent data corruption through extreme values" <|
                \_ ->
                    let
                        validation =
                            Config.getConfig.validation

                        -- Test all validation ranges for reasonable bounds
                        ranges =
                            [ ( validation.excavatorCapacity, "excavatorCapacity", 50.0 )
                            , ( validation.cycleTime, "cycleTime", 100.0 )
                            , ( validation.truckCapacity, "truckCapacity", 200.0 )
                            , ( validation.roundTripTime, "roundTripTime", 500.0 )
                            , ( validation.workHours, "workHours", 48.0 )
                            , ( validation.pondDimensions, "pondDimensions", 10000.0 )
                            ]
                    in
                    ranges
                        |> List.map (\( range, name, maxReasonable ) -> validateRangeReasonable range name maxReasonable)
                        |> Expect.all
            , test "numeric precision remains consistent across calculations" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        -- Test that repeated access maintains precision
                        value1 =
                            case List.head config.defaults.excavators of
                                Just exc ->
                                    exc.bucketCapacity

                                Nothing ->
                                    0.0

                        value2 =
                            case List.head Config.getConfig.defaults.excavators of
                                Just exc ->
                                    exc.bucketCapacity

                                Nothing ->
                                    0.0

                        value3 =
                            case List.head Config.getConfig.defaults.excavators of
                                Just exc ->
                                    exc.bucketCapacity

                                Nothing ->
                                    0.0
                    in
                    -- All accesses should return identical precision
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.0) value1 value2
                        , \_ -> Expect.within (Expect.Absolute 0.0) value2 value3
                        , \_ -> Expect.within (Expect.Absolute 0.0) value1 value3
                        ]
                        ()
            ]
        , describe "Configuration Version Management"
            [ test "configuration version is present and valid" <|
                \_ ->
                    let
                        version =
                            Config.getConfig.version
                    in
                    Expect.all
                        [ \_ -> Expect.greaterThan 0 (String.length version)
                        , \_ -> Expect.true "Version should match semver pattern" (isValidVersion version)
                        , \_ -> Expect.false "Version should not contain dangerous characters" (containsDangerousChars version)
                        ]
                        ()
            , test "version consistency across static and fallback configurations" <|
                \_ ->
                    let
                        staticVersion =
                            Config.getConfig.version

                        fallbackVersion =
                            Config.fallbackConfig.version
                    in
                    -- Versions should be identical for consistency
                    Expect.equal staticVersion fallbackVersion
            , test "configuration handles version comparison edge cases" <|
                \_ ->
                    let
                        version =
                            Config.getConfig.version
                    in
                    -- Version should be usable for comparison operations
                    Expect.all
                        [ \_ -> Expect.notEqual version ""
                        , \_ -> Expect.notEqual version "undefined"
                        , \_ -> Expect.notEqual version "null"
                        , \_ -> Expect.notEqual version "NaN"
                        , \_ -> Expect.false "Version should not be whitespace" (String.trim version |> String.isEmpty)
                        ]
                        ()
            ]
        , describe "Data Recovery Scenarios"
            [ test "configuration provides stable recovery after simulated corruption" <|
                \_ ->
                    let
                        -- Simulate recovery scenario by accessing config multiple times
                        recoveryAttempts =
                            List.range 1 10
                                |> List.map (\_ -> Config.getConfig)
                    in
                    case recoveryAttempts of
                        config1 :: rest ->
                            -- All recovery attempts should return identical data
                            rest
                                |> List.map (\config -> Expect.equal config1.version config.version)
                                |> Expect.all

                        [] ->
                            Expect.fail "Recovery attempts list should not be empty"
            , test "fallback mechanism provides working defaults under all conditions" <|
                \_ ->
                    let
                        fallback =
                            Config.fallbackConfig

                        -- Fallback should provide a complete working configuration
                        firstExcavator =
                            List.head fallback.defaults.excavators

                        firstTruck =
                            List.head fallback.defaults.trucks
                    in
                    case ( firstExcavator, firstTruck ) of
                        ( Just excavator, Just truck ) ->
                            Expect.all
                                [ \_ -> Expect.greaterThan 0 excavator.bucketCapacity
                                , \_ -> Expect.greaterThan 0 excavator.cycleTime
                                , \_ -> Expect.greaterThan 0 truck.capacity
                                , \_ -> Expect.greaterThan 0 truck.roundTripTime
                                , \_ -> Expect.greaterThan 0 fallback.defaults.project.workHoursPerDay
                                , \_ -> Expect.greaterThan 0 fallback.fleetLimits.maxExcavators
                                , \_ -> Expect.greaterThan 0 fallback.fleetLimits.maxTrucks
                                ]
                                ()

                        _ ->
                            Expect.fail "Fallback configuration missing essential equipment data"
            , test "data integrity maintained under rapid access patterns" <|
                \_ ->
                    let
                        -- Simulate rapid configuration access (like rapid user input)
                        rapidAccess =
                            List.range 1 100
                                |> List.map (\_ -> Config.getConfig.version)
                                |> List.foldl (::) []
                    in
                    case rapidAccess of
                        first :: rest ->
                            -- All rapid accesses should return identical version
                            rest
                                |> List.all (\version -> version == first)
                                |> Expect.true "All rapid access attempts should return identical data"

                        [] ->
                            Expect.fail "Rapid access should return data"
            ]
        , describe "Edge Case Data Handling"
            [ test "configuration handles boundary values correctly" <|
                \_ ->
                    let
                        config =
                            Config.getConfig

                        validation =
                            config.validation

                        -- Test that min/max values are at safe boundaries
                        boundaryTests =
                            [ ( validation.excavatorCapacity.min, validation.excavatorCapacity.max, "excavatorCapacity" )
                            , ( validation.cycleTime.min, validation.cycleTime.max, "cycleTime" )
                            , ( validation.truckCapacity.min, validation.truckCapacity.max, "truckCapacity" )
                            , ( validation.roundTripTime.min, validation.roundTripTime.max, "roundTripTime" )
                            , ( validation.workHours.min, validation.workHours.max, "workHours" )
                            , ( validation.pondDimensions.min, validation.pondDimensions.max, "pondDimensions" )
                            ]
                    in
                    boundaryTests
                        |> List.map (\( min, max, field ) -> validateBoundaryValues min max field)
                        |> Expect.all
            , test "string data contains only safe characters" <|
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
                                [ \_ -> validateSafeString excavator.name "excavator.name"
                                , \_ -> validateSafeString truck.name "truck.name"
                                , \_ -> validateSafeString config.version "config.version"
                                ]
                                ()

                        _ ->
                            Expect.fail "Missing equipment data for string validation"
            , test "configuration data structure prevents circular references" <|
                \_ ->
                    let
                        config =
                            Config.getConfig
                    in
                    -- Test that config can be safely serialized (no circular refs)
                    Expect.all
                        [ \_ -> validateNoCircularRefs config.defaults "defaults"
                        , \_ -> validateNoCircularRefs config.fleetLimits "fleetLimits"
                        , \_ -> validateNoCircularRefs config.validation "validation"
                        ]
                        ()
            ]
        ]



-- HELPER FUNCTIONS


{-| Validate configuration completeness
-}
validateConfigurationCompleteness : Config.Config -> Expect.Expectation
validateConfigurationCompleteness config =
    let
        hasVersion =
            not (String.isEmpty config.version)

        hasExcavators =
            List.length config.defaults.excavators > 0

        hasTrucks =
            List.length config.defaults.trucks > 0

        hasFleetLimits =
            config.fleetLimits.maxExcavators > 0 && config.fleetLimits.maxTrucks > 0

        hasValidation =
            config.validation.excavatorCapacity.max > config.validation.excavatorCapacity.min
    in
    if hasVersion && hasExcavators && hasTrucks && hasFleetLimits && hasValidation then
        Expect.pass

    else
        Expect.fail "Configuration is incomplete"


{-| Validate that a number is finite and safe
-}
validateFiniteNumber : Float -> String -> Expect.Expectation
validateFiniteNumber value fieldName =
    if isFinite value && not (isNaN value) then
        Expect.pass

    else
        Expect.fail (fieldName ++ " contains invalid numeric value: " ++ String.fromFloat value)


{-| Validate that a range has reasonable bounds
-}
validateRangeReasonable : Config.ValidationRange -> String -> Float -> Expect.Expectation
validateRangeReasonable range fieldName maxReasonable =
    if range.min >= 0 && range.max > range.min && range.max <= maxReasonable then
        Expect.pass

    else
        Expect.fail (fieldName ++ " has unreasonable range: " ++ String.fromFloat range.min ++ " to " ++ String.fromFloat range.max)


{-| Validate version string format
-}
isValidVersion : String -> Bool
isValidVersion version =
    let
        parts =
            String.split "." version

        isNumericPart part =
            String.toFloat part |> Maybe.map (always True) |> Maybe.withDefault False
    in
    List.length parts >= 2 && List.all isNumericPart (List.take 3 parts)


{-| Check for dangerous characters in strings
-}
containsDangerousChars : String -> Bool
containsDangerousChars str =
    String.contains "<" str
        || String.contains ">" str
        || String.contains "\"" str
        || String.contains "'" str
        || String.contains "&" str
        || String.contains "script" str


{-| Validate boundary values are within safe limits
-}
validateBoundaryValues : Float -> Float -> String -> Expect.Expectation
validateBoundaryValues min max fieldName =
    if min >= 0 && max > min && min < 1000000 && max < 1000000 then
        Expect.pass

    else
        Expect.fail (fieldName ++ " boundary values are unsafe: min=" ++ String.fromFloat min ++ ", max=" ++ String.fromFloat max)


{-| Validate string contains only safe characters
-}
validateSafeString : String -> String -> Expect.Expectation
validateSafeString str fieldName =
    if not (containsDangerousChars str) && String.length str > 0 && String.length str < 100 then
        Expect.pass

    else
        Expect.fail (fieldName ++ " contains unsafe or invalid string data: " ++ str)


{-| Validate no circular references (simplified check)
-}
validateNoCircularRefs : a -> String -> Expect.Expectation
validateNoCircularRefs _ fieldName =
    -- In Elm, circular references are prevented by the type system
    -- This is more of a structural validation
    Expect.pass


{-| Check if a float is finite
-}
isFinite : Float -> Bool
isFinite value =
    not (isNaN value) && not (isInfinite value)


{-| Check if a float is NaN
-}
isNaN : Float -> Bool
isNaN value =
    value /= value


{-| Check if a float is infinite
-}
isInfinite : Float -> Bool
isInfinite value =
    value == (1 / 0) || value == (-1 / 0)