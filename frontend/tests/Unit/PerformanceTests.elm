module Unit.PerformanceTests exposing (suite)

import Dict
import Expect
import Test exposing (Test, describe, test)
import Time
import Utils.Calculations as Calculations
import Utils.Performance as Performance


suite : Test
suite =
    describe "Performance Monitoring System"
        [ describe "Performance Metrics Initialization"
            [ test "should_initialize_metrics_with_default_values" <|
                \_ ->
                    let
                        metrics =
                            Performance.initMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal Nothing metrics.loadTime
                        , \() -> Expect.equal Nothing metrics.calculationTime
                        , \() -> Expect.equal 0.0 metrics.averageCalculationTime
                        , \() -> Expect.equal 0 metrics.calculationCount
                        , \() -> Expect.equal [] metrics.performanceBudgetViolations
                        , \() -> Expect.equal 0.0 metrics.sessionDuration
                        , \() -> Expect.equal Nothing metrics.sessionStartTime
                        , \() -> Expect.equal Dict.empty metrics.customMetrics
                        , \() -> Expect.equal 0.0 metrics.maxCalculationTime
                        , \() -> Expect.equal 0 metrics.totalViolations
                        ]
                        ()
            ]
        , describe "Load Time Measurement"
            [ test "should_record_load_time" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        updatedMetrics =
                            Performance.recordLoadTime 1500.0 initialMetrics
                    in
                    Expect.equal (Just 1500.0) updatedMetrics.loadTime
            , test "should_update_load_time_when_recorded_again" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        firstUpdate =
                            Performance.recordLoadTime 1500.0 initialMetrics

                        secondUpdate =
                            Performance.recordLoadTime 1200.0 firstUpdate
                    in
                    Expect.equal (Just 1200.0) secondUpdate.loadTime
            ]
        , describe "Calculation Time Recording"
            [ test "should_record_calculation_time" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        updatedMetrics =
                            Performance.recordCalculationTime 50.0 initialMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal (Just 50.0) updatedMetrics.calculationTime
                        , \() -> Expect.equal 50.0 updatedMetrics.averageCalculationTime
                        , \() -> Expect.equal 50.0 updatedMetrics.maxCalculationTime
                        , \() -> Expect.equal 1 updatedMetrics.calculationCount
                        ]
                        ()
            , test "should_update_rolling_average_correctly" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        firstUpdate =
                            Performance.recordCalculationTime 100.0 initialMetrics

                        secondUpdate =
                            Performance.recordCalculationTime 50.0 firstUpdate

                        expectedAverage =
                            (100.0 * 0.8) + (50.0 * 0.2)

                        -- 80 + 10 = 90
                    in
                    Expect.within (Expect.Absolute 0.1) expectedAverage secondUpdate.averageCalculationTime
            , test "should_track_max_calculation_time" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        firstUpdate =
                            Performance.recordCalculationTime 50.0 initialMetrics

                        secondUpdate =
                            Performance.recordCalculationTime 120.0 firstUpdate

                        thirdUpdate =
                            Performance.recordCalculationTime 80.0 secondUpdate
                    in
                    Expect.equal 120.0 thirdUpdate.maxCalculationTime
            ]
        , describe "Custom Metrics Recording"
            [ test "should_record_custom_metric" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        updatedMetrics =
                            Performance.recordCustomMetric "memoryUsage" 256.0 initialMetrics
                    in
                    Expect.equal (Just 256.0) (Dict.get "memoryUsage" updatedMetrics.customMetrics)
            , test "should_handle_multiple_custom_metrics" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        withMemory =
                            Performance.recordCustomMetric "memoryUsage" 256.0 initialMetrics

                        withCpu =
                            Performance.recordCustomMetric "cpuUsage" 45.0 withMemory

                        withNetwork =
                            Performance.recordCustomMetric "networkLatency" 120.0 withCpu
                    in
                    Expect.all
                        [ \() -> Expect.equal (Just 256.0) (Dict.get "memoryUsage" withNetwork.customMetrics)
                        , \() -> Expect.equal (Just 45.0) (Dict.get "cpuUsage" withNetwork.customMetrics)
                        , \() -> Expect.equal (Just 120.0) (Dict.get "networkLatency" withNetwork.customMetrics)
                        , \() -> Expect.equal 3 (Dict.size withNetwork.customMetrics)
                        ]
                        ()
            ]
        , describe "Performance Warning Detection"
            [ test "should_warn_when_calculation_exceeds_threshold" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        slowMetrics =
                            Performance.recordCalculationTime 150.0 initialMetrics
                    in
                    Expect.equal True (Performance.shouldWarn slowMetrics)
            , test "should_not_warn_when_calculation_under_threshold" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        fastMetrics =
                            Performance.recordCalculationTime 50.0 initialMetrics
                    in
                    Expect.equal False (Performance.shouldWarn fastMetrics)
            , test "should_not_warn_when_no_calculation_recorded" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics
                    in
                    Expect.equal False (Performance.shouldWarn initialMetrics)
            ]
        , describe "Budget Violation Detection"
            [ test "should_detect_load_time_budget_violation" <|
                \_ ->
                    let
                        currentTime =
                            Time.millisToPosix 1000

                        initialMetrics =
                            Performance.initMetrics

                        slowLoadMetrics =
                            Performance.recordLoadTime 4000.0 initialMetrics

                        -- Over 3000ms budget
                        checkedMetrics =
                            Performance.checkBudgetViolations currentTime slowLoadMetrics
                    in
                    Expect.all
                        [ \() -> Expect.greaterThan 0 (List.length checkedMetrics.performanceBudgetViolations)
                        , \() -> Expect.equal 1 checkedMetrics.totalViolations
                        ]
                        ()
            , test "should_detect_calculation_time_budget_violation" <|
                \_ ->
                    let
                        currentTime =
                            Time.millisToPosix 1000

                        initialMetrics =
                            Performance.initMetrics

                        slowCalcMetrics =
                            Performance.recordCalculationTime 1200.0 initialMetrics

                        -- Over 1000ms budget
                        checkedMetrics =
                            Performance.checkBudgetViolations currentTime slowCalcMetrics
                    in
                    Expect.all
                        [ \() -> Expect.greaterThan 0 (List.length checkedMetrics.performanceBudgetViolations)
                        , \() -> Expect.equal 1 checkedMetrics.totalViolations
                        ]
                        ()
            , test "should_not_detect_violations_when_under_budget" <|
                \_ ->
                    let
                        currentTime =
                            Time.millisToPosix 1000

                        initialMetrics =
                            Performance.initMetrics

                        goodMetrics =
                            Performance.recordLoadTime 2000.0 initialMetrics
                                -- Under 3000ms budget
                                |> Performance.recordCalculationTime 500.0

                        -- Under 1000ms budget
                        checkedMetrics =
                            Performance.checkBudgetViolations currentTime goodMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal 0 (List.length checkedMetrics.performanceBudgetViolations)
                        , \() -> Expect.equal 0 checkedMetrics.totalViolations
                        ]
                        ()
            ]
        , describe "Performance Reporting"
            [ test "should_generate_performance_status_for_good_performance" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        fastMetrics =
                            Performance.recordCalculationTime 50.0 initialMetrics

                        status =
                            Performance.getPerformanceStatus fastMetrics
                    in
                    Expect.equal True (String.contains "✓" status)
            , test "should_generate_warning_status_for_slow_performance" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        slowMetrics =
                            Performance.recordCalculationTime 150.0 initialMetrics

                        status =
                            Performance.getPerformanceStatus slowMetrics
                    in
                    Expect.equal True (String.contains "⚠️" status)
            , test "should_export_performance_data_as_json_format" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        populatedMetrics =
                            Performance.recordLoadTime 1500.0 initialMetrics
                                |> Performance.recordCalculationTime 75.0
                                |> Performance.recordCustomMetric "testMetric" 42.0

                        exportedData =
                            Performance.exportPerformanceData populatedMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal True (String.contains "\"loadTime\":1500" exportedData)
                        , \() -> Expect.equal True (String.contains "\"calculationTime\":75" exportedData)
                        , \() -> Expect.equal True (String.contains "testMetric" exportedData)
                        ]
                        ()
            ]
        , describe "Performance Budget Constants"
            [ test "should_have_correct_budget_values" <|
                \_ ->
                    let
                        budgets =
                            Performance.performanceBudgets
                    in
                    Expect.all
                        [ \() -> Expect.equal 3000.0 budgets.maxLoadTime
                        , \() -> Expect.equal 1000.0 budgets.maxCalculationTime
                        , \() -> Expect.equal 500.0 budgets.maxBundleSize
                        , \() -> Expect.equal 100.0 budgets.warningThreshold
                        ]
                        ()
            ]
        , describe "Console Logging Utilities"
            [ test "should_format_console_log_with_performance_data" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        populatedMetrics =
                            Performance.recordLoadTime 1200.0 initialMetrics
                                |> Performance.recordCalculationTime 80.0

                        logMessage =
                            Performance.logPerformanceToConsole populatedMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal True (String.contains "[Performance]" logMessage)
                        , \() -> Expect.equal True (String.contains "80" logMessage)
                        , \() -> Expect.equal True (String.contains "1200" logMessage)
                        ]
                        ()
            , test "should_format_detailed_console_debug_info" <|
                \_ ->
                    let
                        initialMetrics =
                            Performance.initMetrics

                        populatedMetrics =
                            Performance.recordCalculationTime 50.0 initialMetrics
                                |> Performance.recordCalculationTime 75.0
                                |> Performance.recordLoadTime 1800.0

                        debugInfo =
                            Performance.formatPerformanceForConsole populatedMetrics
                    in
                    Expect.all
                        [ \() -> Expect.equal True (String.contains "Performance Debug Information" debugInfo)
                        , \() -> Expect.equal True (String.contains "Calculations: 2" debugInfo)
                        , \() -> Expect.equal True (String.contains "Load Time: 1800" debugInfo)
                        ]
                        ()
            ]
        ]
