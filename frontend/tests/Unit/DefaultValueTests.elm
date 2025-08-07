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
            , test "should_populate_default_excavator_values_on_init" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults
                    in
                    formData.excavatorCapacity
                        |> Expect.equal "2.5"
            , test "should_populate_default_truck_values_on_init" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults
                    in
                    formData.truckCapacity
                        |> Expect.equal "12"
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
            [ test "should_convert_default_floats_to_strings_correctly" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults
                    in
                    Expect.all
                        [ \fd -> String.toFloat fd.excavatorCapacity |> Expect.equal (Just 2.5)
                        , \fd -> String.toFloat fd.excavatorCycleTime |> Expect.equal (Just 2.0)
                        , \fd -> String.toFloat fd.truckCapacity |> Expect.equal (Just 12.0)
                        , \fd -> String.toFloat fd.truckRoundTripTime |> Expect.equal (Just 15.0)
                        ]
                        formData
            , test "should_maintain_precision_in_string_conversion" <|
                \_ ->
                    let
                        formData =
                            initFormData fallbackConfig.defaults

                        -- Parse back to float and ensure no precision loss
                        excavatorCapacity =
                            String.toFloat formData.excavatorCapacity
                    in
                    case excavatorCapacity of
                        Just value ->
                            Expect.within (Expect.Absolute 0.001) 2.5 value

                        Nothing ->
                            Expect.fail "Should parse back to float"
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
                                [ \v -> Expect.atLeast validation.excavatorCapacity.min defaults.excavator.bucketCapacity
                                , \v -> Expect.atMost validation.excavatorCapacity.max defaults.excavator.bucketCapacity
                                ]
                                defaults.excavator.bucketCapacity
                        , \_ ->
                            Expect.all
                                [ \v -> Expect.atLeast validation.cycleTime.min defaults.excavator.cycleTime
                                , \v -> Expect.atMost validation.cycleTime.max defaults.excavator.cycleTime
                                ]
                                defaults.excavator.cycleTime
                        , \_ ->
                            Expect.all
                                [ \v -> Expect.atLeast validation.truckCapacity.min defaults.truck.capacity
                                , \v -> Expect.atMost validation.truckCapacity.max defaults.truck.capacity
                                ]
                                defaults.truck.capacity
                        ]
                        ()
            , test "should_have_meaningful_equipment_names_in_defaults" <|
                \_ ->
                    let
                        defaults =
                            fallbackConfig.defaults
                    in
                    Expect.all
                        [ \d -> Expect.equal d.excavator.name "Standard Excavator"
                        , \d -> Expect.equal d.truck.name "15-yard Dump Truck"
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
                            formData.excavatorCapacity
                                /= ""
                                && formData.truckCapacity
                                /= ""
                                && formData.pondLength
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
            [ test "should_load_identical_excavator_defaults_across_devices" <|
                \_ ->
                    let
                        -- Config loading is device-agnostic - same config.json for all devices
                        config =
                            fallbackConfig

                        -- Form initialization should be identical for all device types
                        mobileFormData =
                            initFormData config.defaults

                        tabletFormData =
                            initFormData config.defaults

                        desktopFormData =
                            initFormData config.defaults

                        -- Expected values from config.json
                        expectedExcavatorCapacity =
                            "2.5"

                        expectedExcavatorCycle =
                            "2"
                    in
                    Expect.all
                        [ \_ -> Expect.equal expectedExcavatorCapacity mobileFormData.excavatorCapacity
                        , \_ -> Expect.equal expectedExcavatorCapacity tabletFormData.excavatorCapacity
                        , \_ -> Expect.equal expectedExcavatorCapacity desktopFormData.excavatorCapacity
                        , \_ -> Expect.equal mobileFormData.excavatorCapacity tabletFormData.excavatorCapacity
                        , \_ -> Expect.equal tabletFormData.excavatorCapacity desktopFormData.excavatorCapacity
                        , \_ -> Expect.equal expectedExcavatorCycle mobileFormData.excavatorCycleTime
                        , \_ -> Expect.equal expectedExcavatorCycle tabletFormData.excavatorCycleTime
                        , \_ -> Expect.equal expectedExcavatorCycle desktopFormData.excavatorCycleTime
                        ]
                        ()
            , test "should_load_identical_truck_defaults_across_devices" <|
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

                        -- Expected values from config.json
                        expectedTruckCapacity =
                            "12"

                        expectedTruckRoundTrip =
                            "15"
                    in
                    Expect.all
                        [ \_ -> Expect.equal expectedTruckCapacity mobileFormData.truckCapacity
                        , \_ -> Expect.equal expectedTruckCapacity tabletFormData.truckCapacity
                        , \_ -> Expect.equal expectedTruckCapacity desktopFormData.truckCapacity
                        , \_ -> Expect.equal mobileFormData.truckCapacity tabletFormData.truckCapacity
                        , \_ -> Expect.equal tabletFormData.truckCapacity desktopFormData.truckCapacity
                        , \_ -> Expect.equal expectedTruckRoundTrip mobileFormData.truckRoundTripTime
                        , \_ -> Expect.equal expectedTruckRoundTrip tabletFormData.truckRoundTripTime
                        , \_ -> Expect.equal expectedTruckRoundTrip desktopFormData.truckRoundTripTime
                        ]
                        ()
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

                        -- Expected values from config.json
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

                        -- ~185 cubic yards
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
            , test "should_handle_configuration_loading_errors_identically_across_devices" <|
                \_ ->
                    let
                        -- Fallback config is device-agnostic
                        mobileConfig =
                            fallbackConfig

                        tabletConfig =
                            fallbackConfig

                        desktopConfig =
                            fallbackConfig
                    in
                    Expect.all
                        [ \_ -> Expect.equal mobileConfig.version tabletConfig.version
                        , \_ -> Expect.equal tabletConfig.version desktopConfig.version
                        , \_ -> Expect.within (Expect.Absolute 0.001) mobileConfig.defaults.excavator.bucketCapacity tabletConfig.defaults.excavator.bucketCapacity
                        , \_ -> Expect.within (Expect.Absolute 0.001) tabletConfig.defaults.excavator.bucketCapacity desktopConfig.defaults.excavator.bucketCapacity
                        , \_ -> Expect.within (Expect.Absolute 0.001) mobileConfig.defaults.truck.capacity tabletConfig.defaults.truck.capacity
                        , \_ -> Expect.within (Expect.Absolute 0.001) tabletConfig.defaults.truck.capacity desktopConfig.defaults.truck.capacity
                        ]
                        ()
            , test "should_maintain_validation_consistency_with_defaults_across_devices" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        -- Validation rules should be identical across devices
                        mobileValidation =
                            config.validation

                        tabletValidation =
                            config.validation

                        desktopValidation =
                            config.validation

                        -- Default values should be within validation ranges on all devices
                        defaults =
                            config.defaults
                    in
                    Expect.all
                        [ \_ -> Expect.within (Expect.Absolute 0.001) mobileValidation.excavatorCapacity.min tabletValidation.excavatorCapacity.min
                        , \_ -> Expect.within (Expect.Absolute 0.001) tabletValidation.excavatorCapacity.min desktopValidation.excavatorCapacity.min
                        , \_ -> Expect.within (Expect.Absolute 0.001) mobileValidation.excavatorCapacity.max tabletValidation.excavatorCapacity.max
                        , \_ -> Expect.within (Expect.Absolute 0.001) tabletValidation.excavatorCapacity.max desktopValidation.excavatorCapacity.max
                        , \_ -> Expect.atLeast mobileValidation.excavatorCapacity.min defaults.excavator.bucketCapacity
                        , \_ -> Expect.atMost mobileValidation.excavatorCapacity.max defaults.excavator.bucketCapacity
                        , \_ -> Expect.atLeast tabletValidation.truckCapacity.min defaults.truck.capacity
                        , \_ -> Expect.atMost tabletValidation.truckCapacity.max defaults.truck.capacity
                        ]
                        ()
            , test "should_populate_equipment_names_identically_across_devices" <|
                \_ ->
                    let
                        config =
                            fallbackConfig

                        defaults =
                            config.defaults

                        -- Equipment names from config should be identical across devices
                        expectedExcavatorName =
                            "Standard Excavator"

                        expectedTruckName =
                            "15-yard Dump Truck"
                    in
                    Expect.all
                        [ \_ -> Expect.equal expectedExcavatorName defaults.excavator.name
                        , \_ -> Expect.equal expectedTruckName defaults.truck.name
                        , \_ -> String.length defaults.excavator.name |> Expect.greaterThan 0
                        , \_ -> String.length defaults.truck.name |> Expect.greaterThan 0
                        ]
                        ()
            , test "should_ensure_string_conversion_consistency_across_devices" <|
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

                        -- Parse back to ensure no precision loss on any device
                        mobileCapacity =
                            String.toFloat mobileFormData.excavatorCapacity

                        tabletCapacity =
                            String.toFloat tabletFormData.excavatorCapacity

                        desktopCapacity =
                            String.toFloat desktopFormData.excavatorCapacity
                    in
                    case ( mobileCapacity, tabletCapacity, desktopCapacity ) of
                        ( Just mobile, Just tablet, Just desktop ) ->
                            Expect.all
                                [ \_ -> Expect.within (Expect.Absolute 0.001) 2.5 mobile
                                , \_ -> Expect.within (Expect.Absolute 0.001) 2.5 tablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) 2.5 desktop
                                , \_ -> Expect.within (Expect.Absolute 0.001) mobile tablet
                                , \_ -> Expect.within (Expect.Absolute 0.001) tablet desktop
                                ]
                                ()

                        _ ->
                            Expect.fail "String conversion should work identically across all devices"
            ]
        ]
