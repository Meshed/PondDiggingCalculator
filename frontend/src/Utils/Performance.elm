module Utils.Performance exposing (PerformanceMetrics, initMetrics, recordCalculationTime, shouldWarn)

{-| Performance monitoring utilities for real-time calculations

@docs PerformanceMetrics, initMetrics, recordCalculationTime, shouldWarn

-}


-- TYPES


type alias PerformanceMetrics =
    { lastCalculationTime : Float -- milliseconds
    , averageTime : Float -- rolling average
    , maxTime : Float -- highest recorded time
    , calculationCount : Int
    , warningThreshold : Float -- milliseconds
    }


-- CONSTANTS


{-| Performance warning threshold in milliseconds as per AC 3
-}
performanceThreshold : Float
performanceThreshold =
    100.0


-- INITIALIZATION


{-| Initialize performance metrics with default values
-}
initMetrics : PerformanceMetrics
initMetrics =
    { lastCalculationTime = 0.0
    , averageTime = 0.0
    , maxTime = 0.0
    , calculationCount = 0
    , warningThreshold = performanceThreshold
    }


-- RECORDING FUNCTIONS


{-| Record a new calculation time and update rolling metrics
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
                (metrics.averageTime * 0.8) + (timeMs * 0.2)

        newMax =
            max metrics.maxTime timeMs
    in
    { metrics
        | lastCalculationTime = timeMs
        , averageTime = newAverage
        , maxTime = newMax
        , calculationCount = newCount
    }


-- PERFORMANCE CHECKS


{-| Check if current performance should trigger a warning
-}
shouldWarn : PerformanceMetrics -> Bool
shouldWarn metrics =
    metrics.lastCalculationTime > metrics.warningThreshold


{-| Get performance status message for debugging
-}
getPerformanceStatus : PerformanceMetrics -> String
getPerformanceStatus metrics =
    if shouldWarn metrics then
        "⚠️ Calculation took " ++ String.fromFloat metrics.lastCalculationTime ++ "ms (exceeds " ++ String.fromFloat metrics.warningThreshold ++ "ms threshold)"
    else
        "✓ Calculation completed in " ++ String.fromFloat metrics.lastCalculationTime ++ "ms"