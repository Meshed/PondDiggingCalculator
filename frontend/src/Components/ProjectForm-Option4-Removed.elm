module Components.ProjectForm exposing
    ( view, FormData, FormMsg(..), initFormData, updateFormData
    , inputFieldWithUnit
    )

{-| OPTION 4: Complete removal of info banner

This version completely removes the info banner, providing the cleanest
interface with minimal visual distraction. Users can infer the defaults
from the pre-filled form fields.

@docs view, FormData, FormMsg, initFormData, updateFormData

-}

import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (class, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Styles.Components as Components
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType)
import Types.Fields exposing (ExcavatorField(..), PondField(..), ProjectField(..), TruckField(..))
import Types.Validation exposing (ValidationError)
import Utils.Config exposing (Config, Defaults)



-- FORM DATA MODEL


type alias FormData =
    { excavatorCapacity : String
    , excavatorCycleTime : String
    , truckCapacity : String
    , truckRoundTripTime : String
    , workHoursPerDay : String
    , pondLength : String
    , pondWidth : String
    , pondDepth : String
    }


type FormMsg
    = ClearForm



-- FORM INITIALIZATION


{-| Initialize form data from configuration defaults
-}
initFormData : Defaults -> FormData
initFormData defaults =
    case ( List.head defaults.excavators, List.head defaults.trucks ) of
        ( Just excavator, Just truck ) ->
            { excavatorCapacity = String.fromFloat excavator.bucketCapacity
            , excavatorCycleTime = String.fromFloat excavator.cycleTime
            , truckCapacity = String.fromFloat truck.capacity
            , truckRoundTripTime = String.fromFloat truck.roundTripTime
            , workHoursPerDay = String.fromFloat defaults.project.workHoursPerDay
            , pondLength = String.fromFloat defaults.project.pondLength
            , pondWidth = String.fromFloat defaults.project.pondWidth
            , pondDepth = String.fromFloat defaults.project.pondDepth
            }

        _ ->
            -- Fallback if no equipment defaults available
            { excavatorCapacity = "2.5"
            , excavatorCycleTime = "2.0"
            , truckCapacity = "12.0"
            , truckRoundTripTime = "15.0"
            , workHoursPerDay = "8.0"
            , pondLength = "40.0"
            , pondWidth = "25.0"
            , pondDepth = "5.0"
            }


{-| Update form data (placeholder - actual updates come through messages)
-}
updateFormData : FormMsg -> FormData -> FormData
updateFormData msg formData =
    case msg of
        ClearForm ->
            formData



-- VIEW


{-| Render the project input form without info banner
Clean, minimal interface focusing entirely on the input fields
-}
view : DeviceType -> FormData -> (ExcavatorField -> String -> msg) -> (TruckField -> String -> msg) -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> Html msg
view deviceType formData excavatorMsg truckMsg pondMsg projectMsg =
    div [ class (Components.getFormClasses deviceType) ]
        [ -- No info banner - clean interface
          div [ class (Responsive.getGridClasses deviceType) ]
            [ -- Equipment Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Equipment Specifications" ]
                , inputFieldWithUnit deviceType
                    { label = "Excavator Bucket Capacity"
                    , unit = "cubic yards"
                    , helpText = "Volume of material the excavator bucket can hold per scoop"
                    , value = formData.excavatorCapacity
                    , onInput = excavatorMsg BucketCapacity
                    , id = "excavator-capacity"
                    , testId = "excavator-capacity-input"
                    , placeholder = "e.g., 2.5 (typical range: 1.0-5.0)"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Excavator Cycle Time"
                    , unit = "minutes"
                    , helpText = "Time to complete one dig-swing-dump cycle"
                    , value = formData.excavatorCycleTime
                    , onInput = excavatorMsg CycleTime
                    , id = "excavator-cycle"
                    , testId = "excavator-cycle-input"
                    , placeholder = "e.g., 2.0 (typical range: 1.5-3.0)"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Capacity"
                    , unit = "cubic yards"
                    , helpText = "Volume of material the truck can carry per load"
                    , value = formData.truckCapacity
                    , onInput = truckMsg TruckCapacity
                    , id = "truck-capacity"
                    , testId = "truck-capacity-input"
                    , placeholder = "e.g., 12 (typical range: 8-20)"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Round Trip Time"
                    , unit = "minutes"
                    , helpText = "Time for truck to travel to dump site and return"
                    , value = formData.truckRoundTripTime
                    , onInput = truckMsg RoundTripTime
                    , id = "truck-roundtrip"
                    , testId = "truck-roundtrip-input"
                    , placeholder = "e.g., 15 (typical range: 10-30)"
                    }
                ]

            -- Project Section
            , div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Project Parameters" ]
                , inputFieldWithUnit deviceType
                    { label = "Work Hours per Day"
                    , unit = "hours"
                    , helpText = "Productive working hours per day on site"
                    , value = formData.workHoursPerDay
                    , onInput = projectMsg WorkHours
                    , id = "work-hours"
                    , testId = "work-hours-input"
                    , placeholder = "e.g., 8 (typical range: 6-10)"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Length"
                    , unit = "feet"
                    , helpText = "Length of the pond to be excavated"
                    , value = formData.pondLength
                    , onInput = pondMsg PondLength
                    , id = "pond-length"
                    , testId = "pond-length-input"
                    , placeholder = "Enter pond length"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Width"
                    , unit = "feet"
                    , helpText = "Width of the pond to be excavated"
                    , value = formData.pondWidth
                    , onInput = pondMsg PondWidth
                    , id = "pond-width"
                    , testId = "pond-width-input"
                    , placeholder = "Enter pond width"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Depth"
                    , unit = "feet"
                    , helpText = "Average depth of the pond"
                    , value = formData.pondDepth
                    , onInput = pondMsg PondDepth
                    , id = "pond-depth"
                    , testId = "pond-depth-input"
                    , placeholder = "Enter pond depth"
                    }
                ]
            ]
        ]


{-| Enhanced input field with better placeholder text and guidance
Since there's no info banner, we provide more guidance in placeholders and help text
-}
inputFieldWithUnit : DeviceType -> { label : String, unit : String, helpText : String, value : String, onInput : String -> msg, id : String, testId : String, placeholder : String } -> Html msg
inputFieldWithUnit deviceType config =
    div [ class "space-y-2" ]
        [ label
            [ class "block text-sm font-medium text-gray-700"
            , Html.Attributes.for config.id
            ]
            [ text config.label ]
        , div [ class "relative" ]
            [ input
                [ type_ "number"
                , id config.id
                , Html.Attributes.attribute "data-testid" config.testId
                , value config.value
                , onInput config.onInput
                , placeholder config.placeholder
                , class "block w-full pr-20 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm px-3 py-2"
                ]
                []
            , div [ class "absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none" ]
                [ span [ class "text-gray-500 sm:text-sm" ]
                    [ text config.unit ]
                ]
            ]
        , span [ class "text-xs text-gray-500" ]
            [ text config.helpText ]
        ]


{-| Implementation Guide for Complete Removal:

To use this version (simplest implementation):

1.  Replace the import in Main.elm:

        import Components.ProjectForm-Option4-Removed as ProjectForm

2.  Update the view call in Main.elm to the original signature:

        ProjectForm.view model.deviceType formData ExcavatorFieldChanged TruckFieldChanged PondFieldChanged ProjectFieldChanged

3.  Remove from Model:
      - `infoBannerDismissed : Bool` field

4.  Remove from Messages:
      - `DismissInfoBanner` message and its handler

5.  Clean up any related imports and unused code

Benefits:

  - Simplest implementation - no extra state or logic
  - Cleanest visual interface
  - Fastest loading - no banner HTML
  - Self-explanatory form with enhanced placeholders
  - Users can infer defaults from pre-filled values
  - No cognitive load from dismissing banners

Considerations:

  - New users might not immediately understand defaults are provided
  - Less explicit about the tool's capabilities
  - Relies on good placeholder text and help text for guidance

This approach works best when:

  - Your users are experienced with similar tools
  - The interface is intuitive enough without explanatory text
  - You prefer minimal, clean design over instructional UI
  - The form itself clearly communicates its purpose

Enhancement: Instead of a banner, consider adding a subtle "Using default values"
indicator near the section headers or a small info icon with tooltip for
users who need more context.

-}
