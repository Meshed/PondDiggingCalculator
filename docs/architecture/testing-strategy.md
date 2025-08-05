# Testing Strategy

## Testing Pyramid

```
                    E2E Tests (Cypress)
                   /                  \
              Integration Tests         
             /                        \
        Elm Unit Tests            F# Unit Tests (Future)
```

## Test Organization

**Frontend Tests (Elm):**
```
frontend/tests/
├── Unit/
│   ├── CalculationTests.elm        # Core calculation logic tests
│   ├── ValidationTests.elm         # Input validation tests
│   ├── EquipmentTests.elm         # Equipment model tests
│   └── FormattingTests.elm        # Display formatting tests
├── Integration/
│   ├── ComponentTests.elm         # Component integration tests
│   ├── ModelUpdatesTests.elm      # Model update integration
│   └── ConfigurationTests.elm     # Configuration loading tests
├── E2E/
│   ├── cypress/
│   │   ├── integration/
│   │   │   ├── basic-calculation.spec.js    # Basic calculation flow
│   │   │   ├── equipment-management.spec.js # Equipment CRUD operations
│   │   │   ├── responsive-behavior.spec.js  # Device-specific behavior
│   │   │   └── validation-errors.spec.js    # Error handling flows
│   │   └── fixtures/
│   │       ├── default-config.json          # Test configuration data
│   │       └── sample-calculations.json     # Expected calculation results
└── elm.json                        # Test dependencies
```

## Test Examples

**Frontend Component Test (Elm):**
```elm
module Tests.Unit.CalculationTests exposing (suite)

import Test exposing (..)
import Expect
import Utils.Calculations as Calc

suite : Test
suite =
    describe "Calculation Engine Tests"
        [ test "should_calculate_correct_timeline_for_single_equipment" <|
            \_ ->
                let
                    excavator = testExcavator 2.5 2.0
                    truck = testTruck 12.0 15.0
                    config = testConfig 333.33
                    
                    result = Calc.calculateTimeline [excavator] [truck] config
                in
                case result of
                    Ok calculation ->
                        calculation.timelineInDays
                            |> Expect.equal 1
                    
                    Err error ->
                        Expect.fail ("Calculation failed: " ++ Debug.toString error)
        ]
```

**E2E Test (Cypress):**
```javascript
describe('Basic Calculation Flow', () => {
  it('should_calculate_timeline_with_default_values', () => {
    cy.visit('/')
    
    // Verify default values are loaded
    cy.get('[data-testid="excavator-capacity"]').should('have.value', '2.5')
    cy.get('[data-testid="truck-capacity"]').should('have.value', '12')
    
    // Check that calculation appears automatically
    cy.get('[data-testid="timeline-result"]')
      .should('be.visible')
      .and('contain', 'days')
  })
})
```
