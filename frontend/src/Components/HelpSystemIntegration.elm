module Components.HelpSystemIntegration exposing (view, viewHelpButton, viewHelpModal, viewOnboardingHelpPrompt)

{-| Help system integration for onboarding and discoverability

@docs view, viewHelpButton, viewHelpModal, viewOnboardingHelpPrompt

-}

import Html exposing (Html, a, button, div, h2, h3, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, target, type_)
import Html.Events exposing (onClick)
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg)
import Types.Model exposing (Model)
import Types.Onboarding exposing (OnboardingState(..))
import Utils.Config exposing (ValidationRules)
import Utils.HelpContent exposing (HelpContent, getHelpContent)



-- MAIN VIEW


{-| Main help system integration view
-}
view : Model -> Html Msg
view model =
    div []
        [ -- Discoverable help button (fixed positioned)
          viewHelpButton model.deviceType

        -- Help modal (if open) - fixed positioned overlay
        , if model.helpTooltipState == Just "help-modal" then
            viewHelpModal model.deviceType model.config

          else
            text ""

        -- Onboarding help prompt (for users who completed onboarding) - fixed positioned
        , if shouldShowHelpPrompt model then
            viewOnboardingHelpPrompt model.deviceType

          else
            text ""
        ]



-- HELP BUTTON


{-| Discoverable help button with context-aware positioning
-}
viewHelpButton : DeviceType -> Html Msg
viewHelpButton deviceType =
    let
        buttonClasses =
            getHelpButtonClasses deviceType

        iconClasses =
            "w-5 h-5 mr-2"
    in
    button
        [ class buttonClasses
        , type_ "button"
        , onClick (Types.Messages.ShowHelpTooltip "help-modal")
        , id "main-help-button"
        ]
        [ span [ class iconClasses ] [ text "❓" ]
        , text (getHelpButtonText deviceType)
        ]


{-| Get help button styling based on device type
-}
getHelpButtonClasses : DeviceType -> String
getHelpButtonClasses deviceType =
    case deviceType of
        Mobile ->
            "fixed bottom-4 right-4 z-30 bg-blue-600 hover:bg-blue-700 text-white rounded-full p-3 shadow-lg flex items-center"

        Tablet ->
            "fixed bottom-6 right-6 z-30 bg-blue-600 hover:bg-blue-700 text-white rounded-lg px-4 py-3 shadow-lg flex items-center"

        Desktop ->
            "fixed bottom-6 right-6 z-30 bg-blue-600 hover:bg-blue-700 text-white rounded-lg px-4 py-3 shadow-lg flex items-center"


{-| Get help button text based on device type
-}
getHelpButtonText : DeviceType -> String
getHelpButtonText deviceType =
    case deviceType of
        Mobile ->
            ""

        -- Icon only on mobile
        _ ->
            "Help & Tips"



-- HELP MODAL


{-| Comprehensive help modal with FAQ and feature overview
-}
viewHelpModal : DeviceType -> Maybe { a | validation : ValidationRules } -> Html Msg
viewHelpModal deviceType maybeConfig =
    let
        modalClasses =
            getHelpModalClasses deviceType
    in
    div [ class "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50" ]
        [ div [ class modalClasses ]
            [ -- Modal header
              div [ class "flex items-center justify-between p-6 border-b border-gray-200" ]
                [ h2 [ class "text-xl font-bold text-gray-900" ]
                    [ text "Help & Calculator Guide" ]
                , button
                    [ class "text-gray-400 hover:text-gray-600 text-2xl font-bold"
                    , type_ "button"
                    , onClick (Types.Messages.HideHelpTooltip "help-modal")
                    ]
                    [ text "×" ]
                ]

            -- Modal content
            , div [ class "p-6 max-h-96 overflow-y-auto" ]
                [ viewHelpSections deviceType maybeConfig ]

            -- Modal footer
            , div [ class "flex items-center justify-between p-6 border-t border-gray-200 bg-gray-50" ]
                [ button
                    [ class "text-blue-600 hover:text-blue-800 font-medium"
                    , type_ "button"
                    , onClick Types.Messages.StartGuidedTour
                    ]
                    [ text "🎯 Take the Tour Again" ]
                , button
                    [ class "bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg"
                    , type_ "button"
                    , onClick (Types.Messages.HideHelpTooltip "help-modal")
                    ]
                    [ text "Got it!" ]
                ]
            ]
        ]


{-| Get help modal styling based on device type
-}
getHelpModalClasses : DeviceType -> String
getHelpModalClasses deviceType =
    case deviceType of
        Mobile ->
            "bg-white rounded-lg shadow-2xl w-full max-w-sm mx-4"

        _ ->
            "bg-white rounded-lg shadow-2xl w-full max-w-2xl mx-4"



-- HELP CONTENT SECTIONS


{-| Help modal content sections
-}
viewHelpSections : DeviceType -> Maybe { a | validation : ValidationRules } -> Html Msg
viewHelpSections deviceType maybeConfig =
    div [ class "space-y-6" ]
        [ -- Quick Start section
          viewQuickStartSection deviceType

        -- Field Help section
        , case maybeConfig of
            Just config ->
                viewFieldHelpSection config.validation

            Nothing ->
                text ""

        -- FAQ section
        , viewFAQSection deviceType

        -- Calculator Tips section
        , viewCalculatorTipsSection deviceType
        ]


{-| Quick start guide section
-}
viewQuickStartSection : DeviceType -> Html Msg
viewQuickStartSection deviceType =
    div []
        [ h3 [ class "text-lg font-semibold text-gray-900 mb-3" ]
            [ text "🚀 Quick Start Guide" ]
        , case deviceType of
            Mobile ->
                viewMobileQuickStart

            _ ->
                viewDesktopQuickStart
        ]


viewMobileQuickStart : Html Msg
viewMobileQuickStart =
    div [ class "text-gray-700 space-y-2" ]
        [ p [] [ text "1. Enter your pond dimensions (length, width, depth)" ]
        , p [] [ text "2. Adjust equipment settings if needed" ]
        , p [] [ text "3. Set your daily work hours" ]
        , p [] [ text "4. View timeline results instantly!" ]
        ]


viewDesktopQuickStart : Html Msg
viewDesktopQuickStart =
    div [ class "text-gray-700 space-y-2" ]
        [ p [] [ text "1. Configure your equipment fleet (excavators and trucks)" ]
        , p [] [ text "2. Enter pond dimensions and project details" ]
        , p [] [ text "3. Review timeline calculations and bottleneck analysis" ]
        , p [] [ text "4. Optimize equipment balance for efficiency" ]
        ]


{-| Field-specific help section
-}
viewFieldHelpSection : ValidationRules -> Html Msg
viewFieldHelpSection validationRules =
    div []
        [ h3 [ class "text-lg font-semibold text-gray-900 mb-3" ]
            [ text "📋 Field Help" ]
        , p [ class "text-gray-600 mb-3" ]
            [ text "Hover over the ? icons next to fields for detailed help, or click on any field name below:" ]
        , div [ class "grid grid-cols-1 md:grid-cols-2 gap-3" ]
            [ viewFieldHelpItem validationRules "pondLength" "Pond Length"
            , viewFieldHelpItem validationRules "pondWidth" "Pond Width"
            , viewFieldHelpItem validationRules "pondDepth" "Pond Depth"
            , viewFieldHelpItem validationRules "excavatorBucketCapacity" "Excavator Bucket"
            , viewFieldHelpItem validationRules "truckCapacity" "Truck Capacity"
            , viewFieldHelpItem validationRules "workHours" "Work Hours"
            ]
        ]


{-| Individual field help item
-}
viewFieldHelpItem : ValidationRules -> String -> String -> Html Msg
viewFieldHelpItem validationRules fieldId displayName =
    button
        [ class "text-left p-3 bg-gray-50 hover:bg-gray-100 rounded-lg border"
        , type_ "button"
        , onClick (Types.Messages.ShowHelpTooltip fieldId)
        ]
        [ span [ class "font-medium text-gray-900" ] [ text displayName ]
        , case getHelpContent validationRules fieldId of
            Just content ->
                p [ class "text-sm text-gray-600 mt-1" ]
                    [ text (String.left 100 content.description ++ "...") ]

            Nothing ->
                text ""
        ]


{-| FAQ section
-}
viewFAQSection : DeviceType -> Html Msg
viewFAQSection deviceType =
    div []
        [ h3 [ class "text-lg font-semibold text-gray-900 mb-3" ]
            [ text "❓ Frequently Asked Questions" ]
        , div [ class "space-y-4" ]
            [ viewFAQItem "How accurate are the timeline calculations?"
                "Calculations are based on industry-standard equipment performance and include realistic efficiency factors. Actual times may vary based on soil conditions, weather, and operator skill."
            , viewFAQItem "Can I save my calculations?"
                "Currently, calculations are session-based. Your equipment configurations and project data will be preserved while using the calculator."
            , viewFAQItem "What if I have mixed equipment types?"
                (case deviceType of
                    Mobile ->
                        "On mobile, you can configure one excavator and one truck. For complex fleet management, use the desktop version."

                    _ ->
                        "You can add multiple excavators and trucks with different specifications to model your actual fleet composition."
                )
            , viewFAQItem "Why is my timeline longer than expected?"
                "Timeline estimates include realistic efficiency factors and account for equipment coordination. Check for bottlenecks in the results panel - often adding trucks or adjusting equipment balance can improve efficiency."
            ]
        ]


{-| FAQ item component
-}
viewFAQItem : String -> String -> Html Msg
viewFAQItem question answer =
    div [ class "border-l-4 border-blue-200 pl-4" ]
        [ p [ class "font-medium text-gray-900 mb-1" ]
            [ text question ]
        , p [ class "text-gray-700 text-sm" ]
            [ text answer ]
        ]


{-| Calculator tips section
-}
viewCalculatorTipsSection : DeviceType -> Html Msg
viewCalculatorTipsSection deviceType =
    div []
        [ h3 [ class "text-lg font-semibold text-gray-900 mb-3" ]
            [ text "💡 Pro Tips" ]
        , ul [ class "space-y-2 text-gray-700" ]
            [ li [ class "flex items-start" ]
                [ span [ class "mr-2" ] [ text "•" ]
                , text "Match truck capacity to excavator bucket size (4-6 buckets per truck load)"
                ]
            , li [ class "flex items-start" ]
                [ span [ class "mr-2" ] [ text "•" ]
                , text "Consider site access - tight spaces require smaller equipment"
                ]
            , li [ class "flex items-start" ]
                [ span [ class "mr-2" ] [ text "•" ]
                , text "Factor in soil type - clay takes longer to excavate than sand"
                ]
            , case deviceType of
                Mobile ->
                    li [ class "flex items-start" ]
                        [ span [ class "mr-2" ] [ text "•" ]
                        , text "For complex projects, use the desktop version for detailed fleet management"
                        ]

                _ ->
                    li [ class "flex items-start" ]
                        [ span [ class "mr-2" ] [ text "•" ]
                        , text "Watch the bottleneck analysis to optimize your equipment balance"
                        ]
            , li [ class "flex items-start" ]
                [ span [ class "mr-2" ] [ text "•" ]
                , text "Add extra time for weather delays and unexpected soil conditions"
                ]
            ]
        ]



-- ONBOARDING HELP PROMPT


{-| Help prompt for users who have completed onboarding
-}
viewOnboardingHelpPrompt : DeviceType -> Html Msg
viewOnboardingHelpPrompt deviceType =
    let
        promptClasses =
            getHelpPromptClasses deviceType
    in
    div [ class promptClasses ]
        [ p [ class "text-sm text-blue-800" ]
            [ text "💡 Need help? Click the "
            , span [ class "font-medium" ] [ text "Help & Tips" ]
            , text " button for detailed guidance!"
            ]
        , button
            [ class "ml-2 text-xs text-blue-600 hover:text-blue-800 underline"
            , type_ "button"
            , onClick (Types.Messages.ShowHelpTooltip "help-modal")
            ]
            [ text "Show Help" ]
        ]


{-| Help prompt styling based on device type
-}
getHelpPromptClasses : DeviceType -> String
getHelpPromptClasses deviceType =
    case deviceType of
        Mobile ->
            "fixed top-4 left-4 right-4 z-40 bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-center justify-between shadow-lg"

        _ ->
            "fixed top-6 left-6 right-6 z-40 bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-center justify-between shadow-lg max-w-md"



-- HELPER FUNCTIONS


{-| Determine if help prompt should be shown
-}
shouldShowHelpPrompt : Model -> Bool
shouldShowHelpPrompt model =
    model.onboardingState
        == Completed
        && model.isFirstTimeUser
        == False
        && model.helpTooltipState
        == Nothing
