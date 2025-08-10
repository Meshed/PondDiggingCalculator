module Utils.Performance exposing
    ( PerformanceMetrics, PerformanceBudgets, BudgetViolation, PerformanceMetric(..)
    , initMetrics, recordCalculationTime, recordLoadTime, recordCustomMetric
    , shouldWarn, checkBudgetViolations, getPerformanceStatus, getPerformanceReport
    , exportPerformanceData, performanceBudgets
    , logPerformanceToConsole, formatPerformanceForConsole
    )

{-| Comprehensive performance monitoring and optimization system

This module provides client-side performance monitoring capabilities including:

  - Load time measurement and tracking
  - Calculation performance timing
  - Performance budget validation
  - Console logging for development debugging
  - Extensible architecture for future monitoring integration

@docs PerformanceMetrics, PerformanceBudgets, BudgetViolation, PerformanceMetric
@docs initMetrics, recordCalculationTime, recordLoadTime, recordCustomMetric
@docs shouldWarn, checkBudgetViolations, getPerformanceStatus, getPerformanceReport
@docs exportPerformanceData, performanceBudgets
@docs logPerformanceToConsole, formatPerformanceForConsole

-}

import Dict exposing (Dict)
import Time



-- TYPES


{-| Comprehensive performance metrics collection
Following Elm type safety patterns for performance data as specified in Dev Notes
-}
type alias PerformanceMetrics =
    { loadTime : Maybe Float -- application load time in ms
    , calculationTime : Maybe Float -- last calculation duration in ms
    , averageCalculationTime : Float -- running average for trend analysis
    , calculationCount : Int -- total calculations performed
    , performanceBudgetViolations : List BudgetViolation
    , sessionDuration : Float -- current session length in ms
    , sessionStartTime : Maybe Time.Posix -- when performance tracking started
    , customMetrics : Dict String Float -- extensible custom measurements
    , maxCalculationTime : Float -- highest recorded calculation time
    , totalViolations : Int -- count of all budget violations
    }


{-| Performance budget violation record
-}
type alias BudgetViolation =
    { metric : PerformanceMetric
    , actualValue : Float
    , budgetLimit : Float
    , timestamp : Time.Posix
    , severity : ViolationSeverity
    }


{-| Available performance metrics for monitoring
-}
type PerformanceMetric
    = LoadTime
    | CalculationDuration
    | TotalMemoryUsage
    | CustomMetric String


{-| Severity levels for budget violations
-}
type ViolationSeverity
    = Warning
    | Critical


{-| Performance budget configuration as specified in Dev Notes
Construction site connection considerations: 3-second load time target
-}
type alias PerformanceBudgets =
    { maxLoadTime : Float -- 3 seconds for construction site connections
    , maxCalculationTime : Float -- 1 second (sub-second target with buffer)
    , maxBundleSize : Float -- KB - reasonable for mobile construction sites
    , warningThreshold : Float -- threshold for calculation warnings
    }


{-| Performance budget constants (no external dependencies)
Values based on construction site internet connections and professional user needs
-}
performanceBudgets : PerformanceBudgets
performanceBudgets =
    { maxLoadTime = 3000.0 -- 3 seconds for construction site connections
    , maxCalculationTime = 1000.0 -- 1 second (sub-second target with buffer)
    , maxBundleSize = 500.0 -- KB - reasonable for mobile construction sites
    , warningThreshold = 100.0 -- 100ms calculation warning threshold
    }



-- INITIALIZATION


{-| Initialize comprehensive performance metrics with default values
Enhanced from basic metrics to support all story requirements
-}
initMetrics : PerformanceMetrics
initMetrics =
    { loadTime = Nothing
    , calculationTime = Nothing
    , averageCalculationTime = 0.0
    , calculationCount = 0
    , performanceBudgetViolations = []
    , sessionDuration = 0.0
    , sessionStartTime = Nothing
    , customMetrics = Dict.empty
    , maxCalculationTime = 0.0
    , totalViolations = 0
    }



-- RECORDING FUNCTIONS


{-| Record application load time in milliseconds
Implements AC 1: load time measurement and tracking
-}
recordLoadTime : Float -> PerformanceMetrics -> PerformanceMetrics
recordLoadTime timeMs metrics =
    { metrics | loadTime = Just timeMs }


{-| Record a new calculation time and update rolling metrics
Enhanced to support comprehensive performance analysis
-}
recordCalculationTime : Float -> PerformanceMetrics -> PerformanceMetrics
recordCalculationTime timeMs metrics =
    let
        newCount =
            metrics.calculationCount + 1

        newAverage =
            if metrics.calculationCount == 0 then
                timeMs

            else
                -- Simple rolling average with more weight on recent values
                (metrics.averageCalculationTime * 0.8) + (timeMs * 0.2)

        newMax =
            max metrics.maxCalculationTime timeMs
    in
    { metrics
        | calculationTime = Just timeMs
        , averageCalculationTime = newAverage
        , maxCalculationTime = newMax
        , calculationCount = newCount
    }


{-| Record custom performance metric for extensibility
Implements AC 5: framework for adding custom performance measurements
-}
recordCustomMetric : String -> Float -> PerformanceMetrics -> PerformanceMetrics
recordCustomMetric metricName value metrics =
    { metrics
        | customMetrics = Dict.insert metricName value metrics.customMetrics
    }



-- PERFORMANCE VALIDATION


{-| Check if current calculation performance should trigger a warning
-}
shouldWarn : PerformanceMetrics -> Bool
shouldWarn metrics =
    case metrics.calculationTime of
        Just time ->
            time > performanceBudgets.warningThreshold

        Nothing ->
            False


{-| Check for performance budget violations and record them
Implements AC 3: performance budget validation
-}
checkBudgetViolations : Time.Posix -> PerformanceMetrics -> PerformanceMetrics
checkBudgetViolations currentTime metrics =
    let
        violations =
            []

        -- Check load time violation
        loadTimeViolation =
            case metrics.loadTime of
                Just loadTime ->
                    if loadTime > performanceBudgets.maxLoadTime then
                        [ { metric = LoadTime
                          , actualValue = loadTime
                          , budgetLimit = performanceBudgets.maxLoadTime
                          , timestamp = currentTime
                          , severity =
                                if loadTime > (performanceBudgets.maxLoadTime * 1.5) then
                                    Critical

                                else
                                    Warning
                          }
                        ]

                    else
                        []

                Nothing ->
                    []

        -- Check calculation time violation
        calcTimeViolation =
            case metrics.calculationTime of
                Just calcTime ->
                    if calcTime > performanceBudgets.maxCalculationTime then
                        [ { metric = CalculationDuration
                          , actualValue = calcTime
                          , budgetLimit = performanceBudgets.maxCalculationTime
                          , timestamp = currentTime
                          , severity =
                                if calcTime > (performanceBudgets.maxCalculationTime * 2.0) then
                                    Critical

                                else
                                    Warning
                          }
                        ]

                    else
                        []

                Nothing ->
                    []

        allViolations =
            violations ++ loadTimeViolation ++ calcTimeViolation

        newViolationsList =
            metrics.performanceBudgetViolations ++ allViolations

        newTotalViolations =
            metrics.totalViolations + List.length allViolations
    in
    { metrics
        | performanceBudgetViolations = newViolationsList
        , totalViolations = newTotalViolations
    }



-- REPORTING AND ANALYSIS


{-| Get performance status message for debugging
Enhanced to provide comprehensive performance insights
-}
getPerformanceStatus : PerformanceMetrics -> String
getPerformanceStatus metrics =
    case metrics.calculationTime of
        Just time ->
            if shouldWarn metrics then
                "⚠️ Calculation took "
                    ++ String.fromFloat time
                    ++ "ms (exceeds "
                    ++ String.fromFloat performanceBudgets.warningThreshold
                    ++ "ms threshold)"

            else
                "✓ Calculation completed in " ++ String.fromFloat time ++ "ms"

        Nothing ->
            "No calculation timing data available"


{-| Generate comprehensive performance report
Implements AC 5: performance data export capability for analysis
-}
getPerformanceReport : PerformanceMetrics -> String
getPerformanceReport metrics =
    let
        loadTimeReport =
            case metrics.loadTime of
                Just time ->
                    "Load Time: " ++ String.fromFloat time ++ "ms"

                Nothing ->
                    "Load Time: Not measured"

        calcTimeReport =
            case metrics.calculationTime of
                Just time ->
                    "Last Calculation: " ++ String.fromFloat time ++ "ms"

                Nothing ->
                    "Last Calculation: Not measured"

        averageReport =
            "Average Calculation: " ++ String.fromFloat metrics.averageCalculationTime ++ "ms"

        violationsReport =
            "Budget Violations: " ++ String.fromInt metrics.totalViolations

        sessionReport =
            "Session Duration: " ++ String.fromFloat metrics.sessionDuration ++ "ms"

        customMetricsReport =
            if Dict.isEmpty metrics.customMetrics then
                "Custom Metrics: None"

            else
                "Custom Metrics: " ++ String.fromInt (Dict.size metrics.customMetrics) ++ " recorded"
    in
    String.join "\n"
        [ "=== Performance Report ==="
        , loadTimeReport
        , calcTimeReport
        , averageReport
        , violationsReport
        , sessionReport
        , customMetricsReport
        ]


{-| Export performance data in JSON-like format for analysis
Implements AC 5: performance data export capability
-}
exportPerformanceData : PerformanceMetrics -> String
exportPerformanceData metrics =
    let
        loadTime =
            case metrics.loadTime of
                Just time ->
                    String.fromFloat time

                Nothing ->
                    "null"

        calculationTime =
            case metrics.calculationTime of
                Just time ->
                    String.fromFloat time

                Nothing ->
                    "null"

        customMetricsJson =
            metrics.customMetrics
                |> Dict.toList
                |> List.map (\( k, v ) -> "\"" ++ k ++ "\":" ++ String.fromFloat v)
                |> String.join ","
                |> (\s -> "{" ++ s ++ "}")
    in
    "{"
        ++ "\"loadTime\":"
        ++ loadTime
        ++ ","
        ++ "\"calculationTime\":"
        ++ calculationTime
        ++ ","
        ++ "\"averageCalculationTime\":"
        ++ String.fromFloat metrics.averageCalculationTime
        ++ ","
        ++ "\"calculationCount\":"
        ++ String.fromInt metrics.calculationCount
        ++ ","
        ++ "\"maxCalculationTime\":"
        ++ String.fromFloat metrics.maxCalculationTime
        ++ ","
        ++ "\"totalViolations\":"
        ++ String.fromInt metrics.totalViolations
        ++ ","
        ++ "\"sessionDuration\":"
        ++ String.fromFloat metrics.sessionDuration
        ++ ","
        ++ "\"customMetrics\":"
        ++ customMetricsJson
        ++ "}"



-- CONSOLE LOGGING UTILITIES


{-| Log performance metrics to browser console (development only)
Implements AC 4: development-only console logging for performance metrics
-}
logPerformanceToConsole : PerformanceMetrics -> String
logPerformanceToConsole metrics =
    let
        timestamp =
            "[Performance]"

        status =
            getPerformanceStatus metrics

        violations =
            if metrics.totalViolations > 0 then
                " | Violations: " ++ String.fromInt metrics.totalViolations

            else
                ""

        loadInfo =
            case metrics.loadTime of
                Just time ->
                    " | Load: " ++ String.fromFloat time ++ "ms"

                Nothing ->
                    ""
    in
    timestamp ++ " " ++ status ++ violations ++ loadInfo


{-| Format performance data for detailed console debugging
Implements AC 4: detailed timing information for calculation engine operations
-}
formatPerformanceForConsole : PerformanceMetrics -> String
formatPerformanceForConsole metrics =
    let
        lines =
            [ "=== Performance Debug Information ==="
            , "Calculations: " ++ String.fromInt metrics.calculationCount
            , "Average Time: " ++ String.fromFloat metrics.averageCalculationTime ++ "ms"
            , "Max Time: " ++ String.fromFloat metrics.maxCalculationTime ++ "ms"
            , getPerformanceStatus metrics
            ]

        loadTimeDebug =
            case metrics.loadTime of
                Just time ->
                    [ "Load Time: " ++ String.fromFloat time ++ "ms" ]

                Nothing ->
                    [ "Load Time: Not measured" ]

        violationsDebug =
            if List.isEmpty metrics.performanceBudgetViolations then
                [ "Budget Violations: None" ]

            else
                [ "Budget Violations: " ++ String.fromInt (List.length metrics.performanceBudgetViolations) ]

        customMetricsDebug =
            if Dict.isEmpty metrics.customMetrics then
                [ "Custom Metrics: None" ]

            else
                [ "Custom Metrics: " ++ String.fromInt (Dict.size metrics.customMetrics) ++ " active" ]
    in
    String.join "\n" (lines ++ loadTimeDebug ++ violationsDebug ++ customMetricsDebug)
