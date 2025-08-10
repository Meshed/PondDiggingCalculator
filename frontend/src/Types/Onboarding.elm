module Types.Onboarding exposing (OnboardingState(..), TourStep(..), OnboardingConfig, ExampleScenario, defaultOnboardingConfig, defaultExampleScenario)

{-| Onboarding system types and configuration

@docs OnboardingState, TourStep, OnboardingConfig, ExampleScenario, defaultOnboardingConfig, defaultExampleScenario

-}

import Types.DeviceType exposing (DeviceType(..))
import Types.Equipment exposing (Excavator, Truck)



-- ONBOARDING STATE


type OnboardingState
    = NotStarted
    | WelcomeShown
    | TourInProgress Int -- step number
    | ExampleShown
    | Completed


type TourStep
    = IntroStep
    | EquipmentStep
    | ProjectFormStep
    | ResultsStep
    | CompletionStep



-- ONBOARDING CONFIGURATION


type alias OnboardingConfig =
    { tourSteps : List TourStep
    , gestureEnabled : Bool
    , overlayStyle : String
    , skipButtonEnabled : Bool
    , exampleScenario : ExampleScenario
    }



-- EXAMPLE SCENARIO


type alias ExampleScenario =
    { projectName : String
    , description : String
    , excavatorSpec : Excavator
    , truckSpec : Truck
    , pondLength : Float
    , pondWidth : Float
    , pondDepth : Float
    , workHoursPerDay : Float
    , expectedTimeline : Int -- days
    , explanation : String
    }



-- DEFAULT CONFIGURATION


{-| Get onboarding configuration based on device type
-}
defaultOnboardingConfig : DeviceType -> OnboardingConfig
defaultOnboardingConfig deviceType =
    case deviceType of
        Mobile ->
            { tourSteps = simplifiedTourSteps
            , gestureEnabled = True
            , overlayStyle = mobileOverlayClasses
            , skipButtonEnabled = True
            , exampleScenario = defaultExampleScenario
            }

        Tablet ->
            { tourSteps = standardTourSteps
            , gestureEnabled = True
            , overlayStyle = tabletOverlayClasses
            , skipButtonEnabled = True
            , exampleScenario = defaultExampleScenario
            }

        Desktop ->
            { tourSteps = detailedTourSteps
            , gestureEnabled = False
            , overlayStyle = desktopOverlayClasses
            , skipButtonEnabled = True
            , exampleScenario = defaultExampleScenario
            }



-- TOUR STEP CONFIGURATIONS


simplifiedTourSteps : List TourStep
simplifiedTourSteps =
    [ IntroStep, ProjectFormStep, ResultsStep, CompletionStep ]


standardTourSteps : List TourStep
standardTourSteps =
    [ IntroStep, EquipmentStep, ProjectFormStep, ResultsStep, CompletionStep ]


detailedTourSteps : List TourStep
detailedTourSteps =
    [ IntroStep, EquipmentStep, ProjectFormStep, ResultsStep, CompletionStep ]



-- OVERLAY STYLING CLASSES


mobileOverlayClasses : String
mobileOverlayClasses =
    "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60 backdrop-blur-sm px-4"


tabletOverlayClasses : String
tabletOverlayClasses =
    "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 backdrop-blur-sm px-8"


desktopOverlayClasses : String
desktopOverlayClasses =
    "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 backdrop-blur-sm"



-- DEFAULT EXAMPLE SCENARIO


defaultExampleScenario : ExampleScenario
defaultExampleScenario =
    { projectName = "Small Residential Pond"
    , description = "A typical backyard pond project for a homeowner adding a decorative water feature to their landscaping."
    , excavatorSpec =
        { id = "example-excavator"
        , bucketCapacity = 2.5
        , cycleTime = 2.0
        , name = "CAT 320 Excavator"
        , isActive = True
        }
    , truckSpec =
        { id = "example-truck"
        , capacity = 12.0
        , roundTripTime = 15.0
        , name = "Volvo A30G Truck"
        , isActive = True
        }
    , pondLength = 50.0
    , pondWidth = 30.0
    , pondDepth = 6.0
    , workHoursPerDay = 8.0
    , expectedTimeline = 1
    , explanation = "This example shows excavation for about 333 cubic yards of soil, which our calculator estimates will take about 1 day with proper equipment balance."
    }
