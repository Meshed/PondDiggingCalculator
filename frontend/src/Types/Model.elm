module Types.Model exposing (Model, Flags)

{-| Core application state model

@docs Model, Flags

-}

import Components.ProjectForm exposing (FormData)
import Dict exposing (Dict)
import Time
import Types.DeviceType exposing (DeviceType)
import Types.Equipment exposing (Excavator, Truck)
import Types.Onboarding exposing (OnboardingState, TourStep)
import Types.Validation exposing (ValidationError)
import Utils.Calculations exposing (CalculationResult)
import Utils.Config exposing (Config)
import Utils.Debounce exposing (DebounceState)
import Utils.Performance exposing (PerformanceMetrics)



-- MODEL


type alias Model =
    { message : String
    , config : Maybe Config
    , formData : Maybe FormData
    , calculationResult : Maybe CalculationResult
    , lastValidResult : Maybe CalculationResult -- Preserve during validation errors
    , hasValidationErrors : Bool -- Track if current inputs have validation errors
    , deviceType : DeviceType
    , calculationInProgress : Bool -- Prevent race conditions
    , performanceMetrics : PerformanceMetrics -- Track calculation performance
    , debounceState : DebounceState -- For input debouncing
    , excavators : List Excavator -- Fleet of excavators
    , trucks : List Truck -- Fleet of trucks
    , nextExcavatorId : Int -- ID generator for excavators
    , nextTruckId : Int -- ID generator for trucks
    , helpTooltipState : Maybe String -- Track active tooltip field ID
    , showHelpPanel : Bool -- Whether help modal is visible
    , currentContextualHelp : Maybe String -- Current contextual help section
    , realTimeValidation : Bool -- Enable/disable real-time validation
    , fieldValidationErrors : Dict String ValidationError -- Field-specific validation errors
    , validationDebounce : Dict String Time.Posix -- Validation debounce state per field

    -- Onboarding State
    , onboardingState : OnboardingState -- Current onboarding progress
    , showWelcomeOverlay : Bool -- Whether to show welcome overlay
    , currentTourStep : Maybe TourStep -- Current step in guided tour
    , isFirstTimeUser : Bool -- Whether this is the user's first visit
    , exampleScenarioLoaded : Bool -- Whether example scenario is currently loaded

    -- REMOVED: mobileModel - Mobile now uses same state as desktop!
    }


type alias Flags =
    ()
