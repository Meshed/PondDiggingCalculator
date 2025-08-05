# Components

## Main Application Component
**Responsibility:** Root component that manages overall application state, device detection, and coordinates between child components

**Key Interfaces:**
- Initializes application with configuration loading
- Manages device type detection and responsive behavior
- Coordinates state updates between all child components
- Handles top-level error boundaries and fallbacks

**Dependencies:** ConfigurationLoader, DeviceDetector, all child components

**Technology Stack:** Elm main module, Tailwind CSS for base styling, configuration JSON loading

## EquipmentFleetManager
**Responsibility:** Manages the collection of excavators and trucks, handles adding/removing equipment, and maintains fleet state

**Key Interfaces:**
- `addExcavator : Model -> ( Model, Cmd Msg )`
- `removeExcavator : EquipmentId -> Model -> ( Model, Cmd Msg )`
- `updateExcavator : EquipmentId -> ExcavatorUpdate -> Model -> ( Model, Cmd Msg )`
- `addTruck : Model -> ( Model, Cmd Msg )`
- `removeTruck : EquipmentId -> Model -> ( Model, Cmd Msg )`
- `updateTruck : EquipmentId -> TruckUpdate -> Model -> ( Model, Cmd Msg )`

**Dependencies:** ValidationEngine for equipment validation, CalculationEngine for immediate recalculation

**Technology Stack:** Elm update functions, Tailwind CSS for equipment cards, device-responsive behavior

## ProjectConfigurationManager
**Responsibility:** Handles project settings including pond dimensions, work hours, and project metadata

**Key Interfaces:**
- `updatePondDimensions : PondDimensions -> Model -> ( Model, Cmd Msg )`
- `calculatePondVolume : Float -> Float -> Float -> Float`
- `updateWorkHours : Float -> Model -> ( Model, Cmd Msg )`
- `validateProjectConfig : ProjectConfiguration -> Result ValidationError ()`

**Dependencies:** ValidationEngine for input validation, CalculationEngine for volume calculations

**Technology Stack:** Elm forms with Tailwind CSS styling, responsive input layout

## CalculationEngine
**Responsibility:** Core business logic component that performs pond digging timeline calculations using pure functional algorithms

**Key Interfaces:**
- `performCalculation : List Excavator -> List Truck -> ProjectConfiguration -> Result CalculationError CalculationResult`
- `calculateExcavatorProductivity : List Excavator -> Float`
- `calculateTruckProductivity : List Truck -> Float`
- `identifyBottleneck : Float -> Float -> Bottleneck`
- `estimateConfidence : CalculationParameters -> ConfidenceLevel`

**Dependencies:** No external dependencies - pure calculation functions

**Technology Stack:** Pure Elm functions, mathematical calculations, no UI components

## ValidationEngine
**Responsibility:** Handles all input validation, maintains validation state, and provides user-friendly error messages

**Key Interfaces:**
- `validateField : FieldId -> String -> Result ValidationError Float`
- `validateModel : Model -> ValidationState`
- `getFieldError : FieldId -> ValidationState -> Maybe ValidationError`
- `clearValidationErrors : Model -> Model`
- `formatErrorMessage : ValidationError -> String`

**Dependencies:** ValidationRules from configuration, business logic constraints

**Technology Stack:** Elm validation functions, error message formatting, Tailwind CSS for error styling

## DeviceAdaptiveInterface
**Responsibility:** Manages responsive behavior and device-specific feature availability, adapting interface complexity based on screen size

**Key Interfaces:**
- `detectDevice : () -> DeviceType`
- `shouldShowAdvancedFeatures : DeviceType -> Bool`
- `getLayoutClasses : DeviceType -> String`
- `adaptComponentForDevice : DeviceType -> Component -> Component`

**Dependencies:** Browser window size detection, CSS media queries

**Technology Stack:** Elm Browser.Dom for size detection, Tailwind CSS responsive classes, conditional rendering

## ResultsDisplayManager
**Responsibility:** Presents calculation results with appropriate detail level based on device type and user preferences

**Key Interfaces:**
- `displayResults : CalculationResult -> DeviceType -> Html Msg`
- `formatTimeline : Int -> String`
- `showDetailedBreakdown : CalculationResult -> Bool -> Html Msg`
- `generateResultsSummary : CalculationResult -> String`

**Dependencies:** CalculationResult data, device type information

**Technology Stack:** Elm HTML generation, Tailwind CSS for results styling, responsive result cards
