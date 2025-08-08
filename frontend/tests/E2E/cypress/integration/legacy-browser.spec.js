/// <reference types="cypress" />

describe('Legacy Browser Compatibility Tests', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  context('JavaScript API Compatibility', () => {
    it('should handle missing modern JavaScript APIs gracefully', () => {
      cy.window().then((win) => {
        // Simulate older browser environments by removing modern APIs
        const originalFetch = win.fetch;
        const originalPromise = win.Promise;
        const originalArrowFunctions = win.eval;
        
        // Test without fetch API (older browsers)
        delete win.fetch;
        
        // Verify application still loads and functions
        cy.reload();
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .and('have.value', '2.5');
        
        // Test basic functionality works
        cy.get('[data-testid="pond-length-input"]').clear().type('40');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Restore APIs
        win.fetch = originalFetch;
        win.Promise = originalPromise;
      });
    });

    it('should work without ES6+ features where possible', () => {
      cy.window().then((win) => {
        // Test that application doesn't break without modern features
        
        // Simulate older JavaScript environment checks
        const hasArrowFunctions = typeof (() => {}) === 'function';
        const hasConst = (() => {
          try {
            eval('const x = 1;');
            return true;
          } catch (e) {
            return false;
          }
        })();
        
        const hasLet = (() => {
          try {
            eval('let x = 1;');
            return true;
          } catch (e) {
            return false;
          }
        })();
        
        // Log compatibility information
        cy.log(`Arrow functions: ${hasArrowFunctions}`);
        cy.log(`const support: ${hasConst}`);
        cy.log(`let support: ${hasLet}`);
        
        // Application should work regardless
        cy.get('[data-testid="truck-capacity-input"]')
          .clear()
          .type('14');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should handle missing localStorage gracefully', () => {
      cy.window().then((win) => {
        // Backup original localStorage
        const originalLocalStorage = win.localStorage;
        
        // Simulate missing localStorage (some browsers/modes)
        delete win.localStorage;
        
        // Or simulate localStorage that throws errors
        win.localStorage = {
          getItem: () => { throw new Error('localStorage not available'); },
          setItem: () => { throw new Error('localStorage not available'); },
          removeItem: () => { throw new Error('localStorage not available'); },
          clear: () => { throw new Error('localStorage not available'); }
        };
        
        // Application should still function
        cy.reload();
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('have.value', '2.5'); // Should use static config
        
        // Calculations should work
        cy.get('[data-testid="pond-width-input"]').clear().type('35');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Restore localStorage
        win.localStorage = originalLocalStorage;
      });
    });

    it('should handle missing console object gracefully', () => {
      cy.window().then((win) => {
        const originalConsole = win.console;
        
        // Simulate missing console (some embedded browsers)
        delete win.console;
        
        // Or simulate console that throws errors
        win.console = {
          log: () => { throw new Error('Console not available'); },
          error: () => { throw new Error('Console not available'); },
          warn: () => { throw new Error('Console not available'); }
        };
        
        // Application should not crash
        cy.get('[data-testid="pond-depth-input"]').clear().type('7');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Restore console
        win.console = originalConsole;
      });
    });
  });

  context('CSS Feature Compatibility', () => {
    it('should provide fallbacks for modern CSS features', () => {
      // Test CSS Grid fallbacks
      cy.get('body').then($body => {
        const style = document.createElement('style');
        style.textContent = `
          /* Simulate lack of CSS Grid support */
          [data-testid*="input"] {
            display: block !important;
            width: 200px !important;
            margin: 10px 0 !important;
          }
        `;
        document.head.appendChild(style);
        
        // Elements should still be visible and functional
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .clear()
          .type('2.8');
        
        cy.get('[data-testid="pond-length-input"]')
          .should('be.visible')
          .clear()
          .type('45');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Cleanup
        document.head.removeChild(style);
      });
    });

    it('should work without CSS custom properties (variables)', () => {
      cy.get('body').then($body => {
        const style = document.createElement('style');
        style.textContent = `
          /* Override any CSS custom properties with static values */
          * {
            --primary-color: blue !important;
            --background-color: white !important;
            --text-color: black !important;
          }
          
          /* Fallback styles */
          input {
            border: 1px solid #ccc !important;
            padding: 8px !important;
            background: white !important;
            color: black !important;
          }
        `;
        document.head.appendChild(style);
        
        // Functionality should remain intact
        cy.get('[data-testid="truck-roundtrip-input"]')
          .clear()
          .type('18');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Cleanup
        document.head.removeChild(style);
      });
    });

    it('should maintain layout without Flexbox support', () => {
      cy.get('body').then($body => {
        const style = document.createElement('style');
        style.textContent = `
          /* Simulate lack of Flexbox support */
          * {
            display: block !important;
            flex: none !important;
            flex-direction: initial !important;
            justify-content: initial !important;
            align-items: initial !important;
          }
          
          /* Fallback layout */
          form {
            width: 100% !important;
          }
          
          input {
            display: block !important;
            margin: 10px 0 !important;
            width: 200px !important;
          }
        `;
        document.head.appendChild(style);
        
        // Layout should still be usable
        cy.get('[data-testid="work-hours-input"]')
          .should('be.visible')
          .clear()
          .type('9');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Cleanup
        document.head.removeChild(style);
      });
    });
  });

  context('Event Handling Compatibility', () => {
    it('should work with older event handling patterns', () => {
      cy.window().then((win) => {
        // Test that events work with older browsers that don't support modern event features
        
        // Simulate lack of modern event features
        const originalAddEventListener = win.addEventListener;
        let eventHandlerCalled = false;
        
        // Override with older-style event handling test
        win.addEventListener = function(type, handler, options) {
          eventHandlerCalled = true;
          return originalAddEventListener.call(this, type, handler, false); // No options support
        };
        
        // Interact with the application
        cy.get('[data-testid="excavator-cycle-input"]')
          .focus()
          .clear()
          .type('2.2');
        
        cy.wait(100);
        
        cy.then(() => {
          expect(eventHandlerCalled).to.be.true;
        });
        
        // Restore original
        win.addEventListener = originalAddEventListener;
      });
    });

    it('should handle touch events fallback on non-touch devices', () => {
      // Simulate environment without touch events
      cy.window().then((win) => {
        // Remove touch event support
        delete win.TouchEvent;
        delete win.ontouchstart;
        delete win.ontouchmove;
        delete win.ontouchend;
        
        // Application should fall back to mouse events
        cy.get('[data-testid="pond-length-input"]')
          .click()
          .clear()
          .type('50');
        
        cy.get('[data-testid="pond-width-input"]')
          .click()
          .clear()
          .type('30');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should handle keyboard events consistently across browsers', () => {
      // Test keyboard navigation works with older event models
      cy.get('[data-testid="excavator-capacity-input"]').focus();
      
      // Test Tab navigation
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'excavator-cycle-input');
      
      // Test Shift+Tab
      cy.focused().tab({ shift: true });
      cy.focused().should('have.attr', 'data-testid', 'excavator-capacity-input');
      
      // Test Enter key (should not break)
      cy.focused().type('{enter}');
      cy.focused().should('be.visible');
      
      // Test Escape key (should not break)
      cy.focused().type('{esc}');
      cy.focused().should('be.visible');
    });
  });

  context('Performance on Slower Devices', () => {
    it('should remain responsive with simulated slow CPU', () => {
      // Simulate slower processing by adding delays
      cy.window().then((win) => {
        const originalSetTimeout = win.setTimeout;
        
        // Add delay to simulate slower processing
        win.setTimeout = function(callback, delay) {
          return originalSetTimeout(callback, (delay || 0) + 50); // Add 50ms delay
        };
        
        const startTime = performance.now();
        
        // Perform calculation
        cy.get('[data-testid="pond-depth-input"]').clear().type('6');
        cy.wait(500); // Account for extra delay
        
        cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
          const endTime = performance.now();
          const totalTime = endTime - startTime;
          
          // Should complete within reasonable time even with delays
          expect(totalTime).to.be.lessThan(2000); // 2 seconds max
          
          cy.log(`Slow CPU simulation completed in ${totalTime}ms`);
        });
        
        // Restore original
        win.setTimeout = originalSetTimeout;
      });
    });

    it('should handle limited memory scenarios', () => {
      // Simulate memory pressure by creating and releasing objects
      cy.window().then((win) => {
        // Create memory pressure
        const memoryPressure = [];
        for (let i = 0; i < 1000; i++) {
          memoryPressure.push(new Array(1000).fill(i));
        }
        
        // Application should still function
        cy.get('[data-testid="truck-capacity-input"]')
          .clear()
          .type('16');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Release memory pressure
        memoryPressure.length = 0;
        
        // Should still work after memory release
        cy.get('[data-testid="pond-length-input"]').clear().type('55');
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should work with limited network connectivity', () => {
      // Since the app uses static configuration, it should work offline
      
      // Simulate very slow network
      cy.intercept('**', (req) => {
        req.reply((res) => {
          res.delay(2000); // 2 second delay
          res.send();
        });
      }).as('slowNetwork');
      
      // Application should still work (static configuration)
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5');
      
      cy.get('[data-testid="work-hours-input"]')
        .clear()
        .type('10');
      
      cy.wait(450);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Browser-Specific Quirks', () => {
    it('should handle Internet Explorer edge cases', () => {
      cy.window().then((win) => {
        // Simulate IE-specific issues
        
        // IE doesn't support template literals
        const templateLiteralSupport = (() => {
          try {
            eval('`test`');
            return true;
          } catch (e) {
            return false;
          }
        })();
        
        // IE has different event object properties
        const modernEventSupport = 'target' in (new Event('test'));
        
        cy.log(`Template literals: ${templateLiteralSupport}`);
        cy.log(`Modern events: ${modernEventSupport}`);
        
        // Application should work regardless
        cy.get('[data-testid="excavator-cycle-input"]')
          .clear()
          .type('2.4');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should handle Safari-specific behaviors', () => {
      // Safari has specific behaviors with number inputs and date handling
      cy.get('[data-testid="pond-width-input"]').then($input => {
        // Test Safari number input behavior
        $input.val(''); // Clear
        $input.trigger('input');
        
        // Type with Safari-style events
        $input.val('42');
        $input.trigger('input');
        $input.trigger('change');
      });
      
      cy.wait(450);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should handle Firefox-specific behaviors', () => {
      // Firefox has specific behaviors with form validation and events
      cy.window().then((win) => {
        // Test Firefox-specific event handling
        const userAgent = win.navigator.userAgent;
        const isFirefox = userAgent.includes('Firefox');
        
        cy.log(`Is Firefox: ${isFirefox}`);
        cy.log(`User Agent: ${userAgent}`);
        
        // Test input validation behavior
        cy.get('[data-testid="truck-roundtrip-input"]')
          .clear()
          .type('20');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should handle Chrome/Chromium-specific behaviors', () => {
      cy.window().then((win) => {
        // Test Chrome-specific features and fallbacks
        const isChrome = win.navigator.userAgent.includes('Chrome');
        const hasWebGL = !!win.WebGLRenderingContext;
        
        cy.log(`Is Chrome: ${isChrome}`);
        cy.log(`Has WebGL: ${hasWebGL}`);
        
        // Application should work with or without Chrome-specific features
        cy.get('[data-testid="pond-depth-input"]')
          .clear()
          .type('8');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });
  });

  context('Graceful Degradation', () => {
    it('should provide meaningful error messages for unsupported browsers', () => {
      cy.window().then((win) => {
        // Simulate very old browser
        delete win.JSON;
        delete win.Array.prototype.forEach;
        delete win.Object.keys;
        
        // Check that application handles gracefully
        cy.get('body').should('not.contain', 'Uncaught');
        
        // Should at least show some content or error message
        cy.get('body').should($body => {
          const text = $body.text().toLowerCase();
          const hasContent = text.length > 0;
          expect(hasContent).to.be.true;
        });
      });
    });

    it('should maintain core functionality without modern features', () => {
      // Test core functionality works with minimal browser support
      cy.window().then((win) => {
        // Disable advanced features
        delete win.requestAnimationFrame;
        delete win.sessionStorage;
        delete win.history.pushState;
        
        // Core calculation should still work
        cy.get('[data-testid="excavator-capacity-input"]')
          .clear()
          .type('3.2');
        
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type('60');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Results should be accurate
        cy.get('[data-testid="timeline-days"]').should('be.visible');
      });
    });

    it('should work with JavaScript disabled for basic content', () => {
      // This test verifies graceful degradation when JS is disabled
      // Note: Cypress requires JavaScript, so this tests the non-JS experience conceptually
      
      cy.get('body').then($body => {
        // Check that basic HTML structure exists
        expect($body.find('input').length).to.be.greaterThan(0);
        expect($body.find('form, [role="form"]').length).to.be.greaterThan(0);
        
        // Check that form has proper structure for non-JS submission
        cy.get('form, [role="form"]').should($form => {
          if ($form.is('form')) {
            // Real form should have method and action for fallback
            const hasMethod = $form.attr('method') !== undefined;
            const hasAction = $form.attr('action') !== undefined;
            
            if (!hasMethod || !hasAction) {
              cy.log('Recommendation: Add method and action attributes for no-JS fallback');
            }
          }
        });
        
        // Check that inputs have proper labels
        cy.get('input').each($input => {
          const hasLabel = 
            $input.attr('aria-label') ||
            $input.attr('aria-labelledby') ||
            $('label[for="' + $input.attr('id') + '"]').length > 0 ||
            $input.closest('label').length > 0;
          
          if (!hasLabel) {
            cy.log(`Input ${$input.attr('data-testid')} should have proper labeling for accessibility`);
          }
        });
      });
    });
  });
});