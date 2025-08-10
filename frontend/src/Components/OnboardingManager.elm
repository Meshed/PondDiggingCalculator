module Components.OnboardingManager exposing (view, initializeOnboarding, completeOnboarding)

{-| Onboarding manager to coordinate the complete onboarding flow

@docs view, initializeOnboarding, completeOnboarding

-}

import Components.GuidedTour as GuidedTour
import Components.HelpSystemIntegration as HelpSystemIntegration
import Components.WelcomeOverlay as WelcomeOverlay
import Html exposing (Html, div, text)
import Types.DeviceType exposing (DeviceType)
import Types.Messages exposing (Msg)
import Types.Model exposing (Model)
import Types.Onboarding exposing (OnboardingState(..), TourStep(..), defaultOnboardingConfig)



-- INITIALIZATION


{-| Initialize onboarding for a first-time user
-}
initializeOnboarding : Model -> ( Model, Cmd Msg )
initializeOnboarding model =
    if model.isFirstTimeUser && model.onboardingState == NotStarted then
        ( { model
            | showWelcomeOverlay = True
            , onboardingState = NotStarted
          }
        , Cmd.none
        )

    else
        ( model, Cmd.none )


{-| Complete onboarding and clean up state
-}
completeOnboarding : Model -> ( Model, Cmd Msg )
completeOnboarding model =
    ( { model
        | onboardingState = Completed
        , showWelcomeOverlay = False
        , currentTourStep = Nothing
        , isFirstTimeUser = False
      }
    , Cmd.none
    )



-- VIEW


{-| Main onboarding manager view - renders appropriate component based on state
-}
view : Model -> Html Msg
view model =
    if not model.isFirstTimeUser && model.onboardingState == Completed then
        -- No onboarding needed
        text ""

    else
        case model.onboardingState of
            NotStarted ->
                if model.showWelcomeOverlay then
                    let
                        config =
                            defaultOnboardingConfig model.deviceType
                    in
                    WelcomeOverlay.view config model.deviceType identity

                else
                    text ""

            WelcomeShown ->
                text ""

            -- Transition state
            TourInProgress stepNumber ->
                case model.currentTourStep of
                    Just currentStep ->
                        let
                            config =
                                defaultOnboardingConfig model.deviceType

                            totalSteps =
                                List.length config.tourSteps
                        in
                        GuidedTour.view config model.deviceType currentStep (stepNumber + 1) totalSteps identity

                    Nothing ->
                        text ""

            ExampleShown ->
                -- Example scenario is active, no overlay needed
                text ""

            Completed ->
                -- Show help system integration for completed onboarding users
                HelpSystemIntegration.view model



-- TOUR NAVIGATION HELPERS


{-| Get the current step index in the tour
-}
getCurrentStepIndex : List TourStep -> TourStep -> Int
getCurrentStepIndex steps currentStep =
    List.indexedMap Tuple.pair steps
        |> List.filter (\( _, step ) -> step == currentStep)
        |> List.head
        |> Maybe.map Tuple.first
        |> Maybe.withDefault 0


{-| Get the next step in the tour sequence
-}
getNextStep : List TourStep -> TourStep -> Maybe TourStep
getNextStep steps currentStep =
    let
        currentIndex =
            getCurrentStepIndex steps currentStep

        nextIndex =
            currentIndex + 1
    in
    List.drop nextIndex steps |> List.head


{-| Get the previous step in the tour sequence
-}
getPreviousStep : List TourStep -> TourStep -> Maybe TourStep
getPreviousStep steps currentStep =
    let
        currentIndex =
            getCurrentStepIndex steps currentStep

        prevIndex =
            currentIndex - 1
    in
    if prevIndex >= 0 then
        List.drop prevIndex steps |> List.head

    else
        Nothing
