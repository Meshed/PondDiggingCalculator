/**
 * Build Cache Validation E2E Tests
 * 
 * Purpose: Prevent build cache issues from hiding interface changes
 * These tests ensure that major interface features are actually present in the browser,
 * not just compiled successfully.
 */

describe('Build Cache Validation Tests', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  describe('Fleet Management Interface Detection', () => {
    it('should display fleet management sections on desktop', () => {
      // Verify we're on desktop viewport
      cy.viewport(1920, 1080)
      
      // The most critical test: Fleet sections must be present
      cy.get('[data-testid="device-type"]').should('exist')
      
      // Fleet management sections should be present (Story 3.4 requirement)
      cy.contains('Excavator Fleet').should('be.visible')
      cy.contains('Truck Fleet').should('be.visible')
      
      // Add buttons should be present on desktop/tablet only
      cy.contains('Add Excavator').should('be.visible')
      cy.contains('Add Truck').should('be.visible')
      
      // Project Configuration section should still exist
      cy.contains('Project Configuration').should('be.visible')
    })

    it('should hide fleet management on mobile', () => {
      // Switch to mobile viewport
      cy.viewport(375, 667)
      
      // Fleet sections should be hidden on mobile
      cy.contains('Add Excavator').should('not.exist')
      cy.contains('Add Truck').should('not.exist')
      
      // But basic equipment should still be configurable
      cy.contains('Equipment Specifications').should('be.visible')
    })

    it('should not show old single-equipment interface on desktop', () => {
      cy.viewport(1920, 1080)
      
      // The OLD interface should NOT be present - this prevents regression
      cy.get('body').should('not.contain.text', 'Excavator Bucket Capacity')
        .and('not.contain.text', 'Excavator Cycle Time')
        .and('not.contain.text', 'Truck Capacity')
        .and('not.contain.text', 'Truck Round-trip Time')
      
      // Unless they're inside individual fleet items (which is OK)
      cy.get('[data-testid="device-type"]').should('exist')
    })
  })

  describe('Build System Integrity', () => {
    it('should load fresh JavaScript assets', () => {
      // Check that we're not serving stale cached assets
      cy.window().then((win) => {
        // Elm should be defined and working
        expect(win.Elm).to.exist
        expect(win.Elm.Main).to.exist
      })
    })

    it('should reflect latest code changes', () => {
      // This test would fail if serving stale cached files
      // Look for a unique identifier that proves we have the latest build
      
      // Check for fleet-specific functionality
      cy.viewport(1920, 1080)
      cy.get('[data-testid="device-type"]').should('exist')
      
      // If we see fleet sections, we know we have the latest code
      cy.contains('Excavator Fleet').should('exist')
      cy.contains('Truck Fleet').should('exist')
    })
  })

  describe('Development Workflow Protection', () => {
    it('should fail if major features are missing', () => {
      cy.viewport(1920, 1080)
      
      // Critical features that MUST be present after Story 3.4
      const requiredFeatures = [
        'Excavator Fleet',
        'Truck Fleet', 
        'Project Configuration',
        'Add Excavator',
        'Add Truck'
      ]
      
      requiredFeatures.forEach(feature => {
        cy.contains(feature).should('be.visible')
      })
    })
  })
})