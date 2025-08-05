module Components.ProjectForm exposing (view, FormData, FormMsg(..), initFormData, updateFormData)

{-| Input form for pond digging project parameters

@docs view, FormData, FormMsg, initFormData, updateFormData

-}

import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (class, id, placeholder, type_, value)
import Html.Events exposing (onInput)
import Styles.Components as Components
import Styles.Responsive as Responsive
import Styles.Theme as Theme
import Types.DeviceType exposing (DeviceType)
import Types.Fields exposing (ExcavatorField(..), TruckField(..), PondField(..), ProjectField(..))
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



-- INIT


{-| Initialize form data with default values from configuration
-}
initFormData : Defaults -> FormData
initFormData defaults =
    { excavatorCapacity = String.fromFloat defaults.excavator.bucketCapacity
    , excavatorCycleTime = String.fromFloat defaults.excavator.cycleTime
    , truckCapacity = String.fromFloat defaults.truck.capacity
    , truckRoundTripTime = String.fromFloat defaults.truck.roundTripTime
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



-- VIEW


{-| Render the project input form with validation
-}
view : DeviceType -> FormData -> (ExcavatorField -> String -> msg) -> (TruckField -> String -> msg) -> (PondField -> String -> msg) -> (ProjectField -> String -> msg) -> Html msg
view deviceType formData excavatorMsg truckMsg pondMsg projectMsg =
    div [ class (Components.getFormClasses deviceType) ]
        [ -- Info banner about defaults
          div [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
            [ div [ class "flex" ]
                [ div [ class "flex-shrink-0" ]
                    [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                , div [ class "ml-3" ]
                    [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                ]
            ]
        , div [ class (Responsive.getGridClasses deviceType) ]
            [ -- Equipment Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Equipment Specifications" ]
                , inputField deviceType
                    { label = "Excavator Bucket Capacity (cubic yards)"
                    , id = "excavator-capacity"
                    , value = formData.excavatorCapacity
                    , placeholder = ""
                    , onInput = excavatorMsg BucketCapacity
                    , error = getFieldError "excavatorCapacity" formData.errors
                    }
                , inputField deviceType
                    { label = "Excavator Cycle Time (minutes)"
                    , id = "excavator-cycle"
                    , value = formData.excavatorCycleTime
                    , placeholder = ""
                    , onInput = excavatorMsg CycleTime
                    , error = getFieldError "excavatorCycleTime" formData.errors
                    }
                , inputField deviceType
                    { label = "Truck Capacity (cubic yards)"
                    , id = "truck-capacity"
                    , value = formData.truckCapacity
                    , placeholder = ""
                    , onInput = truckMsg TruckCapacity
                    , error = getFieldError "truckCapacity" formData.errors
                    }
                , inputField deviceType
                    { label = "Truck Round-trip Time (minutes)"
                    , id = "truck-roundtrip"
                    , value = formData.truckRoundTripTime
                    , placeholder = ""
                    , onInput = truckMsg RoundTripTime
                    , error = getFieldError "truckRoundTripTime" formData.errors
                    }
                ]
            , -- Project Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Project Parameters" ]
                , inputField deviceType
                    { label = "Work Hours per Day"
                    , id = "work-hours"
                    , value = formData.workHoursPerDay
                    , placeholder = ""
                    , onInput = projectMsg WorkHours
                    , error = getFieldError "workHoursPerDay" formData.errors
                    }
                , inputField deviceType
                    { label = "Pond Length (feet)"
                    , id = "pond-length"
                    , value = formData.pondLength
                    , placeholder = ""
                    , onInput = pondMsg PondLength
                    , error = getFieldError "pondLength" formData.errors
                    }
                , inputField deviceType
                    { label = "Pond Width (feet)"
                    , id = "pond-width"
                    , value = formData.pondWidth
                    , placeholder = ""
                    , onInput = pondMsg PondWidth
                    , error = getFieldError "pondWidth" formData.errors
                    }
                , inputField deviceType
                    { label = "Pond Depth (feet)"
                    , id = "pond-depth"
                    , value = formData.pondDepth
                    , placeholder = ""
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


{-| Get error message for a specific field
-}
getFieldError : String -> List ( String, String ) -> Maybe String
getFieldError fieldName errors =
    errors
        |> List.filter (\( field, _ ) -> field == fieldName)
        |> List.head
        |> Maybe.map Tuple.second
