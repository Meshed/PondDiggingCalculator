module Utils.Storage exposing (saveToLocalStorage, loadFromLocalStorage, storageKey)

{-| Local storage operations for client-side persistence

@docs saveToLocalStorage, loadFromLocalStorage, storageKey

-}

-- STORAGE UTILITIES


storageKey : String
storageKey =
    "pond-calculator-config"


{-| Save configuration to local storage
Note: In a real implementation, this would use ports to JavaScript
For now, this is a placeholder for the storage interface
-}
saveToLocalStorage : String -> Cmd msg
saveToLocalStorage value =
    -- TODO: Implement with ports when needed
    Cmd.none


{-| Load configuration from local storage
Note: In a real implementation, this would use ports to JavaScript
For now, this is a placeholder for the storage interface
-}
loadFromLocalStorage : (Maybe String -> msg) -> Cmd msg
loadFromLocalStorage toMsg =
    -- TODO: Implement with ports when needed
    Cmd.none
