module Unit.DefaultValueTests exposing (suite)

{-| Unit tests for default value loading and behavior

@docs suite

-}

import Components.ProjectForm exposing (initFormData)
import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Utils.Calculations exposing (calculateExcavatorRate, calculateTimeline, calculateTruckRate)
import Utils.Config exposing (Config, fallbackConfig)


suite : Test
suite =
    describe "Default Value Behavior"
        [ describe "Configuration Loading"
            [ test "should_have_fallback_configuration_available_immediately" <|
                \_ ->
                    let
                        config =
                            fallbackConfig
                    in
                    Expect.equal config.version "1.0.0"
            , test "should_populate_default_excavator_values_from_config" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        firstExcavator =
                            List.head config.defaults.excavators
                    in
                    case firstExcavator of
                        Just excavator ->
                            Expect.within (Expect.Absolute 0.01) 2.5 excavator.bucketCapacity

                        Nothing ->
                            Expect.fail "Expected at least one excavator in config defaults"
            , test "should_populate_default_truck_values_from_config" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        firstTruck =
                            List.head config.defaults.trucks
                    in
                    case firstTruck of
                        Just truck ->
                            Expect.equal truck.capacity 12.0

                        Nothing ->
                            Expect.fail "Expected at least one truck in config defaults"
            , test "should_populate_default_project_dimensions_on_init" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults
                    in
                    Expect.all
                        [ \fd -> Expect.equal fd.pondLength "40"
                        , \fd -> Expect.equal fd.pondWidth "25"
                        , \fd -> Expect.equal fd.pondDepth "5"
                        , \fd -> Expect.equal fd.workHoursPerDay "8"
                        ]
                        formData
            ]
        , describe "Default Value Calculations"
            [ test "should_calculate_excavator_rate_with_default_values" <|
                \_ ->
                    let
                        rate =
                            calculateExcavatorRate 2.5 2.0

                        -- (60/2) * 2.5 * 0.85 = 63.75
                        expected =
                            63.75
                    in
                    Expect.within (Expect.Absolute 0.01) expected rate
            , test "should_calculate_truck_rate_with_default_values" <|
                \_ ->
                    let
                        rate =
                            calculateTruckRate 12.0 15.0

                        -- (60/15) * 12 * 0.8 = 38.4
                        expected =
                            38.4
                    in
                    Expect.within (Expect.Absolute 0.01) expected rate
            , test "should_calculate_timeline_approximately_one_day_with_defaults" <|
                \_ ->
                    let
                        -- 40 * 25 * 5 = 5000 cubic feet / 27 = 185 cubic yards
                        pondVolume =
                            (40.0 * 25.0 * 5.0) / 27.0

                        result =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
                    in
                    case result of
                        Ok calculation ->
                            -- With 185 cy at 38.4 cy/hour = 4.8 hours = 1 day
                            Expect.equal calculation.timelineInDays 1

                        Err _ ->
                            Expect.fail "Calculation should succeed with default values"
            , test "should_identify_hauling_bottleneck_with_default_configuration" <|
                \_ ->
                    let
                        pondVolume =
                            (40.0 * 25.0 * 5.0) / 27.0

                        result =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
                    in
                    case result of
                        Ok calculation ->
                            case calculation.bottleneck of
                                Utils.Calculations.HaulingBottleneck ->
                                    Expect.pass

                                _ ->
                                    Expect.fail "Should identify hauling as bottleneck"

                        Err _ ->
                            Expect.fail "Calculation should succeed"
            ]
        , describe "Form Data String Conversion"
            [ test "should_convert_default_project_floats_to_strings_correctly" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults
                    in
                    Expect.all
                        [ \fd -> String.toFloat fd.pondLength |> Expect.equal (Just 40.0)
                        , \fd -> String.toFloat fd.pondWidth |> Expect.equal (Just 25.0)
                        , \fd -> String.toFloat fd.pondDepth |> Expect.equal (Just 5.0)
                        , \fd -> String.toFloat fd.workHoursPerDay |> Expect.equal (Just 8.0)
                        ]
                        formData
            , test "should_maintain_precision_in_project_string_conversion" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults

                        -- Parse back to float and ensure no precision loss
                        pondLength =
                            String.toFloat formData.pondLength
                    in
                    case pondLength of
                        Just value ->
                            Expect.within (Expect.Absolute 0.001) 40.0 value

                        Nothing ->
                            Expect.fail "Should parse pond length back to float"
            ]
        , describe "Validation Rules with Defaults"
            [ test "should_have_default_values_within_validation_ranges" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        defaults =
                            config.defaults

                        validation =
                            config.validation
                    in
                    Expect.all
                        [ \_ ->
                            Expect.all
                                [ \v -> Expect.atLeast validation.excavatorCapacity.min (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                                , \v -> Expect.atMost validation.excavatorCapacity.max (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                                ]
                                (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 2.5)
                        , \_ ->
                            Expect.all
                                [ \v -> Expect.atLeast validation.cycleTime.min (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                                , \v -> Expect.atMost validation.cycleTime.max (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                                ]
                                (List.head defaults.excavators |> Maybe.map .cycleTime |> Maybe.withDefault 2.0)
                        , \_ ->
                            Expect.all
                                [ \v -> Expect.atLeast validation.truckCapacity.min (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                                , \v -> Expect.atMost validation.truckCapacity.max (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                                ]
                                (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 12.0)
                        ]
                        ()
            , test "should_have_meaningful_equipment_names_in_defaults" <|
                \_ ->
                    let
                        defaults =
                            fallbackConfig.defaults
                    in
                    Expect.all
                        [ \d -> Expect.equal (List.head d.excavators |> Maybe.map .name |> Maybe.withDefault "") "CAT 320 Excavator"
                        , \d -> Expect.equal (List.head d.trucks |> Maybe.map .name |> Maybe.withDefault "") "Standard Dump Truck"
                        ]
                        defaults
            ]
        , describe "Performance Requirements"
            [ test "should_initialize_form_data_without_delay" <|
                \_ ->
                    -- This test verifies that form initialization is synchronous
                    let
                        formData =
                            initFormData fallbackConfig.defaults

                        hasAllValues =
                            formData.pondLength
                                /= ""
                                && formData.pondWidth
                                /= ""
                                && formData.workHoursPerDay
                                /= ""
                    in
                    Expect.equal hasAllValues True
            , test "should_complete_calculation_with_default_values" <|
                \_ ->
                    let
                        pondVolume =
                            (40.0 * 25.0 * 5.0) / 27.0

                        result =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
                    in
                    case result of
                        Ok _ ->
                            Expect.pass

                        Err _ ->
                            Expect.fail "Calculation must succeed with defaults"
            ]
        , describe "Cross-Device Default Value Consistency"
            [ test "should_load_identical_equipment_config_across_devices" <|
                \_ ->
                    let
                        -- Equipment config is device-agnostic - same config for all devices
                        config =
                            fallbackConfig

                        firstExcavator =
                            List.head config.defaults.excavators

                        firstTruck =
                            List.head config.defaults.trucks
                    in
                    case ( firstExcavator, firstTruck ) of
                        ( Just excavator, Just truck ) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.01) 2.5 excavator.bucketCapacity
                                , \_ -> Expect.within (Expect.Absolute 0.01) 2.0 excavator.cycleTime
                                , \_ -> Expect.equal "CAT 320 Excavator" excavator.name
                                , \_ -> Expect.within (Expect.Absolute 0.01) 12.0 truck.capacity
                                , \_ -> Expect.within (Expect.Absolute 0.01) 15.0 truck.roundTripTime
                                , \_ -> Expect.equal "Standard Dump Truck" truck.name
                                ]
                                ()

                        _ ->
                            Expect.fail "Expected at least one excavator and truck in config"
            , test "should_load_identical_project_defaults_across_devices" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        mobileFormData =
                            initFormData config.defaults

                        tabletFormData =
                            initFormData config.defaults

                        desktopFormData =
                            initFormData config.defaults

                        -- Expected values from config
                        expectedWorkHours =
                            "8"

                        expectedPondLength =
                            "40"

                        expectedPondWidth =
                            "25"

                        expectedPondDepth =
                            "5"
                    in
                    Expect.all
                        [ \_ -> Expect.equal expectedWorkHours mobileFormData.workHoursPerDay
                        , \_ -> Expect.equal expectedWorkHours tabletFormData.workHoursPerDay
                        , \_ -> Expect.equal expectedWorkHours desktopFormData.workHoursPerDay
                        , \_ -> Expect.equal mobileFormData.workHoursPerDay tabletFormData.workHoursPerDay
                        , \_ -> Expect.equal tabletFormData.workHoursPerDay desktopFormData.workHoursPerDay
                        , \_ -> Expect.equal expectedPondLength mobileFormData.pondLength
                        , \_ -> Expect.equal expectedPondLength tabletFormData.pondLength
                        , \_ -> Expect.equal expectedPondLength desktopFormData.pondLength
                        , \_ -> Expect.equal expectedPondWidth mobileFormData.pondWidth
                        , \_ -> Expect.equal expectedPondWidth tabletFormData.pondWidth
                        , \_ -> Expect.equal expectedPondWidth desktopFormData.pondWidth
                        ]
                        ()
            , test "should_produce_identical_calculation_results_with_defaults_across_devices" <|
                \_ ->
                    let
                        -- Default pond volume calculation
                        pondVolume =
                            (40.0 * 25.0 * 5.0) / 27.0

                        -- Calculate timeline using default values (device-agnostic)
                        mobileResult =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0

                        tabletResult =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0

                        desktopResult =
                            calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
                    in
                    case ( mobileResult, tabletResult, desktopResult ) of
                        ( Ok mobile, Ok tablet, Ok desktop ) ->
                            Expect.all
                                [ \_ -> Expect.equal mobile.timelineInDays tablet.timelineInDays
                                , \_ -> Expect.equal tablet.timelineInDays desktop.timelineInDays
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobile.totalHours tablet.totalHours
                                , \_ -> Expect.within (Expect.Absolute 0.001) tablet.totalHours desktop.totalHours
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobile.excavationRate tablet.excavationRate
                                , \_ -> Expect.within (Expect.Absolute 0.001) tablet.excavationRate desktop.excavationRate
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobile.haulingRate tablet.haulingRate
                                , \_ -> Expect.within (Expect.Absolute 0.001) tablet.haulingRate desktop.haulingRate
                                , \_ -> Expect.equal mobile.bottleneck tablet.bottleneck
                                , \_ -> Expect.equal tablet.bottleneck desktop.bottleneck
                                ]
                                ()

                        _ ->
                            Expect.fail "Default value calculations should succeed identically across all devices"
            , test "should_maintain_validation_consistency_with_defaults_across_devices" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        -- Validation rules are identical across devices (same config)
                        validation =
                            config.validation

                        defaults =
                            config.defaults
                    in
                    Expect.all
                        [ \_ -> Expect.atLeast validation.excavatorCapacity.min (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0)
                        , \_ -> Expect.atMost validation.excavatorCapacity.max (List.head defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0)
                        , \_ -> Expect.atLeast validation.truckCapacity.min (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0)
                        , \_ -> Expect.atMost validation.truckCapacity.max (List.head defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0)
                        , \_ -> Expect.atLeast validation.pondDimensions.min 40.0
                        , \_ -> Expect.atMost validation.pondDimensions.max 40.0
                        ]
                        ()
            ]
        ]
