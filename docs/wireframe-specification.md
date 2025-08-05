# Wireframe Specification - Pond Digging Calculator

## Overview

This document provides detailed wireframe guidance and component specifications for the Pond Digging Calculator frontend implementation. It complements the front-end specification and provides visual layout guidance for development.

## 1. Information Architecture & Layout Strategy

### Primary Layout Concept
- **Desktop/Tablet**: Two-column layout (Input Panel | Results Panel)
- **Mobile**: Single-column stack (Input → Calculate Button → Results)

### Design Philosophy
- Device-appropriate complexity: comprehensive features on desktop/tablet, simplified calculator on mobile
- Professional construction tool aesthetic
- Touch-friendly for field use
- High contrast for outdoor visibility

## 2. Core Component Hierarchy

### Desktop/Tablet Wireframe (≥768px)
```
┌─────────────────────────────────────────────────┐
│ Header: "Pond Digging Calculator" + Logo       │
├─────────────────┬───────────────────────────────┤
│ INPUT PANEL     │ RESULTS PANEL                 │
│                 │                               │
│ • Basic Info    │ • Timeline Summary            │
│ • Dimensions    │ • Equipment Details           │
│ • Equipment     │ • Professional Export         │
│ • Site Factors  │                               │
│                 │                               │
│ [Calculate Btn] │                               │
└─────────────────┴───────────────────────────────┘
│ Footer: Help Links + About                     │
└─────────────────────────────────────────────────┘
```

### Mobile Wireframe (<768px)
```
┌─────────────────────────────┐
│ Header (Compact)            │
├─────────────────────────────┤
│ Basic Information           │
│ ┌─────────────────────────┐ │
│ │ Length: [    ] ft       │ │
│ │ Width:  [    ] ft       │ │
│ │ Depth:  [    ] ft       │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Equipment (Simplified)      │
│ ┌─────────────────────────┐ │
│ │ [Excavator Dropdown]    │ │
│ │ [Truck Dropdown]        │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [CALCULATE TIMELINE]        │
├─────────────────────────────┤
│ Results (Collapsible)       │
│ ┌─────────────────────────┐ │
│ │ Total Time: X.X days    │ │
│ │ [Show Details ▼]        │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## 3. Detailed Component Specifications

### Header Component
- **Desktop**: Full logo + navigation + project name
- **Tablet**: Compact logo + hamburger menu
- **Mobile**: Icon + app name only
- Height: 60px desktop, 50px mobile
- Background: Professional blue (#2C5282)
- Text: White for contrast

### Input Panel (Desktop/Tablet)
Width: 40% of viewport, minimum 320px, maximum 480px

#### Basic Information Section
```
┌─── Basic Information ─────────────┐
│ Project Name: [________________] │
│ Location:     [________________] │
│                                  │
│ Pond Dimensions:                 │
│ Length: [____] ft  Width: [____] ft │
│ Depth:  [____] ft                │
│                                  │
│ ☐ Irregular shape (advanced)     │
└──────────────────────────────────┘
```

**Field Specifications:**
- Input fields: 48px height for touch targets
- Labels: 14px, medium weight, dark gray (#4A5568)
- Validation: Inline error messages in red (#E53E3E)
- Required fields marked with red asterisk

#### Equipment Selection (Desktop)
```
┌─── Equipment Fleet ───────────────┐
│ Primary Excavator:               │
│ [Dropdown: 20-ton, 30-ton, etc.] │
│                                  │
│ Dump Trucks:                     │
│ [Dropdown: 10-yard, 15-yard...]  │
│ Quantity: [__] trucks            │
│                                  │
│ ☐ Add support equipment          │
│ ☐ Custom equipment specs         │
└──────────────────────────────────┘
```

**Equipment Dropdown Options:**
- Excavators: 20-ton, 30-ton, 40-ton, Custom
- Trucks: 10-yard, 15-yard, 20-yard, Custom
- Default selection: 30-ton excavator, 15-yard trucks
- Quantity selector: 1-10 range with +/- buttons

#### Site Factors (Expandable)
```
┌─── Site Conditions ──────────────┐
│ Soil Type: [Dropdown: Clay...]   │
│ Access:    [Dropdown: Good...]   │
│ Weather:   [Dropdown: Dry...]    │
│                                  │
│ ☐ Advanced factors (optional)    │
└──────────────────────────────────┘
```

**Default collapsed state** with "Show advanced options" toggle

### Results Panel (Desktop/Tablet)
Width: 60% of viewport, minimum 400px

#### Timeline Summary
```
┌─── Timeline Results ──────────────┐
│ 🕒 Total Project Time             │
│     2.3 days                     │
│                                  │
│ 📊 Breakdown:                    │
│ • Excavation: 1.8 days          │
│ • Hauling:    0.4 days          │
│ • Setup:      0.1 days          │
│                                  │
│ [📤 Export Results]              │
│ [📋 Copy Summary]               │
└──────────────────────────────────┘
```

**Visual Hierarchy:**
- Total time: 32px bold, primary color
- Breakdown items: 16px regular, with bullet points
- Action buttons: Secondary style, 44px touch targets

#### Equipment Details (Expandable)
```
┌─── Equipment Analysis ───────────┐
│ Primary Equipment:               │
│ • 30-ton excavator: 1.8 days    │
│ • 15-yard trucks: 3 units       │
│                                  │
│ Productivity Rates:              │
│ • Excavation: 120 cy/hr         │
│ • Hauling: 15 loads/day         │
│                                  │
│ [▼ Show detailed calculations]   │
└──────────────────────────────────┘
```

## 4. Responsive Breakpoint Strategy

### Breakpoint Definitions
- **Mobile**: 320px - 767px
- **Tablet**: 768px - 1023px  
- **Desktop**: 1024px+

### Breakpoint Behavior
- **Mobile (320-767px)**: 
  - Single column layout
  - Simplified inputs only
  - Collapsible results sections
  - Sticky calculate button
  
- **Tablet (768-1023px)**: 
  - Two column layout
  - Medium complexity inputs
  - Equipment options visible
  
- **Desktop (1024px+)**: 
  - Two column layout
  - Full feature set
  - Advanced options available
  - Detailed analysis panels

### Progressive Enhancement Features
- **Mobile**: Essential calculator functionality
- **Tablet**: + Equipment selection, basic site factors
- **Desktop**: + Advanced features, detailed breakdowns, export options

## 5. User Flow Wireframe

### Primary User Journey
```
Landing → Input Basic Info → Select Equipment → 
Review Site Factors → Calculate → View Results → Export
```

### Mobile-Specific Flow
1. **Input Phase**: Stack all inputs vertically with clear section headers
2. **Calculation**: Prominent calculate button, loading state feedback
3. **Results Phase**: Expandable cards with key metrics first

### Error States Flow
```
Invalid Input → Inline Error Message → 
Correction Guidance → Re-validation → Success State
```

## 6. Key Interaction Patterns

### Form Interactions
- **Real-time validation**: Inline error messages with clear recovery guidance
- **Progressive disclosure**: Advanced options hidden initially, expandable on demand
- **Smart defaults**: Pre-populated with common construction scenarios
- **Auto-calculation**: Debounced updates on input change (300ms delay)

### Results Interactions
- **Expandable sections**: Progressive detail disclosure for complex calculations
- **Copy functionality**: One-click copy to clipboard for key metrics
- **Export options**: PDF generation, email summary, print-friendly view
- **Comparison mode**: Save and compare multiple calculation scenarios

### Touch Interactions (Mobile)
- **Minimum touch targets**: 44px x 44px for all interactive elements
- **Swipe gestures**: Left/right swipe between input sections
- **Pull-to-refresh**: Update calculation with latest inputs
- **Long-press**: Context menus for advanced options

## 7. Accessibility Wireframe Requirements

### Visual Accessibility
- **High contrast ratios**: 4.5:1 minimum for normal text, 3:1 for large text
- **Color independence**: Information conveyed through multiple channels (color + text + icons)
- **Large touch targets**: 44px minimum for all interactive elements
- **Clear focus indicators**: 2px outline with high contrast color

### Keyboard Navigation
- **Tab order**: Logical left-to-right, top-to-bottom progression
- **Skip links**: "Skip to main content" and "Skip to results"
- **Keyboard shortcuts**: Enter to calculate, Escape to close modals
- **Focus management**: Proper focus handling for dynamic content

### Screen Reader Support
- **Semantic HTML**: Proper heading hierarchy (h1, h2, h3)
- **ARIA labels**: Descriptive labels for complex interactions
- **Live regions**: Results announcements for screen readers
- **Error announcements**: Clear error state communication

## 8. Component State Specifications

### Input States
- **Default**: Clean, ready for input
- **Active**: Focused with highlight border
- **Valid**: Subtle green indicator
- **Invalid**: Red border with error message
- **Disabled**: Grayed out, not interactive

### Button States
- **Default**: Primary blue background
- **Hover**: Darker blue background
- **Active**: Pressed state with subtle shadow
- **Loading**: Spinner icon with disabled state
- **Disabled**: Grayed out, reduced opacity

### Results States
- **Empty**: Placeholder content with call-to-action
- **Loading**: Skeleton screens or spinner
- **Success**: Populated with calculation results
- **Error**: Error message with retry option

## 9. Animation and Transition Guidelines

### Micro-interactions
- **Input focus**: Smooth border color transition (200ms)
- **Button hover**: Background color fade (150ms)
- **Results appearance**: Slide-up animation (300ms ease-out)
- **Section expansion**: Height animation (250ms ease-in-out)

### Loading States
- **Calculation progress**: Indeterminate progress bar
- **Result loading**: Skeleton screens for content areas
- **Export generation**: Modal with progress indication

## 10. Implementation Notes for AI Development

### Priority Implementation Order
1. **Phase 1**: Basic mobile layout with essential calculator
2. **Phase 2**: Desktop two-column layout with equipment selection
3. **Phase 3**: Advanced features and export functionality
4. **Phase 4**: Accessibility enhancements and micro-interactions

### Key Technical Considerations
- **Elm Architecture**: All wireframe states map to Model-View-Update pattern
- **Type Safety**: Input validation corresponds to Elm type system
- **Responsive Implementation**: CSS Grid for layout, Flexbox for components
- **Performance**: Lazy loading for advanced features, debounced calculations

### Testing Considerations
- **Mobile-first testing**: Start with smallest viewport, scale up
- **Touch device testing**: Verify all interactions work on touch screens
- **Keyboard testing**: Ensure full keyboard accessibility
- **Screen reader testing**: Verify with actual assistive technology

---

This wireframe specification should be used in conjunction with the front-end specification document to guide implementation. All visual designs should maintain the professional construction tool aesthetic while prioritizing usability and accessibility.