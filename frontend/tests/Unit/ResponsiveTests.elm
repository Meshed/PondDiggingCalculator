module Unit.ResponsiveTests exposing (suite)

{-| Test suite for responsive functionality

@docs suite

-}

import Expect
import Styles.Components as Components
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))


suite : Test
suite =
    describe "Responsive Tests"
        [ deviceDetectionTests
        , componentAdaptationTests
        , touchTargetTests
        , typographyScalingTests
        , layoutIntegrityTests
        ]


{-| Test device detection accuracy at breakpoint boundaries
-}
deviceDetectionTests : Test
deviceDetectionTests =
    describe "Device Detection"
        [ test "should_detect_mobile_device_below_768px" <|
            \_ ->
                let
                    windowSize =
                        { width = 600, height = 800 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Mobile
        , test "should_detect_mobile_device_at_320px_minimum" <|
            \_ ->
                let
                    windowSize =
                        { width = 320, height = 568 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Mobile
        , test "should_detect_tablet_device_at_768px_boundary" <|
            \_ ->
                let
                    windowSize =
                        { width = 768, height = 1024 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Tablet
        , test "should_detect_tablet_device_at_1024px_boundary" <|
            \_ ->
                let
                    windowSize =
                        { width = 1024, height = 768 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Tablet
        , test "should_detect_desktop_device_above_1024px" <|
            \_ ->
                let
                    windowSize =
                        { width = 1200, height = 900 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Desktop
        , test "should_detect_desktop_device_at_1920px_wide" <|
            \_ ->
                let
                    windowSize =
                        { width = 1920, height = 1080 }

                    deviceType =
                        Types.DeviceType.fromWindowSize windowSize
                in
                Expect.equal deviceType Desktop
        ]


{-| Test component layout adaptation for each device type
-}
componentAdaptationTests : Test
componentAdaptationTests =
    describe "Component Adaptation"
        [ test "should_provide_mobile_optimized_form_classes" <|
            \_ ->
                let
                    mobileClasses =
                        Components.getFormClasses Mobile
                in
                Expect.all
                    [ \classes -> String.contains "p-4" classes |> Expect.equal True
                    , \classes -> String.contains "space-y-4" classes |> Expect.equal True
                    ]
                    mobileClasses
        , test "should_provide_tablet_optimized_form_classes" <|
            \_ ->
                let
                    tabletClasses =
                        Components.getFormClasses Tablet
                in
                Expect.all
                    [ \classes -> String.contains "p-6" classes |> Expect.equal True
                    , \classes -> String.contains "space-y-6" classes |> Expect.equal True
                    ]
                    tabletClasses
        , test "should_provide_desktop_optimized_form_classes" <|
            \_ ->
                let
                    desktopClasses =
                        Components.getFormClasses Desktop
                in
                Expect.all
                    [ \classes -> String.contains "p-8" classes |> Expect.equal True
                    , \classes -> String.contains "space-y-6" classes |> Expect.equal True
                    ]
                    desktopClasses
        , test "should_provide_different_grid_layouts_per_device" <|
            \_ ->
                let
                    mobileGrid =
                        Responsive.getGridClasses Mobile

                    tabletGrid =
                        Responsive.getGridClasses Tablet

                    desktopGrid =
                        Responsive.getGridClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "grid-cols-1" mobileGrid |> Expect.equal True
                    , \_ -> String.contains "grid-cols-2" tabletGrid |> Expect.equal True
                    , \_ -> String.contains "grid-cols-3" desktopGrid |> Expect.equal True
                    ]
                    ()
        ]


{-| Test touch target minimum size requirements (44px × 44px)
-}
touchTargetTests : Test
touchTargetTests =
    describe "Touch Target Requirements"
        [ test "should_provide_44px_minimum_touch_targets_on_mobile" <|
            \_ ->
                let
                    mobileButtonClasses =
                        Theme.getButtonClasses Mobile
                in
                String.contains "min-h-11" mobileButtonClasses |> Expect.equal True
        , test "should_provide_44px_minimum_input_targets_on_mobile" <|
            \_ ->
                let
                    mobileInputClasses =
                        Theme.getInputClasses Mobile
                in
                String.contains "min-h-11" mobileInputClasses |> Expect.equal True
        , test "should_provide_larger_touch_targets_on_mobile_than_desktop" <|
            \_ ->
                let
                    mobileButtonClasses =
                        Theme.getButtonClasses Mobile

                    desktopButtonClasses =
                        Theme.getButtonClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "py-3" mobileButtonClasses |> Expect.equal True
                    , \_ -> String.contains "py-2" desktopButtonClasses |> Expect.equal True
                    , \_ -> String.contains "text-lg" mobileButtonClasses |> Expect.equal True
                    , \_ -> String.contains "text-sm" desktopButtonClasses |> Expect.equal True
                    ]
                    ()
        , test "should_maintain_touch_targets_on_tablet" <|
            \_ ->
                let
                    tabletButtonClasses =
                        Theme.getButtonClasses Tablet

                    tabletInputClasses =
                        Theme.getInputClasses Tablet
                in
                Expect.all
                    [ \_ -> String.contains "min-h-11" tabletButtonClasses |> Expect.equal True
                    , \_ -> String.contains "min-h-11" tabletInputClasses |> Expect.equal True
                    ]
                    ()
        ]


{-| Test typography and spacing scaling across device sizes
-}
typographyScalingTests : Test
typographyScalingTests =
    describe "Typography and Spacing Scaling"
        [ test "should_scale_heading_typography_appropriately" <|
            \_ ->
                let
                    mobileTypography =
                        Theme.getTypographyScale Mobile

                    tabletTypography =
                        Theme.getTypographyScale Tablet

                    desktopTypography =
                        Theme.getTypographyScale Desktop
                in
                Expect.all
                    [ \_ -> String.contains "text-2xl" mobileTypography.heading |> Expect.equal True
                    , \_ -> String.contains "text-3xl" tabletTypography.heading |> Expect.equal True
                    , \_ -> String.contains "text-4xl" desktopTypography.heading |> Expect.equal True
                    ]
                    ()
        , test "should_provide_appropriate_spacing_for_each_device" <|
            \_ ->
                let
                    mobileSpacing =
                        Responsive.getSpacingClasses Mobile

                    tabletSpacing =
                        Responsive.getSpacingClasses Tablet

                    desktopSpacing =
                        Responsive.getSpacingClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "space-y-4" mobileSpacing.section |> Expect.equal True
                    , \_ -> String.contains "space-y-6" tabletSpacing.section |> Expect.equal True
                    , \_ -> String.contains "space-y-8" desktopSpacing.section |> Expect.equal True
                    ]
                    ()
        , test "should_scale_validation_message_display" <|
            \_ ->
                let
                    mobileValidation =
                        Components.getValidationMessageClasses Mobile

                    desktopValidation =
                        Components.getValidationMessageClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "bg-red-50" mobileValidation |> Expect.equal True
                    , \_ -> String.contains "bg-red-50" desktopValidation |> Expect.equal False
                    , \_ -> String.contains "text-sm" mobileValidation |> Expect.equal True
                    , \_ -> String.contains "text-xs" desktopValidation |> Expect.equal True
                    ]
                    ()
        ]


{-| Test layout integrity across all defined breakpoints
-}
layoutIntegrityTests : Test
layoutIntegrityTests =
    describe "Layout Integrity"
        [ test "should_provide_consistent_container_classes" <|
            \_ ->
                let
                    mobileContainer =
                        Responsive.getContainerClasses Mobile

                    tabletContainer =
                        Responsive.getContainerClasses Tablet

                    desktopContainer =
                        Responsive.getContainerClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "mx-auto" mobileContainer |> Expect.equal True
                    , \_ -> String.contains "mx-auto" tabletContainer |> Expect.equal True
                    , \_ -> String.contains "mx-auto" desktopContainer |> Expect.equal True
                    , \_ -> String.contains "px-2" mobileContainer |> Expect.equal True
                    , \_ -> String.contains "max-w-6xl" desktopContainer |> Expect.equal True
                    ]
                    ()
        , test "should_provide_appropriate_equipment_card_layout" <|
            \_ ->
                let
                    mobileCard =
                        Components.getEquipmentCardClasses Mobile

                    desktopCard =
                        Components.getEquipmentCardClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "flex-col" mobileCard |> Expect.equal True
                    , \_ -> String.contains "flex-row" desktopCard |> Expect.equal True
                    , \_ -> String.contains "bg-white" mobileCard |> Expect.equal True
                    , \_ -> String.contains "bg-white" desktopCard |> Expect.equal True
                    ]
                    ()
        , test "should_maintain_results_panel_consistency" <|
            \_ ->
                let
                    mobileResults =
                        Components.getResultsPanelClasses Mobile

                    tabletResults =
                        Components.getResultsPanelClasses Tablet

                    desktopResults =
                        Components.getResultsPanelClasses Desktop
                in
                Expect.all
                    [ \_ -> String.contains "bg-blue-50" mobileResults |> Expect.equal True
                    , \_ -> String.contains "bg-blue-50" tabletResults |> Expect.equal True
                    , \_ -> String.contains "bg-blue-50" desktopResults |> Expect.equal True
                    , \_ -> String.contains "p-4" mobileResults |> Expect.equal True
                    , \_ -> String.contains "p-8" desktopResults |> Expect.equal True
                    ]
                    ()
        ]
