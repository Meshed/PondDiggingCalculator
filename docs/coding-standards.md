# Coding Standards

## Critical Fullstack Rules

- **Type Safety First:** Always use Elm's type system to prevent runtime errors - define custom types instead of primitive types where domain meaning exists (e.g., `EquipmentId` instead of `String`)
- **Pure Function Calculations:** All calculation logic must be pure functions with no side effects - makes testing reliable and enables confident refactoring
- **Configuration Over Code:** Equipment defaults, validation rules, and UI settings must be in JSON config files, never hardcoded - enables post-deployment updates
- **Validation at Boundaries:** Validate all user inputs immediately and display errors inline - never allow invalid data to reach calculation engine
- **Device-Responsive Logic:** Components must check device type and adapt functionality, not just styling - mobile gets simplified features, desktop gets full capabilities
- **Error Result Types:** Use Elm's `Result` type for all operations that can fail - never use `Maybe` when specific error information is needed
- **No Magic Numbers:** All calculation constants must be named and documented - use `excavatorEfficiencyFactor = 0.85` not just `0.85` in calculations
- **Immutable State Updates:** Never modify existing data structures - always create new ones through Elm's update functions
- **Tailwind Class Constants:** Define Tailwind classes as Elm constants in Theme module - prevents CSS class typos and enables compile-time checking
- **Test-Driven Calculations:** All calculation functions must have unit tests with known input/output pairs before implementation

## Code Quality and Functional Programming Principles

- **Readability Over Cleverness:** Write code that is readable, maintainable, and consistent - prefer clarity over cleverness and always document non-obvious logic
- **Functional Transformations:** Prefer **map, filter, fold/reduce** over loops - use functional transformations and pipelines for data processing
- **Immutable by Default:** Avoid mutable state - return new values instead of modifying existing ones
- **Pure Functions:** Minimize side effects and follow pure functional patterns where possible - enables testing and reasoning about code
- **Result/Either Error Handling:** 
  - **F#:** Use Result/Either patterns for error handling, no unhandled exceptions for errors expected in normal flow
  - **Elm:** Return `Result` from functions that may fail or need error handling
- **Descriptive Test Names:** Name test functions descriptively across all languages - test names should explain the expected behavior
- **Documentation Requirements:** Every public function must have a docstring or comment explaining its purpose
- **Meaningful Comments:** Inline comments explain WHY, not WHAT - code should be self-documenting for the "what"

## Naming Conventions

| Element | Frontend (Elm) | Backend (F#) | Example |
|---------|---------------|--------------|---------|
| Types | PascalCase | PascalCase | `CalculationResult`, `ValidationError` |
| Functions | camelCase | camelCase | `calculateTimeline`, `validateInput` |
| Variables | camelCase | camelCase | `excavatorCapacity`, `pondVolume` |
| Constants | camelCase | PascalCase | `defaultWorkHours` (Elm), `DefaultWorkHours` (F#) |
| Modules | PascalCase | PascalCase | `Utils.Calculations`, `Domain.Equipment` |
| CSS Classes | kebab-case | N/A | `equipment-card`, `results-panel` |
| JSON Keys | camelCase | camelCase | `bucketCapacity`, `workHoursPerDay` |
| Test Functions | descriptive_with_underscores | descriptive_with_underscores | `should_calculate_correct_timeline_for_single_equipment` |

## Code Examples

**Correct Elm Implementation:**
```elm
-- Good: Documented public function with clear purpose
{-| Calculate the hourly excavation rate for a single excavator.
    Takes bucket capacity in cubic yards and cycle time in minutes.
    Returns cubic yards per hour accounting for real-world efficiency.
-}
calculateExcavatorRate : CubicYards -> Minutes -> CubicYards
calculateExcavatorRate bucketCapacity cycleTime =
    let
        cyclesPerHour = 60.0 / cycleTime
        theoreticalRate = cyclesPerHour * bucketCapacity
    in
    -- Apply efficiency factor because real-world conditions reduce productivity
    theoreticalRate * excavatorEfficiencyFactor

-- Good: Functional pipeline with map/filter/fold
{-| Calculate total productivity from a fleet of excavators.
    Filters active equipment and sums their individual rates.
-}
calculateFleetExcavationRate : List Excavator -> CubicYards
calculateFleetExcavationRate excavators =
    excavators
        |> List.filter .isActive  -- Only include active equipment
        |> List.map (\excavator -> calculateExcavatorRate excavator.bucketCapacity excavator.cycleTime)
        |> List.foldl (+) 0.0     -- Sum all rates

-- Good: Result type for error handling with descriptive error
{-| Validate excavator bucket capacity against industry standards.
    Returns validated capacity or specific validation error.
-}
validateBucketCapacity : Float -> Result ValidationError CubicYards
validateBucketCapacity capacity =
    if capacity <= 0 then
        Err (ValueTooLow capacity 0.1)
    else if capacity > 15.0 then
        -- Industry standard: largest excavators rarely exceed 15 cubic yards
        Err (ValueTooHigh capacity 15.0)
    else
        Ok capacity
```
