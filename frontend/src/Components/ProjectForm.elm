module Components.ProjectForm exposing
    ( view, FormData, FormMsg(..), initFormData, updateFormData
    , inputFieldWithUnit
    )

{-| Input form for pond digging project parameters

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
import Utils.Validation as Validation



-- TYPES


type alias FormData =
    { excavatorCapacity : String
    , excavatorCycleTime : String
    , truckCapacity : String
    , truckRoundTripTime : String
    , workHoursPerDay : String
    , pondLength : String
    , pondWidth : String
    , pondDepth : String
    , errors : List ( String, String ) -- (fieldName, errorMessage)
    }


type FormMsg
    = UpdateExcavatorCapacity String
    | UpdateExcavatorCycleTime String
    | UpdateTruckCapacity String
    | UpdateTruckRoundTripTime String
    | UpdateWorkHours String
    | UpdatePondLength String
    | UpdatePondWidth String
    | UpdatePondDepth String
    | ClearForm



-- INIT


{-| Initialize form data with default values from configuration
-}
initFormData : Defaults -> FormData
initFormData defaults =
    let
        -- Use first excavator and truck from lists as default
        defaultExcavator =
            List.head defaults.excavators
                |> Maybe.withDefault { bucketCapacity = 2.5, cycleTime = 2.0, name = "Default Excavator" }

        defaultTruck =
            List.head defaults.trucks
                |> Maybe.withDefault { capacity = 12.0, roundTripTime = 15.0, name = "Default Truck" }
    in
    { excavatorCapacity = String.fromFloat defaultExcavator.bucketCapacity
    , excavatorCycleTime = String.fromFloat defaultExcavator.cycleTime
    , truckCapacity = String.fromFloat defaultTruck.capacity
    , truckRoundTripTime = String.fromFloat defaultTruck.roundTripTime
    , workHoursPerDay = String.fromFloat defaults.project.workHoursPerDay
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
        UpdateExcavatorCapacity value ->
            { formData | excavatorCapacity = value }

        UpdateExcavatorCycleTime value ->
            { formData | excavatorCycleTime = value }

        UpdateTruckCapacity value ->
            { formData | truckCapacity = value }

        UpdateTruckRoundTripTime value ->
            { formData | truckRoundTripTime = value }

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
view : DeviceType -> FormData -> Bool -> msg -> (ExcavatorField -> String -> msg) -> (TruckField -> String -> msg) -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> Html msg
view deviceType formData infoBannerDismissed dismissMsg excavatorMsg truckMsg pondMsg projectMsg =
    div [ class (Components.getFormClasses deviceType) ]
        [ -- Info banner about defaults (dismissible)
          if not infoBannerDismissed then
            div [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
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
                            ]
                            [ text "×" ]
                        ]
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
                    , id = "excavator-capacity"
                    , value = formData.excavatorCapacity
                    , placeholder = "e.g., 2.5"
                    , onInput = excavatorMsg BucketCapacity
                    , error = getFieldError "excavatorCapacity" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Excavator Cycle Time"
                    , unit = "minutes"
                    , helpText = "Time to dig, swing, dump, and return to digging position"
                    , id = "excavator-cycle"
                    , value = formData.excavatorCycleTime
                    , placeholder = "e.g., 0.5"
                    , onInput = excavatorMsg CycleTime
                    , error = getFieldError "excavatorCycleTime" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Capacity"
                    , unit = "cubic yards"
                    , helpText = "Maximum volume of material the truck can carry"
                    , id = "truck-capacity"
                    , value = formData.truckCapacity
                    , placeholder = "e.g., 15"
                    , onInput = truckMsg TruckCapacity
                    , error = getFieldError "truckCapacity" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Truck Round-trip Time"
                    , unit = "minutes"
                    , helpText = "Total time for truck to travel to dump site, unload, and return"
                    , id = "truck-roundtrip"
                    , value = formData.truckRoundTripTime
                    , placeholder = "e.g., 30"
                    , onInput = truckMsg RoundTripTime
                    , error = getFieldError "truckRoundTripTime" formData.errors
                    }
                ]
            , -- Project Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Project Parameters" ]
                , inputFieldWithUnit deviceType
                    { label = "Work Hours per Day"
                    , unit = "hours"
                    , helpText = "Number of productive work hours per day"
                    , id = "work-hours"
                    , value = formData.workHoursPerDay
                    , placeholder = "e.g., 8"
                    , onInput = projectMsg WorkHours
                    , error = getFieldError "workHoursPerDay" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Length"
                    , unit = "feet"
                    , helpText = "Length of the pond to be excavated"
                    , id = "pond-length"
                    , value = formData.pondLength
                    , placeholder = "e.g., 100"
                    , onInput = pondMsg PondLength
                    , error = getFieldError "pondLength" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Width"
                    , unit = "feet"
                    , helpText = "Width of the pond to be excavated"
                    , id = "pond-width"
                    , value = formData.pondWidth
                    , placeholder = "e.g., 50"
                    , onInput = pondMsg PondWidth
                    , error = getFieldError "pondWidth" formData.errors
                    }
                , inputFieldWithUnit deviceType
                    { label = "Pond Depth"
                    , unit = "feet"
                    , helpText = "Average depth of the pond to be excavated"
                    , id = "pond-depth"
                    , value = formData.pondDepth
                    , placeholder = "e.g., 10"
                    , onInput = pondMsg PondDepth
                    , error = getFieldError "pondDepth" formData.errors
                    }
                ]
            ]
        ]



-- HELPER FUNCTIONS


type alias InputFieldConfig msg =
    { label : String
    , id : String
    , value : String
    , placeholder : String
    , onInput : String -> msg
    , error : Maybe String
    }


type alias InputFieldWithUnitConfig msg =
    { label : String
    , unit : String
    , helpText : String
    , id : String
    , value : String
    , placeholder : String
    , onInput : String -> msg
    , error : Maybe String
    }


{-| Reusable input field component with validation display
-}
inputField : DeviceType -> InputFieldConfig msg -> Html msg
inputField deviceType config =
    div [ class "space-y-2" ]
        [ label
            [ class "block text-sm font-medium text-gray-700"
            , Html.Attributes.for config.id
            ]
            [ text config.label ]
        , input
            [ type_ "number"
            , id config.id
            , value config.value
            , placeholder config.placeholder
            , onInput config.onInput
            , class (inputClasses deviceType config.error)
            ]
            []
        , case config.error of
            Just errorMsg ->
                span [ class (Components.getValidationMessageClasses deviceType) ] [ text errorMsg ]

            Nothing ->
                span [ class "text-sm text-gray-500" ] []
        ]


{-| Get CSS classes for input based on validation state and device type
-}
inputClasses : DeviceType -> Maybe String -> String
inputClasses deviceType error =
    let
        baseClasses =
            Theme.getInputClasses deviceType
    in
    case error of
        Just _ ->
            baseClasses ++ " border-red-300 text-red-900 placeholder-red-300 focus:border-red-500 focus:ring-red-500"

        Nothing ->
            baseClasses ++ " border-gray-300 placeholder-gray-400 focus:border-indigo-500 focus:ring-indigo-500"


{-| Enhanced input field component with unit display and help text
-}
inputFieldWithUnit : DeviceType -> InputFieldWithUnitConfig msg -> Html msg
inputFieldWithUnit deviceType config =
    let
        labelClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "block text-sm font-semibold text-gray-700 mb-1"

                Types.DeviceType.Tablet ->
                    "block text-sm font-semibold text-gray-700 mb-1"

                _ ->
                    "block text-sm font-medium text-gray-700"

        helpTextClass =
            case deviceType of
                Types.DeviceType.Desktop ->
                    "text-xs text-gray-500 mt-1"

                Types.DeviceType.Tablet ->
                    "text-xs text-gray-500 mt-1"

                _ ->
                    "hidden"
    in
    div [ class "space-y-2" ]
        [ label
            [ class labelClass
            , Html.Attributes.for config.id
            ]
            [ text config.label
            , span [ class "ml-2 text-xs font-normal text-gray-500" ]
                [ text ("(" ++ config.unit ++ ")") ]
            ]
        , div [ class "input-with-unit" ]
            [ input
                [ type_ "number"
                , id config.id
                , value config.value
                , placeholder config.placeholder
                , onInput config.onInput
                , class (inputClasses deviceType config.error ++ " no-spinners")
                ]
                []
            , div [ class "unit-display" ]
                [ span [] [ text config.unit ]
                ]
            ]
        , if deviceType /= Types.DeviceType.Mobile then
            div [ class helpTextClass ] [ text config.helpText ]

          else
            text ""
        , case config.error of
            Just errorMsg ->
                span [ class (Components.getValidationMessageClasses deviceType) ] [ text errorMsg ]

            Nothing ->
                text ""
        ]


{-| Get error message for a specific field
-}
getFieldError : String -> List ( String, String ) -> Maybe String
getFieldError fieldName errors =
    errors
        |> List.filter (\( field, _ ) -> field == fieldName)
        |> List.head
        |> Maybe.map Tuple.second
