module Utils.DeviceDetector exposing (detectDevice, shouldShowAdvancedFeatures, adaptComponentForDevice)

{-| Device detection and responsive utilities

@docs detectDevice, shouldShowAdvancedFeatures, adaptComponentForDevice

-}

import Browser.Dom as Dom
import Task
import Types.DeviceType exposing (DeviceType(..))


{-| Detect device type from current window size
-}
detectDevice : () -> Cmd (Result Dom.Error { width : Int, height : Int })
detectDevice _ =
    Task.attempt identity
        (Task.map (\viewport -> { width = round viewport.viewport.width, height = round viewport.viewport.height })
            Dom.getViewport)


{-| Determine if advanced features should be shown based on device capabilities
Mobile devices get simplified interface, desktop gets full features
-}
shouldShowAdvancedFeatures : DeviceType -> Bool
shouldShowAdvancedFeatures deviceType =
    case deviceType of
        Mobile ->
            False

        Tablet ->
            True

        Desktop ->
            True


{-| Adapt component behavior for specific device types
This is a placeholder for component-specific adaptations
-}
adaptComponentForDevice : DeviceType -> a -> a
adaptComponentForDevice _ component =
    component