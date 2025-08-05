module Integration.ComponentTests exposing (suite)

{-| Integration tests for component interactions

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Utils.Config exposing (fallbackConfig)
import Components.ProjectForm as ProjectForm
import Utils.Calculations exposing (calculateTimeline)
import Utils.Validation as Validation


suite : Test
suite =
    describe "Component Integration Tests"
        [ describe "Form Initialization with Defaults"
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