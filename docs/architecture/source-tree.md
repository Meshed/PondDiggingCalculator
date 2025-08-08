# Source Tree Architecture

## Project Structure Overview

The Pond Digging Calculator follows a monorepo architecture with clear separation between frontend application code, documentation, and project tooling.

## Root Level Structure

```
PondDiggingCalculator/
├── CLAUDE.md                    # Development workflow and NPM scripts
├── README.md                    # Project documentation
├── package.json                 # Root-level dependencies and scripts
├── package-lock.json           # Dependency lock file
├── node_modules/               # Root-level node dependencies
├── docs/                       # All project documentation
├── frontend/                   # Elm frontend application
└── .bmad-core/                # Build management and development tooling
```

## Documentation Structure (`docs/`)

```
docs/
├── architecture/               # Technical architecture documentation
│   ├── index.md               # Architecture overview and navigation
│   ├── coding-standards.md    # Development standards and conventions
│   ├── tech-stack.md          # Technology stack documentation
│   ├── unified-project-structure.md  # Project structure guidelines
│   ├── frontend-architecture.md      # Frontend-specific architecture
│   ├── backend-architecture.md       # Backend architecture (future)
│   ├── api-specification.md   # API definitions and contracts
│   ├── data-models.md         # Data structure definitions
│   ├── core-workflows.md      # Key application workflows
│   ├── testing-strategy.md    # Testing approach and standards
│   ├── deployment-architecture.md    # Deployment and infrastructure
│   ├── security-and-performance.md   # Security and performance guidelines
│   └── error-handling-strategy.md    # Error handling patterns
├── prd/                       # Product requirements and epics
│   ├── index.md               # PRD overview and navigation
│   ├── goals-and-background-context.md  # Project context
│   ├── requirements.md        # Functional requirements
│   ├── technical-assumptions.md       # Technical constraints
│   ├── epic-1-foundation-core-calculator.md      # Epic 1
│   ├── epic-2-device-responsive-interface.md     # Epic 2
│   ├── epic-3-mixed-equipment-fleet-management.md # Epic 3
│   ├── epic-4-professional-polish-user-experience.md # Epic 4
│   └── epic-5-production-deployment-infrastructure.md # Epic 5
├── stories/                   # Individual development stories
│   ├── 1.1.project-foundation-setup.md
│   ├── 1.2.core-calculation-engine.md
│   ├── 3.1.equipment-configuration-file-structure.md
│   └── [other story files...]
└── development/               # Development tools and templates
    ├── code-templates/        # Elm code templates
    │   ├── calculation-template.elm
    │   ├── component-template.elm
    │   ├── utility-template.elm
    │   └── validation-template.elm
    └── [other development guides...]
```

## Frontend Application Structure (`frontend/`)

```
frontend/
├── package.json               # Frontend dependencies and NPM scripts
├── package-lock.json         # Frontend dependency lock
├── elm.json                  # Elm project configuration
├── tailwind.config.js        # Tailwind CSS configuration
├── cypress.config.js         # E2E testing configuration
├── node_modules/             # Frontend node dependencies
├── elm-stuff/                # Elm compiler cache and artifacts
├── dist/                     # Build output directory
├── public/                   # Static assets and configuration
│   ├── index.html            # Main HTML template
│   ├── styles.css           # Global CSS styles
│   └── config.json          # Runtime configuration (to be deprecated)
├── src/                      # Elm source code
│   ├── Main.elm              # Application entry point
│   ├── Components/           # Reusable UI components
│   │   ├── ProjectForm.elm   # Project input form component
│   │   └── ResultsPanel.elm  # Calculation results display
│   ├── Pages/                # Page-level components
│   │   ├── Desktop.elm       # Desktop interface layout
│   │   └── Mobile.elm        # Mobile interface layout
│   ├── Views/                # View rendering modules
│   │   └── MobileView.elm    # Mobile-specific view logic
│   ├── Types/                # Type definitions and domain models
│   │   ├── Model.elm         # Application state model
│   │   ├── Messages.elm      # Application messages/actions
│   │   ├── Equipment.elm     # Equipment domain types
│   │   ├── Validation.elm    # Validation types and errors
│   │   ├── Fields.elm        # Form field types
│   │   └── DeviceType.elm    # Device detection types
│   ├── Utils/                # Utility modules and business logic
│   │   ├── Calculations.elm  # Core calculation engine
│   │   ├── Validation.elm    # Input validation logic
│   │   ├── Config.elm        # Configuration loading and management
│   │   ├── DeviceDetector.elm # Device type detection
│   │   ├── Performance.elm   # Performance monitoring utilities
│   │   ├── Storage.elm       # Local storage utilities
│   │   └── Debounce.elm      # Input debouncing utilities
│   ├── Styles/               # Styling and theme modules
│   │   ├── Theme.elm         # Color themes and design tokens
│   │   ├── Components.elm    # Component-specific styling
│   │   └── Responsive.elm    # Responsive design utilities
│   └── styles.css           # Additional CSS styles
└── tests/                   # Test suites
    ├── Unit/                # Unit test modules
    │   ├── CalculationTests.elm      # Calculation engine tests
    │   ├── ValidationTests.elm       # Validation logic tests
    │   ├── FleetValidationTests.elm  # Fleet-specific validation tests
    │   ├── PerformanceTests.elm      # Performance validation tests
    │   └── [other unit test files...]
    ├── Integration/         # Integration test modules
    │   ├── CrossDeviceTests.elm      # Cross-device functionality tests
    │   ├── DeviceConsistencyTests.elm # Device consistency validation
    │   ├── FleetOperationsTests.elm  # Fleet operation integration tests
    │   └── [other integration test files...]
    └── E2E/                # End-to-end test suites
        ├── cypress/         # Cypress test configuration
        │   ├── integration/ # E2E test specifications
        │   │   ├── user-journeys.spec.js
        │   │   ├── cross-browser.spec.js
        │   │   ├── mobile-device-workflows.spec.js
        │   │   └── [other E2E specs...]
        │   ├── support/     # Cypress support files
        │   └── scripts/     # Test execution scripts
        └── [Elm E2E test modules...]
```

## Future Configuration Structure (Story 3.1 Target)

```
PondDiggingCalculator/
├── config/                           # NEW: Build-time configuration
│   ├── equipment-defaults.json       # NEW: Main equipment configuration  
│   ├── equipment-defaults.schema.json # NEW: JSON schema validation
│   └── README.md                     # NEW: Configuration documentation
└── frontend/
    ├── public/
    │   └── config.json              # DEPRECATED: Remove after migration
    └── src/Utils/
        └── Config.elm               # UPDATE: Remove HTTP loading, add static import
```

## Key Architecture Principles

### Module Organization
- **Types/**: Domain models and type definitions - no business logic
- **Utils/**: Business logic and utilities - pure functions where possible
- **Components/**: Reusable UI components with encapsulated styling
- **Pages/**: Top-level page layouts and device-specific orchestration
- **Views/**: View rendering logic and device-specific adaptations

### File Naming Conventions
- **Elm Modules**: PascalCase matching module names (`CalculationTests.elm` → `module CalculationTests`)
- **JSON Files**: kebab-case for readability (`equipment-defaults.json`)
- **Test Files**: Descriptive names indicating test scope (`Unit/CalculationTests.elm`)

### Dependency Flow
```
Main.elm
├── Pages/ (Desktop.elm, Mobile.elm)
│   ├── Components/ (ProjectForm.elm, ResultsPanel.elm)
│   ├── Views/ (MobileView.elm)
│   └── Utils/ (all utility modules)
├── Types/ (shared across all modules)
└── Styles/ (theme and styling utilities)
```

### Configuration Architecture
- **Current**: HTTP-based JSON loading from `frontend/public/config.json`
- **Target**: Build-time JSON integration from `config/equipment-defaults.json`
- **Build Process**: Static configuration embedding via Elm compilation

### Testing Organization
- **Unit Tests**: Test individual functions and modules in isolation
- **Integration Tests**: Test module interactions and data flow
- **E2E Tests**: Test complete user workflows across device types

## Development Workflow Integration

### NPM Scripts (from CLAUDE.md)
```bash
npm run dev              # Start development server
npm run build           # Production build
npm test                # Run all tests
npm run format          # Auto-format all Elm files
npm run validate        # Complete validation pipeline
```

### Git Pre-commit Hook
- Runs formatting validation and tests automatically
- Prevents commits with formatting issues or test failures
- Ensures code quality standards are maintained

This source tree architecture supports the project's goals of device-responsive design, functional programming principles, and comprehensive testing while maintaining clear separation of concerns and scalable organization.