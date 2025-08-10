# Code Structure and Patterns Guide

## Elm Module Organization and Responsibilities

The Pond Digging Calculator follows a strict modular architecture with clear separation of concerns. Each module has well-defined responsibilities and minimal coupling to ensure maintainability and testability.

### Module Hierarchy Overview

```
src/
├── Main.elm                    # Application entry point and message routing
├── Types/                      # Domain models and type definitions
│   ├── Model.elm              # Central application state model
│   ├── Messages.elm           # All application messages and actions
│   ├── Equipment.elm          # Equipment domain types (Excavator, Truck)
│   ├── Validation.elm         # Validation types and error definitions
│   ├── Fields.elm             # Form field identifiers and types
│   ├── DeviceType.elm         # Device detection types
│   └── Onboarding.elm         # Onboarding state and tour definitions
├── Utils/                      # Business logic and utility functions
│   ├── Calculations.elm       # Core calculation engine (pure functions)
│   ├── Validation.elm         # Input validation logic
│   ├── Config.elm             # Configuration management
│   ├── DeviceDetector.elm     # Device type detection
│   ├── Performance.elm        # Performance monitoring utilities
│   ├── Storage.elm            # Local storage management
│   ├── Debounce.elm           # Input debouncing utilities
│   └── ExampleScenario.elm    # Example data generation
├── Components/                 # Reusable UI components
│   ├── ProjectForm.elm        # Project input form component
│   ├── ResultsPanel.elm       # Calculation results display
│   ├── EquipmentList.elm      # Equipment fleet management
│   ├── ValidationMessage.elm  # Validation error display
│   ├── HelpSystem.elm         # Context-sensitive help
│   ├── OnboardingManager.elm  # User onboarding workflow
│   └── [other components...]
├── Pages/                      # Top-level page layouts
│   ├── Desktop.elm            # Desktop interface layout
│   └── Mobile.elm             # Mobile interface layout
├── Views/                      # View rendering and device adaptation
│   └── MobileView.elm         # Mobile-specific view logic
├── Styles/                     # Styling and theme management
│   ├── Theme.elm              # Color themes and design tokens
│   ├── Components.elm         # Component-specific styling
│   └── Responsive.elm         # Responsive design utilities
└── Ports/                      # JavaScript interop
    └── Console.elm            # Browser console logging
```

## Functional Programming Patterns Used

### Pure Functions for Business Logic

**Principle**: All calculation and validation logic is implemented as pure functions that always produce the same output for the same input, with no side effects.

**Example - Core Calculation Engine**:
```elm
-- Utils/Calculations.elm
{-| Calculate excavation time for a given volume and hourly rate.
    Pure function with predictable behavior for testing.
-}
calculateExcavationTime : Float -> Float -> Float
calculateExcavationTime totalVolume hourlyRate =
    if hourlyRate <= 0 then
        0
    else
        totalVolume / hourlyRate

{-| Calculate pond volume from dimensions.
    Demonstrates composition of pure functions.
-}
calculatePondVolume : Float -> Float -> Float -> Float
calculatePondVolume length width depth =
    length * width * depth

{-| Calculate complete project timeline from pond dimensions and equipment fleet.
    Combines multiple pure calculations into a single result.
-}
calculateProjectTimeline : ProjectData -> List Equipment -> CalculationResult
calculateProjectTimeline project equipment =
    let
        totalVolume = calculatePondVolume project.length project.width project.depth
        totalHourlyRate = calculateFleetHourlyRate equipment
        excavationTime = calculateExcavationTime totalVolume totalHourlyRate
    in
    { totalVolume = totalVolume
    , excavationTime = excavationTime
    , costEstimate = calculateCost excavationTime project.hourlyRate
    , isValid = totalVolume > 0 && totalHourlyRate > 0
    }
```

### Immutable Data Transformations

**Principle**: Data is never modified in place. All updates create new data structures using functional transformation patterns.

**Example - Equipment Fleet Management**:
```elm
-- Utils/FleetManagement.elm
{-| Add new equipment to fleet, preserving immutability
-}
addEquipmentToFleet : Equipment -> List Equipment -> List Equipment
addEquipmentToFleet newEquipment existingFleet =
    newEquipment :: existingFleet

{-| Update specific equipment in fleet using map transformation
-}
updateEquipmentInFleet : EquipmentId -> (Equipment -> Equipment) -> List Equipment -> List Equipment
updateEquipmentInFleet targetId updateFn fleet =
    List.map 
        (\equipment -> 
            if equipment.id == targetId then
                updateFn equipment
            else
                equipment
        ) 
        fleet

{-| Filter active equipment using functional pipeline
-}
getActiveEquipment : List Equipment -> List Equipment
getActiveEquipment fleet =
    fleet
        |> List.filter .isActive
        |> List.sortBy .name
```

### Function Composition and Pipelines

**Principle**: Complex operations are built by composing smaller, focused functions using the pipeline operator (`|>`).

**Example - Validation Pipeline**:
```elm
-- Utils/Validation.elm
{-| Validate project inputs using functional composition
-}
validateProject : ProjectData -> Result (List ValidationError) ProjectData
validateProject project =
    project
        |> validatePondDimensions
        |> Result.andThen validateWorkHours
        |> Result.andThen validateProjectConsistency

validatePondDimensions : ProjectData -> Result ValidationError ProjectData
validatePondDimensions project =
    if project.length <= 0 || project.width <= 0 || project.depth <= 0 then
        Err (InvalidDimensions "All pond dimensions must be greater than zero")
    else
        Ok project
```

### Maybe and Result Types for Error Handling

**Principle**: Use Elm's `Maybe` and `Result` types to handle optional values and errors explicitly, making impossible states impossible.

**Example - Configuration Loading**:
```elm
-- Utils/Config.elm
{-| Load and validate configuration with explicit error handling
-}
loadConfiguration : String -> Result ConfigError Config
loadConfiguration configJson =
    case Decode.decodeString configDecoder configJson of
        Ok config ->
            validateConfigurationRanges config
                |> Result.mapError ConfigValidationError
        
        Err decodeError ->
            Err (ConfigParsingError decodeError)

{-| Get configuration with fallback for robust error recovery
-}
getConfigWithFallback : Maybe Config -> Config
getConfigWithFallback maybeConfig =
    case maybeConfig of
        Just config ->
            config
        
        Nothing ->
            fallbackConfig
```

### Custom Types for Domain Modeling

**Principle**: Use custom types instead of primitives to make domain concepts explicit and prevent invalid states.

**Example - Equipment Domain Types**:
```elm
-- Types/Equipment.elm
type Equipment
    = ExcavatorEquipment Excavator
    | TruckEquipment Truck

type alias Excavator =
    { id : EquipmentId
    , bucketCapacity : CubicYards
    , cycleTime : Minutes
    , name : String
    , isActive : Bool
    }

type alias Truck =
    { id : EquipmentId
    , capacity : CubicYards
    , roundTripTime : Minutes
    , name : String
    , isActive : Bool
    }

-- Use type aliases for clarity and type safety
type alias EquipmentId = String
type alias CubicYards = Float
type alias Minutes = Float
```

## State Management Approach

### Central Application State (Model)

**Principle**: All application state is centralized in a single `Model` record, providing a single source of truth and predictable state updates.

**Core Model Structure**:
```elm
-- Types/Model.elm
type alias Model =
    { -- Configuration and Initialization
      config : Maybe Config
    , deviceType : DeviceType
    
    -- Form State
    , formData : Maybe FormData
    , fieldValidationErrors : Dict String ValidationError
    , realTimeValidation : Bool
    
    -- Equipment Fleet
    , excavators : List Excavator
    , trucks : List Truck
    , nextExcavatorId : Int
    , nextTruckId : Int
    
    -- Calculation State
    , calculationResult : Maybe CalculationResult
    , lastValidResult : Maybe CalculationResult
    , calculationInProgress : Bool
    , hasValidationErrors : Bool
    
    -- UI State
    , showHelpPanel : Bool
    , helpTooltipState : Maybe String
    , onboardingState : OnboardingState
    , showWelcomeOverlay : Bool
    
    -- Performance and Utilities
    , performanceMetrics : PerformanceMetrics
    , debounceState : DebounceState
    , validationDebounce : Dict String Time.Posix
    }
```

### Message-Based Updates (Elm Architecture)

**Principle**: State changes are triggered by messages that describe user actions or system events. All updates are pure functions that return new state.

**Message Types**:
```elm
-- Types/Messages.elm
type Msg
    = -- Configuration and Initialization
      ConfigLoaded Config
    | DeviceTypeDetected DeviceType
    
    -- Project Form Updates
    | UpdatePondField PondField String
    | UpdateProjectField ProjectField String
    | ValidateField String
    
    -- Equipment Fleet Management
    | AddExcavator
    | RemoveExcavator EquipmentId
    | UpdateExcavator EquipmentId ExcavatorUpdate
    | AddTruck
    | RemoveTruck EquipmentId
    | UpdateTruck EquipmentId TruckUpdate
    
    -- Calculation and Validation
    | TriggerCalculation
    | CalculationComplete CalculationResult
    | ValidationError String ValidationError
    | ClearValidationErrors
    
    -- UI State Updates
    | ShowHelpTooltip String
    | HideHelpTooltip
    | ToggleHelpPanel
    | UpdateOnboardingState OnboardingState
```

### Update Function Pattern

**Principle**: The update function is the only place where state changes occur, ensuring predictable and testable state transitions.

**Update Function Structure**:
```elm
-- Main.elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePondField field value ->
            updatePondFieldHandler field value model
        
        AddExcavator ->
            addExcavatorHandler model
        
        TriggerCalculation ->
            triggerCalculationHandler model
        
        -- ... other message handlers

-- Dedicated handler functions for complex updates
updatePondFieldHandler : PondField -> String -> Model -> ( Model, Cmd Msg )
updatePondFieldHandler field value model =
    case model.formData of
        Just formData ->
            let
                updatedFormData = updatePondFieldInFormData field value formData
                updatedModel = { model | formData = Just updatedFormData }
            in
            if model.realTimeValidation then
                ( updatedModel, triggerValidationCmd field value )
            else
                ( updatedModel, Cmd.none )
        
        Nothing ->
            ( model, Cmd.none )
```

## Validation and Error Handling Patterns

### Input Validation Strategy

**Principle**: Validate all inputs at multiple layers - immediate UI feedback, form-level validation, and business logic validation.

**Validation Types**:
```elm
-- Types/Validation.elm
type ValidationError
    = Required String -- Field is required but empty
    | OutOfRange String Float Float Float -- Field value outside valid range
    | InvalidFormat String -- Field format is invalid
    | BusinessLogicError String -- Domain-specific validation error
    | ConfigurationError String -- Configuration-related error

-- Validation result type for composable validation
type ValidationResult a
    = Valid a
    | Invalid (List ValidationError)
```

**Multi-Layer Validation**:
```elm
-- Utils/Validation.elm
{-| Validate individual field inputs with immediate feedback
-}
validateFieldInput : Field -> String -> Config -> Result ValidationError Float
validateFieldInput field input config =
    input
        |> String.toFloat
        |> Result.fromMaybe (InvalidFormat "Must be a valid number")
        |> Result.andThen (validateFieldRange field config)

{-| Validate field against configuration ranges
-}
validateFieldRange : Field -> Config -> Float -> Result ValidationError Float
validateFieldRange field config value =
    let
        range = getFieldValidationRange field config
    in
    if value < range.min then
        Err (OutOfRange (fieldToString field) value range.min range.max)
    else if value > range.max then
        Err (OutOfRange (fieldToString field) value range.min range.max)
    else
        Ok value

{-| Validate complete form data for business logic consistency
-}
validateFormData : FormData -> List Equipment -> Result (List ValidationError) FormData
validateFormData formData equipment =
    let
        validationResults =
            [ validatePondDimensions formData
            , validateProjectSettings formData
            , validateEquipmentFleet equipment
            , validateProjectFeasibility formData equipment
            ]
        
        errors = validationResults |> List.filterMap Result.err |> List.concat
    in
    if List.isEmpty errors then
        Ok formData
    else
        Err errors
```

### Error Recovery Patterns

**Principle**: Provide graceful degradation and recovery from errors while maintaining application usability.

**Configuration Error Recovery**:
```elm
-- Main.elm
init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        config = 
            case loadConfiguration flags.configJson of
                Ok validConfig ->
                    validConfig
                
                Err configError ->
                    -- Log error and use fallback configuration
                    let
                        _ = Debug.log "Configuration error" configError
                    in
                    fallbackConfig
    in
    -- Continue initialization with valid configuration
    initializeModel config
```

**Calculation Error Handling**:
```elm
-- Components/ResultsPanel.elm
viewCalculationResults : Maybe CalculationResult -> Maybe CalculationResult -> Html Msg
viewCalculationResults maybeResult lastValidResult =
    case maybeResult of
        Just result ->
            if result.isValid then
                viewValidResults result
            else
                viewCalculationErrors result.errors lastValidResult
        
        Nothing ->
            case lastValidResult of
                Just lastResult ->
                    viewStaleResults lastResult -- Show last valid results
                
                Nothing ->
                    viewNoResults -- Prompt user to enter data
```

## Device-Responsive Architecture

### Device Type Detection and Adaptation

**Principle**: Detect device type and adapt both UI layout and functionality to provide optimal user experience per device.

**Device Detection**:
```elm
-- Utils/DeviceDetector.elm
type DeviceType
    = Desktop
    | Tablet
    | Mobile

detectDeviceType : Int -> Int -> DeviceType
detectDeviceType windowWidth windowHeight =
    if windowWidth >= 1024 then
        Desktop
    else if windowWidth >= 768 then
        Tablet
    else
        Mobile

-- Integration with application initialization
subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onResize (\width height ->
        DeviceTypeDetected (detectDeviceType width height)
    )
```

**Device-Specific Functionality**:
```elm
-- Pages/Desktop.elm vs Pages/Mobile.elm
viewDesktopInterface : Model -> Html Msg
viewDesktopInterface model =
    div [ class "desktop-layout" ]
        [ viewFullProjectForm model  -- Complete form with all fields
        , viewAdvancedEquipmentManager model  -- Full fleet management
        , viewDetailedResults model  -- Comprehensive results display
        , viewHelpSystem model  -- Context-sensitive help
        ]

viewMobileInterface : Model -> Html Msg  
viewMobileInterface model =
    div [ class "mobile-layout" ]
        [ viewSimplifiedForm model  -- Essential fields only
        , viewBasicEquipmentList model  -- Simplified equipment selection
        , viewSummaryResults model  -- Key results only
        , viewTouchOptimizedControls model  -- Touch-friendly interactions
        ]
```

**Responsive Component Architecture**:
```elm
-- Components/ProjectForm.elm
viewProjectForm : DeviceType -> FormData -> Html Msg
viewProjectForm deviceType formData =
    case deviceType of
        Desktop ->
            viewDesktopForm formData
        
        Tablet ->
            viewTabletForm formData
        
        Mobile ->
            viewMobileForm formData

-- Different layouts for different devices
viewDesktopForm : FormData -> Html Msg
viewDesktopForm formData =
    div [ class "form-grid desktop-grid" ]
        [ viewPondDimensionsSection formData
        , viewProjectSettingsSection formData
        , viewAdvancedOptionsSection formData
        ]

viewMobileForm : FormData -> Html Msg
viewMobileForm formData =
    div [ class "form-stack mobile-stack" ]
        [ viewEssentialFieldsOnly formData
        , viewProgressiveDisclosure formData
        ]
```

## Performance and Optimization Patterns

### Lazy Evaluation for Expensive Operations

**Principle**: Use `Html.Lazy` to prevent unnecessary re-rendering of expensive view components.

```elm
-- Components/ResultsPanel.elm
view : Model -> Html Msg
view model =
    div [ class "results-container" ]
        [ Html.Lazy.lazy2 viewCalculationResults 
            model.calculationResult 
            model.performanceMetrics
        , Html.Lazy.lazy viewEquipmentSummary model.excavators
        , Html.Lazy.lazy viewCostBreakdown model.calculationResult
        ]
```

### Input Debouncing for Real-time Validation

**Principle**: Debounce rapid user inputs to prevent excessive calculation and validation cycles.

```elm
-- Utils/Debounce.elm
type alias DebounceState =
    { pending : Dict String Time.Posix
    , delay : Float  -- milliseconds
    }

updateWithDebounce : String -> String -> Time.Posix -> DebounceState -> ( DebounceState, Bool )
updateWithDebounce fieldId value currentTime debounceState =
    let
        updatedPending = Dict.insert fieldId currentTime debounceState.pending
        shouldTrigger = checkIfShouldTrigger fieldId currentTime debounceState.delay debounceState.pending
    in
    ( { debounceState | pending = updatedPending }, shouldTrigger )

-- Integration in Main.elm update function
UpdatePondField field value ->
    case model.formData of
        Just formData ->
            let
                (newDebounceState, shouldValidate) = 
                    updateWithDebounce (fieldToString field) value currentTime model.debounceState
                
                updatedModel = 
                    { model 
                    | formData = Just (updatePondField field value formData)
                    , debounceState = newDebounceState 
                    }
                
                cmd = 
                    if shouldValidate then
                        Task.perform (always TriggerCalculation) (Task.succeed ())
                    else
                        Cmd.none
            in
            ( updatedModel, cmd )
```

### Memory Management and Cleanup

**Principle**: Prevent memory leaks by cleaning up unused state and avoiding accumulation of stale data.

```elm
-- Utils/Performance.elm
type alias PerformanceMetrics =
    { calculationTime : Float
    , validationTime : Float
    , renderTime : Float
    , memoryUsage : Float
    }

cleanupStaleData : Model -> Model
cleanupStaleData model =
    { model
    | fieldValidationErrors = 
        model.fieldValidationErrors
            |> Dict.filter (\_ error -> isRecentError error)
    , validationDebounce = 
        model.validationDebounce
            |> Dict.filter (\_ time -> isRecentTime time)
    }
```

This comprehensive code structure and patterns guide ensures the Pond Digging Calculator maintains clean architecture, functional programming principles, and optimal performance while remaining maintainable and extensible.