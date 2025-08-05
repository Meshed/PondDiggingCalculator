# Unified Project Structure

```
PondDiggingCalculator/
├── .github/                              # CI/CD workflows
│   └── workflows/
│       ├── elm-ci.yml                   # Elm build and test pipeline
│       ├── deploy-static.yml            # Deploy to GitHub Pages
│       └── fsharp-ci.yml               # Future F# backend CI
├── frontend/                            # Elm application (current MVP)
│   ├── src/
│   │   ├── Main.elm                    # Application entry point
│   │   ├── Types/
│   │   │   ├── Model.elm              # Core application state
│   │   │   ├── Equipment.elm          # Equipment domain types
│   │   │   ├── Validation.elm         # Validation types and errors
│   │   │   └── Messages.elm           # Application messages
│   │   ├── Components/
│   │   │   ├── EquipmentCard.elm      # Equipment display component
│   │   │   ├── EquipmentList.elm      # Fleet management component
│   │   │   ├── ProjectForm.elm        # Project configuration form
│   │   │   ├── ResultsPanel.elm       # Results display component
│   │   │   └── ValidationMessage.elm  # Error message component
│   │   ├── Pages/
│   │   │   ├── Desktop.elm           # Desktop/tablet interface
│   │   │   ├── Mobile.elm            # Mobile interface
│   │   │   └── Common.elm            # Shared page elements
│   │   ├── Utils/
│   │   │   ├── Validation.elm        # Input validation functions
│   │   │   ├── Calculations.elm      # Core calculation engine
│   │   │   ├── Formatting.elm        # Display formatting
│   │   │   ├── Storage.elm           # Local storage operations
│   │   │   └── Config.elm            # Configuration loading
│   │   └── Styles/
│   │       ├── Theme.elm             # Tailwind class definitions
│   │       ├── Components.elm        # Component-specific styles
│   │       └── Responsive.elm        # Device-specific styling
│   ├── public/
│   │   ├── index.html                # Main HTML template
│   │   ├── config.json               # Application configuration
│   │   ├── favicon.ico               # Site favicon
│   │   └── manifest.json             # PWA manifest (future)
│   ├── tests/
│   │   ├── CalculationTests.elm      # Calculation engine tests
│   │   ├── ValidationTests.elm       # Validation function tests
│   │   └── ComponentTests.elm        # UI component tests
│   ├── elm.json                      # Elm package configuration
│   ├── package.json                  # Node.js build dependencies
│   ├── tailwind.config.js            # Tailwind CSS configuration
│   ├── parcel.json                   # Parcel bundler configuration
│   └── README.md                     # Frontend development guide
├── backend/                          # Future F# backend (post-MVP)
│   ├── src/
│   │   ├── Domain/
│   │   │   ├── Equipment.fs          # Equipment domain logic
│   │   │   ├── Project.fs           # Project domain logic
│   │   │   ├── Calculation.fs       # Calculation domain logic
│   │   │   └── Validation.fs        # Domain validation rules
│   │   ├── Infrastructure/
│   │   │   ├── Database/
│   │   │   │   ├── ProjectRepository.fs    # Project data access
│   │   │   │   ├── EquipmentRepository.fs  # Equipment data access
│   │   │   │   └── Migrations/            # Database migrations
│   │   │   └── Configuration/
│   │   │       └── Settings.fs            # Application settings
│   │   ├── Application/
│   │   │   ├── ProjectService.fs          # Project business logic
│   │   │   ├── CalculationService.fs      # Calculation orchestration
│   │   │   └── ValidationService.fs       # Input validation service
│   │   ├── Web/
│   │   │   ├── Controllers/
│   │   │   │   ├── ProjectController.fs    # Project API endpoints
│   │   │   │   ├── CalculationController.fs # Calculation endpoints
│   │   │   │   └── ConfigController.fs     # Configuration endpoints
│   │   │   └── Startup.fs                 # Application startup
│   │   └── Program.fs                     # Application entry point
│   ├── tests/
│   │   ├── Domain.Tests/              # Domain logic tests
│   │   ├── Application.Tests/         # Application service tests
│   │   └── Integration.Tests/         # API integration tests
│   ├── PondCalculator.Backend.fsproj  # F# project file
│   └── README.md                     # Backend development guide
├── shared/                           # Shared resources and documentation
│   ├── config/
│   │   ├── eslint/                   # Shared ESLint configuration
│   │   └── prettier/                 # Code formatting configuration
│   └── scripts/                      # Shared build and utility scripts
│       ├── build-frontend.sh         # Frontend build script
│       ├── test-all.sh              # Run all tests
│       ├── deploy-static.sh         # Static site deployment
│       └── setup-dev.sh             # Development environment setup
├── docs/                             # Project documentation
│   ├── prd.md                       # Product Requirements Document
│   ├── wireframe-specification.md   # UI wireframes and specs
│   ├── architecture.md              # This architecture document
│   └── development-guide.md         # Development setup guide
├── .env.example                     # Environment variables template
├── .gitignore                       # Git ignore patterns
├── package.json                     # Root package.json for monorepo scripts
├── CLAUDE.md                        # AI development context file
└── README.md                        # Project overview and setup
```
