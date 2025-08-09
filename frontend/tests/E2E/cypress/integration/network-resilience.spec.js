/// <reference types="cypress" />

describe('Network Resilience Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1200, 800);
  });

  context('Offline Functionality', () => {
    it('should work offline with cached configuration', () => {
      // First, ensure the app loads normally with network
      cy.get('[data-testid="timeline-result"]').should('exist');
      
      // Verify configuration is loaded
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value').and('not.be.empty');
      
      // Test basic functionality while online
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('6');
      
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Simulate going offline
      cy.window().then((win) => {
        // Mock navigator.onLine to false
        cy.stub(win.navigator, 'onLine').value(false);
        
        // Mock fetch to fail for new requests
        cy.intercept('*', { forceNetworkError: true }).as('networkError');
      });
      
      // Test that app continues to work offline
      cy.get('[data-testid="pond-length-input"]').clear().type('75');
      cy.wait(500);
      
      // Calculations should still work (no network required)
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Fleet operations should still work
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      // Configuration changes should persist in memory
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('App continues to function offline');
    });

    it('should handle network reconnection gracefully', () => {
      // Start online
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Go offline
      cy.window().then((win) => {
        cy.stub(win.navigator, 'onLine').value(false);
      });
      
      // Make changes while offline
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      cy.wait(500);
      
      // Reconnect
      cy.window().then((win) => {
        cy.stub(win.navigator, 'onLine').value(true);
      });
      
      // App should continue working normally
      cy.get('[data-testid="pond-width-input"]').clear().type('40');
      cy.wait(500);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Test that all functionality remains available
      cy.get('[data-testid="add-truck-btn"]').click();
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      cy.log('Network reconnection handled gracefully');
    });
  });

  context('Network Error Handling', () => {
    it('should handle slow network connections', () => {
      // Simulate slow network by intercepting and delaying requests
      cy.intercept('GET', '**/*', (req) => {
        req.reply((res) => {
          // Add 2 second delay to simulate slow network
          return new Promise(resolve => {
            setTimeout(() => resolve(res), 2000);
          });
        });
      }).as('slowNetwork');
      
      // Reload to test with slow network
      cy.reload();
      
      // App should still load and function, just slower
      cy.get('[data-testid="timeline-result"]', { timeout: 10000 }).should('be.visible');
      
      // Test that user can still interact while network is slow
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible')
        .clear()
        .type('2.8');
      
      cy.wait(1000);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('App handles slow network connections');
    });

    it('should handle intermittent network failures', () => {
      let requestCount = 0;
      
      // Simulate intermittent failures (fail every other request)
      cy.intercept('*', (req) => {
        requestCount++;
        if (requestCount % 2 === 0) {
          req.reply({ forceNetworkError: true });
        } else {
          req.continue();
        }
      }).as('intermittentFailures');
      
      // Test that app remains stable despite network issues
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      cy.get('[data-testid="pond-width-input"]').clear().type('25');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      cy.wait(1000);
      
      // Core functionality should still work
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Fleet operations should be unaffected by network issues
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      cy.log('App handles intermittent network failures');
    });

    it('should provide appropriate error messages for network issues', () => {
      // Simulate complete network failure
      cy.intercept('*', { forceNetworkError: true }).as('networkFailure');
      
      // Try to reload the page
      cy.reload();
      
      // Since configuration is now build-time, the app should still load
      // but we can test error handling for any potential network requests
      
      // App should load with fallback configuration
      cy.get('body', { timeout: 10000 }).should('be.visible');
      
      // Test that calculations still work with cached/default config
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
      
      // If there are any error messages, they should be user-friendly
      cy.get('body').then(($body) => {
        if ($body.find('[data-testid="error-message"]').length > 0) {
          cy.get('[data-testid="error-message"]')
            .should('be.visible')
            .and('not.contain', 'undefined')
            .and('not.contain', 'null')
            .and('not.contain', 'Error:');
        }
      });
      
      cy.log('Network error handling tested');
    });
  });

  context('Configuration Resilience', () => {
    it('should fall back to default configuration when network fails', () => {
      // Test that app works even if external config loading fails
      cy.intercept('GET', '**/config.json', { forceNetworkError: true }).as('configFail');
      
      cy.reload();
      
      // App should still load with built-in defaults
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible')
        .and('have.value');
      
      // Default configuration should allow normal operation
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      cy.wait(500);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Fleet operations should work with default limits
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      cy.log('Fallback configuration works correctly');
    });

    it('should validate configuration integrity', () => {
      // Test with corrupted configuration data
      cy.intercept('GET', '**/config.json', {
        body: { invalid: 'configuration', missing: 'required fields' }
      }).as('corruptConfig');
      
      cy.reload();
      
      // App should handle corrupted config gracefully
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
      
      // Should fall back to safe defaults
      cy.get('[data-testid="timeline-result"]').should('exist');
      
      // Basic functionality should remain available
      cy.get('[data-testid="pond-length-input"]').clear().type('35');
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('Configuration integrity validation works');
    });
  });

  context('Performance Under Network Stress', () => {
    it('should maintain performance during network issues', () => {
      // Simulate high latency network
      cy.intercept('*', (req) => {
        req.reply((res) => {
          return new Promise(resolve => {
            setTimeout(() => resolve(res), 1000);
          });
        });
      }).as('highLatency');
      
      const startTime = performance.now();
      
      // Test calculation performance isn't affected by network issues
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.2');
      cy.get('[data-testid="pond-length-input"]').clear().type('55');
      cy.get('[data-testid="pond-width-input"]').clear().type('35');
      
      cy.wait(800); // Wait for calculation debounce
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.then(() => {
        const endTime = performance.now();
        const totalTime = endTime - startTime;
        
        // Calculation performance should not be significantly impacted
        // by network latency (calculations are client-side)
        expect(totalTime).to.be.lessThan(5000);
        
        cy.log(`Calculations completed in ${totalTime}ms despite network latency`);
      });
    });

    it('should handle concurrent network issues and fleet operations', () => {
      // Simulate random network failures
      cy.intercept('*', (req) => {
        if (Math.random() > 0.7) {
          req.reply({ forceNetworkError: true });
        } else {
          req.continue();
        }
      }).as('randomNetworkIssues');
      
      const startTime = performance.now();
      
      // Perform multiple fleet operations
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.wait(200);
      }
      
      // Configure equipment
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .first()
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('2.8');
      
      // Set pond parameters
      cy.get('[data-testid="pond-length-input"]').clear().type('65');
      cy.get('[data-testid="pond-depth-input"]').clear().type('7');
      
      cy.wait(1000);
      
      // Verify everything still works
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 4);
      
      cy.then(() => {
        const endTime = performance.now();
        const totalTime = endTime - startTime;
        
        expect(totalTime).to.be.lessThan(8000);
        
        cy.log(`Fleet operations completed in ${totalTime}ms with network issues`);
      });
    });
  });

  context('Browser Storage Resilience', () => {
    it('should handle localStorage unavailability', () => {
      // Simulate localStorage being unavailable
      cy.window().then((win) => {
        cy.stub(win.Storage.prototype, 'setItem').throws(new Error('Storage unavailable'));
        cy.stub(win.Storage.prototype, 'getItem').returns(null);
      });
      
      // App should still function without local storage
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .clear()
        .type('2.7');
      
      cy.get('[data-testid="pond-length-input"]').clear().type('42');
      cy.wait(500);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Fleet operations should work without storage
      cy.get('[data-testid="add-truck-btn"]').click();
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      cy.log('App functions without localStorage');
    });

    it('should handle corrupted localStorage data', () => {
      // Set corrupted data in localStorage
      cy.window().then((win) => {
        win.localStorage.setItem('pondDiggingCalculator', 'corrupted-data-not-json');
        win.localStorage.setItem('deviceType', 'invalid-device');
      });
      
      cy.reload();
      
      // App should handle corrupted storage gracefully
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
      
      // Should fall back to defaults
      cy.get('[data-testid="timeline-result"]').should('exist');
      
      // Normal functionality should be restored
      cy.get('[data-testid="pond-length-input"]').clear().type('38');
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('Corrupted localStorage handled gracefully');
    });
  });
});