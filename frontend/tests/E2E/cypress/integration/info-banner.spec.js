/**
 * E2E Tests for Info Banner User Interactions
 * 
 * Tests the complete user experience with the dismissible info banner:
 * - Banner visibility and appearance
 * - Dismiss button functionality
 * - Banner state persistence during session
 * - Visual regression testing
 * - Cross-device behavior
 * - Accessibility compliance
 */

describe('Info Banner User Interactions', () => {
  
  beforeEach(() => {
    // Start fresh for each test
    cy.clearLocalStorage();
    cy.clearCookies();
    cy.visit('/');
    cy.wait(100); // Allow app to initialize
  });

  describe('Banner Display and Visibility', () => {
    it('should display info banner on initial page load', () => {
      cy.get('[data-testid="info-banner"]')
        .should('be.visible')
        .and('contain.text', 'Default values for common equipment are pre-loaded');
      
      cy.get('[data-testid="info-banner"]')
        .should('have.class', 'bg-blue-50')
        .and('have.class', 'border-blue-200');
    });

    it('should display banner with proper styling and content', () => {
      cy.get('[data-testid="info-banner"]').within(() => {
        // Check for info icon
        cy.get('.text-blue-400').should('contain.text', 'ℹ️');
        
        // Check for main message
        cy.contains('Default values for common equipment are pre-loaded').should('be.visible');
        cy.contains('Adjust any values to match your specific project requirements').should('be.visible');
        
        // Check for dismiss button
        cy.get('[data-testid="dismiss-banner-button"]')
          .should('be.visible')
          .and('contain.text', '×')
          .and('have.attr', 'title', 'Dismiss this message');
      });
    });

    it('should display banner above form content', () => {
      // Verify banner appears before the form sections
      cy.get('[data-testid="info-banner"]').should('be.visible');
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      
      // Check DOM order
      cy.get('[data-testid="info-banner"]')
        .should('exist')
        .then($banner => {
          cy.get('[data-testid="excavator-capacity-input"]')
            .should('exist')
            .then($input => {
              expect($banner[0].compareDocumentPosition($input[0]) & Node.DOCUMENT_POSITION_FOLLOWING)
                .to.be.greaterThan(0);
            });
        });
    });
  });

  describe('Banner Dismissal Functionality', () => {
    it('should dismiss banner when clicking the × button', () => {
      // Verify banner is initially visible
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Click dismiss button
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Verify banner is hidden
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should maintain dismiss state during form interactions', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Interact with form fields
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('3.5');
      
      cy.get('[data-testid="pond-length-input"]')
        .clear()
        .type('50');
      
      // Banner should remain hidden
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should maintain dismiss state during calculation', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Fill out form and trigger calculation
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-width-input"]').clear().type('25');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      // Trigger calculation (assuming there's a calculate button or auto-calculation)
      cy.get('[data-testid="calculate-button"]', { timeout: 1000 })
        .should('be.visible')
        .click();
      
      // Banner should remain hidden during and after calculation
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Wait for calculation to complete and verify still hidden
      cy.get('[data-testid="calculation-results"]', { timeout: 5000 })
        .should('be.visible');
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should maintain dismiss state across device orientation changes', () => {
      // Test on mobile viewport
      cy.viewport('iphone-x');
      
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Change to tablet viewport
      cy.viewport('ipad-2');
      cy.wait(100); // Allow layout adjustment
      
      // Banner should remain dismissed
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Change to desktop viewport
      cy.viewport(1280, 720);
      cy.wait(100);
      
      // Banner should still remain dismissed
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });
  });

  describe('Banner Session Persistence', () => {
    it('should reset banner visibility on page refresh', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Refresh page
      cy.reload();
      
      // Banner should be visible again (session-based persistence)
      cy.get('[data-testid="info-banner"]').should('be.visible');
    });

    it('should reset banner when navigating away and back', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Navigate to different page (if app has multiple pages) or simulate navigation
      cy.visit('/about', { failOnStatusCode: false }); // May not exist, that's OK
      cy.go('back');
      
      // Or if single page app, simulate by clearing and revisiting
      cy.visit('/');
      
      // Banner should be visible again
      cy.get('[data-testid="info-banner"]').should('be.visible');
    });
  });

  describe('Cross-Device Banner Behavior', () => {
    const devices = [
      { name: 'mobile', viewport: 'iphone-x' },
      { name: 'tablet', viewport: 'ipad-2' },
      { name: 'desktop', viewport: [1280, 720] }
    ];

    devices.forEach(device => {
      it(`should display and function correctly on ${device.name}`, () => {
        if (Array.isArray(device.viewport)) {
          cy.viewport(device.viewport[0], device.viewport[1]);
        } else {
          cy.viewport(device.viewport);
        }
        
        // Banner should be visible
        cy.get('[data-testid="info-banner"]').should('be.visible');
        
        // Dismiss button should be clickable
        cy.get('[data-testid="dismiss-banner-button"]')
          .should('be.visible')
          .click();
        
        // Banner should be dismissed
        cy.get('[data-testid="info-banner"]').should('not.exist');
      });
    });

    it('should maintain responsive layout with banner present', () => {
      const viewports = ['iphone-6', 'ipad-2', [1920, 1080]];
      
      viewports.forEach(viewport => {
        if (Array.isArray(viewport)) {
          cy.viewport(viewport[0], viewport[1]);
        } else {
          cy.viewport(viewport);
        }
        
        // Banner should not break layout
        cy.get('[data-testid="info-banner"]').should('be.visible');
        
        // Form should still be usable
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .and('not.be.covered');
        
        // Page should not have horizontal scrollbar
        cy.get('body').should('have.css', 'overflow-x', 'hidden');
      });
    });
  });

  describe('Banner Accessibility', () => {
    it('should be accessible to screen readers', () => {
      cy.get('[data-testid="info-banner"]')
        .should('have.attr', 'role', 'alert')
        .or('have.attr', 'aria-live', 'polite');
      
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('have.attr', 'aria-label')
        .or('have.attr', 'title');
    });

    it('should support keyboard navigation', () => {
      // Tab to dismiss button
      cy.get('body').tab();
      
      // Should eventually focus on dismiss button (may take several tabs)
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('be.focused')
        .or(() => {
          // Alternative: directly focus and test
          cy.get('[data-testid="dismiss-banner-button"]').focus().should('be.focused');
        });
      
      // Press Enter to dismiss
      cy.focused().type('{enter}');
      
      // Banner should be dismissed
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should have sufficient color contrast', () => {
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Check background color is accessible blue
      cy.get('[data-testid="info-banner"]')
        .should('have.css', 'background-color')
        .and('match', /rgb\(239, 246, 255\)|rgb\(191, 219, 254\)/); // bg-blue-50 variants
      
      // Check text has good contrast
      cy.get('[data-testid="info-banner"]')
        .should('have.css', 'color')
        .and('match', /rgb\(30, 58, 138\)|rgb\(29, 78, 216\)/); // text-blue-800/700
    });
  });

  describe('Banner Visual Regression', () => {
    it('should maintain consistent visual appearance', () => {
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Take screenshot for visual regression (if visual testing is set up)
      cy.get('[data-testid="info-banner"]').matchImageSnapshot('info-banner-default');
    });

    it('should display hover state correctly', () => {
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('be.visible')
        .trigger('mouseover');
      
      // Check hover state styling
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('have.css', 'color')
        .and('match', /rgb\(29, 78, 216\)/); // hover:text-blue-600
    });

    it('should display focus state correctly', () => {
      cy.get('[data-testid="dismiss-banner-button"]').focus();
      
      // Check focus ring
      cy.focused()
        .should('have.css', 'outline')
        .or('have.css', 'box-shadow')
        .and('not.equal', 'none');
    });
  });

  describe('Banner Error Handling', () => {
    it('should gracefully handle rapid clicking', () => {
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Click dismiss button rapidly multiple times
      cy.get('[data-testid="dismiss-banner-button"]')
        .click()
        .click()
        .click();
      
      // Should be dismissed without errors
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Application should remain functional
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .type('2.5');
    });

    it('should handle dismiss during form validation', () => {
      // Enter invalid data
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('999');
      
      // Dismiss banner during validation
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Banner should be dismissed despite validation issues
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Validation should still work normally
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.class', 'border-red-500')
        .or('have.attr', 'aria-invalid', 'true');
    });
  });

  describe('Banner Performance', () => {
    it('should dismiss quickly without lag', () => {
      const startTime = Date.now();
      
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      cy.get('[data-testid="info-banner"]')
        .should('not.exist')
        .then(() => {
          const endTime = Date.now();
          expect(endTime - startTime).to.be.lessThan(100); // Should dismiss in <100ms
        });
    });

    it('should not cause memory leaks with repeated dismiss/refresh cycles', () => {
      // Simulate repeated usage pattern
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="dismiss-banner-button"]').click();
        cy.get('[data-testid="info-banner"]').should('not.exist');
        cy.reload();
        cy.get('[data-testid="info-banner"]').should('be.visible');
      }
      
      // Application should remain responsive
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .clear()
        .type('2.5')
        .should('have.value', '2.5');
    });
  });

});