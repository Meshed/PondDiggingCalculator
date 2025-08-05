# Backend Architecture

**No backend in MVP phase** - This section defines the future backend architecture for when data persistence and server-side features are needed.

## Service Architecture (Future F# Implementation)

**Function Organization (Future F# Backend):**
```
src/
├── Domain/
│   ├── Equipment.fs           -- Equipment domain types and logic
│   ├── Project.fs            -- Project domain types and logic
│   ├── Calculation.fs        -- Calculation domain logic
│   └── Validation.fs         -- Domain validation rules
├── Infrastructure/
│   ├── Database/
│   │   ├── ProjectRepository.fs    -- Project data access
│   │   ├── EquipmentRepository.fs  -- Equipment data access
│   │   └── Migrations/            -- Database schema migrations
│   └── Configuration/
│       └── Settings.fs            -- Application configuration
├── Application/
│   ├── ProjectService.fs          -- Project business logic
│   ├── CalculationService.fs      -- Calculation orchestration
│   └── ValidationService.fs       -- Input validation
├── Web/
│   ├── Controllers/
│   │   ├── ProjectController.fs    -- Project API endpoints
│   │   ├── CalculationController.fs -- Calculation API endpoints
│   │   └── ConfigurationController.fs -- Config API endpoints
│   └── Startup.fs                     -- Application startup
└── Tests/
    ├── Domain.Tests/              -- Domain logic tests
    ├── Application.Tests/         -- Service tests
    └── Integration.Tests/         -- API integration tests
```

**Function Template (F# Domain Logic):**
```fsharp
// Domain/Calculation.fs - Pure calculation functions
module Domain.Calculation

// Pure calculation function - mirrors Elm frontend logic
let calculateTimeline (excavators: Excavator list) (trucks: Truck list) (config: ProjectConfiguration) : Result<CalculationResult, CalculationError> =
    result {
        let! validatedExcavators = validateExcavators excavators
        let! validatedTrucks = validateTrucks trucks
        let! validatedConfig = validateProjectConfig config
        
        let excavationRate = calculateExcavationRate validatedExcavators
        let haulingRate = calculateHaulingRate validatedTrucks
        let effectiveRate = min excavationRate haulingRate
        let totalHours = validatedConfig.PondVolume / effectiveRate
        let timelineDays = int (ceil (totalHours / validatedConfig.WorkHoursPerDay))
        
        return {
            TimelineInDays = timelineDays
            TotalHours = totalHours
            ExcavationRate = excavationRate
            HaulingRate = haulingRate
            CalculatedAt = DateTime.UtcNow
        }
    }
```
