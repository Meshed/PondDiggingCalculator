module Components.ProjectForm exposing (view, FormData, FormMsg(..), initFormData, updateFormData)

{-| Input form for pond digging project parameters

@docs view, FormData, FormMsg, initFormData, updateFormData

-}

import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (class, id, placeholder, type_, value)
import Html.Events exposing (onInput)
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
view : FormData -> (FormMsg -> msg) -> Html msg
view formData toMsg =
    div [ class "project-form max-w-4xl mx-auto p-6 bg-white rounded-lg shadow-lg" ]
        [ -- Info banner about defaults
          div [ class "mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md" ]
            [ div [ class "flex" ]
                [ div [ class "flex-shrink-0" ]
                    [ span [ class "text-blue-400" ] [ text "ℹ️" ] ]
                , div [ class "ml-3" ]
                    [ text "Default values for common equipment are pre-loaded. Adjust any values to match your specific project requirements." ]
                ]
            ]
        , div [ class "grid grid-cols-1 md:grid-cols-2 gap-6" ]
            [ -- Equipment Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Equipment Specifications" ]
                , inputField
                    { label = "Excavator Bucket Capacity (cubic yards)"
                    , id = "excavator-capacity"
                    , value = formData.excavatorCapacity
                    , placeholder = ""
                    , onInput = UpdateExcavatorCapacity >> toMsg
                    , error = getFieldError "excavatorCapacity" formData.errors
                    }
                , inputField
                    { label = "Excavator Cycle Time (minutes)"
                    , id = "excavator-cycle"
                    , value = formData.excavatorCycleTime
                    , placeholder = ""
                    , onInput = UpdateExcavatorCycleTime >> toMsg
                    , error = getFieldError "excavatorCycleTime" formData.errors
                    }
                , inputField
                    { label = "Truck Capacity (cubic yards)"
                    , id = "truck-capacity"
                    , value = formData.truckCapacity
                    , placeholder = ""
                    , onInput = UpdateTruckCapacity >> toMsg
                    , error = getFieldError "truckCapacity" formData.errors
                    }
                , inputField
                    { label = "Truck Round-trip Time (minutes)"
                    , id = "truck-roundtrip"
                    , value = formData.truckRoundTripTime
                    , placeholder = ""
                    , onInput = UpdateTruckRoundTripTime >> toMsg
                    , error = getFieldError "truckRoundTripTime" formData.errors
                    }
                ]
            , -- Project Section
              div [ class "space-y-4" ]
                [ div [ class "text-lg font-semibold text-gray-800 mb-4" ]
                    [ text "Project Parameters" ]
                , inputField
                    { label = "Work Hours per Day"
                    , id = "work-hours"
                    , value = formData.workHoursPerDay
                    , placeholder = ""
                    , onInput = UpdateWorkHours >> toMsg
                    , error = getFieldError "workHoursPerDay" formData.errors
                    }
                , inputField
                    { label = "Pond Length (feet)"
                    , id = "pond-length"
                    , value = formData.pondLength
                    , placeholder = ""
                    , onInput = UpdatePondLength >> toMsg
                    , error = getFieldError "pondLength" formData.errors
                    }
                , inputField
                    { label = "Pond Width (feet)"
                    , id = "pond-width"
                    , value = formData.pondWidth
                    , placeholder = ""
                    , onInput = UpdatePondWidth >> toMsg
                    , error = getFieldError "pondWidth" formData.errors
                    }
                , inputField
                    { label = "Pond Depth (feet)"
                    , id = "pond-depth"
                    , value = formData.pondDepth
                    , placeholder = ""
                    , onInput = UpdatePondDepth >> toMsg
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
inputField : InputFieldConfig msg -> Html msg
inputField config =
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
            , class (inputClasses config.error)
            ]
            []
        , case config.error of
            Just errorMsg ->
                span [ class "text-sm text-red-600" ] [ text errorMsg ]

            Nothing ->
                span [ class "text-sm text-gray-500" ] []
        ]


{-| Get CSS classes for input based on validation state
-}
inputClasses : Maybe String -> String
inputClasses error =
    let
        baseClasses =
            "block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 sm:text-sm"
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
