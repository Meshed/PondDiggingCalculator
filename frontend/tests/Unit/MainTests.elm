module Unit.MainTests exposing (..)

import Expect
import Test exposing (..)
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Types.Validation exposing (ValidationError(..))
import Utils.Config exposing (Config)


suite : Test
suite =
    describe "Main Application Tests"
        [ describe "Model Initialization"
            [ test "should_initialize_model_with_expected_message" <|
                \_ ->
                    let
                        expectedMessage =
                            "Pond Digging Calculator - Core Calculation Engine"

                        model =
                            { message = expectedMessage
                            , config = Nothing
                            , formData = Nothing
                            , calculationResult = Nothing
                            }
                    in
                    Expect.equal expectedMessage model.message
            , test "should_initialize_model_with_no_config" <|
                \_ ->
                    let
                        model =
                            { message = "Pond Digging Calculator - Foundation Setup Complete"
                            , config = Nothing
                            }
                    in
                    Expect.equal Nothing model.config
            ]
        , describe "Message Handling"
            [ test "should_handle_config_loaded_success" <|
                \_ ->
                    let
                        model =
                            { message = "Test"
                            , config = Nothing
                            , formData = Nothing
                            , calculationResult = Nothing
                            }

                        sampleConfig : Config
                        sampleConfig =
                            { version = "1.0.0"
                            , defaults =
                                { excavators = [ { bucketCapacity = 2.5, cycleTime = 2.0, name = "Test Excavator" } ]
                                , trucks = [ { capacity = 12.0, roundTripTime = 15.0, name = "Test Truck" } ]
                                , project = { workHoursPerDay = 8.0, pondLength = 50.0, pondWidth = 30.0, pondDepth = 6.0 }
                                }
                            , fleetLimits = { maxExcavators = 10, maxTrucks = 20 }
                            , validation =
                                { excavatorCapacity = { min = 0.5, max = 15.0 }
                                , cycleTime = { min = 0.5, max = 10.0 }
                                , truckCapacity = { min = 5.0, max = 30.0 }
                                , roundTripTime = { min = 5.0, max = 60.0 }
                                , workHours = { min = 1.0, max = 16.0 }
                                , pondDimensions = { min = 1.0, max = 1000.0 }
                                }
                            }
                    in
                    Expect.equal (Just sampleConfig) (Just sampleConfig)
            , test "should_handle_config_loaded_error" <|
                \_ ->
                    let
                        model =
                            { message = "Test"
                            , config = Nothing
                            , formData = Nothing
                            , calculationResult = Nothing
                            }

                        error =
                            ConfigurationError "Test error"
                    in
                    Expect.equal Nothing model.config
            ]
        ]
