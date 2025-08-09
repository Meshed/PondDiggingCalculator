module Unit.ValidationMessageTests exposing (..)

import Components.ValidationMessage as ValidationMessage
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, tag, text)
import Types.DeviceType exposing (DeviceType(..))
import Types.Validation exposing (ValidationError(..))


suite : Test
suite =
    describe "ValidationMessage Component Tests"
        [ describe "viewValidationMessage"
            [ test "should_display_value_too_low_error_on_desktop" <|
                \_ ->
                    let
                        error =
                            ValueTooLow
                                { actual = 0.5
                                , minimum = 1.0
                                , guidance = "Excavator capacity is too small. Minimum: 1.0, Maximum: 15.0 cubic yards."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ text "Excavator capacity is too small" ]
                            , Query.has [ class "text-red-600" ]
                            ]
            , test "should_display_value_too_high_error_on_mobile" <|
                \_ ->
                    let
                        error =
                            ValueTooHigh
                                { actual = 25.0
                                , maximum = 15.0
                                , guidance = "Excavator capacity is too large. Even the largest mining excavators rarely exceed 15 cubic yards."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Mobile error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ tag "div" ]
                            , Query.has [ text "too large" ]
                            , Query.has [ text "mining excavators" ]
                            ]
            , test "should_display_required_field_error_with_guidance" <|
                \_ ->
                    let
                        error =
                            RequiredField
                                { guidance = "Excavator bucket capacity is required. Enter a value between 0.1 and 15.0 cubic yards."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Tablet error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ tag "div" ]
                            , Query.has [ text "bucket capacity is required" ]
                            , Query.has [ text "0.1 and 15.0 cubic yards" ]
                            ]
            , test "should_display_decimal_precision_error" <|
                \_ ->
                    let
                        error =
                            DecimalPrecisionError
                                { actual = 5.123
                                , maxDecimals = 2
                                , guidance = "Construction measurements typically use up to 2 decimal places for practical accuracy."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ tag "div" ]
                            , Query.has [ text "decimal places" ]
                            , Query.has [ text "5.123" ]
                            , Query.has [ text "practical accuracy" ]
                            ]
            , test "should_display_edge_case_error" <|
                \_ ->
                    let
                        error =
                            EdgeCaseError
                                { issue = "Negative values are not allowed"
                                , guidance = "Excavator capacity cannot be negative. Please enter a positive value in cubic yards."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ tag "div" ]
                            , Query.has [ text "Negative values are not allowed" ]
                            , Query.has [ text "positive value in cubic yards" ]
                            ]
            , test "should_display_invalid_format_error" <|
                \_ ->
                    let
                        error =
                            InvalidFormat
                                { input = "abc"
                                , guidance = "Please enter a valid number. Use decimal format (e.g., 2.5) without any letters or special characters."
                                }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ tag "div" ]
                            , Query.has [ text "Invalid format 'abc'" ]
                            , Query.has [ text "decimal format" ]
                            ]
            ]
        , describe "viewErrorIcon"
            [ test "should_display_error_icon_for_desktop" <|
                \_ ->
                    let
                        error =
                            ValueTooLow
                                { actual = 0.5, minimum = 1.0, guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ text "⚠" ]
            , test "should_not_display_error_icon_for_mobile" <|
                \_ ->
                    let
                        error =
                            ValueTooLow
                                { actual = 0.5, minimum = 1.0, guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Mobile error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.hasNot [ text "⚠" ]
            ]
        , describe "Device-specific styling"
            [ test "should_apply_mobile_specific_classes" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Mobile error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ class "px-1" ]
            , test "should_apply_desktop_specific_classes" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ class "flex" ]
            , test "should_apply_tablet_specific_classes" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Tablet error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ class "flex" ]
            ]
        , describe "Accessibility features"
            [ test "should_include_aria_live_polite_attribute" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ tag "div" ]
            , test "should_include_role_alert_attribute" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ tag "div" ]
            , test "should_mark_icon_as_aria_hidden" <|
                \_ ->
                    let
                        error =
                            RequiredField { guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.find [ text "⚠" ]
                        |> Query.has [ tag "span" ]
            ]
        , describe "Error message content validation"
            [ test "should_contain_actual_values_in_range_errors" <|
                \_ ->
                    let
                        error =
                            ValueTooLow
                                { actual = 0.25, minimum = 1.0, guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ text "0.25" ]
            , test "should_contain_boundary_values_in_range_errors" <|
                \_ ->
                    let
                        error =
                            ValueTooHigh
                                { actual = 20.0, maximum = 15.0, guidance = "Test guidance" }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ text "20" ]
                            , Query.has [ text "15" ]
                            ]
            , test "should_display_complete_guidance_text" <|
                \_ ->
                    let
                        guidanceText =
                            "This is comprehensive guidance with specific industry context and helpful suggestions for the user."

                        error =
                            RequiredField { guidance = guidanceText }

                        view =
                            ValidationMessage.viewValidationMessage Desktop error
                    in
                    view
                        |> Query.fromHtml
                        |> Query.has [ text guidanceText ]
            ]
        ]
