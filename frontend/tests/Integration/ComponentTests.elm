module Integration.ComponentTests exposing (suite)

{-| Integration tests for component interactions

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config exposing (fallbackConfig)
import Components.ProjectForm as ProjectForm
import Components.EquipmentCard as EquipmentCard
import Components.ResultsPanel as ResultsPanel
import Utils.Calculations exposing (calculateTimeline, CalculationResult, Bottleneck(..), ConfidenceLevel(..))
import Utils.Validation as Validation
import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (Equipment, EquipmentType(..))
import Test.Html.Query as Query
import Test.Html.Selector as Selector exposing (..)
import Html


suite : Test
suite =
    describe "Component Integration Tests"
        [ describe "Rich Interface Component Interactions"
            [ test "should_display_enhanced_input_fields_with_units_and_help_text" <|
                \_ ->
                    let
                        formData = ProjectForm.initFormData fallbackConfig.defaults
                        
                        -- Test that enhanced input field renders with units
                        inputFieldHtml = ProjectForm.inputFieldWithUnit Desktop
                            { label = "Test Field"
                            , unit = "cubic yards"
                            , helpText = "Test help text"
                            , id = "test-field"
                            , value = "10.0"
                            , placeholder = "Enter value"
                            , onInput = \_ -> ()
                            , error = Nothing
                            }
                        
                        queryResult = Query.fromHtml inputFieldHtml
                    in
                    queryResult
                        |> Query.has [ Selector.text "cubic yards" ]
            
            , test "should_render_equipment_cards_with_visual_icons" <|
                \_ ->
                    let
                        testEquipment = createTestExcavator
                        config =
                            { equipment = testEquipment
                            , isActive = True
                            , showAdvanced = True
                            , fleetCount = 2
                            }
                        
                        cardHtml = EquipmentCard.view Desktop config (\_ -> ())
                        queryResult = Query.fromHtml cardHtml
                    in
                    queryResult
                        |> Query.findAll [ Selector.tag "svg" ]
                        |> Query.count (Expect.atLeast 1)
            
            , test "should_display_fleet_count_badges_correctly" <|
                \_ ->
                    let
                        testEquipment = createTestExcavator
                        config =
                            { equipment = testEquipment
                            , isActive = True
                            , showAdvanced = True
                            , fleetCount = 5
                            }
                        
                        cardHtml = EquipmentCard.view Desktop config (\_ -> ())
                        queryResult = Query.fromHtml cardHtml
                    in
                    queryResult
                        |> Query.has [ Selector.text "Fleet: 5" ]
            
            , test "should_show_productivity_indicators_for_active_excavators" <|
                \_ ->
                    let
                        testEquipment = createTestExcavator
                        config =
                            { equipment = testEquipment
                            , isActive = True
                            , showAdvanced = True
                            , fleetCount = 1
                            }
                        
                        cardHtml = EquipmentCard.view Desktop config (\_ -> ())
                        queryResult = Query.fromHtml cardHtml
                    in
                    queryResult
                        |> Query.has [ Selector.text "Productivity" ]
            
            , test "should_display_enhanced_results_with_additional_metrics" <|
                \_ ->
                    let
                        testResult = createTestCalculationResult
                        resultsHtml = ResultsPanel.view Desktop testResult False
                        queryResult = Query.fromHtml resultsHtml
                    in
                    queryResult
                        |> Query.has [ Selector.text "Total Dirt Moved" ]
            
            , test "should_show_visual_efficiency_bars_for_desktop" <|
                \_ ->
                    let
                        testResult = createTestCalculationResult
                        resultsHtml = ResultsPanel.view Desktop testResult False
                        queryResult = Query.fromHtml resultsHtml
                    in
                    queryResult
                        |> Query.has [ Selector.text "Equipment Balance" ]
            
            , test "should_adapt_layout_for_different_device_types" <|
                \_ ->
                    let
                        testResult = createTestCalculationResult
                        
                        desktopHtml = ResultsPanel.view Desktop testResult False
                        tabletHtml = ResultsPanel.view Tablet testResult False
                        mobileHtml = ResultsPanel.view Mobile testResult False
                        
                        desktopQuery = Query.fromHtml desktopHtml
                        tabletQuery = Query.fromHtml tabletHtml
                        mobileQuery = Query.fromHtml mobileHtml
                    in
                    Expect.all
                        [ \_ -> desktopQuery |> Query.has [ Selector.class "text-7xl" ]
                        , \_ -> tabletQuery |> Query.has [ Selector.class "text-6xl" ]
                        , \_ -> mobileQuery |> Query.has [ Selector.class "text-5xl" ]
                        ] ()
            ]
        
        , describe "Form Initialization with Defaults"
            [ test "should_initialize_form_with_all_default_values_populated" <|
                \_ ->
                    let
                        formData = ProjectForm.initFormData fallbackConfig.defaults
                        allFieldsPopulated =
                            formData.excavatorCapacity /= "" &&
                            formData.excavatorCycleTime /= "" &&
                            formData.truckCapacity /= "" &&
                            formData.truckRoundTripTime /= "" &&
                            formData.workHoursPerDay /= "" &&
                            formData.pondLength /= "" &&
                            formData.pondWidth /= "" &&
                            formData.pondDepth /= ""
                    in
                    Expect.equal allFieldsPopulated True
            
            , test "should_allow_modification_of_default_values" <|
                \_ ->
                    let
                        initialForm = ProjectForm.initFormData fallbackConfig.defaults
                        updatedForm = ProjectForm.updateFormData 
                            (ProjectForm.UpdateExcavatorCapacity "3.0") 
                            initialForm
                    in
                    Expect.equal updatedForm.excavatorCapacity "3.0"
            
            , test "should_maintain_other_values_when_one_field_changes" <|
                \_ ->
                    let
                        initialForm = ProjectForm.initFormData fallbackConfig.defaults
                        updatedForm = ProjectForm.updateFormData 
                            (ProjectForm.UpdatePondLength "60.0") 
                            initialForm
                    in
                    Expect.all
                        [ \f -> Expect.equal f.pondLength "60.0"
                        , \f -> Expect.equal f.pondWidth "25"  -- Should remain unchanged
                        , \f -> Expect.equal f.excavatorCapacity "2.5"  -- Should remain unchanged
                        ]
                        updatedForm
            ]
        
        , describe "Default Values Flow Through Calculation"
            [ test "should_produce_valid_calculation_with_form_defaults" <|
                \_ ->
                    let
                        formData = ProjectForm.initFormData fallbackConfig.defaults
                        
                        -- Parse form strings to floats
                        maybeExc = 
                            ( String.toFloat formData.excavatorCapacity
                            , String.toFloat formData.excavatorCycleTime
                            )
                        maybeTruck = 
                            ( String.toFloat formData.truckCapacity
                            , String.toFloat formData.truckRoundTripTime
                            )
                        maybePond = 
                            ( String.toFloat formData.pondLength
                            , String.toFloat formData.pondWidth
                            , String.toFloat formData.pondDepth
                            )
                        maybeWork = String.toFloat formData.workHoursPerDay
                    in
                    case maybeExc of
                        (Just excCap, Just excCycle) ->
                            case maybeTruck of
                                (Just truckCap, Just truckRound) ->
                                    case maybePond of
                                        (Just length, Just width, Just depth) ->
                                            case maybeWork of
                                                Just workHours ->
                                                    let
                                                        pondVolume = (length * width * depth) / 27.0
                                                        result = calculateTimeline excCap excCycle truckCap truckRound pondVolume workHours
                                                    in
                                                    case result of
                                                        Ok calculation ->
                                                            Expect.equal calculation.timelineInDays 1
                                                        
                                                        Err _ ->
                                                            Expect.fail "Calculation should succeed"
                                                
                                                Nothing ->
                                                    Expect.fail "Could not parse work hours"
                                        
                                        _ ->
                                            Expect.fail "Could not parse pond dimensions"
                                
                                _ ->
                                    Expect.fail "Could not parse truck values"
                        
                        _ ->
                            Expect.fail "Could not parse excavator values"
            
            , test "should_validate_default_values_successfully" <|
                \_ ->
                    let
                        inputs =
                            { excavatorCapacity = 2.5
                            , excavatorCycleTime = 2.0
                            , truckCapacity = 12.0
                            , truckRoundTripTime = 15.0
                            , workHoursPerDay = 8.0
                            , pondLength = 40.0
                            , pondWidth = 25.0
                            , pondDepth = 5.0
                            }
                        
                        validationResult = Validation.validateAllInputs fallbackConfig.validation inputs
                    in
                    case validationResult of
                        Ok _ ->
                            Expect.pass
                        
                        Err _ ->
                            Expect.fail "Default values should pass validation"
            ]
        
        , describe "Form Update Behavior"
            [ test "should_update_excavator_capacity_field" <|
                \_ ->
                    let
                        form = ProjectForm.initFormData fallbackConfig.defaults
                        updated = ProjectForm.updateFormData (ProjectForm.UpdateExcavatorCapacity "5.0") form
                    in
                    Expect.equal updated.excavatorCapacity "5.0"
            
            , test "should_update_cycle_time_field" <|
                \_ ->
                    let
                        form = ProjectForm.initFormData fallbackConfig.defaults
                        updated = ProjectForm.updateFormData (ProjectForm.UpdateExcavatorCycleTime "3.0") form
                    in
                    Expect.equal updated.excavatorCycleTime "3.0"
            
            , test "should_update_truck_capacity_field" <|
                \_ ->
                    let
                        form = ProjectForm.initFormData fallbackConfig.defaults
                        updated = ProjectForm.updateFormData (ProjectForm.UpdateTruckCapacity "15.0") form
                    in
                    Expect.equal updated.truckCapacity "15.0"
            
            , test "should_update_work_hours_field" <|
                \_ ->
                    let
                        form = ProjectForm.initFormData fallbackConfig.defaults
                        updated = ProjectForm.updateFormData (ProjectForm.UpdateWorkHours "10.0") form
                    in
                    Expect.equal updated.workHoursPerDay "10.0"
            
            , test "should_update_pond_dimensions" <|
                \_ ->
                    let
                        form = ProjectForm.initFormData fallbackConfig.defaults
                        updated1 = ProjectForm.updateFormData (ProjectForm.UpdatePondLength "100.0") form
                        updated2 = ProjectForm.updateFormData (ProjectForm.UpdatePondWidth "50.0") updated1
                        updated3 = ProjectForm.updateFormData (ProjectForm.UpdatePondDepth "10.0") updated2
                    in
                    Expect.all
                        [ \f -> Expect.equal f.pondLength "100.0"
                        , \f -> Expect.equal f.pondWidth "50.0"
                        , \f -> Expect.equal f.pondDepth "10.0"
                        ]
                        updated3
            ]
        ]


-- Helper functions for rich interface tests
createTestExcavator : Equipment
createTestExcavator =
    { id = "excavator-1"
    , name = "CAT 320 Excavator"
    , equipmentType = Excavator
    , bucketCapacity = 2.5
    , cycleTime = 0.5
    , isActive = True
    }


createTestCalculationResult : CalculationResult
createTestCalculationResult =
    { timelineInDays = 3
    , totalHours = 24.0
    , excavationRate = 120.0
    , haulingRate = 100.0
    , bottleneck = HaulingBottleneck
    , confidence = Medium
    , assumptions = [ "Standard conditions" ]
    , warnings = [ "Consider equipment balance" ]
    }