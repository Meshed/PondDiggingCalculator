# Function Documentation Guide

## Overview
This guide establishes comprehensive documentation standards for all Elm functions in the Pond Digging Calculator project, ensuring code maintainability and developer understanding.

## Docstring Requirements

### Public Function Documentation (MANDATORY)
Every public function (exposed in module definition) MUST have a docstring using Elm's documentation syntax:

```elm
{-| Calculate the hourly excavation rate for a single excavator.
    
    Takes bucket capacity in cubic yards and cycle time in minutes.
    Returns cubic yards per hour accounting for real-world efficiency.
    
    ## Parameters
    - `bucketCapacity`: Equipment bucket size in cubic yards (0.5-15.0 range)
    - `cycleTime`: Time per excavation cycle in minutes (1.0-5.0 typical)
    
    ## Returns
    Excavation rate in cubic yards per hour, adjusted for 85% efficiency factor.
    
    ## Examples
    ```elm
    calculateExcavatorRate 2.5 2.0
    --> 63.75  -- (30 cycles/hour * 2.5 capacity * 0.85 efficiency)
    ```
-}
calculateExcavatorRate : CubicYards -> Minutes -> CubicYards
```

### Private Function Documentation (RECOMMENDED)
Internal helper functions should have brief documentation explaining their purpose:

```elm
{-| Convert cycle time to cycles per hour for rate calculations. -}
cyclesToHourlyRate : Minutes -> Float
cyclesToHourlyRate cycleTime =
    60.0 / cycleTime
```

## Documentation Templates

### Simple Function Template
For straightforward functions with clear inputs/outputs:

```elm
{-| [Brief description of what the function does].
    
    [Optional: More detailed explanation if needed]
    
    ## Parameters
    - `paramName`: Description and expected range/format
    
    ## Returns
    Description of return value and its format/type.
-}
functionName : InputType -> ReturnType
```

### Complex Function Template
For functions with multiple parameters, error handling, or complex logic:

```elm
{-| [Brief description of the function's primary purpose].
    
    [Detailed explanation of the function's behavior, including any important
    business logic, calculations, or special handling]
    
    ## Parameters
    - `param1`: Description, expected range, and format
    - `param2`: Description and any constraints
    - `param3`: Description of optional parameter behavior
    
    ## Returns
    - `Ok result`: Description of successful result format
    - `Err error`: Description of possible error conditions
    
    ## Examples
    ```elm
    -- Basic usage
    functionName input1 input2 input3
    --> Ok expectedOutput
    
    -- Error case
    functionName invalidInput input2 input3  
    --> Err (ValidationError "Detailed error message")
    ```
    
    ## See Also
    - `relatedFunction1`: For related functionality
    - `relatedFunction2`: For alternative approaches
-}
functionName : Param1Type -> Param2Type -> Maybe Param3Type -> Result ErrorType ResultType
```

### Validation Function Template
For functions that validate inputs and return Result types:

```elm
{-| Validate [specific input] against [business rules/constraints].
    
    Ensures the input meets the following criteria:
    - [Criterion 1 with specific limits]
    - [Criterion 2 with business justification]
    - [Criterion 3 with technical constraints]
    
    ## Parameters
    - `input`: The value to validate with expected format
    
    ## Returns
    - `Ok validatedValue`: Input passed all validation checks
    - `Err ValidationError`: Specific error describing validation failure
    
    ## Error Types
    - `ValueTooLow actualValue minimumValue`: Input below acceptable range
    - `ValueTooHigh actualValue maximumValue`: Input above acceptable range
    - `InvalidFormat inputString`: Input format doesn't match expected pattern
    
    ## Examples
    ```elm
    validateBucketCapacity 2.5
    --> Ok 2.5
    
    validateBucketCapacity -1.0
    --> Err (ValueTooLow -1.0 0.1)
    
    validateBucketCapacity 20.0
    --> Err (ValueTooHigh 20.0 15.0)
    ```
-}
validateBucketCapacity : Float -> Result ValidationError CubicYards
```

### Calculation Function Template
For mathematical/computational functions:

```elm
{-| Calculate [specific metric] using [methodology/formula].
    
    Uses the following formula:
    [Mathematical formula or algorithm description]
    
    Accounts for:
    - [Factor 1]: [Impact on calculation]
    - [Factor 2]: [Business rule or constraint]
    - [Factor 3]: [Real-world adjustment]
    
    ## Parameters
    - `param1`: Description with units (e.g., "cubic yards", "hours per day")
    - `param2`: Description with acceptable range
    
    ## Returns
    [Result description] in [specific units] rounded to [precision].
    
    ## Assumptions
    - [Assumption 1]: [Business rationale]
    - [Assumption 2]: [Technical constraint]
    
    ## Examples
    ```elm
    calculateProjectTimeline equipmentList 1000.0
    --> Ok { days = 5.2, hours = 41.6 }
    
    calculateProjectTimeline [] 1000.0
    --> Err InsufficientEquipment
    ```
-}
calculateProjectTimeline : List Equipment -> CubicYards -> Result CalculationError Timeline
```

## Parameter Description Standards

### Required Elements
1. **Name**: Use the exact parameter name from function signature
2. **Description**: Clear explanation of the parameter's purpose
3. **Type/Format**: Expected data type and format
4. **Constraints**: Valid ranges, formats, or business rules

### Parameter Documentation Examples

```elm
-- ✅ GOOD: Comprehensive parameter documentation
{-| ...
    ## Parameters
    - `bucketCapacity`: Equipment bucket size in cubic yards, valid range 0.5-15.0
    - `cycleTime`: Time per excavation cycle in minutes, typically 1.0-5.0 
    - `soilType`: Type of soil affecting excavation speed (Clay | Sand | Rock | Mixed)
    - `workHoursPerDay`: Daily operating hours, standard range 6-12 hours
    ...
-}

-- ❌ BAD: Vague parameter documentation  
{-| ...
    ## Parameters
    - `capacity`: The capacity
    - `time`: How long it takes
    - `soil`: Soil information
    ...
-}
```

### Units and Ranges
Always specify units and acceptable ranges:

```elm
-- ✅ GOOD: Clear units and constraints
- `pondLength`: Pond length in feet, minimum 10.0, maximum 500.0
- `dailyRate`: Equipment rental cost in USD per day, positive values only
- `efficiency`: Equipment efficiency factor as decimal, range 0.1-1.0

-- ❌ BAD: Missing units and constraints
- `pondLength`: The length of the pond
- `dailyRate`: How much it costs
- `efficiency`: How efficient it is
```

## Return Value Documentation

### Simple Returns
For functions returning a single value:

```elm
{-| ...
    ## Returns
    Total excavation time in days, rounded to one decimal place.
-}
```

### Result Type Returns
For functions using Result for error handling:

```elm
{-| ...
    ## Returns
    - `Ok calculationResult`: Successful calculation with timeline and cost data
    - `Err ValidationError`: Input validation failed with specific error details
    - `Err CalculationError`: Mathematical calculation failed due to constraints
-}
```

### Complex Return Types
For functions returning records or custom types:

```elm
{-| ...
    ## Returns
    `ProjectEstimate` record containing:
    - `totalCost`: Project cost in USD including equipment and labor
    - `timeline`: Estimated completion time with start/end dates
    - `equipment`: List of required equipment with daily schedules
    - `risks`: Potential project risks and mitigation strategies
-}
```

## Examples Requirement

### When Examples Are Required
Examples are MANDATORY for:
1. **Validation functions**: Show both success and error cases
2. **Calculation functions**: Demonstrate typical inputs and expected outputs
3. **Complex functions**: Functions with multiple parameters or edge cases
4. **API functions**: Functions called by other modules or components

### Example Format Standards

```elm
{-| ...
    ## Examples
    ```elm
    -- Standard case: typical equipment configuration
    validateEquipmentList standardExcavators
    --> Ok [excavator1, excavator2, excavator3]
    
    -- Edge case: empty equipment list
    validateEquipmentList []
    --> Err NoEquipmentProvided
    
    -- Error case: invalid equipment specifications
    validateEquipmentList [invalidExcavator]
    --> Err (InvalidEquipment "Bucket capacity -2.0 is below minimum 0.1")
    ```
-}
```

### Example Content Guidelines
1. **Representative**: Show typical use cases, not just trivial examples
2. **Educational**: Examples should help developers understand proper usage
3. **Complete**: Include necessary context (variable definitions, imports)
4. **Accurate**: Examples must produce the documented output

## Inline Comment Standards

### When to Use Inline Comments
Inline comments should explain **WHY**, not **WHAT**:

```elm
-- ✅ GOOD: Explains business reasoning
calculateTotalCost equipmentList =
    let
        baseCost = List.sum (List.map .dailyCost equipmentList)
        -- Add 15% markup for fuel and maintenance costs not included in base rates
        adjustedCost = baseCost * 1.15
        -- Apply 10% discount for projects longer than 30 days to encourage larger contracts
        finalCost = if baseCost > 30000 then adjustedCost * 0.9 else adjustedCost
    in
    finalCost

-- ❌ BAD: Explains obvious code behavior
calculateTotalCost equipmentList =
    let
        -- Get the sum of daily costs
        baseCost = List.sum (List.map .dailyCost equipmentList)
        -- Multiply by 1.15
        adjustedCost = baseCost * 1.15
        -- Check if greater than 30000
        finalCost = if baseCost > 30000 then adjustedCost * 0.9 else adjustedCost
    in
    finalCost
```

### Complex Logic Comments
For complex algorithms or business logic:

```elm
calculateOptimalEquipmentMix : ProjectRequirements -> List Equipment -> List Equipment
calculateOptimalEquipmentMix requirements availableEquipment =
    availableEquipment
        -- First pass: filter equipment that meets basic project requirements
        |> List.filter (meetsBasicRequirements requirements)
        -- Second pass: optimize for cost-effectiveness using industry ratios
        -- Rule: 1 bulldozer per 3 excavators for optimal soil movement
        |> optimizeEquipmentRatios
        -- Final pass: ensure total capacity exceeds project needs by 20%
        -- Safety margin accounts for equipment downtime and weather delays
        |> ensureSafetyMargin requirements.totalVolume
```

### Magic Number Comments
All numeric constants must be explained:

```elm
-- ✅ GOOD: Explained constants
excavatorEfficiencyFactor : Float
excavatorEfficiencyFactor = 0.85  -- Industry standard: 85% efficiency accounts for operator breaks, refueling, and positioning time

maxProjectDuration : Days  
maxProjectDuration = 365  -- Business rule: projects longer than 1 year require special approval

-- ❌ BAD: Unexplained magic numbers
someCalculation = inputValue * 0.85 * 365
```

## Module-Level Documentation

### Module Header Documentation
Every module should document its purpose and public API:

```elm
{-| Equipment calculation utilities for pond digging projects.

This module provides the core calculation engine for determining project
timelines, costs, and equipment requirements based on pond specifications
and available equipment fleet.

## Core Functions
@docs calculateTimeline, calculateCost, calculateOptimalEquipment

## Validation
@docs validateProjectInputs, validateEquipmentList

## Types
@docs CalculationResult, CalculationError, ProjectTimeline

## Usage Example
```elm
import Utils.Calculations as Calc

result = Calc.calculateTimeline equipmentList pondSpecifications
case result of
    Ok timeline -> displayResults timeline
    Err error -> displayError error
```

-}
module Utils.Calculations exposing
    ( calculateTimeline
    , calculateCost  
    , calculateOptimalEquipment
    , validateProjectInputs
    , validateEquipmentList
    , CalculationResult
    , CalculationError  
    , ProjectTimeline
    )
```

## Documentation Quality Checklist

### Before Committing Code
- [ ] Every public function has a docstring
- [ ] All parameters are documented with types and constraints  
- [ ] Return values are clearly explained
- [ ] Complex functions include usage examples
- [ ] Error cases are documented for Result types
- [ ] Business logic has explanatory inline comments
- [ ] Magic numbers are explained with comments
- [ ] Module header documents the module's purpose

### Code Review Checklist
- [ ] Documentation matches actual function behavior
- [ ] Examples are correct and run successfully
- [ ] Parameter descriptions include units and ranges
- [ ] Error handling is properly documented
- [ ] Comments explain business reasoning, not just code mechanics
- [ ] Documentation is clear and helpful for other developers