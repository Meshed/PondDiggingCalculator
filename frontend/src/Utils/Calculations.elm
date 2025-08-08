module Utils.Calculations exposing
    ( calculateExcavatorRate, calculateTruckRate, calculateTimeline
    , calculateExcavatorFleetProductivity, calculateTruckFleetProductivity
    , performCalculation
    , CalculationResult, CalculationError(..), Bottleneck(..), ConfidenceLevel(..)
    )

{-| Core calculation engine for pond digging timeline estimates

@docs calculateExcavatorRate, calculateTruckRate, calculateTimeline
@docs calculateExcavatorFleetProductivity, calculateTruckFleetProductivity
@docs performCalculation
@docs CalculationResult, CalculationError, Bottleneck, ConfidenceLevel

-}

import Types.Equipment exposing (CubicYards, Excavator, Minutes, Truck)
import Types.Validation exposing (ValidationError)



-- CONSTANTS


{-| Real-world efficiency factor for excavators accounting for positioning,
operator breaks, and site conditions
-}
excavatorEfficiencyFactor : Float
excavatorEfficiencyFactor =
    0.85


{-| Truck efficiency factor accounting for loading/unloading time,
traffic delays, and coordination with excavators
-}
truckEfficiencyFactor : Float
truckEfficiencyFactor =
    0.8



-- TYPES


type CalculationError
    = ValidationError ValidationError
    | InsufficientEquipment
    | InvalidConfiguration String


type Bottleneck
    = ExcavationBottleneck
    | HaulingBottleneck
    | Balanced


type ConfidenceLevel
    = High
    | Medium
    | Low


type alias CalculationResult =
    { timelineInDays : Int -- whole days (rounded up)
    , totalHours : Float -- precise calculation
    , excavationRate : Float -- cy/hour
    , haulingRate : Float -- cy/hour
    , bottleneck : Bottleneck
    , confidence : ConfidenceLevel
    , assumptions : List String
    , warnings : List String
    }



-- CALCULATION FUNCTIONS


{-| Calculate the hourly excavation rate for a single excavator.
Takes bucket capacity in cubic yards and cycle time in minutes.
Returns cubic yards per hour accounting for real-world efficiency.
-}
calculateExcavatorRate : CubicYards -> Minutes -> CubicYards
calculateExcavatorRate bucketCapacity cycleTime =
    let
        cyclesPerHour =
            60.0 / cycleTime

        theoreticalRate =
            cyclesPerHour * bucketCapacity
    in
    -- Apply efficiency factor because real-world conditions reduce productivity
    theoreticalRate * excavatorEfficiencyFactor


{-| Calculate the hourly hauling rate for a single truck.
Takes truck capacity in cubic yards and round-trip time in minutes.
Returns cubic yards per hour accounting for loading/unloading efficiency.
-}
calculateTruckRate : CubicYards -> Minutes -> CubicYards
calculateTruckRate truckCapacity roundTripTime =
    let
        tripsPerHour =
            60.0 / roundTripTime

        theoreticalRate =
            tripsPerHour * truckCapacity
    in
    -- Apply efficiency factor for loading/unloading and coordination delays
    theoreticalRate * truckEfficiencyFactor


{-| Calculate complete timeline for pond digging project.
Takes excavator specs, truck specs, pond volume, and work hours per day.
Returns detailed calculation result with timeline rounded up to whole days.
-}
calculateTimeline : CubicYards -> Minutes -> CubicYards -> Minutes -> Float -> Float -> Result CalculationError CalculationResult
calculateTimeline excavatorCapacity excavatorCycle truckCapacity truckRoundTrip pondVolume workHoursPerDay =
    if pondVolume <= 0 then
        Err (InvalidConfiguration "Pond volume must be positive")

    else if workHoursPerDay <= 0 then
        Err (InvalidConfiguration "Work hours per day must be positive")

    else
        let
            excavationRate =
                calculateExcavatorRate excavatorCapacity excavatorCycle

            haulingRate =
                calculateTruckRate truckCapacity truckRoundTrip

            -- The limiting factor determines overall productivity
            effectiveRate =
                min excavationRate haulingRate

            -- Calculate timeline
            totalHours =
                pondVolume / effectiveRate

            timelineInDays =
                ceiling (totalHours / workHoursPerDay)

            -- Determine bottleneck
            bottleneck =
                if abs (excavationRate - haulingRate) < 5.0 then
                    Balanced

                else if excavationRate < haulingRate then
                    ExcavationBottleneck

                else
                    HaulingBottleneck

            -- Assess confidence based on equipment balance
            confidence =
                case bottleneck of
                    Balanced ->
                        High

                    _ ->
                        if abs (excavationRate - haulingRate) > 20.0 then
                            Low

                        else
                            Medium

            -- Generate assumptions and warnings
            assumptions =
                [ "Excavator efficiency: " ++ String.fromFloat (excavatorEfficiencyFactor * 100) ++ "%"
                , "Truck efficiency: " ++ String.fromFloat (truckEfficiencyFactor * 100) ++ "%"
                , "No weather delays assumed"
                , "Site conditions allow continuous operation"
                ]

            warnings =
                case bottleneck of
                    ExcavationBottleneck ->
                        [ "Excavation is the limiting factor - consider additional excavators" ]

                    HaulingBottleneck ->
                        [ "Hauling is the limiting factor - consider additional trucks" ]

                    Balanced ->
                        []
        in
        Ok
            { timelineInDays = timelineInDays
            , totalHours = totalHours
            , excavationRate = excavationRate
            , haulingRate = haulingRate
            , bottleneck = bottleneck
            , confidence = confidence
            , assumptions = assumptions
            , warnings = warnings
            }


{-| Calculate total productivity of an excavator fleet.
Only includes active excavators in the calculation.
Returns cubic yards per hour for the entire fleet.
-}
calculateExcavatorFleetProductivity : List Excavator -> Float
calculateExcavatorFleetProductivity excavators =
    excavators
        |> List.filter .isActive
        |> List.map (\excavator -> calculateExcavatorRate excavator.bucketCapacity excavator.cycleTime)
        |> List.sum


{-| Calculate total productivity of a truck fleet.
Only includes active trucks in the calculation.
Returns cubic yards per hour for the entire fleet.
-}
calculateTruckFleetProductivity : List Truck -> Float
calculateTruckFleetProductivity trucks =
    trucks
        |> List.filter .isActive
        |> List.map (\truck -> calculateTruckRate truck.capacity truck.roundTripTime)
        |> List.sum


{-| Main calculation function for fleet-based pond digging projects.
Takes fleet lists, pond volume, and work hours per day.
Returns detailed calculation result with timeline and analysis.
-}
performCalculation : List Excavator -> List Truck -> Float -> Float -> Result CalculationError CalculationResult
performCalculation excavators trucks pondVolume workHoursPerDay =
    let
        activeExcavatorCount =
            List.length (List.filter .isActive excavators)

        activeTruckCount =
            List.length (List.filter .isActive trucks)
    in
    if activeExcavatorCount == 0 then
        Err InsufficientEquipment

    else if activeTruckCount == 0 then
        Err InsufficientEquipment

    else if pondVolume <= 0 then
        Err (InvalidConfiguration "Pond volume must be positive")

    else if workHoursPerDay <= 0 then
        Err (InvalidConfiguration "Work hours per day must be positive")

    else
        let
            excavationRate =
                calculateExcavatorFleetProductivity excavators

            haulingRate =
                calculateTruckFleetProductivity trucks

            -- The limiting factor determines overall productivity
            effectiveRate =
                min excavationRate haulingRate

            -- Calculate timeline
            totalHours =
                pondVolume / effectiveRate

            timelineInDays =
                ceiling (totalHours / workHoursPerDay)

            -- Determine bottleneck
            bottleneck =
                if abs (excavationRate - haulingRate) < 5.0 then
                    Balanced

                else if excavationRate < haulingRate then
                    ExcavationBottleneck

                else
                    HaulingBottleneck

            -- Assess confidence based on fleet size and balance
            confidence =
                case bottleneck of
                    Balanced ->
                        if activeExcavatorCount >= 2 && activeTruckCount >= 2 then
                            High

                        else
                            Medium

                    _ ->
                        if abs (excavationRate - haulingRate) > 20.0 then
                            Low

                        else
                            Medium

            -- Generate assumptions and warnings
            assumptions =
                [ "Excavator efficiency: " ++ String.fromFloat (excavatorEfficiencyFactor * 100) ++ "%"
                , "Truck efficiency: " ++ String.fromFloat (truckEfficiencyFactor * 100) ++ "%"
                , "Fleet coordination assumed optimal"
                , "No weather delays assumed"
                , "Site conditions allow continuous operation"
                , String.fromInt activeExcavatorCount ++ " active excavator(s)"
                , String.fromInt activeTruckCount ++ " active truck(s)"
                ]

            warnings =
                case bottleneck of
                    ExcavationBottleneck ->
                        [ "Excavation is the limiting factor - consider additional excavators" ]

                    HaulingBottleneck ->
                        [ "Hauling is the limiting factor - consider additional trucks" ]

                    Balanced ->
                        []
        in
        Ok
            { timelineInDays = timelineInDays
            , totalHours = totalHours
            , excavationRate = excavationRate
            , haulingRate = haulingRate
            , bottleneck = bottleneck
            , confidence = confidence
            , assumptions = assumptions
            , warnings = warnings
            }
