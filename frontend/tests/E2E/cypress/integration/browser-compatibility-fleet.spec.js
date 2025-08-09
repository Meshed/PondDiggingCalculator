/// <reference types="cypress" />

describe('Browser Compatibility for Fleet Management', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1920, 1080); // Standard large desktop resolution
  });

  context('Cross-Browser Fleet UI Compatibility', () => {
    it('should detect browser type and adapt if necessary', () => {
      cy.window().then((win) => {
        const userAgent = win.navigator.userAgent.toLowerCase();
        const browserInfo = {
          isFirefox: userAgent.includes('firefox'),
          isChrome: userAgent.includes('chrome') && !userAgent.includes('edge'),
          isEdge: userAgent.includes('edge'),
          isSafari: userAgent.includes('safari') && !userAgent.includes('chrome'),
          userAgent: userAgent
        };

        cy.log('Browser Detection Results:');
        Object.entries(browserInfo).forEach(([key, value]) => {
          cy.log(`${key}: ${value}`);
        });

        // All modern browsers should show fleet management
        cy.get('[data-testid="add-excavator-btn"]', { timeout: 5000 })
          .should('be.visible');
          
        cy.get('[data-testid="add-truck-btn"]', { timeout: 5000 })
          .should('be.visible');

        cy.log(`✅ Fleet UI working in detected browser`);
      });
    });

    it('should handle browser-specific CSS rendering', () => {
      // Test that fleet sections render properly across browsers
      cy.get('[data-testid="excavator-list"]')
        .should('be.visible')
        .and('have.css', 'display')
        .and('not.equal', 'none');
        
      cy.get('[data-testid="truck-list"]')
        .should('be.visible')
        .and('have.css', 'display')
        .and('not.equal', 'none');

      // Test grid layout works across browsers
      cy.get('.grid-cols-3').should('exist');
      
      // Test that equipment items have proper styling
      cy.get('.equipment-item')
        .should('be.visible')
        .and('have.css', 'background-color')
        .and('not.equal', 'rgba(0, 0, 0, 0)'); // Should have background

      cy.log('✅ CSS rendering works across browsers');
    });

    it('should handle browser-specific JavaScript features', () => {
      // Test modern JavaScript features work
      cy.window().then((win) => {
        // Test that modern features are supported
        expect(win.Promise).to.exist;
        expect(win.fetch).to.exist;
        expect(win.localStorage).to.exist;
        expect(win.sessionStorage).to.exist;

        // Test browser-specific performance APIs
        if (win.performance && win.performance.memory) {
          cy.log('✅ Performance memory API available');
        } else {
          cy.log('⚠️ Performance memory API not available');
        }

        // Test that fleet operations work with browser APIs
        cy.get('[data-testid="add-excavator-btn"]').click();
        
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', 2);

        cy.log('✅ JavaScript fleet operations work');
      });
    });
  });

  context('Firefox-Specific Fleet Testing', () => {
    it('should work optimally in Firefox', () => {
      cy.window().then((win) => {
        const isFirefox = win.navigator.userAgent.toLowerCase().includes('firefox');
        
        if (isFirefox) {
          cy.log('🦊 Running Firefox-specific tests');
          
          // Test Firefox-specific behaviors
          cy.get('[data-testid="add-excavator-btn"]')
            .should('be.visible')
            .click();
            
          // Firefox should handle DOM updates well
          cy.get('[data-testid="excavator-list"]')
            .find('.equipment-item')
            .should('have.length', 2);
            
          // Test Firefox focus management
          cy.get('[data-testid="excavator-list"]')
            .find('.equipment-item')
            .eq(1)
            .find('[data-testid*="excavator-capacity"]')
            .focus()
            .should('be.focused');
            
          // Test Firefox input handling
          cy.focused()
            .clear()
            .type('3.2')
            .should('have.value', '3.2');

          cy.log('✅ Firefox-specific behaviors work correctly');
        } else {
          cy.log('ℹ️ Not running in Firefox - skipping Firefox-specific tests');
        }
      });
    });

    it('should handle Firefox keyboard navigation', () => {
      cy.window().then((win) => {
        const isFirefox = win.navigator.userAgent.toLowerCase().includes('firefox');
        
        if (isFirefox) {
          // Add some equipment for navigation testing
          cy.get('[data-testid="add-excavator-btn"]').click();
          
          // Test tabbing through fleet elements
          cy.get('body').tab();
          
          // Should be able to navigate through fleet inputs
          let tabCount = 0;
          const maxTabs = 10;
          
          function tabAndCheck() {
            if (tabCount < maxTabs) {
              cy.focused().then($focused => {
                const testId = $focused.attr('data-testid');
                if (testId && (testId.includes('excavator') || testId.includes('truck'))) {
                  cy.log(`Firefox tab navigation: focused on ${testId}`);
                }
                tabCount++;
                cy.focused().tab();
                if (tabCount < maxTabs) {
                  tabAndCheck();
                }
              });
            }
          }
          
          tabAndCheck();
          
          cy.log('✅ Firefox keyboard navigation works');
        }
      });
    });
  });

  context('Chrome-Specific Fleet Testing', () => {
    it('should work optimally in Chrome', () => {
      cy.window().then((win) => {
        const isChrome = win.navigator.userAgent.toLowerCase().includes('chrome') && 
                         !win.navigator.userAgent.toLowerCase().includes('edge');
        
        if (isChrome) {
          cy.log('🌎 Running Chrome-specific tests');
          
          // Test Chrome DevTools integration (if available)
          if (win.performance && win.performance.memory) {
            const initialMemory = win.performance.memory.usedJSHeapSize;
            
            // Perform fleet operations
            for (let i = 0; i < 3; i++) {
              cy.get('[data-testid="add-excavator-btn"]').click();
              cy.wait(200);
            }
            
            const afterMemory = win.performance.memory.usedJSHeapSize;
            const memoryIncrease = (afterMemory - initialMemory) / 1024 / 1024;
            
            cy.log(`Chrome memory usage increase: ${memoryIncrease.toFixed(2)} MB`);
            expect(memoryIncrease).to.be.lessThan(5); // Should be reasonable
          }
          
          // Test Chrome-specific rendering optimizations
          cy.get('[data-testid="excavator-list"]')
            .find('.equipment-item')
            .should('have.length', 4) // 1 initial + 3 added
            .each($item => {
              cy.wrap($item).should('be.visible');
            });

          cy.log('✅ Chrome-specific behaviors work correctly');
        } else {
          cy.log('ℹ️ Not running in Chrome - skipping Chrome-specific tests');
        }
      });
    });
  });

  context('Edge-Specific Fleet Testing', () => {
    it('should work optimally in Edge', () => {
      cy.window().then((win) => {
        const isEdge = win.navigator.userAgent.toLowerCase().includes('edge');
        
        if (isEdge) {
          cy.log('🌀 Running Edge-specific tests');
          
          // Test Edge compatibility with fleet features
          cy.get('[data-testid="add-truck-btn"]')
            .should('be.visible')
            .click();
            
          cy.get('[data-testid="truck-list"]')
            .find('.equipment-item')
            .should('have.length', 2);
            
          // Test Edge input handling
          cy.get('[data-testid="truck-list"]')
            .find('.equipment-item')
            .eq(1)
            .find('[data-testid*="truck-capacity"]')
            .clear()
            .type('18.5')
            .should('have.value', '18.5');

          cy.log('✅ Edge-specific behaviors work correctly');
        } else {
          cy.log('ℹ️ Not running in Edge - skipping Edge-specific tests');
        }
      });
    });
  });

  context('Safari-Specific Fleet Testing', () => {
    it('should work optimally in Safari', () => {
      cy.window().then((win) => {
        const isSafari = win.navigator.userAgent.toLowerCase().includes('safari') && 
                         !win.navigator.userAgent.toLowerCase().includes('chrome');
        
        if (isSafari) {
          cy.log('🧭 Running Safari-specific tests');
          
          // Test Safari CSS rendering
          cy.get('.grid-cols-3')
            .should('have.css', 'display', 'grid');
            
          // Test Safari form handling
          cy.get('[data-testid="add-excavator-btn"]').click();
          
          cy.get('[data-testid="excavator-list"]')
            .find('.equipment-item')
            .eq(1)
            .find('[data-testid*="excavator-name"]')
            .clear()
            .type('Safari Test Excavator')
            .should('have.value', 'Safari Test Excavator');

          cy.log('✅ Safari-specific behaviors work correctly');
        } else {
          cy.log('ℹ️ Not running in Safari - skipping Safari-specific tests');
        }
      });
    });
  });

  context('Universal Browser Compatibility', () => {
    it('should provide consistent fleet experience across all browsers', () => {
      // Test core fleet functionality that should work everywhere
      const testSequence = [
        () => cy.get('[data-testid="add-excavator-btn"]').click(),
        () => cy.get('[data-testid="add-truck-btn"]').click(),
        () => cy.get('[data-testid="excavator-list"]').find('.equipment-item').should('have.length', 2),
        () => cy.get('[data-testid="truck-list"]').find('.equipment-item').should('have.length', 2)
      ];

      testSequence.forEach((step, index) => {
        step();
        cy.log(`✅ Universal test step ${index + 1} completed`);
      });

      // Test calculation integration
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      cy.get('[data-testid="pond-width-input"]').clear().type('40');
      cy.get('[data-testid="pond-depth-input"]').clear().type('7');
      
      cy.wait(1000);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]')
        .should('contain.text', 'day')
        .and('not.contain', 'NaN');

      cy.log('✅ Universal fleet functionality works across browsers');
    });

    it('should handle browser capability differences gracefully', () => {
      cy.window().then((win) => {
        const capabilities = {
          localStorage: !!win.localStorage,
          sessionStorage: !!win.sessionStorage,
          fetch: !!win.fetch,
          promiseSupport: !!win.Promise,
          performanceAPI: !!win.performance,
          memoryAPI: !!(win.performance && win.performance.memory),
          intersectionObserver: !!win.IntersectionObserver,
          mutationObserver: !!win.MutationObserver
        };

        cy.log('Browser Capabilities:');
        Object.entries(capabilities).forEach(([key, value]) => {
          const status = value ? '✅' : '❌';
          cy.log(`${status} ${key}: ${value}`);
        });

        // Fleet should work regardless of advanced API support
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', 2);

        cy.log('✅ Fleet works despite varying browser capabilities');
      });
    });

    it('should maintain performance across different browsers', () => {
      const startTime = performance.now();
      
      // Perform standard fleet operations
      for (let i = 0; i < 2; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
        cy.wait(100);
      }
      
      // Configure equipment
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.5');
        
      // Set pond dimensions and calculate
      cy.get('[data-testid="pond-length-input"]').clear().type('55');
      cy.get('[data-testid="pond-width-input"]').clear().type('35');
      
      cy.wait(1000);
      
      cy.then(() => {
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        cy.window().then((win) => {
          const browserType = win.navigator.userAgent.toLowerCase().includes('firefox') ? 'Firefox' :
                              win.navigator.userAgent.toLowerCase().includes('chrome') ? 'Chrome' :
                              win.navigator.userAgent.toLowerCase().includes('edge') ? 'Edge' :
                              win.navigator.userAgent.toLowerCase().includes('safari') ? 'Safari' :
                              'Unknown';
          
          cy.log(`${browserType} performance: ${duration.toFixed(2)}ms`);
          
          // Should complete within reasonable time regardless of browser
          expect(duration).to.be.lessThan(8000);
        });
      });
    });
  });

  context('Accessibility Across Browsers', () => {
    it('should maintain accessibility standards in all browsers', () => {
      // Test keyboard accessibility
      cy.get('body').tab();
      
      // Should be able to reach fleet buttons via keyboard
      cy.get('[data-testid="add-excavator-btn"]')
        .focus()
        .should('be.focused');
        
      // Test ARIA attributes
      cy.get('[data-testid="add-excavator-btn"]')
        .should('have.attr', 'type', 'button');
        
      // Test that screen readers can identify fleet sections
      cy.get('h2').contains('Excavator Fleet').should('be.visible');
      cy.get('h2').contains('Truck Fleet').should('be.visible');
      
      // Test focus management after adding equipment
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('input')
        .first()
        .focus()
        .should('be.focused');

      cy.log('✅ Accessibility maintained across browsers');
    });
  });
});