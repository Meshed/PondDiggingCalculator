module Components.GuidedTour exposing (view, viewTourContent, TourStepContent)

{-| Guided tour component with progressive feature highlighting

@docs view, viewTourContent, TourStepContent

-}

import Html exposing (Html, button, div, h3, p, span, text)
import Html.Attributes exposing (class, id, style, type_)
import Html.Events exposing (onClick)
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg)
import Types.Onboarding exposing (OnboardingConfig, TourStep(..))



-- TYPES


type alias TourStepContent =
    { title : String
    , description : String
    , targetElement : String -- CSS selector or ID
    , position : TourPosition
    }


type TourPosition
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Center



-- VIEW


{-| Main guided tour view with backdrop and highlighted element
-}
view : OnboardingConfig -> DeviceType -> TourStep -> Int -> Int -> (Msg -> msg) -> Html msg
view config deviceType currentStep stepNumber totalSteps toMsg =
    let
        stepContent =
            getStepContent deviceType currentStep

        backdropStyle =
            getTourBackdropStyle

        tooltipStyle =
            getTooltipStyle stepContent.position deviceType
    in
    div [ class "fixed inset-0 z-40" ]
        [ -- Dark backdrop with spotlight hole
          div
            [ class "fixed inset-0 bg-black bg-opacity-60"
            , style "backdrop-filter" "blur(2px)"
            ]
            []

        -- Highlighted element spotlight (placeholder - would need JS for dynamic positioning)
        , div
            [ class "absolute border-4 border-blue-400 rounded-lg shadow-2xl bg-transparent"
            , id "tour-spotlight"

            -- Placeholder positioning - in real implementation would be calculated via ports
            , style "top" "200px"
            , style "left" "300px"
            , style "width" "300px"
            , style "height" "200px"
            , style "pointer-events" "none"
            ]
            []

        -- Tour tooltip/content
        , div
            [ class tooltipStyle
            , id "tour-tooltip"
            ]
            [ viewTourContent config deviceType stepContent stepNumber totalSteps toMsg ]
        ]


{-| Tour step content display
-}
viewTourContent : OnboardingConfig -> DeviceType -> TourStepContent -> Int -> Int -> (Msg -> msg) -> Html msg
viewTourContent config deviceType stepContent stepNumber totalSteps toMsg =
    div [ class "bg-white rounded-lg shadow-2xl p-6 max-w-sm w-full" ]
        [ -- Step indicator
          div [ class "flex items-center justify-between mb-4" ]
            [ span [ class "text-sm text-gray-500" ]
                [ text ("Step " ++ String.fromInt stepNumber ++ " of " ++ String.fromInt totalSteps) ]
            , button
                [ class "text-gray-400 hover:text-gray-600 text-xl font-bold"
                , type_ "button"
                , onClick (toMsg Types.Messages.CompleteTour)
                ]
                [ text "×" ]
            ]

        -- Step content
        , div [ class "mb-6" ]
            [ h3 [ class "text-lg font-semibold text-gray-900 mb-2" ]
                [ text stepContent.title ]
            , p [ class "text-gray-600 leading-relaxed" ]
                [ text stepContent.description ]
            ]

        -- Navigation buttons
        , div [ class "flex justify-between items-center" ]
            [ -- Previous button (conditionally shown)
              if stepNumber > 1 then
                button
                    [ class "px-4 py-2 text-gray-600 hover:text-gray-800 font-medium"
                    , type_ "button"
                    , onClick (toMsg Types.Messages.PreviousTourStep)
                    ]
                    [ text "← Previous" ]

              else
                div [] []

            -- Empty placeholder
            -- Next/Finish button
            , if stepNumber < totalSteps then
                button
                    [ class "bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-lg transition-colors duration-200"
                    , type_ "button"
                    , onClick (toMsg Types.Messages.NextTourStep)
                    ]
                    [ text "Next →" ]

              else
                button
                    [ class "bg-green-600 hover:bg-green-700 text-white font-semibold py-2 px-6 rounded-lg transition-colors duration-200"
                    , type_ "button"
                    , onClick (toMsg Types.Messages.CompleteTour)
                    ]
                    [ text "Finish Tour" ]
            ]
        ]



-- STEP CONTENT


{-| Get content for each tour step based on device type
-}
getStepContent : DeviceType -> TourStep -> TourStepContent
getStepContent deviceType step =
    case step of
        IntroStep ->
            { title = "Welcome to the Pond Calculator"
            , description = "This tool helps you estimate excavation timelines for pond projects. Let's take a quick tour of the key features."
            , targetElement = "#main-container"
            , position = Center
            }

        EquipmentStep ->
            case deviceType of
                Mobile ->
                    { title = "Equipment Configuration"
                    , description = "Configure your excavation equipment. On mobile, you can manage one excavator and truck for quick calculations."
                    , targetElement = ".equipment-section"
                    , position = TopRight
                    }

                _ ->
                    { title = "Fleet Management"
                    , description = "Manage your equipment fleet here. Add multiple excavators and trucks to optimize your project timeline."
                    , targetElement = ".equipment-section"
                    , position = TopRight
                    }

        ProjectFormStep ->
            { title = "Project Details"
            , description = "Enter your pond dimensions and work schedule. The calculator updates in real-time as you type."
            , targetElement = "#project-form"
            , position = BottomLeft
            }

        ResultsStep ->
            { title = "Timeline Results"
            , description = "View detailed timeline calculations, equipment utilization, and bottleneck analysis to optimize your project."
            , targetElement = "#results-panel"
            , position = TopLeft
            }

        CompletionStep ->
            { title = "You're All Set!"
            , description = "You now know the key features. Remember: you can access detailed help anytime using the 'Help & Tips' button, and hover over any ? icon for field-specific guidance."
            , targetElement = "#main-container"
            , position = Center
            }



-- STYLING


{-| Get backdrop style for tour overlay
-}
getTourBackdropStyle : String
getTourBackdropStyle =
    "fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm z-40"


{-| Get tooltip positioning style based on target position and device
-}
getTooltipStyle : TourPosition -> DeviceType -> String
getTooltipStyle position deviceType =
    let
        baseClasses =
            "absolute z-50"

        positionClasses =
            case position of
                TopLeft ->
                    "top-4 left-4"

                TopRight ->
                    "top-4 right-4"

                BottomLeft ->
                    "bottom-4 left-4"

                BottomRight ->
                    "bottom-4 right-4"

                Center ->
                    "top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2"

        deviceClasses =
            case deviceType of
                Mobile ->
                    "mx-4"

                _ ->
                    ""
    in
    String.join " " [ baseClasses, positionClasses, deviceClasses ]
