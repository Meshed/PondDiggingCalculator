module Utils.DeviceDetector exposing (detectDevice, shouldShowAdvancedFeatures, adaptComponentForDevice, isMobileUserAgent)

{-| Device detection and responsive utilities

@docs detectDevice, shouldShowAdvancedFeatures, adaptComponentForDevice, isMobileUserAgent

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


{-| Check if user agent string indicates mobile device
Returns True for common mobile user agents
-}
isMobileUserAgent : String -> Bool
isMobileUserAgent userAgent =
    let
        lowerAgent = String.toLower userAgent
        mobileKeywords = 
            [ "android"
            , "webos"
            , "iphone"
            , "ipad"
            , "ipod"
            , "blackberry"
            , "windows phone"
            , "mobile"
            , "tablet"
            ]
    in
    List.any (\keyword -> String.contains keyword lowerAgent) mobileKeywords