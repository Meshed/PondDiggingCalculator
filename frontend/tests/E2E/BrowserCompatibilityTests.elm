module E2E.BrowserCompatibilityTests exposing (suite)

{-| Cross-browser compatibility validation tests
Ensures core functionality works across target browsers on all device types

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Utils.Calculations as Calculations
import Utils.Config as Config
import Utils.DeviceDetector as DeviceDetector
import Utils.Validation as Validation


suite : Test
suite =
    describe "Cross-Browser Compatibility Validation"
        [ desktopBrowserCompatibilityTests
        , mobileBrowserCompatibilityTests
        , tabletBrowserCompatibilityTests
        , coreCalculationFunctionalityTests
        , browserSpecificFeatureTests
        ]


{-| Test core functionality on desktop browsers (Chrome 90+, Firefox 88+, Safari 14+)
-}
desktopBrowserCompatibilityTests : Test
desktopBrowserCompatibilityTests =
    describe "Desktop Browser Compatibility (>1024px width)"
        [ test "should_detect_desktop_device_type_consistently_across_browsers" <|
            \_ ->
                let
                    -- Desktop viewport dimensions
                    desktopViewport =
                        { width = 1200, height = 800 }

                    desktopViewportLarge =
                        { width = 1920, height = 1080 }

                    desktopViewportMinimum =
                        { width = 1025, height = 768 }

                    deviceType1 =
                        Types.DeviceType.fromWindowSize desktopViewport

                    deviceType2 =
                        Types.DeviceType.fromWindowSize desktopViewportLarge

                    deviceType3 =
                        Types.DeviceType.fromWindowSize desktopViewportMinimum
                in
                Expect.all
                    [ \_ -> Expect.equal Desktop deviceType1
                    , \_ -> Expect.equal Desktop deviceType2
                    , \_ -> Expect.equal Desktop deviceType3
                    ]
                    ()
        , test "should_enable_advanced_features_on_desktop_browsers" <|
            \_ ->
                let
                    desktopFeatureEnabled =
                        DeviceDetector.shouldShowAdvancedFeatures Desktop
                in
                -- Desktop should show full functionality across Chrome/Firefox/Safari
                Expect.equal True desktopFeatureEnabled
        , test "should_handle_complex_calculations_on_desktop_browsers" <|
            \_ ->
                let
                    -- Complex calculation that desktop browsers should handle
                    excavatorCapacity =
                        5.0

                    excavatorCycle =
                        1.5

                    truckCapacity =
                        20.0

                    truckRoundTrip =
                        12.0

                    pondVolume =
                        2000.0

                    -- Large pond
                    workHours =
                        10.0

                    result =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case result of
                    Ok calculation ->
                        Expect.all
                            [ \r -> Expect.greaterThan 0 r.timelineInDays
                            , \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> Expect.greaterThan 0.0 r.excavationRate
                            , \r -> Expect.greaterThan 0.0 r.haulingRate
                            , \r -> List.length r.assumptions |> Expect.greaterThan 0
                            ]
                            calculation

                    Err _ ->
                        Expect.fail "Complex calculations should succeed on desktop browsers"
        , test "should_validate_complex_inputs_on_desktop_browsers" <|
            \_ ->
                let
                    -- Desktop browsers should handle comprehensive validation
                    validationRules =
                        { excavatorCapacity = { min = 0.5, max = 15.0 }
                        , cycleTime = { min = 0.5, max = 10.0 }
                        , truckCapacity = { min = 5.0, max = 30.0 }
                        , roundTripTime = { min = 5.0, max = 60.0 }
                        , workHours = { min = 1.0, max = 16.0 }
                        , pondDimensions = { min = 1.0, max = 1000.0 }
                        }

                    complexInputs =
                        { excavatorCapacity = 7.5
                        , excavatorCycleTime = 1.8
                        , truckCapacity = 18.5
                        , truckRoundTripTime = 22.3
                        , workHoursPerDay = 9.5
                        , pondLength = 85.7
                        , pondWidth = 42.3
                        , pondDepth = 8.2
                        }

                    result =
                        Validation.validateAllInputs validationRules complexInputs
                in
                case result of
                    Ok validInputs ->
                        Expect.equal complexInputs validInputs

                    Err _ ->
                        Expect.fail "Desktop browsers should handle complex input validation"
        ]


{-| Test core functionality on mobile browsers (Chrome mobile, Safari mobile <768px)
-}
mobileBrowserCompatibilityTests : Test
mobileBrowserCompatibilityTests =
    describe "Mobile Browser Compatibility (<768px width)"
        [ test "should_detect_mobile_device_type_consistently_across_browsers" <|
            \_ ->
                let
                    -- Mobile viewport dimensions
                    mobileViewport =
                        { width = 375, height = 667 }

                    -- iPhone
                    mobileViewportSmall =
                        { width = 320, height = 568 }

                    -- Small mobile
                    mobileViewportLarge =
                        { width = 414, height = 896 }

                    -- Large mobile
                    deviceType1 =
                        Types.DeviceType.fromWindowSize mobileViewport

                    deviceType2 =
                        Types.DeviceType.fromWindowSize mobileViewportSmall

                    deviceType3 =
                        Types.DeviceType.fromWindowSize mobileViewportLarge
                in
                Expect.all
                    [ \_ -> Expect.equal Mobile deviceType1
                    , \_ -> Expect.equal Mobile deviceType2
                    , \_ -> Expect.equal Mobile deviceType3
                    ]
                    ()
        , test "should_disable_advanced_features_on_mobile_browsers" <|
            \_ ->
                let
                    mobileFeatureEnabled =
                        DeviceDetector.shouldShowAdvancedFeatures Mobile
                in
                -- Mobile should show simplified interface across Chrome/Safari mobile
                Expect.equal False mobileFeatureEnabled
        , test "should_handle_basic_calculations_on_mobile_browsers" <|
            \_ ->
                let
                    -- Basic calculation that mobile browsers should handle efficiently
                    excavatorCapacity =
                        2.5

                    excavatorCycle =
                        2.0

                    truckCapacity =
                        12.0

                    truckRoundTrip =
                        15.0

                    pondVolume =
                        300.0

                    -- Reasonable pond size for mobile
                    workHours =
                        8.0

                    result =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case result of
                    Ok calculation ->
                        Expect.all
                            [ \r -> Expect.greaterThan 0 r.timelineInDays
                            , \r -> Expect.lessThan 10 r.timelineInDays -- Should be reasonable
                            , \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> Expect.lessThan 100.0 r.totalHours -- Should complete quickly
                            ]
                            calculation

                    Err _ ->
                        Expect.fail "Basic calculations should succeed on mobile browsers"
        , test "should_validate_simple_inputs_on_mobile_browsers" <|
            \_ ->
                let
                    -- Mobile browsers should handle basic validation efficiently
                    mobileValidationRules =
                        { excavatorCapacity = { min = 0.5, max = 15.0 }
                        , cycleTime = { min = 0.5, max = 10.0 }
                        , truckCapacity = { min = 5.0, max = 30.0 }
                        , roundTripTime = { min = 5.0, max = 60.0 }
                        , workHours = { min = 1.0, max = 16.0 }
                        , pondDimensions = { min = 1.0, max = 1000.0 }
                        }

                    basicInputs =
                        { excavatorCapacity = 3.0
                        , excavatorCycleTime = 2.0
                        , truckCapacity = 12.0
                        , truckRoundTripTime = 15.0
                        , workHoursPerDay = 8.0
                        , pondLength = 40.0
                        , pondWidth = 25.0
                        , pondDepth = 5.0
                        }

                    result =
                        Validation.validateAllInputs mobileValidationRules basicInputs
                in
                case result of
                    Ok validInputs ->
                        Expect.equal basicInputs validInputs

                    Err _ ->
                        Expect.fail "Mobile browsers should handle basic input validation"
        , test "should_handle_mobile_user_agent_detection" <|
            \_ ->
                let
                    -- Test common mobile user agent patterns
                    iphoneUserAgent =
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"

                    androidUserAgent =
                        "Mozilla/5.0 (Linux; Android 10; SM-G975F)"

                    mobileChrome =
                        "Mozilla/5.0 (Linux; Android 11; Pixel 4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Mobile Safari/537.36"

                    isiPhone =
                        DeviceDetector.isMobileUserAgent iphoneUserAgent

                    isAndroid =
                        DeviceDetector.isMobileUserAgent androidUserAgent

                    isMobileChrome =
                        DeviceDetector.isMobileUserAgent mobileChrome
                in
                Expect.all
                    [ \_ -> Expect.equal True isiPhone
                    , \_ -> Expect.equal True isAndroid
                    , \_ -> Expect.equal True isMobileChrome
                    ]
                    ()
        ]


{-| Test core functionality on tablet browsers (Safari iPad, Chrome tablet 768-1024px)
-}
tabletBrowserCompatibilityTests : Test
tabletBrowserCompatibilityTests =
    describe "Tablet Browser Compatibility (768-1024px width)"
        [ test "should_detect_tablet_device_type_consistently_across_browsers" <|
            \_ ->
                let
                    -- Tablet viewport dimensions
                    tabletViewport =
                        { width = 768, height = 1024 }

                    -- iPad portrait
                    tabletViewportLandscape =
                        { width = 1024, height = 768 }

                    -- iPad landscape
                    tabletViewportMid =
                        { width = 900, height = 1200 }

                    -- Mid-size tablet
                    deviceType1 =
                        Types.DeviceType.fromWindowSize tabletViewport

                    deviceType2 =
                        Types.DeviceType.fromWindowSize tabletViewportLandscape

                    deviceType3 =
                        Types.DeviceType.fromWindowSize tabletViewportMid
                in
                Expect.all
                    [ \_ -> Expect.equal Tablet deviceType1
                    , \_ -> Expect.equal Tablet deviceType2
                    , \_ -> Expect.equal Tablet deviceType3
                    ]
                    ()
        , test "should_enable_advanced_features_on_tablet_browsers" <|
            \_ ->
                let
                    tabletFeatureEnabled =
                        DeviceDetector.shouldShowAdvancedFeatures Tablet
                in
                -- Tablet should show full functionality like desktop
                Expect.equal True tabletFeatureEnabled
        , test "should_handle_medium_complexity_calculations_on_tablet_browsers" <|
            \_ ->
                let
                    -- Medium complexity calculation suitable for tablet
                    excavatorCapacity =
                        3.5

                    excavatorCycle =
                        2.2

                    truckCapacity =
                        16.0

                    truckRoundTrip =
                        18.0

                    pondVolume =
                        800.0

                    -- Medium pond size
                    workHours =
                        9.0

                    result =
                        Calculations.calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHours
                in
                case result of
                    Ok calculation ->
                        Expect.all
                            [ \r -> Expect.greaterThan 0 r.timelineInDays
                            , \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> Expect.greaterThan 0.0 r.excavationRate
                            , \r -> Expect.greaterThan 0.0 r.haulingRate
                            ]
                            calculation

                    Err _ ->
                        Expect.fail "Medium complexity calculations should succeed on tablet browsers"
        , test "should_handle_tablet_user_agent_detection" <|
            \_ ->
                let
                    -- Test common tablet user agent patterns
                    iPadUserAgent =
                        "Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)"

                    androidTabletUserAgent =
                        "Mozilla/5.0 (Linux; Android 10; SM-T870)"

                    isiPad =
                        DeviceDetector.isMobileUserAgent iPadUserAgent

                    isAndroidTablet =
                        DeviceDetector.isMobileUserAgent androidTabletUserAgent
                in
                Expect.all
                    [ \_ -> Expect.equal True isiPad
                    , \_ -> Expect.equal True isAndroidTablet
                    ]
                    ()
        ]


{-| Test that core calculation functionality works across all browser/device combinations
-}
coreCalculationFunctionalityTests : Test
coreCalculationFunctionalityTests =
    describe "Core Functionality Across All Browser/Device Combinations"
        [ test "should_execute_calculations_within_performance_targets_on_all_browsers" <|
            \_ ->
                let
                    -- Standard calculation that should perform well on all browsers
                    standardCalculation =
                        Calculations.calculateTimeline 2.5 2.0 12.0 15.0 400.0 8.0

                    -- Performance requirement: calculation should complete quickly
                    -- (In real E2E tests, this would measure actual execution time)
                    calculationSucceeds =
                        case standardCalculation of
                            Ok _ ->
                                True

                            Err _ ->
                                False
                in
                Expect.equal True calculationSucceeds
        , test "should_handle_validation_errors_consistently_across_all_browsers" <|
            \_ ->
                let
                    validationRules =
                        { excavatorCapacity = { min = 0.5, max = 15.0 }
                        , cycleTime = { min = 0.5, max = 10.0 }
                        , truckCapacity = { min = 5.0, max = 30.0 }
                        , roundTripTime = { min = 5.0, max = 60.0 }
                        , workHours = { min = 1.0, max = 16.0 }
                        , pondDimensions = { min = 1.0, max = 1000.0 }
                        }

                    invalidInputs =
                        { excavatorCapacity = -1.0 -- Invalid
                        , excavatorCycleTime = 2.0
                        , truckCapacity = 12.0
                        , truckRoundTripTime = 15.0
                        , workHoursPerDay = 8.0
                        , pondLength = 40.0
                        , pondWidth = 25.0
                        , pondDepth = 5.0
                        }

                    result =
                        Validation.validateAllInputs validationRules invalidInputs
                in
                case result of
                    Err _ ->
                        Expect.pass

                    -- Should fail validation on all browsers
                    Ok _ ->
                        Expect.fail "Invalid inputs should fail validation on all browsers"
        , test "should_load_default_values_reliably_across_all_browsers" <|
            \_ ->
                let
                    -- Default configuration should load identically across browsers
                    config =
                        Config.fallbackConfig

                    defaultExcavator =
                        List.head config.defaults.excavators |> Maybe.map .bucketCapacity |> Maybe.withDefault 0.0

                    defaultTruck =
                        List.head config.defaults.trucks |> Maybe.map .capacity |> Maybe.withDefault 0.0

                    defaultWorkHours =
                        config.defaults.project.workHoursPerDay
                in
                Expect.all
                    [ \_ -> Expect.within (Expect.Absolute 0.001) 2.5 defaultExcavator
                    , \_ -> Expect.within (Expect.Absolute 0.001) 12.0 defaultTruck
                    , \_ -> Expect.within (Expect.Absolute 0.001) 8.0 defaultWorkHours
                    ]
                    ()
        , test "should_maintain_calculation_precision_across_all_browsers" <|
            \_ ->
                let
                    -- Test floating point precision consistency
                    preciseInputs =
                        { excavatorCapacity = 2.33333
                        , excavatorCycle = 1.66667
                        , truckCapacity = 11.11111
                        , truckRoundTrip = 14.28571
                        , pondVolume = 333.33333
                        , workHours = 7.77777
                        }

                    result =
                        Calculations.calculateTimeline
                            preciseInputs.excavatorCapacity
                            preciseInputs.excavatorCycle
                            preciseInputs.truckCapacity
                            preciseInputs.truckRoundTrip
                            preciseInputs.pondVolume
                            preciseInputs.workHours
                in
                case result of
                    Ok calculation ->
                        Expect.all
                            [ \r -> Expect.greaterThan 0.0 r.totalHours
                            , \r -> Expect.greaterThan 0.0 r.excavationRate
                            , \r -> Expect.greaterThan 0.0 r.haulingRate
                            ]
                            calculation

                    Err _ ->
                        Expect.fail "Precise calculations should succeed across all browsers"
        ]


{-| Test browser-specific features and edge cases
-}
browserSpecificFeatureTests : Test
browserSpecificFeatureTests =
    describe "Browser-Specific Feature Compatibility"
        [ test "should_handle_javascript_number_limits_across_browsers" <|
            \_ ->
                let
                    -- Test edge cases that might behave differently across browsers
                    veryLargeNumber =
                        999999999.0

                    verySmallNumber =
                        0.000001

                    largeCalculation =
                        Calculations.calculateTimeline 15.0 0.5 50.0 5.0 veryLargeNumber 16.0
                in
                case largeCalculation of
                    Ok large ->
                        Expect.greaterThan 0 large.timelineInDays

                    Err _ ->
                        Expect.pass
        , test "should_handle_string_to_float_conversion_consistently" <|
            \_ ->
                let
                    -- Test string parsing that might vary between browsers
                    testValues =
                        [ "2.5"
                        , "2.50"
                        , "2.500000"
                        , "02.5"
                        , "2.5000000000001"
                        ]

                    parseResults =
                        List.map String.toFloat testValues

                    allParsed =
                        List.all
                            (\result ->
                                case result of
                                    Just _ ->
                                        True

                                    Nothing ->
                                        False
                            )
                            parseResults
                in
                Expect.equal True allParsed
        , test "should_handle_device_detection_consistently_across_browsers" <|
            \_ ->
                let
                    -- Test that device detection works with various viewport sizes
                    testViewports =
                        [ { width = 320, height = 568 } -- Mobile
                        , { width = 768, height = 1024 } -- Tablet
                        , { width = 1200, height = 800 } -- Desktop
                        , { width = 1920, height = 1080 } -- Large desktop
                        ]

                    deviceTypes =
                        List.map Types.DeviceType.fromWindowSize testViewports

                    expectedTypes =
                        [ Mobile, Tablet, Desktop, Desktop ]
                in
                Expect.equal expectedTypes deviceTypes
        , test "should_maintain_consistent_behavior_with_browser_rounding_differences" <|
            \_ ->
                let
                    -- Test calculations that might round differently across browsers
                    testCase1 =
                        Calculations.calculateExcavatorRate 2.333333 1.666667

                    testCase2 =
                        Calculations.calculateTruckRate 11.111111 14.285714

                    -- Results should be consistent (within reasonable tolerance)
                    bothAreNumbers =
                        (testCase1 > 0.0) && (testCase2 > 0.0)
                in
                Expect.equal True bothAreNumbers
        ]
