module Unit.FleetValidationTests exposing (suite)

{-| Unit tests for fleet validation functionality

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)
import Types.Equipment exposing (EquipmentId, Excavator, Truck)
import Types.Validation exposing (ValidationError(..))
import Utils.Config exposing (ValidationRange, ValidationRules, fallbackConfig)
import Utils.Validation exposing (ExcavatorField(..), TruckField(..), validateExcavatorFleet, validateTruckFleet)


suite : Test
suite =
    describe "Fleet Validation Tests"
        [ describe "Excavator Fleet Validation"
            [ test "validates all excavators in fleet independently" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        mixedFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Valid 1", isActive = True }
                            , { id = "exc2", bucketCapacity = -1.0, cycleTime = 1.8, name = "Invalid Capacity", isActive = True }
                            , { id = "exc3", bucketCapacity = 3.0, cycleTime = -0.5, name = "Invalid Cycle", isActive = True }
                            , { id = "exc4", bucketCapacity = 2.2, cycleTime = 2.1, name = "Valid 2", isActive = True }
                            ]

                        validationErrors =
                            validateExcavatorFleet validationRules mixedFleet
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            -- Should have error for exc2's bucket capacity
                            validationErrors
                                |> List.any (\( id, field, error ) -> id == "exc2" && field == ExcavatorBucketCapacity)
                                |> Expect.equal True
                        , \_ ->
                            -- Should have error for exc3's cycle time
                            validationErrors
                                |> List.any (\( id, field, error ) -> id == "exc3" && field == ExcavatorCycleTime)
                                |> Expect.equal True
                        ]
                        ()
            , test "returns no errors for valid excavator fleet" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        validFleet =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = 2.0, name = "Valid 1", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = 1.8, name = "Valid 2", isActive = True }
                            , { id = "exc3", bucketCapacity = 1.5, cycleTime = 2.5, name = "Valid 3", isActive = True }
                            ]

                        validationErrors =
                            validateExcavatorFleet validationRules validFleet
                    in
                    Expect.equal [] validationErrors
            , test "rejects negative bucket capacities" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithNegativeCapacity =
                            [ { id = "exc1", bucketCapacity = -2.5, cycleTime = 2.0, name = "Negative Capacity", isActive = True }
                            , { id = "exc2", bucketCapacity = -0.1, cycleTime = 1.8, name = "Slightly Negative", isActive = True }
                            ]

                        validationErrors =
                            validateExcavatorFleet validationRules fleetWithNegativeCapacity
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            validationErrors
                                |> List.all (\( id, field, error ) -> field == ExcavatorBucketCapacity)
                                |> Expect.equal True
                        ]
                        ()
            , test "rejects negative cycle times" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithNegativeCycleTime =
                            [ { id = "exc1", bucketCapacity = 2.5, cycleTime = -1.0, name = "Negative Cycle", isActive = True }
                            , { id = "exc2", bucketCapacity = 3.0, cycleTime = -0.5, name = "Slightly Negative Cycle", isActive = True }
                            ]

                        validationErrors =
                            validateExcavatorFleet validationRules fleetWithNegativeCycleTime
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            validationErrors
                                |> List.all (\( id, field, error ) -> field == ExcavatorCycleTime)
                                |> Expect.equal True
                        ]
                        ()
            , test "validates values against industry standard ranges" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithOutOfRangeValues =
                            [ { id = "exc1", bucketCapacity = 0.1, cycleTime = 2.0, name = "Too Small Capacity", isActive = True } -- Below min
                            , { id = "exc2", bucketCapacity = 20.0, cycleTime = 1.8, name = "Too Large Capacity", isActive = True } -- Above max
                            , { id = "exc3", bucketCapacity = 2.5, cycleTime = 0.1, name = "Too Fast Cycle", isActive = True } -- Below min
                            , { id = "exc4", bucketCapacity = 3.0, cycleTime = 15.0, name = "Too Slow Cycle", isActive = True } -- Above max
                            ]

                        validationErrors =
                            validateExcavatorFleet validationRules fleetWithOutOfRangeValues
                    in
                    Expect.all
                        [ \_ -> Expect.equal 4 (List.length validationErrors)
                        , \_ ->
                            -- Check that we have errors for both capacity and cycle time fields
                            let
                                capacityErrors =
                                    List.filter (\( id, field, error ) -> field == ExcavatorBucketCapacity) validationErrors

                                cycleErrors =
                                    List.filter (\( id, field, error ) -> field == ExcavatorCycleTime) validationErrors
                            in
                            Expect.all
                                [ \_ -> Expect.equal 2 (List.length capacityErrors)
                                , \_ -> Expect.equal 2 (List.length cycleErrors)
                                ]
                                ()
                        ]
                        ()
            , test "handles empty excavator fleet" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        emptyFleet =
                            []

                        validationErrors =
                            validateExcavatorFleet validationRules emptyFleet
                    in
                    Expect.equal [] validationErrors
            ]
        , describe "Truck Fleet Validation"
            [ test "validates all trucks in fleet independently" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        mixedFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Valid 1", isActive = True }
                            , { id = "truck2", capacity = -5.0, roundTripTime = 12.0, name = "Invalid Capacity", isActive = True }
                            , { id = "truck3", capacity = 18.0, roundTripTime = -10.0, name = "Invalid Round Trip", isActive = True }
                            , { id = "truck4", capacity = 15.0, roundTripTime = 18.0, name = "Valid 2", isActive = True }
                            ]

                        validationErrors =
                            validateTruckFleet validationRules mixedFleet
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            -- Should have error for truck2's capacity
                            validationErrors
                                |> List.any (\( id, field, error ) -> id == "truck2" && field == TruckFieldCapacity)
                                |> Expect.equal True
                        , \_ ->
                            -- Should have error for truck3's round trip time
                            validationErrors
                                |> List.any (\( id, field, error ) -> id == "truck3" && field == TruckFieldRoundTripTime)
                                |> Expect.equal True
                        ]
                        ()
            , test "returns no errors for valid truck fleet" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        validFleet =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = 15.0, name = "Valid 1", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = 12.0, name = "Valid 2", isActive = True }
                            , { id = "truck3", capacity = 8.0, roundTripTime = 20.0, name = "Valid 3", isActive = True }
                            , { id = "truck4", capacity = 25.0, roundTripTime = 25.0, name = "Valid 4", isActive = True }
                            ]

                        validationErrors =
                            validateTruckFleet validationRules validFleet
                    in
                    Expect.equal [] validationErrors
            , test "rejects negative truck capacities" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithNegativeCapacity =
                            [ { id = "truck1", capacity = -12.0, roundTripTime = 15.0, name = "Negative Capacity", isActive = True }
                            , { id = "truck2", capacity = -0.5, roundTripTime = 12.0, name = "Slightly Negative", isActive = True }
                            ]

                        validationErrors =
                            validateTruckFleet validationRules fleetWithNegativeCapacity
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            validationErrors
                                |> List.all (\( id, field, error ) -> field == TruckFieldCapacity)
                                |> Expect.equal True
                        ]
                        ()
            , test "rejects negative round-trip times" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithNegativeRoundTrip =
                            [ { id = "truck1", capacity = 12.0, roundTripTime = -15.0, name = "Negative Round Trip", isActive = True }
                            , { id = "truck2", capacity = 18.0, roundTripTime = -1.0, name = "Slightly Negative RT", isActive = True }
                            ]

                        validationErrors =
                            validateTruckFleet validationRules fleetWithNegativeRoundTrip
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length validationErrors)
                        , \_ ->
                            validationErrors
                                |> List.all (\( id, field, error ) -> field == TruckFieldRoundTripTime)
                                |> Expect.equal True
                        ]
                        ()
            , test "validates values against industry standard ranges" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        fleetWithOutOfRangeValues =
                            [ { id = "truck1", capacity = 2.0, roundTripTime = 15.0, name = "Too Small Capacity", isActive = True } -- Below min
                            , { id = "truck2", capacity = 35.0, roundTripTime = 12.0, name = "Too Large Capacity", isActive = True } -- Above max
                            , { id = "truck3", capacity = 15.0, roundTripTime = 2.0, name = "Too Fast Round Trip", isActive = True } -- Below min
                            , { id = "truck4", capacity = 12.0, roundTripTime = 70.0, name = "Too Slow Round Trip", isActive = True } -- Above max
                            ]

                        validationErrors =
                            validateTruckFleet validationRules fleetWithOutOfRangeValues
                    in
                    Expect.all
                        [ \_ -> Expect.equal 4 (List.length validationErrors)
                        , \_ ->
                            -- Check that we have errors for both capacity and round trip time fields
                            let
                                capacityErrors =
                                    List.filter (\( id, field, error ) -> field == TruckFieldCapacity) validationErrors

                                roundTripErrors =
                                    List.filter (\( id, field, error ) -> field == TruckFieldRoundTripTime) validationErrors
                            in
                            Expect.all
                                [ \_ -> Expect.equal 2 (List.length capacityErrors)
                                , \_ -> Expect.equal 2 (List.length roundTripErrors)
                                ]
                                ()
                        ]
                        ()
            , test "handles empty truck fleet" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        emptyFleet =
                            []

                        validationErrors =
                            validateTruckFleet validationRules emptyFleet
                    in
                    Expect.equal [] validationErrors
            ]
        , describe "Multi-Equipment Validation Scenarios"
            [ test "handles multiple invalid items independently" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        problematicExcavatorFleet =
                            [ { id = "exc1", bucketCapacity = -2.5, cycleTime = -1.0, name = "Double Invalid", isActive = True }
                            , { id = "exc2", bucketCapacity = 50.0, cycleTime = 20.0, name = "Double Out of Range", isActive = True }
                            , { id = "exc3", bucketCapacity = 2.5, cycleTime = 2.0, name = "Valid", isActive = True }
                            ]

                        problematicTruckFleet =
                            [ { id = "truck1", capacity = -12.0, roundTripTime = -15.0, name = "Double Invalid", isActive = True }
                            , { id = "truck2", capacity = 50.0, roundTripTime = 100.0, name = "Double Out of Range", isActive = True }
                            , { id = "truck3", capacity = 12.0, roundTripTime = 15.0, name = "Valid", isActive = True }
                            ]

                        excavatorErrors =
                            validateExcavatorFleet validationRules problematicExcavatorFleet

                        truckErrors =
                            validateTruckFleet validationRules problematicTruckFleet
                    in
                    Expect.all
                        [ \_ -> Expect.equal 4 (List.length excavatorErrors) -- 2 equipment × 2 fields each
                        , \_ -> Expect.equal 4 (List.length truckErrors) -- 2 equipment × 2 fields each
                        , \_ ->
                            -- Verify specific equipment has multiple errors
                            excavatorErrors
                                |> List.filter (\( id, field, error ) -> id == "exc1")
                                |> List.length
                                |> Expect.equal 2
                        , \_ ->
                            -- Verify specific truck has multiple errors
                            truckErrors
                                |> List.filter (\( id, field, error ) -> id == "truck1")
                                |> List.length
                                |> Expect.equal 2
                        ]
                        ()
            , test "validation errors include correct field identification" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        excavatorWithCapacityError =
                            [ { id = "exc1", bucketCapacity = -1.0, cycleTime = 2.0, name = "Capacity Error", isActive = True } ]

                        excavatorWithCycleError =
                            [ { id = "exc2", bucketCapacity = 2.5, cycleTime = -1.0, name = "Cycle Error", isActive = True } ]

                        truckWithCapacityError =
                            [ { id = "truck1", capacity = -5.0, roundTripTime = 15.0, name = "Capacity Error", isActive = True } ]

                        truckWithRoundTripError =
                            [ { id = "truck2", capacity = 12.0, roundTripTime = -5.0, name = "Round Trip Error", isActive = True } ]

                        capacityErrors =
                            validateExcavatorFleet validationRules excavatorWithCapacityError

                        cycleErrors =
                            validateExcavatorFleet validationRules excavatorWithCycleError

                        truckCapacityErrors =
                            validateTruckFleet validationRules truckWithCapacityError

                        truckRoundTripErrors =
                            validateTruckFleet validationRules truckWithRoundTripError
                    in
                    Expect.all
                        [ \_ ->
                            case List.head capacityErrors of
                                Just ( id, field, error ) ->
                                    Expect.all
                                        [ \_ -> Expect.equal "exc1" id
                                        , \_ -> Expect.equal ExcavatorBucketCapacity field
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have capacity error"
                        , \_ ->
                            case List.head cycleErrors of
                                Just ( id, field, error ) ->
                                    Expect.all
                                        [ \_ -> Expect.equal "exc2" id
                                        , \_ -> Expect.equal ExcavatorCycleTime field
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have cycle error"
                        , \_ ->
                            case List.head truckCapacityErrors of
                                Just ( id, field, error ) ->
                                    Expect.all
                                        [ \_ -> Expect.equal "truck1" id
                                        , \_ -> Expect.equal TruckFieldCapacity field
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have truck capacity error"
                        , \_ ->
                            case List.head truckRoundTripErrors of
                                Just ( id, field, error ) ->
                                    Expect.all
                                        [ \_ -> Expect.equal "truck2" id
                                        , \_ -> Expect.equal TruckFieldRoundTripTime field
                                        ]
                                        ()

                                Nothing ->
                                    Expect.fail "Should have truck round trip error"
                        ]
                        ()
            ]
        , describe "Fleet Size Validation Edge Cases"
            [ test "validates large fleet correctly" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        largeValidFleet =
                            List.range 1 10
                                |> List.map
                                    (\i ->
                                        { id = "exc" ++ String.fromInt i
                                        , bucketCapacity = 2.0 + toFloat i * 0.2
                                        , cycleTime = 1.8 + toFloat i * 0.1
                                        , name = "Excavator " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        validationErrors =
                            validateExcavatorFleet validationRules largeValidFleet
                    in
                    Expect.equal [] validationErrors
            , test "identifies multiple errors in large fleet" <|
                \_ ->
                    let
                        validationRules =
                            fallbackConfig.validation

                        largeFleetWithErrors =
                            List.range 1 8
                                |> List.map
                                    (\i ->
                                        { id = "truck" ++ String.fromInt i
                                        , capacity =
                                            if modBy 3 i == 0 then
                                                -5.0

                                            else
                                                12.0 + toFloat i

                                        -- Every 3rd truck has invalid capacity
                                        , roundTripTime =
                                            if modBy 4 i == 0 then
                                                -2.0

                                            else
                                                15.0 + toFloat i

                                        -- Every 4th truck has invalid round trip
                                        , name = "Truck " ++ String.fromInt i
                                        , isActive = True
                                        }
                                    )

                        validationErrors =
                            validateTruckFleet validationRules largeFleetWithErrors

                        -- truck3 and truck6 have capacity errors
                        -- truck4 and truck8 have round trip errors
                        -- truck12 would have both but we only have 8 trucks
                        expectedErrorCount =
                            4

                        -- truck3, truck4, truck6, truck8
                    in
                    Expect.equal expectedErrorCount (List.length validationErrors)
            ]
        ]
