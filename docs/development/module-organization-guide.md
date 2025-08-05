# Module Organization Guide

## Overview
This guide establishes clear patterns for organizing Elm modules in the Pond Digging Calculator project, ensuring consistent structure and preventing circular dependencies.

## Module Hierarchy Structure

### Top-Level Directory Structure
```
frontend/src/
├── Main.elm                    # Application entry point
├── Types/                      # Domain types and data models
├── Components/                 # Reusable UI components  
├── Pages/                      # Top-level page components
├── Utils/                      # Pure utility functions
└── Styles/                     # Styling and theme modules
```

### Types/ Directory
**Purpose**: Core domain types, data models, and message definitions

```
Types/
├── Model.elm                   # Main application state
├── Messages.elm                # Application-wide messages
├── Equipment.elm               # Equipment domain types
├── Validation.elm              # Validation types and errors
├── DeviceType.elm             # Device detection types
└── Currency.elm               # Currency and formatting types
```

**Naming Convention**: PascalCase matching the domain concept
**Dependencies**: Types modules should have minimal dependencies on other modules

### Components/ Directory  
**Purpose**: Reusable UI components that can be composed together

```
Components/
├── EquipmentCard.elm          # Individual equipment display
├── EquipmentList.elm          # Equipment collection management
├── ProjectForm.elm            # Project configuration form
├── ResultsPanel.elm           # Calculation results display
├── ValidationMessage.elm      # Error/validation message display
└── Common/                    
    ├── Button.elm             # Reusable button component
    ├── Input.elm              # Form input components
    └── Modal.elm              # Modal dialog component
```

**Naming Convention**: PascalCase describing the component's purpose
**Dependencies**: May depend on Types/, Utils/, and Styles/ modules

### Pages/ Directory
**Purpose**: Top-level page components that compose multiple components

```
Pages/
├── Desktop.elm                # Desktop/tablet interface
├── Mobile.elm                 # Mobile interface  
├── Common.elm                 # Shared page elements
└── NotFound.elm               # 404 error page
```

**Naming Convention**: PascalCase indicating the page type or device target
**Dependencies**: May depend on all other module types

### Utils/ Directory
**Purpose**: Pure utility functions with no side effects

```
Utils/
├── Calculations.elm           # Core calculation engine
├── Validation.elm             # Input validation functions
├── Formatting.elm             # Display formatting utilities
├── Config.elm                 # Configuration loading
├── Storage.elm                # Local storage operations
├── DeviceDetector.elm         # Device type detection
└── Math.elm                   # Mathematical helper functions
```

**Naming Convention**: PascalCase describing the utility category
**Dependencies**: Should only depend on Types/ modules, never on Components/ or Pages/

### Styles/ Directory
**Purpose**: Styling definitions, theme constants, and responsive design

```
Styles/
├── Theme.elm                  # Tailwind class constants and color palette
├── Components.elm             # Component-specific style definitions
├── Responsive.elm             # Device-specific styling utilities
└── Layout.elm                 # Layout helper classes and grid definitions
```

**Naming Convention**: PascalCase describing the styling category
**Dependencies**: No dependencies on other project modules

## File Naming Conventions

### Module Files
- **PascalCase**: All module files use PascalCase matching their module name
- **Descriptive**: File names should clearly indicate the module's purpose
- **Singular vs Plural**: Use singular for individual concepts, plural for collections

```elm
-- Good examples
EquipmentCard.elm              -- Single component
ValidationMessage.elm          -- Single message component
Calculations.elm               -- Collection of calculation functions
```

### Test Files
- **Mirror Structure**: Test files mirror the src/ directory structure
- **Suffix Pattern**: Add "Tests" suffix to the module name

```
tests/
├── Types/
│   ├── EquipmentTests.elm
│   └── ValidationTests.elm
├── Components/
│   ├── EquipmentCardTests.elm
│   └── ProjectFormTests.elm
├── Utils/
│   ├── CalculationsTests.elm
│   └── ValidationTests.elm
└── Integration/
    ├── CalculationWorkflowTests.elm
    └── FormValidationTests.elm
```

## Module Dependency Guidelines

### Dependency Hierarchy (Top to Bottom)
1. **Types/** - No dependencies (except other Types/ modules)
2. **Utils/** - May depend on Types/ only
3. **Components/** - May depend on Types/, Utils/, Styles/
4. **Pages/** - May depend on any module category
5. **Main.elm** - May depend on any module category

### Circular Dependency Prevention

#### Allowed Dependencies
```elm
-- ✅ GOOD: Utils depending on Types
module Utils.Calculations exposing (..)
import Types.Equipment exposing (Equipment, CubicYards)

-- ✅ GOOD: Components depending on Types and Utils  
module Components.EquipmentCard exposing (..)
import Types.Equipment exposing (Equipment)
import Utils.Formatting exposing (formatCurrency)

-- ✅ GOOD: Pages composing Components
module Pages.Desktop exposing (..)
import Components.EquipmentCard exposing (renderEquipmentCard)
import Components.ProjectForm exposing (renderProjectForm)
```

#### Forbidden Dependencies
```elm
-- ❌ BAD: Types depending on Utils
module Types.Equipment exposing (..)
import Utils.Validation exposing (validateCapacity)  -- CIRCULAR!

-- ❌ BAD: Utils depending on Components
module Utils.Calculations exposing (..)
import Components.ResultsPanel exposing (renderResults)  -- WRONG LAYER!

-- ❌ BAD: Components depending on Pages
module Components.EquipmentCard exposing (..)
import Pages.Desktop exposing (someFunction)  -- WRONG DIRECTION!
```

#### Breaking Circular Dependencies
If you encounter circular dependencies, use these strategies:

1. **Extract Common Types**: Move shared types to a more fundamental module
2. **Invert Dependencies**: Pass functions as parameters instead of importing
3. **Create Bridge Modules**: Use intermediate modules to break cycles

```elm
-- Instead of circular dependency, pass function as parameter
renderEquipmentCard : (Equipment -> String) -> Equipment -> Html Msg
renderEquipmentCard formatFunction equipment =
    div [] [ text (formatFunction equipment) ]
```

## Import Organization Standards

### Import Ordering
1. **Standard Library**: Elm core modules first
2. **Third-Party**: Community packages 
3. **Local Types**: Project Types/ modules
4. **Local Modules**: Other project modules

```elm
-- Standard library imports
import Html exposing (Html, div, text, button)
import Html.Attributes exposing (class, id, disabled)
import Html.Events exposing (onClick)
import Json.Decode as Decode

-- Third-party imports
import RemoteData exposing (RemoteData)

-- Local type imports  
import Types.Model exposing (Model, Msg(..))
import Types.Equipment exposing (Equipment, EquipmentType(..))
import Types.Validation exposing (ValidationError)

-- Local module imports
import Utils.Calculations exposing (calculateTimeline)
import Utils.Formatting exposing (formatCurrency, formatDuration)
import Styles.Theme exposing (primaryButton, cardStyle)
```

### Import Grouping
- **One blank line** between each import category
- **Alphabetical order** within each category
- **Explicit imports** preferred over blanket imports

```elm
-- ✅ GOOD: Explicit imports
import Types.Equipment exposing (Equipment, CubicYards, EquipmentType(..))
import Utils.Validation exposing (validateInput, ValidationResult)

-- ❌ AVOID: Blanket imports (except for common Html functions)
import Types.Equipment exposing (..)
import Utils.Validation exposing (..)
```

### Exposing Guidelines
- **Types**: Expose the type and its constructors when needed
- **Functions**: Expose only what's needed by external modules
- **Internal**: Keep helper functions private

```elm
-- Public API exposure
module Utils.Calculations exposing 
    ( calculateTimeline
    , calculateCost
    , ValidationResult(..)
    )

-- Private helper functions not exposed
```

## Module Documentation Standards

### Module Header Documentation
Every module should start with documentation explaining its purpose:

```elm
{-| Equipment domain types and related functionality.

This module defines all equipment-related types used throughout the application,
including excavators, bulldozers, and their operational parameters.

# Types
@docs Equipment, EquipmentType, OperationalStatus

# Construction
@docs createEquipment, defaultEquipment

# Validation  
@docs validateEquipment, validateCapacity

-}
module Types.Equipment exposing
    ( Equipment
    , EquipmentType(..)
    , OperationalStatus(..)
    , createEquipment
    , defaultEquipment
    , validateEquipment
    , validateCapacity
    )
```

### Public API Documentation
- **@docs**: Document all exposed functions and types
- **Sections**: Group related functions with headers
- **Examples**: Provide usage examples for complex functions

## Best Practices Summary

### Module Design Principles
1. **Single Responsibility**: Each module should have one clear purpose
2. **High Cohesion**: Related functionality should be grouped together
3. **Low Coupling**: Minimize dependencies between modules
4. **Clear Interfaces**: Expose only what other modules need

### Dependency Management
1. **Unidirectional Flow**: Dependencies should flow in one direction
2. **Layer Isolation**: Respect the dependency hierarchy
3. **Minimal Imports**: Only import what you actually use
4. **Type Isolation**: Keep domain types in their own modules

### File Organization
1. **Predictable Structure**: Follow the established directory patterns
2. **Descriptive Names**: File names should clearly indicate contents
3. **Consistent Naming**: Use the same naming conventions throughout
4. **Test Mirroring**: Test files should mirror source structure