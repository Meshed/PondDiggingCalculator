module Utils.Debounce exposing (DebounceState, initDebounce, getDelayForDevice, shouldDebounce, updateDebounceState)

{-| Input debouncing utility for real-time calculations

@docs DebounceState, initDebounce, getDelayForDevice, shouldDebounce, updateDebounceState

-}


-- TYPES


type alias DebounceState =
    { lastInputTime : Float
    , delay : Float
    }


-- CONFIGURATION


{-| Default debounce delay as per story requirements
-}
defaultDelay : Float
defaultDelay =
    300.0


{-| Device-specific delays for mobile vs desktop
-}
getDelayForDevice : String -> Float
getDelayForDevice deviceType =
    case deviceType of
        "Mobile" ->
            500.0 -- Longer delay for mobile devices

        _ ->
            defaultDelay -- 300ms for desktop


-- INITIALIZATION


{-| Initialize debounce state
-}
initDebounce : DebounceState
initDebounce =
    { lastInputTime = 0.0
    , delay = defaultDelay
    }


-- DEBOUNCE LOGIC


{-| Check if enough time has passed since last input to trigger calculation
-}
shouldDebounce : Float -> DebounceState -> Bool
shouldDebounce currentTime debounceState =
    (currentTime - debounceState.lastInputTime) >= debounceState.delay


{-| Update debounce state with new input time
-}
updateDebounceState : Float -> DebounceState -> DebounceState
updateDebounceState currentTime debounceState =
    { debounceState | lastInputTime = currentTime }