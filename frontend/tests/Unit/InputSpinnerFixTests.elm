module Unit.InputSpinnerFixTests exposing (suite)

{-| Unit tests for input field spinner fix
Ensures that input fields render correctly without spinner controls

@docs suite

-}

import Components.ProjectForm as ProjectForm
import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Types.DeviceType exposing (DeviceType(..))


suite : Test
suite =
    describe "Input Spinner Fix Tests"
        [ inputFieldRenderingTests
        , cssClassApplicationTests
        , deviceSpecificBehaviorTests
        , unitTextDisplayTests
        ]


{-| Test that input fields render with correct attributes
-}
inputFieldRenderingTests : Test
inputFieldRenderingTests =
    describe "Input Field Rendering"
        [ test "should_render_number_inputs_with_correct_type" <|
            \_ ->
                let
                    config =
                        { label = "Test Field"
                        , unit = "units"
                        , helpText = "Test help"
                        , id = "test-input"
                        , testId = "test-input"
                        , errorId = "test-input-error"
                        , value = "5.0"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input" ]
                    |> Query.has [ Selector.attribute (Attr.type_ "number") ]
        , test "should_render_input_with_proper_value_attribute" <|
            \_ ->
                let
                    config =
                        { label = "Capacity"
                        , unit = "cubic yards"
                        , helpText = "Test"
                        , id = "capacity-input"
                        , testId = "capacity-input"
                        , errorId = "capacity-input-error"
                        , value = "3.5"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input" ]
                    |> Query.has [ Selector.attribute (Attr.value "3.5") ]
        , test "should_render_input_with_correct_id" <|
            \_ ->
                let
                    config =
                        { label = "Test"
                        , unit = "feet"
                        , helpText = "Test"
                        , id = "pond-length"
                        , testId = "pond-length"
                        , errorId = "pond-length-error"
                        , value = "40"
                        , placeholder = "0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Tablet config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input" ]
                    |> Query.has [ Selector.id "pond-length" ]
        ]


{-| Test CSS class application for spinner hiding
-}
cssClassApplicationTests : Test
cssClassApplicationTests =
    describe "CSS Class Application"
        [ test "should_apply_relative_class_to_container_div" <|
            \_ ->
                let
                    config =
                        { label = "Test"
                        , unit = "units"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "1.0"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "input-with-unit" ]
                    |> Query.has [ Selector.tag "div" ]
        , test "should_apply_input_classes_for_device_type" <|
            \_ ->
                let
                    config =
                        { label = "Test"
                        , unit = "units"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "1.0"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    desktopRendered =
                        ProjectForm.inputFieldWithUnit Desktop config

                    mobileRendered =
                        ProjectForm.inputFieldWithUnit Mobile config
                in
                Expect.all
                    [ \_ ->
                        desktopRendered
                            |> Query.fromHtml
                            |> Query.find [ Selector.tag "input" ]
                            |> Query.has [ Selector.class "py-2" ]

                    -- Desktop padding
                    , \_ ->
                        mobileRendered
                            |> Query.fromHtml
                            |> Query.find [ Selector.tag "input" ]
                            |> Query.has [ Selector.class "py-3" ]

                    -- Mobile padding
                    ]
                    ()
        ]


{-| Test device-specific behavior
-}
deviceSpecificBehaviorTests : Test
deviceSpecificBehaviorTests =
    describe "Device-Specific Behavior"
        [ test "should_show_help_text_on_desktop_and_tablet" <|
            \_ ->
                let
                    config =
                        { label = "Test Field"
                        , unit = "units"
                        , helpText = "This is helpful text"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "1.0"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    desktopRendered =
                        ProjectForm.inputFieldWithUnit Desktop config

                    tabletRendered =
                        ProjectForm.inputFieldWithUnit Tablet config

                    mobileRendered =
                        ProjectForm.inputFieldWithUnit Mobile config
                in
                Expect.all
                    [ \_ ->
                        desktopRendered
                            |> Query.fromHtml
                            |> Query.contains [ Html.text "This is helpful text" ]
                    , \_ ->
                        tabletRendered
                            |> Query.fromHtml
                            |> Query.contains [ Html.text "This is helpful text" ]
                    , \_ ->
                        mobileRendered
                            |> Query.fromHtml
                            |> Query.hasNot [ Selector.text "This is helpful text" ]
                    ]
                    ()
        , test "should_apply_correct_label_classes_per_device" <|
            \_ ->
                let
                    config =
                        { label = "Test Label"
                        , unit = "units"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "1.0"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    desktopRendered =
                        ProjectForm.inputFieldWithUnit Desktop config

                    mobileRendered =
                        ProjectForm.inputFieldWithUnit Mobile config
                in
                Expect.all
                    [ \_ ->
                        desktopRendered
                            |> Query.fromHtml
                            |> Query.find [ Selector.tag "label" ]
                            |> Query.has [ Selector.class "font-semibold" ]

                    -- Desktop uses semibold
                    , \_ ->
                        mobileRendered
                            |> Query.fromHtml
                            |> Query.find [ Selector.tag "label" ]
                            |> Query.has [ Selector.class "font-medium" ]

                    -- Mobile uses medium
                    ]
                    ()
        ]


{-| Test unit text display
-}
unitTextDisplayTests : Test
unitTextDisplayTests =
    describe "Unit Text Display"
        [ test "should_display_unit_in_label" <|
            \_ ->
                let
                    config =
                        { label = "Pond Length"
                        , unit = "feet"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "40"
                        , placeholder = "0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "label" ]
                    |> Query.contains [ Html.text "(feet)" ]
        , test "should_display_unit_in_absolute_positioned_span" <|
            \_ ->
                let
                    config =
                        { label = "Capacity"
                        , unit = "cubic yards"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "2.5"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Nothing
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                rendered
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "unit-display" ]
                    |> Query.contains [ Html.text "cubic yards" ]
        , test "should_handle_different_unit_types" <|
            \_ ->
                let
                    unitTests =
                        [ ( "feet", "feet" )
                        , ( "cubic yards", "cubic yards" )
                        , ( "minutes", "minutes" )
                        , ( "hours", "hours" )
                        ]

                    testUnit ( unit, expectedText ) =
                        let
                            config =
                                { label = "Test"
                                , unit = unit
                                , helpText = "Test"
                                , id = "test"
                                , testId = "test"
                                , errorId = "test-error"
                                , value = "1.0"
                                , placeholder = "0.0"
                                , onInput = \_ -> ()
                                , error = Nothing
                                }

                            rendered =
                                ProjectForm.inputFieldWithUnit Desktop config
                        in
                        rendered
                            |> Query.fromHtml
                            |> Query.contains [ Html.text expectedText ]
                in
                Expect.all
                    (List.map (\unitData _ -> testUnit unitData) unitTests)
                    ()
        , test "should_maintain_unit_display_with_validation_errors" <|
            \_ ->
                let
                    config =
                        { label = "Test"
                        , unit = "units"
                        , helpText = "Test"
                        , id = "test"
                        , testId = "test"
                        , errorId = "test-error"
                        , value = "-1"
                        , placeholder = "0.0"
                        , onInput = \_ -> ()
                        , error = Just "Value must be positive"
                        }

                    rendered =
                        ProjectForm.inputFieldWithUnit Desktop config
                in
                Expect.all
                    [ \_ ->
                        rendered
                            |> Query.fromHtml
                            |> Query.contains [ Html.text "units" ]
                    , \_ ->
                        rendered
                            |> Query.fromHtml
                            |> Query.contains [ Html.text "Value must be positive" ]
                    ]
                    ()
        ]
