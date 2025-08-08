module Components.ProjectForm exposing
    ( view, FormData, FormMsg(..), initFormData, updateFormData
    , inputFieldWithUnit
    )

{-| OPTION 2: Show banner only when values are still defaults

This version of ProjectForm shows the info banner only when the form
contains default values, hiding it once users start customizing.

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


{-| Check if form data still contains default values
-}
hasDefaultValues : FormData -> Bool
hasDefaultValues formData =
    formData.excavatorCapacity == "2.5"
        && formData.excavatorCycleTime == "2"
        && formData.truckCapacity == "12"
        && formData.truckRoundTripTime == "15"
        && formData.workHoursPerDay == "8"
        && formData.pondLength == "40"
        && formData.pondWidth == "25"
        && formData.pondDepth == "5"


{-| Render the project input form with validation
Shows info banner only when form contains default values
-}
view : DeviceType -> FormData -> (ExcavatorField -> String -> msg) -> (TruckField -> String -> msg) -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> Html msg
view deviceType formData excavatorMsg truckMsg pondMsg projectMsg =
    div [ class (Components.getFormClasses deviceType) ]
        [ -- Info banner about defaults (only when still using defaults)
          if hasDefaultValues formData then
            div [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                    , div [ class "ml-3" ]
                        [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                    , div [ class "ml-auto text-xs text-blue-600" ]
                        [ text "(This message will disappear when you modify any value)" ]
                    ]
                ]
          else
            text ""
        , div [ class (Responsive.getGridClasses deviceType) ]
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
                    }
                , inputFieldWithUnit deviceType
                    { label = "Excavator Cycle Time"
                    , unit = "minutes"
                    , helpText = "Time to complete one dig-swing-dump cycle"
                    , value = formData.excavatorCycleTime
                    , onInput = excavatorMsg CycleTime
                    , id = "excavator-cycle"
                    , testId = "excavator-cycle-input"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Capacity"
                    , unit = "cubic yards"
                    , helpText = "Volume of material the truck can carry per load"
                    , value = formData.truckCapacity
                    , onInput = truckMsg TruckCapacity
                    , id = "truck-capacity"
                    , testId = "truck-capacity-input"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Round Trip Time"
                    , unit = "minutes"
                    , helpText = "Time for truck to travel to dump site and return"
                    , value = formData.truckRoundTripTime
                    , onInput = truckMsg RoundTripTime
                    , id = "truck-roundtrip"
                    , testId = "truck-roundtrip-input"
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
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Length"
                    , unit = "feet"
                    , helpText = "Length of the pond to be excavated"
                    , value = formData.pondLength
                    , onInput = pondMsg PondLength
                    , id = "pond-length"
                    , testId = "pond-length-input"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Width"
                    , unit = "feet"
                    , helpText = "Width of the pond to be excavated"
                    , value = formData.pondWidth
                    , onInput = pondMsg PondWidth
                    , id = "pond-width"
                    , testId = "pond-width-input"
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Depth"
                    , unit = "feet"
                    , helpText = "Average depth of the pond"
                    , value = formData.pondDepth
                    , onInput = pondMsg PondDepth
                    , id = "pond-depth"
                    , testId = "pond-depth-input"
                    }
                ]
            ]
        ]


{-| Input field with unit display and help text
-}
inputFieldWithUnit : DeviceType -> { label : String, unit : String, helpText : String, value : String, onInput : String -> msg, id : String, testId : String } -> Html msg
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
                , placeholder ("Enter " ++ String.toLower config.label)
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


{-| Usage Instructions:

To use this version instead of the dismissible version:

1. Replace the import in Main.elm:
   ```elm
   import Components.ProjectForm as ProjectForm
   ```
   With:
   ```elm
   import Components.ProjectForm-Option2-DefaultsOnly as ProjectForm
   ```

2. Update the view call in Main.elm to remove the banner-related parameters:
   ```elm
   ProjectForm.view model.deviceType formData ExcavatorFieldChanged TruckFieldChanged PondFieldChanged ProjectFieldChanged
   ```

3. Remove the infoBannerDismissed field from the Model and DismissInfoBanner message.

Benefits:
- Automatically hides the message once users start customizing
- No additional state management required
- Progressive disclosure that adapts to user behavior
- Clean user experience for return users

-}