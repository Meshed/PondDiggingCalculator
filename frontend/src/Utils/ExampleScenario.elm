module Utils.ExampleScenario exposing (loadExampleScenario, clearExampleScenario)

{-| Example scenario utilities for onboarding

@docs loadExampleScenario, clearExampleScenario

-}

import Components.ProjectForm exposing (FormData)
import Types.Equipment exposing (Excavator, Truck)
import Types.Messages exposing (Msg(..))
import Types.Model exposing (Model)
import Types.Onboarding exposing (ExampleScenario, defaultExampleScenario)
import Utils.Config



-- EXAMPLE SCENARIO OPERATIONS


{-| Load example scenario into the model
-}
loadExampleScenario : Model -> ( Model, Cmd Msg )
loadExampleScenario model =
    let
        example =
            defaultExampleScenario

        -- Create example project form data
        exampleFormData =
            { workHoursPerDay = String.fromFloat example.workHoursPerDay
            , pondLength = String.fromFloat example.pondLength
            , pondWidth = String.fromFloat example.pondWidth
            , pondDepth = String.fromFloat example.pondDepth
            , errors = []
            }

        -- Replace fleet with example equipment
        exampleExcavators =
            [ example.excavatorSpec ]

        exampleTrucks =
            [ example.truckSpec ]

        updatedModel =
            { model
                | formData = Just exampleFormData
                , excavators = exampleExcavators
                , trucks = exampleTrucks
                , onboardingState = Types.Onboarding.ExampleShown
                , exampleScenarioLoaded = True
                , showWelcomeOverlay = False
            }
    in
    -- Return the updated model - calculation will be triggered by Main
    ( updatedModel, Cmd.none )


{-| Clear example scenario and restore defaults
-}
clearExampleScenario : Model -> ( Model, Cmd Msg )
clearExampleScenario model =
    case model.config of
        Just config ->
            let
                -- Reset form to config defaults
                resetFormData =
                    Components.ProjectForm.initFormData config.defaults

                -- Reset fleet from configuration defaults
                initialExcavators =
                    initExcavatorsFromConfig config.defaults.excavators 1

                initialTrucks =
                    initTrucksFromConfig config.defaults.trucks 1

                updatedModel =
                    { model
                        | formData = Just resetFormData
                        , excavators = initialExcavators
                        , trucks = initialTrucks
                        , exampleScenarioLoaded = False
                        , calculationResult = Nothing
                        , lastValidResult = Nothing
                        , hasValidationErrors = False
                    }
            in
            -- Return the updated model - calculation will be triggered by Main
            ( updatedModel, Cmd.none )

        Nothing ->
            ( model, Cmd.none )



-- HELPER FUNCTIONS (duplicated from Main.elm for now)


{-| Initialize excavators from configuration defaults with generated IDs
-}
initExcavatorsFromConfig : List Utils.Config.ExcavatorDefaults -> Int -> List Excavator
initExcavatorsFromConfig excavatorDefaults startId =
    List.indexedMap
        (\index defaults ->
            { id = "excavator-" ++ String.fromInt (startId + index)
            , bucketCapacity = defaults.bucketCapacity
            , cycleTime = defaults.cycleTime
            , name = defaults.name
            , isActive = True
            }
        )
        excavatorDefaults


{-| Initialize trucks from configuration defaults with generated IDs
-}
initTrucksFromConfig : List Utils.Config.TruckDefaults -> Int -> List Truck
initTrucksFromConfig truckDefaults startId =
    List.indexedMap
        (\index defaults ->
            { id = "truck-" ++ String.fromInt (startId + index)
            , capacity = defaults.capacity
            , roundTripTime = defaults.roundTripTime
            , name = defaults.name
            , isActive = True
            }
        )
        truckDefaults
