# Testing Documentation

## Test Structure and Organization

The Pond Digging Calculator follows a comprehensive three-tier testing strategy with clear separation between unit tests, integration tests, and end-to-end tests. All tests are written in Elm using the elm-test framework, with additional Cypress tests for cross-browser E2E validation.

### Test Directory Structure

```
frontend/tests/
├── Unit/                           # Unit tests (isolated function testing)
│   ├── CalculationTests.elm        # Core calculation engine tests
│   ├── ValidationTests.elm         # Input validation logic tests
│   ├── FleetValidationTests.elm    # Equipment fleet validation tests
│   ├── ConfigTests.elm             # Configuration loading tests
│   ├── PerformanceTests.elm        # Performance validation tests
│   ├── DesktopTests.elm            # Desktop-specific component tests
│   ├── MobileTests.elm             # Mobile-specific component tests
│   └── [other unit test modules...]
├── Integration/                    # Integration tests (component interactions)
│   ├── CrossDeviceTests.elm        # Cross-device functionality tests
│   ├── DeviceConsistencyTests.elm  # Device state consistency validation
│   ├── FleetOperationsTests.elm    # Fleet management integration tests
│   ├── ValidationStateIntegrationTests.elm  # Validation state management
│   └── [other integration test modules...]
└── E2E/                           # End-to-end tests (full user workflows)
    ├── BrowserCompatibilityTests.elm  # Elm E2E framework tests
    └── cypress/                    # Cypress browser automation
        ├── integration/            # Cypress test specifications
        │   ├── user-journeys.spec.js       # Complete user workflows
        │   ├── mobile-device-workflows.spec.js  # Mobile-specific scenarios
        │   ├── performance-validation.spec.js   # Performance benchmarks
        │   ├── accessibility.spec.js       # Accessibility compliance
        │   ├── cross-browser.spec.js       # Cross-browser compatibility
        │   └── [other E2E specifications...]
        ├── support/                # Cypress support files and utilities
        └── fixtures/               # Test data and mock configurations
```

## NPM Test Commands and Their Purposes

### Core Test Commands

#### `npm test`
**Purpose**: Run all Elm unit and integration tests  
**Command**: `elm-test`  
**Coverage**: All `frontend/tests/Unit/` and `frontend/tests/Integration/` modules  
**Duration**: ~10-30 seconds  
**Use Case**: Primary validation during development and CI/CD  

#### `npm run test:watch`
**Purpose**: Run tests in watch mode with automatic re-execution on file changes  
**Command**: `elm-test --watch`  
**Coverage**: Same as `npm test` but with file watching  
**Use Case**: Active development with immediate feedback  

#### `npm run test:e2e`
**Purpose**: Run all end-to-end tests headlessly  
**Command**: `cypress run`  
**Coverage**: All Cypress specs in `tests/E2E/cypress/integration/`  
**Duration**: ~5-15 minutes  
**Use Case**: Full regression testing before deployment  

#### `npm run test:e2e:open`
**Purpose**: Open Cypress interactive test runner  
**Command**: `cypress open`  
**Coverage**: Interactive execution of E2E tests with debugging  
**Use Case**: E2E test development and debugging  

### Specialized Test Commands

#### Browser-Specific E2E Testing
```bash
npm run test:e2e:chrome      # Chrome browser testing
npm run test:e2e:firefox     # Firefox browser testing  
npm run test:e2e:edge        # Edge browser testing
npm run test:e2e:all-browsers # Sequential testing across all browsers
```

#### Feature-Specific E2E Testing
```bash
npm run test:e2e:mobile      # Mobile device workflow testing
npm run test:e2e:performance # Performance validation testing
npm run test:e2e:accessibility # Accessibility compliance testing
npm run test:e2e:user-journeys # Core user journey testing
npm run test:e2e:comprehensive # All specialized E2E tests
```

#### Complete Validation Pipeline
```bash
npm run validate             # Build + Unit/Integration tests
npm run validate:full        # validate + Comprehensive E2E tests
npm run pretest              # Format validation before test execution
```

## How to Write New Tests for Each Type

### Unit Tests (Testing Individual Functions)

**Purpose**: Test pure functions in isolation with predictable inputs/outputs.

**Location**: `frontend/tests/Unit/[ModuleName]Tests.elm`

**Structure**:
```elm
module Unit.CalculationTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Utils.Calculations exposing (calculateExcavationTime)

suite : Test
suite =
    describe "Utils.Calculations"
        [ describe "calculateExcavationTime"
            [ test "should calculate correct time for single excavator" <|
                \_ ->
                    let
                        volume = 1000.0  -- cubic yards
                        hourlyRate = 50.0 -- cubic yards per hour
                        expected = 20.0   -- hours
                    in
                    calculateExcavationTime volume hourlyRate
                        |> Expect.equal expected
            
            , test "should handle zero volume correctly" <|
                \_ ->
                    calculateExcavationTime 0.0 50.0
                        |> Expect.equal 0.0
            
            , test "should handle edge case with very small volumes" <|
                \_ ->
                    calculateExcavationTime 0.1 25.0
                        |> Expect.within (Expect.Absolute 0.001) 0.004
            ]
        ]
```

**Testing Principles**:
- One test module per source module
- Test both happy path and edge cases
- Use descriptive test names explaining the expected behavior
- Include boundary value testing (zero, negative, very large values)
- Test error conditions using `Result` types

**Example Test Categories**:
- Calculation accuracy with known input/output pairs
- Input validation and error handling
- Boundary conditions and edge cases
- Configuration loading and parsing
- Device type detection logic

### Integration Tests (Testing Module Interactions)

**Purpose**: Verify that multiple modules work together correctly and data flows properly between components.

**Location**: `frontend/tests/Integration/[FeatureName]Tests.elm`

**Structure**:
```elm
module Integration.FleetOperationsTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Types.Model exposing (Model, initialModel)
import Types.Messages exposing (Msg(..))
import Main exposing (update)
import Utils.Config exposing (getConfig)

suite : Test
suite =
    describe "Fleet Operations Integration"
        [ describe "Adding equipment to fleet"
            [ test "should update model state and trigger recalculation" <|
                \_ ->
                    let
                        config = getConfig
                        initialState = initialModel config
                        addExcavatorMsg = AddEquipment (ExcavatorEquipment defaultExcavator)
                        (updatedModel, cmd) = update addExcavatorMsg initialState
                    in
                    Expect.all
                        [ \model -> List.length model.equipmentFleet |> Expect.equal 1
                        , \model -> model.calculationResults.isValid |> Expect.equal True
                        ] updatedModel
            ]
        ]
```

**Testing Focus**:
- Message handling and state transitions
- Cross-device state consistency
- Component communication and data flow
- Configuration integration with business logic
- Validation state propagation

### End-to-End Tests (Full User Workflows)

#### Elm E2E Tests

**Purpose**: Test complete user workflows within the Elm architecture.

**Location**: `frontend/tests/E2E/BrowserCompatibilityTests.elm`

**Structure**:
```elm
module E2E.BrowserCompatibilityTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text, class)
import Main exposing (view, initialModel, update)
import Types.Messages exposing (Msg(..))

suite : Test
suite =
    describe "Complete User Workflows"
        [ test "should complete pond calculation workflow" <|
            \_ ->
                let
                    model = initialModel getConfig
                    -- Simulate user input sequence
                    (model1, _) = update (UpdatePondLength "50") model
                    (model2, _) = update (UpdatePondWidth "30") model1
                    (model3, _) = update (UpdatePondDepth "6") model2
                    (finalModel, _) = update Calculate model3
                    
                    renderedView = view finalModel
                in
                renderedView
                    |> Query.fromHtml
                    |> Query.find [ class "results-panel" ]
                    |> Query.has [ text "Timeline calculated successfully" ]
        ]
```

#### Cypress E2E Tests (Browser Automation)

**Purpose**: Test real browser interactions, cross-browser compatibility, and performance validation.

**Location**: `frontend/tests/E2E/cypress/integration/[feature].spec.js`

**Structure**:
```javascript
describe('Pond Digging Calculator - User Journeys', () => {
  beforeEach(() => {
    cy.visit('http://localhost:1234');
    cy.viewport(1920, 1080); // Desktop resolution
  });

  it('should complete full pond calculation workflow', () => {
    // Enter project details
    cy.get('[data-testid="pond-length-input"]')
      .clear()
      .type('50');
    
    cy.get('[data-testid="pond-width-input"]')
      .clear()
      .type('30');
      
    cy.get('[data-testid="pond-depth-input"]')
      .clear()
      .type('6');

    // Add equipment
    cy.get('[data-testid="add-excavator-button"]').click();
    cy.get('[data-testid="excavator-capacity-input"]')
      .clear()
      .type('2.5');

    // Trigger calculation
    cy.get('[data-testid="calculate-button"]').click();

    // Verify results
    cy.get('[data-testid="results-panel"]')
      .should('be.visible')
      .and('contain', 'Timeline');
    
    cy.get('[data-testid="total-time"]')
      .should('contain', 'hours');

    // Verify performance
    cy.window()
      .its('performance.timing')
      .then((timing) => {
        const loadTime = timing.loadEventEnd - timing.navigationStart;
        expect(loadTime).to.be.lessThan(3000); // <3s load time
      });
  });

  it('should work correctly on mobile viewport', () => {
    cy.viewport('iphone-x');
    
    // Mobile-specific workflow
    cy.get('[data-testid="mobile-menu-toggle"]').click();
    cy.get('[data-testid="simplified-form"]').should('be.visible');
    
    // Test touch interactions
    cy.get('[data-testid="pond-size-slider"]')
      .trigger('touchstart')
      .trigger('touchmove', { clientX: 200 })
      .trigger('touchend');
  });
});
```

## Test Coverage Expectations and Standards

### Unit Test Coverage Requirements

**Target Coverage**: 90%+ for core business logic modules
- **Utils/Calculations.elm**: 95%+ (critical calculation accuracy)
- **Utils/Validation.elm**: 90%+ (input validation reliability)
- **Utils/Config.elm**: 85%+ (configuration loading robustness)

**Coverage Measurement**:
```bash
# Generate coverage report (future implementation)
npm run test:coverage
```

### Integration Test Standards

**Required Integration Scenarios**:
- Device switching maintains state consistency (Desktop ↔ Mobile)
- Configuration changes propagate to all dependent components
- Equipment fleet operations update calculations correctly
- Validation errors display consistently across device types

**Coverage Target**: 80%+ of cross-module interactions tested

### E2E Test Standards

**Browser Compatibility Matrix**:
- Chrome 90+ (Primary)
- Firefox 88+ (Secondary)  
- Edge 90+ (Secondary)
- Safari 14+ (Mobile testing)

**Performance Requirements**:
- Initial load: < 3 seconds on 3G connection
- Calculation updates: < 100ms response time
- Memory usage: < 50MB after 10 minutes of interaction
- No memory leaks during 1-hour usage session

**Accessibility Standards**:
- WCAG 2.1 AA compliance
- Keyboard navigation support
- Screen reader compatibility
- Color contrast validation

## Testing Checklist for New Features

### Pre-Development Testing Setup
- [ ] Create test file in appropriate directory (`Unit/`, `Integration/`, or `E2E/`)
- [ ] Write failing tests that describe expected behavior (TDD approach)
- [ ] Ensure test naming follows descriptive convention

### Unit Testing Checklist
- [ ] Test happy path with typical inputs
- [ ] Test boundary conditions (min/max values, empty inputs)
- [ ] Test error conditions and invalid inputs
- [ ] Test edge cases and unusual but valid inputs
- [ ] Verify pure function behavior (same input → same output)
- [ ] Test type safety and decoder behavior for JSON/config

### Integration Testing Checklist  
- [ ] Test message flow between components
- [ ] Verify state updates propagate correctly
- [ ] Test device-specific behavior integration
- [ ] Validate configuration integration
- [ ] Test error state propagation

### E2E Testing Checklist
- [ ] Create Cypress spec for new user workflow
- [ ] Test across desktop and mobile viewports
- [ ] Validate performance impact (load time, responsiveness)
- [ ] Test accessibility compliance
- [ ] Verify cross-browser compatibility
- [ ] Test error recovery and user feedback

### Test Execution Validation
- [ ] All tests pass locally: `npm run validate:full`
- [ ] Format validation passes: `npm run format:check`
- [ ] Build succeeds: `npm run build`
- [ ] E2E tests pass in CI environment
- [ ] Performance benchmarks within acceptable ranges

## Testing Tools and Utilities

### Elm Testing Framework

**elm-test**: Core testing framework
- Pure Elm test runner with no JavaScript dependencies
- Built-in assertion library with comprehensive matchers
- Fuzz testing support for property-based testing
- Watch mode for development-time feedback

### Cypress Testing Framework

**Cypress**: Browser automation and E2E testing
- Real browser testing (Chrome, Firefox, Edge)
- Time-travel debugging with test replay
- Network stubbing and mocking capabilities
- Screenshot and video recording for failures
- Accessibility testing with cypress-axe plugin

### Testing Utilities

**Test Data Factories**:
```elm
-- Utils/TestFactory.elm
createTestExcavator : Float -> Float -> String -> Excavator
createTestExcavator capacity cycleTime name =
    { id = "test-" ++ name
    , bucketCapacity = capacity
    , cycleTime = cycleTime  
    , name = name
    , isActive = True
    }

createTestProject : Float -> Float -> Float -> Project
createTestProject length width depth =
    { pondLength = length
    , pondWidth = width
    , pondDepth = depth
    , workHoursPerDay = 8.0
    }
```

**Cypress Custom Commands**:
```javascript
// cypress/support/commands.js
Cypress.Commands.add('addEquipment', (equipmentType, specifications) => {
  cy.get(`[data-testid="add-${equipmentType}-button"]`).click();
  
  Object.entries(specifications).forEach(([field, value]) => {
    cy.get(`[data-testid="${equipmentType}-${field}-input"]`)
      .clear()
      .type(value.toString());
  });
});

Cypress.Commands.add('validatePerformance', (maxLoadTime = 3000) => {
  cy.window()
    .its('performance.timing')
    .then((timing) => {
      const loadTime = timing.loadEventEnd - timing.navigationStart;
      expect(loadTime).to.be.lessThan(maxLoadTime);
    });
});
```

## Debugging and Troubleshooting Tests

### Common Test Failures

**Elm Compilation Errors**:
- Verify imports are correct and modules exist
- Check type annotations match actual function signatures
- Ensure test data matches expected types

**Cypress Test Failures**:
- Check element selectors exist in DOM
- Verify viewport size matches test expectations
- Confirm application is running on expected port
- Review network requests and responses

**Performance Test Failures**:
- Check system resources and background processes
- Verify test environment matches production constraints
- Review Lighthouse audits for specific performance bottlenecks

### Test Debugging Tools

**Elm Debugger Integration**:
```elm
-- Add Debug.log statements in test code
test "should calculate timeline correctly" <|
    \_ ->
        let
            result = calculateTimeline testProject testFleet
                |> Debug.log "Timeline calculation result"
        in
        result.totalHours |> Expect.equal 24.5
```

**Cypress Debugging**:
```javascript
// Use cy.debug() and cy.pause() for interactive debugging
it('should handle user interaction', () => {
  cy.get('[data-testid="form-input"]').type('test value');
  cy.debug(); // Pause execution and open DevTools
  cy.get('[data-testid="submit-button"]').click();
});
```

## Test Performance and Optimization

### Test Execution Speed

**Unit Tests**: Target < 5 seconds total execution time
**Integration Tests**: Target < 15 seconds total execution time  
**E2E Tests**: Target < 10 minutes comprehensive execution time

**Optimization Strategies**:
- Use `Test.only` during development to run focused tests
- Group related tests with `describe` blocks for better organization
- Minimize DOM queries in Cypress tests with smart selectors
- Use parallel test execution where possible

### CI/CD Integration

**GitHub Actions Test Pipeline**:
```yaml
- name: Run Unit Tests
  run: |
    cd frontend
    npm test

- name: Run E2E Tests  
  run: |
    cd frontend
    npm run build
    npm run test:e2e:comprehensive

- name: Upload Test Results
  uses: actions/upload-artifact@v3
  if: failure()
  with:
    name: test-results
    path: |
      frontend/test-results/
      frontend/cypress/screenshots/
      frontend/cypress/videos/
```

This comprehensive testing strategy ensures the Pond Digging Calculator maintains high quality, reliability, and performance across all supported devices and browsers while providing clear guidance for adding tests to new features.