module Types.DeviceType exposing (DeviceType(..), fromWindowSize)

{-| Device type definitions for responsive design support

@docs DeviceType, fromWindowSize

-}

-- DEVICE TYPE


{-| Device type enumeration based on screen breakpoints
Mobile: < 768px
Tablet: 768px - 1024px
Desktop: > 1024px
-}
type DeviceType
    = Mobile -- < 768px
    | Tablet -- 768px - 1024px
    | Desktop -- > 1024px


{-| Determine device type from window dimensions
-}
fromWindowSize : { width : Int, height : Int } -> DeviceType
fromWindowSize { width } =
    if width < 768 then
        Mobile

    else if width <= 1024 then
        Tablet

    else
        Desktop
