module Main exposing (main)

import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Types.Model exposing (Model, Flags)
import Types.Messages exposing (Msg(..))
import Utils.Config exposing (loadConfig)


-- MAIN

main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


-- MODEL

init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { message = "Pond Digging Calculator - Foundation Setup Complete"
      , config = Nothing
      }
    , loadConfig ConfigLoaded
    )


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        
        ConfigLoaded result ->
            case result of
                Ok config ->
                    ( { model | config = Just config }, Cmd.none )
                
                Err _ ->
                    ( model, Cmd.none )
        
        EquipmentAdded _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )
        
        EquipmentRemoved _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )
        
        EquipmentUpdated _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )
        
        ValidationFailed _ ->
            -- TODO: Implement in future story
            ( model, Cmd.none )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


-- VIEW

view : Model -> Html Msg
view model =
    div [ class "container mx-auto p-4" ]
        [ div [ class "text-center" ]
            [ text model.message ]
        ]