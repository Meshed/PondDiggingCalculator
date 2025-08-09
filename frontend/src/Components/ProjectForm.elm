module Components.ProjectForm exposing (view, FormData, FormMsg(..), initFormData, updateFormData)

{-| Input form for pond digging project parameters

@docs view, FormData, FormMsg, initFormData, updateFormData

-}

import Components.HelpTooltip as HelpTooltip
import Html exposing (Html, button, div, input, label, span, text)
import Html.Attributes exposing (class, id, placeholder, step, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType)
import Types.Fields exposing (PondField(..), ProjectField(..))
import Types.Validation exposing (ValidationError)
import Utils.Config exposing (Config, Defaults)
import Utils.HelpContent exposing (getHelpContent)
import Utils.Validation as Validation



-- TYPES


type alias FormData =
    { workHoursPerDay : String
    , pondLength : String
    , pondWidth : String
    , pondDepth : String
    , errors : List ( String, String ) -- (fieldName, errorMessage)
    }


type FormMsg
    = UpdateWorkHours String
    | UpdatePondLength String
    | UpdatePondWidth String
    | UpdatePondDepth String
    | ClearForm



-- INIT


{-| Initialize form data with default values from configuration
-}
initFormData : Defaults -> FormData
initFormData defaults =
    { workHoursPerDay = String.fromFloat defaults.project.workHoursPerDay
    , pondLength = String.fromFloat defaults.project.pondLength
    , pondWidth = String.fromFloat defaults.project.pondWidth
    , pondDepth = String.fromFloat defaults.project.pondDepth
    , errors = []
    }



-- UPDATE


{-| Update form data based on user input
-}
updateFormData : FormMsg -> FormData -> FormData
updateFormData msg formData =
    case msg of
        UpdateWorkHours value ->
            { formData | workHoursPerDay = value }

        UpdatePondLength value ->
            { formData | pondLength = value }

        UpdatePondWidth value ->
            { formData | pondWidth = value }

        UpdatePondDepth value ->
            { formData | pondDepth = value }

        ClearForm ->
            -- Reset to default config values - this should be handled at the Main level
            -- For now, just return the same formData, actual reset will happen in Main
            formData



-- VIEW


{-| Render the project input form with validation
-}
view : DeviceType -> FormData -> Bool -> msg -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> (String -> msg) -> (String -> msg) -> Maybe String -> Html msg
view deviceType formData infoBannerDismissed dismissMsg pondMsg projectMsg showHelpMsg hideHelpMsg activeTooltipId =
    div [ class "space-y-4" ]
        [ -- Info banner about defaults (dismissible)
          if not infoBannerDismissed then
            div
                [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md"
                , Html.Attributes.attribute "data-testid" "info-banner"
                ]
                [ div [ class "flex items-start" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                    , div [ class "ml-3 flex-1" ]
                        [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                    , div [ class "ml-3 flex-shrink-0" ]
                        [ button
                            [ onClick dismissMsg
                            , class "text-blue-400 hover:text-blue-600 font-bold text-lg leading-none"
                            , title "Dismiss this message"
                            , Html.Attributes.attribute "data-testid" "dismiss-banner-button"
                            ]
                            [ text "×" ]
                        ]
                    ]
                ]

          else
            text ""
        , let
            typography =
                Theme.getTypographyScale deviceType
          in
          div [ class "space-y-4" ]
            [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                [ text "Project Parameters" ]
            , div [ class "grid grid-cols-2 gap-3" ]
                [ div []
                    [ label [ class (typography.body ++ " block text-gray-700 mb-1 flex items-center") ]
                        [ text "Work Hours per Day (hours)"
                        , HelpTooltip.helpIcon deviceType "workHours" showHelpMsg hideHelpMsg activeTooltipId
                        ]
                    , input
                        [ type_ "number"
                        , class "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        , id "work-hours"
                        , Html.Attributes.attribute "data-testid" "work-hours-input"
                        , value formData.workHoursPerDay
                        , placeholder "e.g., 8"
                        , onInput (projectMsg WorkHours)
                        , step "0.1"
                        , Html.Attributes.min "0.1"
                        ]
                        []
                    ]
                , div []
                    [ label [ class (typography.body ++ " block text-gray-700 mb-1 flex items-center") ]
                        [ text "Pond Length (feet)"
                        , HelpTooltip.helpIcon deviceType "pondLength" showHelpMsg hideHelpMsg activeTooltipId
                        ]
                    , input
                        [ type_ "number"
                        , class "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        , id "pond-length"
                        , Html.Attributes.attribute "data-testid" "pond-length-input"
                        , value formData.pondLength
                        , placeholder "e.g., 100"
                        , onInput (pondMsg PondLength)
                        , step "0.1"
                        , Html.Attributes.min "0.1"
                        ]
                        []
                    ]
                ]
            , div [ class "grid grid-cols-2 gap-3" ]
                [ div []
                    [ label [ class (typography.body ++ " block text-gray-700 mb-1 flex items-center") ]
                        [ text "Pond Width (feet)"
                        , HelpTooltip.helpIcon deviceType "pondWidth" showHelpMsg hideHelpMsg activeTooltipId
                        ]
                    , input
                        [ type_ "number"
                        , class "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        , id "pond-width"
                        , Html.Attributes.attribute "data-testid" "pond-width-input"
                        , value formData.pondWidth
                        , placeholder "e.g., 50"
                        , onInput (pondMsg PondWidth)
                        , step "0.1"
                        , Html.Attributes.min "0.1"
                        ]
                        []
                    ]
                , div []
                    [ label [ class (typography.body ++ " block text-gray-700 mb-1 flex items-center") ]
                        [ text "Pond Depth (feet)"
                        , HelpTooltip.helpIcon deviceType "pondDepth" showHelpMsg hideHelpMsg activeTooltipId
                        ]
                    , input
                        [ type_ "number"
                        , class "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        , id "pond-depth"
                        , Html.Attributes.attribute "data-testid" "pond-depth-input"
                        , value formData.pondDepth
                        , placeholder "e.g., 10"
                        , onInput (pondMsg PondDepth)
                        , step "0.1"
                        , Html.Attributes.min "0.1"
                        ]
                        []
                    ]
                ]
            ]
        ]



-- HELPER FUNCTIONS


{-| Get error message for a specific field
-}
getFieldError : String -> List ( String, String ) -> Maybe String
getFieldError fieldName errors =
    errors
        |> List.filter (\( field, _ ) -> field == fieldName)
        |> List.head
        |> Maybe.map Tuple.second
