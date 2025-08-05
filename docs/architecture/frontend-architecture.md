# Frontend Architecture

## Component Architecture

**Component Organization:**
```
src/
├── Main.elm                    -- Application entry point and main update loop
├── Types/
│   ├── Model.elm              -- Core application state types
│   ├── Equipment.elm          -- Equipment-related types
│   ├── Validation.elm         -- Validation types and errors
│   └── Messages.elm           -- All application messages
├── Components/
│   ├── EquipmentCard.elm      -- Individual equipment item display
│   ├── EquipmentList.elm      -- Equipment fleet management
│   ├── ProjectForm.elm        -- Project configuration inputs
│   ├── ResultsPanel.elm       -- Calculation results display
│   ├── ValidationMessage.elm  -- Error message components
│   └── DeviceDetector.elm     -- Responsive behavior component
├── Pages/
│   ├── Desktop.elm           -- Desktop/tablet full interface
│   ├── Mobile.elm            -- Mobile simplified interface
│   └── Common.elm            -- Shared page elements
├── Utils/
│   ├── Validation.elm        -- Input validation functions
│   ├── Calculations.elm      -- Core calculation engine
│   ├── Formatting.elm        -- Display formatting utilities
│   ├── Storage.elm           -- Local storage operations
│   └── Config.elm            -- Configuration loading
└── Styles/
    ├── Theme.elm             -- Tailwind class definitions
    ├── Components.elm        -- Component-specific styles
    └── Responsive.elm        -- Device-specific styling
```

## State Management Architecture

**State Structure:**
```elm
-- Centralized application state following Elm Architecture
type alias Model =
    { -- Core Data
      excavators : List Excavator
    , trucks : List Truck  
    , projectConfig : ProjectConfiguration
    , appConfig : AppConfiguration
    
    -- UI State
    , deviceType : DeviceType
    , currentPage : Page
    , validationState : ValidationState
    , loadingState : LoadingState
    
    -- Calculation State  
    , currentResult : Maybe CalculationResult
    , calculationInProgress : Bool
    , lastCalculationTime : Time.Posix
    
    -- Session State
    , nextEquipmentId : Int
    , hasUnsavedChanges : Bool
    , sessionStartTime : Time.Posix
    }
```

**State Management Patterns:**
- **Single Source of Truth:** All state lives in one Model
- **Immutable Updates:** State changes create new Model instances
- **Command Pattern:** Side effects handled through Cmd Msg
- **Subscriptions:** Real-time updates through Browser events
- **Local Storage Sync:** Automatic persistence of key data
