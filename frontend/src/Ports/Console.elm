port module Ports.Console exposing (logToConsole, logErrorToConsole, logPerformanceToConsole)

{-| Console logging ports for development debugging

This module provides ports for logging to the browser console.
In production builds, these ports will be no-ops to avoid performance overhead.

@docs logToConsole, logErrorToConsole, logPerformanceToConsole

-}

-- CONSOLE LOGGING PORTS


{-| Log general information to console (development only)
-}
port logToConsole : String -> Cmd msg


{-| Log error information to console (development only)
-}
port logErrorToConsole : String -> Cmd msg


{-| Log performance information to console (development only)
-}
port logPerformanceToConsole : String -> Cmd msg
