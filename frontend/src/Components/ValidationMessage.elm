module Components.ValidationMessage exposing (viewValidationMessage, viewErrorIcon)

{-| Validation message display component for showing user-friendly error messages

@docs viewValidationMessage, viewErrorIcon

-}

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (attribute, class)
import Styles.Theme exposing (errorIconClass, getErrorMessageClasses)
import Types.DeviceType exposing (DeviceType(..))
import Types.Validation exposing (ValidationError(..))
import Utils.Validation exposing (errorToString)


{-| Display a validation error message with device-appropriate styling and accessibility
-}
viewValidationMessage : DeviceType -> ValidationError -> Html msg
viewValidationMessage deviceType error =
    let
        messageClasses =
            getErrorMessageClasses deviceType

        errorText =
            errorToString error

        showIcon =
            deviceType /= Mobile
    in
    div
        [ class messageClasses
        , attribute "role" "alert"
        , attribute "aria-live" "polite"
        ]
        [ if showIcon then
            viewErrorIcon

          else
            text ""
        , span
            [ class
                (if showIcon then
                    "ml-2"

                 else
                    ""
                )
            ]
            [ text errorText ]
        ]


{-| Display error icon for desktop and tablet interfaces
-}
viewErrorIcon : Html msg
viewErrorIcon =
    span
        [ class errorIconClass
        , attribute "aria-hidden" "true"
        ]
        [ text "⚠" ]
