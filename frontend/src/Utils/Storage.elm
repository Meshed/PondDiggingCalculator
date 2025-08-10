module Utils.Storage exposing
    ( saveToLocalStorage, loadFromLocalStorage, storageKey
    , saveOnboardingState, loadOnboardingState, onboardingStorageKey, decodeOnboardingState
    )

{-| Local storage operations for client-side persistence

@docs saveToLocalStorage, loadFromLocalStorage, storageKey
@docs saveOnboardingState, loadOnboardingState, onboardingStorageKey, decodeOnboardingState

-}

import Json.Decode as Decode
import Json.Encode as Encode
import Types.Onboarding exposing (OnboardingState(..))



-- STORAGE UTILITIES


storageKey : String
storageKey =
    "pond-calculator-config"


{-| Save configuration to local storage
Note: In a real implementation, this would use ports to JavaScript
For now, this is a placeholder for the storage interface
-}
saveToLocalStorage : String -> Cmd msg
saveToLocalStorage value =
    -- TODO: Implement with ports when needed
    Cmd.none


{-| Load configuration from local storage
Note: In a real implementation, this would use ports to JavaScript
For now, this is a placeholder for the storage interface
-}
loadFromLocalStorage : (Maybe String -> msg) -> Cmd msg
loadFromLocalStorage toMsg =
    -- TODO: Implement with ports when needed
    Cmd.none



-- ONBOARDING STORAGE


onboardingStorageKey : String
onboardingStorageKey =
    "pondCalculator.onboardingState"


{-| Save onboarding state to local storage
-}
saveOnboardingState : OnboardingState -> Cmd msg
saveOnboardingState state =
    let
        jsonValue =
            encodeOnboardingState state |> Encode.encode 0
    in
    -- TODO: Use ports to save to localStorage
    -- For now, this is a placeholder
    Cmd.none


{-| Load onboarding state from local storage
-}
loadOnboardingState : (Maybe String -> msg) -> Cmd msg
loadOnboardingState toMsg =
    -- TODO: Use ports to load from localStorage
    -- For now, assume first-time user
    toMsg Nothing
        |> (\msg ->
                -- Simulate immediate callback
                Cmd.none
           )



-- JSON ENCODING/DECODING


{-| Encode onboarding state to JSON
-}
encodeOnboardingState : OnboardingState -> Encode.Value
encodeOnboardingState state =
    case state of
        NotStarted ->
            Encode.object [ ( "state", Encode.string "not_started" ) ]

        WelcomeShown ->
            Encode.object [ ( "state", Encode.string "welcome_shown" ) ]

        TourInProgress step ->
            Encode.object
                [ ( "state", Encode.string "tour_in_progress" )
                , ( "step", Encode.int step )
                ]

        ExampleShown ->
            Encode.object [ ( "state", Encode.string "example_shown" ) ]

        Completed ->
            Encode.object [ ( "state", Encode.string "completed" ) ]


{-| Decode onboarding state from JSON
-}
decodeOnboardingState : String -> OnboardingState
decodeOnboardingState jsonString =
    case Decode.decodeString onboardingStateDecoder jsonString of
        Ok state ->
            state

        Err _ ->
            NotStarted


onboardingStateDecoder : Decode.Decoder OnboardingState
onboardingStateDecoder =
    Decode.field "state" Decode.string
        |> Decode.andThen
            (\stateString ->
                case stateString of
                    "not_started" ->
                        Decode.succeed NotStarted

                    "welcome_shown" ->
                        Decode.succeed WelcomeShown

                    "tour_in_progress" ->
                        Decode.map TourInProgress (Decode.field "step" Decode.int)

                    "example_shown" ->
                        Decode.succeed ExampleShown

                    "completed" ->
                        Decode.succeed Completed

                    _ ->
                        Decode.succeed NotStarted
            )
