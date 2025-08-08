module Components.ProjectForm exposing
    ( view, FormData, FormMsg(..), initFormData, updateFormData
    , inputFieldWithUnit
    )

{-| OPTION 3: Progressive Disclosure with localStorage persistence

This version tracks whether the user has seen the info banner before
using browser localStorage, showing it only to first-time users.

@docs view, FormData, FormMsg, initFormData, updateFormData

-}

import Html exposing (Html, button, div, input, label, span, text)
import Html.Attributes exposing (class, id, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput)
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


{-| Render the project input form with progressive disclosure
Shows banner only to first-time users based on localStorage state
-}
view : DeviceType -> FormData -> Bool -> Bool -> msg -> (ExcavatorField -> String -> msg) -> (TruckField -> String -> msg) -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> Html msg
view deviceType formData checkingStorage infoBannerSeen markSeenMsg excavatorMsg truckMsg pondMsg projectMsg =
    div [ class (Components.getFormClasses deviceType) ]
        [ -- Info banner with progressive disclosure
          if checkingStorage then
            -- Show loading state while checking localStorage
            div [ class "mb-6 p-4 bg-gray-50 border border-gray-200 rounded-md animate-pulse" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-shrink-0" ]
                        [ div [ class "w-4 h-4 bg-gray-300 rounded" ] [] ]
                    , div [ class "ml-3 flex-1" ]
                        [ div [ class "h-4 bg-gray-300 rounded w-3/4" ] [] ]
                    ]
                ]
          else if not infoBannerSeen then
            -- Show banner for first-time users
            div [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
                [ div [ class "flex items-start" ]
                    [ div [ class "flex-shrink-0" ]
                        [ span [ class "text-blue-400" ] [ text "👋" ] ]
                    , div [ class "ml-3 flex-1" ]
                        [ div [ class "font-medium text-blue-800 mb-1" ]
                            [ text "Welcome to Pond Digging Calculator!" ]
                        , div [ class "text-blue-700" ]
                            [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                        ]
                    , div [ class "ml-3 flex-shrink-0" ]
                        [ button
                            [ onClick markSeenMsg
                            , class "text-blue-400 hover:text-blue-600 font-bold text-lg leading-none focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
                            , title "Got it, don't show this again"
                            ]
                            [ text "×" ]
                        ]
                    ]
                ]
          else
            -- Hide banner for returning users
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


{-| Implementation Guide for Progressive Disclosure:

To implement this version, you need to add localStorage support:

1. Add ports to Main.elm:
```elm
port setLocalStorage : (String, String) -> Cmd msg
port getLocalStorage : String -> Cmd msg
port gotLocalStorage : (String -> msg) -> Sub msg
```

2. Add JavaScript to index.html:
```javascript
app.ports.setLocalStorage.subscribe(function([key, value]) {
    try {
        localStorage.setItem(key, value);
    } catch (e) {
        console.warn('Could not save to localStorage:', e);
    }
});

app.ports.getLocalStorage.subscribe(function(key) {
    try {
        const value = localStorage.getItem(key) || "";
        app.ports.gotLocalStorage.send(value);
    } catch (e) {
        console.warn('Could not read from localStorage:', e);
        app.ports.gotLocalStorage.send("");
    }
});
```

3. Update Model:
```elm
type alias Model =
    { -- existing fields
    , checkingInfoBannerStatus : Bool
    , infoBannerSeen : Bool
    }
```

4. Add Messages:
```elm
type Msg
    = -- existing messages
    | CheckInfoBannerStatus
    | InfoBannerStatusReceived String
    | MarkInfoBannerSeen
```

5. Update init and update functions as shown in the Storage module guide.

Benefits:
- Professional user experience
- Respects user preferences across sessions
- Reduces cognitive load for return users
- Graceful degradation if localStorage unavailable

This provides the best long-term user experience for a production application.

-}