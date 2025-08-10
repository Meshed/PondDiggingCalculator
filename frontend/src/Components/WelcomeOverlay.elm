module Components.WelcomeOverlay exposing (view, viewWelcomeContent)

{-| Welcome overlay component for first-time visitors

@docs view, viewWelcomeContent

-}

import Html exposing (Html, button, div, h1, h2, p, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Types.DeviceType exposing (DeviceType(..))
import Types.Messages exposing (Msg)
import Types.Onboarding exposing (OnboardingConfig)



-- VIEW


{-| Main welcome overlay view
-}
view : OnboardingConfig -> DeviceType -> (Msg -> msg) -> Html msg
view config deviceType toMsg =
    div [ class config.overlayStyle ]
        [ div
            [ class "bg-white rounded-lg shadow-2xl max-w-md w-full mx-auto p-8 relative"
            , id "welcome-overlay"
            ]
            [ viewWelcomeContent config deviceType toMsg ]
        ]


{-| Welcome overlay content
-}
viewWelcomeContent : OnboardingConfig -> DeviceType -> (Msg -> msg) -> Html msg
viewWelcomeContent config deviceType toMsg =
    div [ class "text-center" ]
        [ -- Welcome header
          div [ class "mb-6" ]
            [ h1
                [ class "text-2xl font-bold text-gray-900 mb-2" ]
                [ text "Welcome to the Pond Digging Calculator!" ]
            , h2
                [ class "text-lg text-gray-600" ]
                [ text "Calculate excavation timelines for your pond projects" ]
            ]

        -- Feature highlights
        , div [ class "mb-8" ]
            [ viewFeatureList deviceType ]

        -- Call-to-action buttons
        , div [ class "space-y-3" ]
            [ -- Start Tour Button
              button
                [ class "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg text-lg transition-colors duration-200"
                , type_ "button"
                , onClick (toMsg Types.Messages.StartGuidedTour)
                ]
                [ text "Take the Tour" ]

            -- Try Example Button
            , button
                [ class "w-full bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-6 rounded-lg text-lg transition-colors duration-200"
                , type_ "button"
                , onClick (toMsg Types.Messages.LoadExampleScenario)
                ]
                [ text "Try Example Project" ]

            -- Skip to Calculator Button
            , button
                [ class "w-full bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200"
                , type_ "button"
                , onClick (toMsg Types.Messages.SkipOnboarding)
                ]
                [ text "Skip to Calculator" ]

            -- Help system reference
            , div [ class "text-center mt-3" ]
                [ p [ class "text-xs text-gray-500" ]
                    [ text "💡 Need help later? Look for the "
                    , span [ class "font-medium" ] [ text "Help & Tips" ]
                    , text " button!"
                    ]
                ]
            ]
        ]


{-| Feature list based on device type
-}
viewFeatureList : DeviceType -> Html msg
viewFeatureList deviceType =
    case deviceType of
        Mobile ->
            viewMobileFeatures

        Tablet ->
            viewTabletFeatures

        Desktop ->
            viewDesktopFeatures


viewMobileFeatures : Html msg
viewMobileFeatures =
    div [ class "space-y-2 text-left" ]
        [ viewFeatureItem "📱" "Mobile-optimized interface"
        , viewFeatureItem "⚡" "Quick calculations"
        , viewFeatureItem "📊" "Professional results"
        ]


viewTabletFeatures : Html msg
viewTabletFeatures =
    div [ class "space-y-2 text-left" ]
        [ viewFeatureItem "🔧" "Equipment fleet management"
        , viewFeatureItem "📐" "Precise pond dimensions"
        , viewFeatureItem "📊" "Detailed timeline reports"
        , viewFeatureItem "📱" "Touch-friendly interface"
        ]


viewDesktopFeatures : Html msg
viewDesktopFeatures =
    div [ class "space-y-2 text-left" ]
        [ viewFeatureItem "🚜" "Multi-equipment fleet management"
        , viewFeatureItem "📏" "Precise pond dimension calculations"
        , viewFeatureItem "📊" "Comprehensive timeline analysis"
        , viewFeatureItem "⚙️" "Advanced configuration options"
        , viewFeatureItem "📈" "Real-time calculation updates"
        ]


viewFeatureItem : String -> String -> Html msg
viewFeatureItem icon description =
    div [ class "flex items-center space-x-3" ]
        [ span [ class "text-lg" ] [ text icon ]
        , span [ class "text-gray-700" ] [ text description ]
        ]
