# Technical Architecture Documentation

## Project Structure Overview

The Pond Digging Calculator is a pure frontend Elm application designed with functional programming principles and device-responsive architecture. This document provides comprehensive technical documentation for understanding, modifying, and extending the application.

### Directory Structure

```
PondDiggingCalculator/
├── frontend/               # Elm application
│   ├── src/               # Source code
│   │   ├── Main.elm       # Application entry point
│   │   ├── Types/         # Domain types and models
│   │   ├── Components/    # Reusable UI components
│   │   ├── Pages/         # Device-specific page layouts
│   │   ├── Views/         # View rendering logic
│   │   ├── Utils/         # Business logic and utilities
│   │   └── Styles/        # Theming and styling
│   ├── tests/             # Test suites
│   ├── public/            # Static assets
│   └── dist/              # Build output
├── docs/                  # Documentation
└── config/                # Configuration files
```

## Elm Architecture Patterns (Model-View-Update)

### Core Architecture

The application follows the Elm Architecture pattern with strict unidirectional data flow:

```elm
-- Model: Application State
type alias Model =
    { projectForm : ProjectForm
    , equipmentFleet : List Equipment
    , calculations : CalculationResults
    , deviceType : DeviceType
    , errors : List ValidationError
    }

-- Messages: User Actions and System Events
type Msg
    = UpdateProjectField Field String
    | AddEquipment Equipment
    | RemoveEquipment EquipmentId
    | Calculate
    | DeviceTypeDetected DeviceType
    | ValidationError ValidationError

-- Update: State Transitions
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UpdateProjectField field value ->
            ({ model | projectForm = updateField field value model.projectForm }, Cmd.none)
        
        Calculate ->
            let
                results = calculateTimeline model.projectForm model.equipmentFleet
            in
            ({ model | calculations = results }, Cmd.none)
        -- ... other message handlers
```

### State Management Principles

1. **Single Source of Truth**: All application state resides in the Model
2. **Immutable Updates**: State is never mutated, only replaced with new values
3. **Pure Functions**: All update logic is pure and deterministic
4. **Explicit Effects**: Side effects are managed through Commands (Cmd)

### Component Architecture

Components are organized by responsibility:

- **Types/**: Domain models with no business logic
- **Utils/**: Pure functions for calculations and validation
- **Components/**: Reusable UI elements with encapsulated behavior
- **Pages/**: Top-level layouts that orchestrate components
- **Views/**: Device-specific view adapters

## Build Pipeline and Toolchain

### Build Process

The application uses a modern JavaScript toolchain optimized for Elm:

#### Development Build
```bash
npm run dev
# Executes: parcel serve frontend/public/index.html --dist-dir frontend/dist
```

Features:
- Hot module replacement for instant feedback
- Source maps for debugging
- Development-time error messages
- No minification for readability

#### Production Build
```bash
npm run build
# Executes: parcel build frontend/public/index.html --dist-dir frontend/dist --no-source-maps
```

Optimizations:
- Dead code elimination via Elm compiler
- JavaScript minification and bundling
- CSS purging for unused Tailwind classes
- Asset optimization and compression
- No source maps for smaller bundle size

### Toolchain Components

#### Elm Compiler (0.19.1)
- Type checking and inference
- Compile-time optimizations
- JavaScript code generation
- Dead code elimination

#### Parcel Bundler (2.0+)
- Zero-configuration bundling
- Automatic Elm compilation
- CSS processing with PostCSS
- Asset optimization
- Hot module replacement

#### Tailwind CSS (3.4+)
- Utility-first CSS framework
- JIT (Just-In-Time) compilation
- PurgeCSS integration for production
- Responsive design utilities

### Build Optimization

The build process includes several optimization steps:

1. **Elm Optimizations**:
   - `--optimize` flag enables smaller output
   - Dead code elimination removes unused functions
   - Inline expansion for performance

2. **CSS Optimizations**:
   - Tailwind JIT only includes used classes
   - CSS minification and compression
   - Critical CSS extraction

3. **JavaScript Optimizations**:
   - Tree shaking removes unused code
   - Minification reduces file size
   - Code splitting for lazy loading (future)

## Deployment Process to GitHub Pages

### Automated Deployment Pipeline

The application deploys automatically via GitHub Actions:

#### Workflow Configuration (.github/workflows/deploy-static.yml)
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
        working-directory: ./frontend
      
      - name: Run tests
        run: npm test
        working-directory: ./frontend
      
      - name: Build application
        run: npm run build
        working-directory: ./frontend
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/github-pages-action@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./frontend/dist
          publish_branch: gh-pages
```

### Deployment Steps

1. **Trigger**: Push to main branch or manual workflow dispatch
2. **Environment Setup**: Ubuntu runner with Node.js 20
3. **Dependencies**: Install locked dependencies with `npm ci`
4. **Testing**: Run full test suite to validate changes
5. **Build**: Create production build with optimizations
6. **Deploy**: Push dist/ contents to gh-pages branch
7. **Activation**: GitHub Pages serves from gh-pages branch

### Manual Deployment

For manual deployment or rollback:

```bash
# Build production version
cd frontend
npm run build

# Deploy to GitHub Pages (requires gh-pages package)
npm install -g gh-pages
gh-pages -d dist

# Rollback to previous version
git checkout gh-pages
git revert HEAD
git push origin gh-pages
```

## Architecture Decision Records (ADRs)

### ADR-001: Pure Frontend Architecture

**Status**: Accepted  
**Date**: 2025-01-15

**Context**: Need to minimize infrastructure complexity and deployment costs.

**Decision**: Build as pure client-side application with no backend dependencies.

**Consequences**:
- ✅ Zero infrastructure costs
- ✅ Simple deployment to static hosting
- ✅ No server maintenance required
- ❌ Limited to client-side storage
- ❌ No user accounts or data persistence

---

### ADR-002: Elm for Frontend Development

**Status**: Accepted  
**Date**: 2025-01-15

**Context**: Need reliable, maintainable code with minimal runtime errors.

**Decision**: Use Elm 0.19.1 for all frontend development.

**Consequences**:
- ✅ No runtime exceptions
- ✅ Enforced immutability
- ✅ Excellent refactoring support
- ✅ Time-travel debugging
- ❌ Smaller ecosystem than JavaScript
- ❌ Learning curve for developers

---

### ADR-003: Tailwind CSS for Styling

**Status**: Accepted  
**Date**: 2025-01-20

**Context**: Need consistent, responsive styling with minimal CSS overhead.

**Decision**: Use Tailwind CSS with JIT compilation.

**Consequences**:
- ✅ Consistent design system
- ✅ Minimal CSS bundle size
- ✅ Responsive utilities built-in
- ✅ No CSS naming conflicts
- ❌ HTML can become verbose
- ❌ Requires purging configuration

---

### ADR-004: Static Configuration Files

**Status**: Accepted  
**Date**: 2025-02-01

**Context**: Equipment defaults need to be configurable without code changes.

**Decision**: Use build-time JSON configuration files compiled into application.

**Consequences**:
- ✅ Configuration changes don't require code modifications
- ✅ Type-safe after compilation
- ✅ No runtime HTTP requests
- ❌ Requires rebuild for configuration changes
- ❌ Configuration not modifiable by end users

---

### ADR-005: Device-Responsive Architecture

**Status**: Accepted  
**Date**: 2025-02-10

**Context**: Application must work across desktop, tablet, and mobile devices.

**Decision**: Implement device-specific layouts and functionality adaptations.

**Consequences**:
- ✅ Optimal experience per device type
- ✅ Reduced complexity on mobile
- ✅ Full features on desktop
- ❌ Multiple view implementations
- ❌ Additional testing requirements

## Module Responsibilities

### Core Modules

#### Main.elm
- Application entry point
- Browser program initialization
- Top-level message routing
- Port subscriptions

#### Types/Model.elm
- Central application state definition
- Domain type definitions
- Type aliases for clarity

#### Utils/Calculations.elm
- Core calculation engine
- Timeline estimation logic
- Cost calculations
- Pure mathematical functions

#### Utils/Validation.elm
- Input validation rules
- Error message generation
- Constraint checking
- Data sanitization

#### Components/ProjectForm.elm
- Project input form rendering
- Field-level validation display
- User input handling
- Form state management

#### Components/ResultsPanel.elm
- Calculation results display
- Timeline visualization
- Cost breakdown presentation
- Export functionality

#### Pages/Desktop.elm
- Desktop layout orchestration
- Full feature set
- Multi-panel layout
- Advanced interactions

#### Pages/Mobile.elm
- Mobile-optimized layout
- Simplified interface
- Touch-friendly controls
- Reduced feature set

## Performance Considerations

### Optimization Strategies

1. **Lazy Evaluation**:
   ```elm
   -- Use lazy for expensive computations
   viewResults : Model -> Html Msg
   viewResults model =
       Html.Lazy.lazy2 renderResults model.calculations model.config
   ```

2. **Debounced Inputs**:
   ```elm
   -- Debounce rapid input changes
   subscriptions : Model -> Sub Msg
   subscriptions model =
       Time.every 300 (always TriggerCalculation)
   ```

3. **Virtual DOM Efficiency**:
   ```elm
   -- Use keyed elements for lists
   viewEquipmentList : List Equipment -> Html Msg
   viewEquipmentList equipment =
       Html.Keyed.node "div" []
           (List.map (\e -> (e.id, viewEquipment e)) equipment)
   ```

### Performance Targets

- Initial load: < 3 seconds on 3G
- Calculation updates: < 100ms
- Input response: < 50ms
- Animation frame rate: 60 FPS

## Security Considerations

### Input Validation
- All user inputs validated before processing
- Numeric bounds checking
- String length limits
- Special character filtering

### Data Handling
- No sensitive data storage
- No external API calls in MVP
- Client-side only processing
- No user authentication required

### Content Security Policy
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               style-src 'self' 'unsafe-inline'; 
               script-src 'self';">
```

## Browser Compatibility

### Supported Browsers
- Chrome 90+ (recommended)
- Firefox 88+
- Safari 14+
- Edge 90+

### Progressive Enhancement
- Core functionality works without JavaScript (degraded)
- CSS Grid fallback to Flexbox
- Touch events with mouse fallbacks
- Responsive images with srcset

## Development Tools

### Elm Development
- elm-format: Code formatting
- elm-test: Unit testing
- elm-review: Code quality
- elm-live: Development server (alternative to Parcel)

### Debugging
- Elm Debugger: Time-travel debugging
- Browser DevTools: Network and performance
- Redux DevTools: State inspection (via ports)

### Testing Tools
- elm-test: Unit and integration tests
- Cypress: End-to-end testing
- Jest: JavaScript utility testing
- Lighthouse: Performance auditing