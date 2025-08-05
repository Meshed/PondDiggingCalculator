module Unit.DefaultValueTests exposing (suite)

{-| Unit tests for default value loading and behavior

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config exposing (Config, fallbackConfig)
import Components.ProjectForm exposing (initFormData)
import Utils.Calculations exposing (calculateTimeline, calculateExcavatorRate, calculateTruckRate)


suite : Test
suite =
    describe "Default Value Behavior"
        [ describe "Configuration Loading"
            [ test "should_have_fallback_configuration_available_immediately" <|
                \_ ->
                    let
                        config = fallbackConfig
                    in
                    Expect.equal config.version "1.0.0"
            
            , test "should_populate_default_excavator_values_on_init" <|
                \_ ->
                    let
                        formData = initFormData fallbackConfig.defaults
                    in
                    formData.excavatorCapacity
                        |> Expect.equal "2.5"
            
            , test "should_populate_default_truck_values_on_init" <|
                \_ ->
                    let
                        formData = initFormData fallbackConfig.defaults
                    in
                    formData.truckCapacity
                        |> Expect.equal "12"
            
            , test "should_populate_default_project_dimensions_on_init" <|
                \_ ->
                    let
                        formData = initFormData fallbackConfig.defaults
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
                        rate = calculateExcavatorRate 2.5 2.0
                        -- (60/2) * 2.5 * 0.85 = 63.75
                        expected = 63.75
                    in
                    Expect.within (Expect.Absolute 0.01) expected rate
            
            , test "should_calculate_truck_rate_with_default_values" <|
                \_ ->
                    let
                        rate = calculateTruckRate 12.0 15.0
                        -- (60/15) * 12 * 0.8 = 38.4
                        expected = 38.4
                    in
                    Expect.within (Expect.Absolute 0.01) expected rate
            
            , test "should_calculate_timeline_approximately_one_day_with_defaults" <|
                \_ ->
                    let
                        -- 40 * 25 * 5 = 5000 cubic feet / 27 = 185 cubic yards
                        pondVolume = (40.0 * 25.0 * 5.0) / 27.0
                        
                        result = calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
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
                        pondVolume = (40.0 * 25.0 * 5.0) / 27.0
                        result = calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
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
                        formData = initFormData fallbackConfig.defaults
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
                        formData = initFormData fallbackConfig.defaults
                        -- Parse back to float and ensure no precision loss
                        excavatorCapacity = String.toFloat formData.excavatorCapacity
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
                        config = fallbackConfig
                        defaults = config.defaults
                        validation = config.validation
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
                        defaults = fallbackConfig.defaults
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
                        formData = initFormData fallbackConfig.defaults
                        hasAllValues = 
                            formData.excavatorCapacity /= "" &&
                            formData.truckCapacity /= "" &&
                            formData.pondLength /= ""
                    in
                    Expect.equal hasAllValues True
            
            , test "should_complete_calculation_with_default_values" <|
                \_ ->
                    let
                        pondVolume = (40.0 * 25.0 * 5.0) / 27.0
                        result = calculateTimeline 2.5 2.0 12.0 15.0 pondVolume 8.0
                    in
                    case result of
                        Ok _ ->
                            Expect.pass
                        
                        Err _ ->
                            Expect.fail "Calculation must succeed with defaults"
            ]
        ]