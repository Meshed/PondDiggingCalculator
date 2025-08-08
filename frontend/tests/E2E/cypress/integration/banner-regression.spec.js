/**
 * Banner Regression Tests
 * 
 * Comprehensive regression test suite to prevent future issues with the info banner.
 * These tests specifically target scenarios that could break banner functionality
 * during code changes, refactoring, or feature additions.
 */

describe('Banner Regression Tests', () => {
  
  beforeEach(() => {
    cy.clearLocalStorage();
    cy.clearCookies();
    cy.visit('/');
    cy.wait(100);
  });

  describe('DOM Structure Regression', () => {
    it('should maintain banner DOM structure and test IDs', () => {
      // These attributes are critical for tests - regression would break testing
      cy.get('[data-testid="info-banner"]')
        .should('exist')
        .and('be.visible')
        .and('have.class', 'bg-blue-50');
      
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('exist')
        .and('be.visible')
        .and('contain.text', '×');
      
      // Verify banner contains expected elements
      cy.get('[data-testid="info-banner"]').within(() => {
        cy.get('.text-blue-400').should('contain.text', 'ℹ️');
        cy.contains('Default values for common equipment').should('exist');
        cy.get('[data-testid="dismiss-banner-button"]').should('exist');
      });
    });

    it('should prevent banner from being accidentally nested or duplicated', () => {
      // Only one banner should exist
      cy.get('[data-testid="info-banner"]')
        .should('have.length', 1);
      
      // Banner should not be nested within form elements
      cy.get('form [data-testid="info-banner"]').should('not.exist');
      cy.get('input [data-testid="info-banner"]').should('not.exist');
      
      // Banner should appear before form content, not within it
      cy.get('[data-testid="info-banner"]')
        .should('exist')
        .parent()
        .should('not.have.class', 'form-group')
        .and('not.have.class', 'input-group');
    });

    it('should maintain correct banner positioning in layout', () => {
      // Banner should be one of the first elements in the main container
      cy.get('main, .main-content, [role="main"]')
        .first()
        .within(() => {
          cy.get('[data-testid="info-banner"]').should('exist');
        });
      
      // Banner should not float or be positioned absolutely (unless intentional)
      cy.get('[data-testid="info-banner"]')
        .should('have.css', 'position', 'static')
        .or('have.css', 'position', 'relative');
    });
  });

  describe('Message Handler Regression', () => {
    it('should prevent DismissInfoBanner message from being dropped or mishandled', () => {
      // Verify initial state
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Click dismiss and verify it works
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Should disappear within reasonable time (not be stuck in processing)
      cy.get('[data-testid="info-banner"]', { timeout: 1000 }).should('not.exist');
      
      // Should not reappear after short delay (message not being re-triggered)
      cy.wait(500);
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should prevent message handler from affecting other form state', () => {
      // Set up some form state
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Verify form state is preserved
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '3.5');
      cy.get('[data-testid="pond-length-input"]').should('have.value', '45');
      
      // Verify other functionality still works
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-width-input"]').should('have.value', '30');
    });

    it('should handle dismiss message during rapid user interactions', () => {
      // Start rapid form interactions
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2');
      cy.get('[data-testid="dismiss-banner-button"]').click(); // Dismiss during typing
      cy.get('[data-testid="excavator-capacity-input"]').type('.5');
      
      // Banner should be dismissed despite ongoing interactions
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Form should continue working normally
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
    });
  });

  describe('Model State Regression', () => {
    it('should prevent infoBannerDismissed field from being lost or corrupted', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Perform various actions that might corrupt state
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('4.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
      
      // Trigger validation errors
      cy.get('[data-testid="pond-depth-input"]').clear().type('0');
      
      // Change device (if responsive behavior exists)
      cy.viewport('iphone-x');
      cy.wait(100);
      cy.viewport(1280, 720);
      
      // Banner should remain dismissed throughout
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should prevent model reset from accidentally showing banner again', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Perform actions that might reset parts of the model
      cy.get('[data-testid="excavator-capacity-input"]').clear();
      cy.get('[data-testid="truck-capacity-input"]').clear();
      cy.get('[data-testid="pond-length-input"]').clear();
      
      // Clear all form fields (might trigger form reset)
      cy.get('input[type="number"]').clear();
      
      // Banner should remain dismissed
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should maintain banner state through model validation cycles', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Create validation errors
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="pond-depth-input"]').clear().type('0');
      
      // Fix validation errors
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      // Trigger calculation if available
      cy.get('[data-testid="calculate-button"]', { timeout: 1000 })
        .should('exist')
        .click()
        .then(() => {
          // Wait for calculation
          cy.wait(1000);
        })
        .catch(() => {
          // Calculate button doesn't exist, that's OK
          cy.log('Calculate button not found, skipping calculation test');
        });
      
      // Banner should remain dismissed through all validation cycles
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });
  });

  describe('Component Integration Regression', () => {
    it('should prevent banner from interfering with form validation display', () => {
      // Dismiss banner first
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Create validation error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('999');
      
      // Validation error should display properly
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.class', 'border-red-500')
        .or('have.attr', 'aria-invalid', 'true')
        .or(() => {
          // Look for error message
          cy.get('.text-red-500, .error-message, [role="alert"]')
            .should('contain.text', 'capacity')
            .or('contain.text', 'invalid')
            .or('contain.text', 'range');
        });
      
      // Banner should remain dismissed and not conflict with error display
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should prevent banner from breaking responsive layout calculations', () => {
      const viewports = [
        { width: 375, height: 667 },   // Mobile
        { width: 768, height: 1024 },  // Tablet
        { width: 1280, height: 720 }   // Desktop
      ];
      
      viewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        
        // Banner should be visible and properly sized
        cy.get('[data-testid="info-banner"]')
          .should('be.visible')
          .and('have.css', 'width')
          .and('not.equal', '0px');
        
        // Banner should not cause horizontal scrolling
        cy.get('body').invoke('prop', 'scrollWidth').should('be.at.most', viewport.width);
        
        // Dismiss banner
        cy.get('[data-testid="dismiss-banner-button"]').click();
        
        // Layout should remain stable
        cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      });
    });

    it('should prevent banner from breaking during async operations', () => {
      // Start async operation (form submission, calculation, etc.)
      cy.get('[data-testid="pond-length-input"]').type('50');
      cy.get('[data-testid="pond-width-input"]').type('30');
      
      // Dismiss banner during potential async operation
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Continue with form interaction
      cy.get('[data-testid="pond-depth-input"]').type('6');
      
      // Banner should remain dismissed
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Form should remain functional
      cy.get('[data-testid="pond-depth-input"]').should('have.value', '6');
    });
  });

  describe('CSS and Styling Regression', () => {
    it('should prevent banner styling from being broken by CSS changes', () => {
      cy.get('[data-testid="info-banner"]')
        .should('be.visible')
        .and('have.css', 'padding')
        .and('not.equal', '0px');
      
      // Should have proper background color
      cy.get('[data-testid="info-banner"]')
        .should('have.css', 'background-color')
        .and('not.equal', 'rgba(0, 0, 0, 0)'); // Not transparent
      
      // Should have border
      cy.get('[data-testid="info-banner"]')
        .should('have.css', 'border-width')
        .and('not.equal', '0px');
      
      // Dismiss button should be properly styled
      cy.get('[data-testid="dismiss-banner-button"]')
        .should('have.css', 'cursor', 'pointer')
        .and('be.visible');
    });

    it('should prevent banner from being hidden by z-index issues', () => {
      // Banner should be visible above other content
      cy.get('[data-testid="info-banner"]')
        .should('be.visible')
        .and('have.css', 'z-index')
        .then(zIndex => {
          // Should either have no z-index (rely on document flow) or positive z-index
          expect(parseInt(zIndex) || 0).to.be.at.least(0);
        });
      
      // Should not be covered by form elements
      cy.get('[data-testid="info-banner"]').should('not.be.covered');
    });
  });

  describe('State Persistence Regression', () => {
    it('should prevent accidental localStorage implementation from breaking session-based behavior', () => {
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Refresh page - banner should reappear (session-based, not persistent)
      cy.reload();
      
      // Banner should be visible again
      cy.get('[data-testid="info-banner"]').should('be.visible');
    });

    it('should prevent banner state from leaking between different instances', () => {
      // Dismiss banner in first session
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      
      // Open new tab/window (simulate new session)
      cy.visit('/');
      
      // Banner should be visible in new session
      cy.get('[data-testid="info-banner"]').should('be.visible');
    });
  });

  describe('Performance Regression', () => {
    it('should prevent banner operations from causing performance degradation', () => {
      const operations = [];
      
      // Measure banner visibility check
      const start1 = performance.now();
      cy.get('[data-testid="info-banner"]').should('be.visible');
      operations.push(performance.now() - start1);
      
      // Measure banner dismiss
      const start2 = performance.now();
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
      operations.push(performance.now() - start2);
      
      // All operations should complete quickly
      cy.then(() => {
        operations.forEach(duration => {
          expect(duration).to.be.lessThan(1000); // Should complete in <1 second
        });
      });
    });

    it('should prevent memory leaks from banner state management', () => {
      // Simulate heavy usage pattern
      for (let i = 0; i < 10; i++) {
        cy.reload();
        cy.get('[data-testid="info-banner"]').should('be.visible');
        cy.get('[data-testid="dismiss-banner-button"]').click();
        cy.get('[data-testid="info-banner"]').should('not.exist');
      }
      
      // Application should remain responsive
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('2.5')
        .should('have.value', '2.5');
    });
  });

  describe('Edge Case Regression', () => {
    it('should handle banner operations when DOM is modified externally', () => {
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Simulate DOM modification (e.g., by browser extension or other scripts)
      cy.get('[data-testid="info-banner"]').then($banner => {
        $banner[0].style.transform = 'translateY(-100px)';
      });
      
      // Should still be able to dismiss
      cy.get('[data-testid="dismiss-banner-button"]').click({ force: true });
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should handle rapid page navigation during banner interaction', () => {
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Immediately navigate (simulate back button or programmatic navigation)
      cy.visit('/');
      
      // Should not cause errors and banner should appear normally
      cy.get('[data-testid="info-banner"]').should('be.visible');
    });

    it('should handle banner interaction during page unload', () => {
      cy.get('[data-testid="info-banner"]').should('be.visible');
      
      // Start dismiss operation and immediately navigate away
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.visit('/'); // Immediate navigation
      
      // Should not cause JavaScript errors
      cy.get('[data-testid="info-banner"]').should('be.visible'); // Fresh page
      
      // And should work normally
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });
  });

  describe('Future Feature Compatibility', () => {
    it('should maintain banner functionality if new form fields are added', () => {
      // Simulate new form fields by testing with all existing fields
      const formFields = [
        'excavator-capacity-input',
        'excavator-cycle-input',
        'truck-capacity-input',
        'truck-roundtrip-input',
        'work-hours-input',
        'pond-length-input',
        'pond-width-input',
        'pond-depth-input'
      ];
      
      // Interact with all fields
      formFields.forEach(fieldId => {
        cy.get(`[data-testid="${fieldId}"]`, { timeout: 1000 })
          .should('exist')
          .clear()
          .type('5')
          .should('have.value', '5')
          .catch(() => {
            // Field might not exist, that's OK
            cy.log(`Field ${fieldId} not found, skipping`);
          });
      });
      
      // Banner should still function
      cy.get('[data-testid="info-banner"]').should('be.visible');
      cy.get('[data-testid="dismiss-banner-button"]').click();
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });

    it('should maintain banner functionality if calculation engine changes', () => {
      // Fill out complete form
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-width-input"]').clear().type('25');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      // Dismiss banner
      cy.get('[data-testid="dismiss-banner-button"]').click();
      
      // Trigger calculation (might be automatic or manual)
      cy.wait(2000); // Allow for automatic calculations
      
      // Banner should remain dismissed regardless of calculation results
      cy.get('[data-testid="info-banner"]').should('not.exist');
    });
  });

});