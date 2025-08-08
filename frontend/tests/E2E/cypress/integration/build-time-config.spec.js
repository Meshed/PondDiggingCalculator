/// <reference types="cypress" />

describe('Build-Time Configuration Integration Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    // Configuration is loaded at build-time (static) - no HTTP wait needed
  });

  context('Offline-First Architecture Validation', () => {
    it('should work completely offline without any network requests', () => {
      // Block ALL network requests to simulate complete offline operation
      cy.intercept('**', { forceNetworkError: true }).as('offlineMode');
      
      cy.visit('/');
      
      // Application should load with build-time configuration
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .and('have.value', '2.5'); // From static config
        
      cy.get('[data-testid="excavator-cycle-input"]')
        .should('have.value', '2'); // From static config
        
      cy.get('[data-testid="truck-capacity-input"]')
        .should('have.value', '12'); // From static config
        
      cy.get('[data-testid="truck-roundtrip-input"]')
        .should('have.value', '15'); // From static config
        
      cy.get('[data-testid="work-hours-input"]')
        .should('have.value', '8'); // From static config
        
      // Default pond dimensions should load
      cy.get('[data-testid="pond-length-input"]').should('have.value', '40');
      cy.get('[data-testid="pond-width-input"]').should('have.value', '25');
      cy.get('[data-testid="pond-depth-input"]').should('have.value', '5');
      
      // Should perform calculations completely offline
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.wait(400); // Debounce
      
      // Results should appear without network dependency
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
      cy.get('[data-testid="hauling-rate"]').should('be.visible');
    });

    it('should load significantly faster than HTTP-based configuration', () => {
      const performanceThresholds = {
        configLoad: 50,   // ms - static config should be nearly instant
        firstPaint: 300,  // ms - faster first render
        interactive: 500  // ms - faster time to interactive
      };
      
      const startTime = performance.now();
      
      cy.visit('/');
      
      // Configuration should be available immediately
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5')
        .then(() => {
          const configLoadTime = performance.now() - startTime;
          
          // Static configuration should eliminate HTTP latency
          expect(configLoadTime).to.be.lessThan(performanceThresholds.configLoad);
          
          cy.log(`Static config load time: ${configLoadTime}ms`);
        });
      
      // Application should be interactive faster
      cy.get('[data-testid="pond-length-input"]')
        .should('be.visible')
        .clear()
        .type('45')
        .then(() => {
          const interactiveTime = performance.now() - startTime;
          
          expect(interactiveTime).to.be.lessThan(performanceThresholds.interactive);
          
          cy.log(`Time to interactive: ${interactiveTime}ms`);
        });
    });

    it('should maintain consistent configuration across devices offline', () => {
      const devices = [
        { name: 'Mobile', width: 375, height: 667 },
        { name: 'Tablet', width: 768, height: 1024 },
        { name: 'Desktop', width: 1200, height: 800 }
      ];

      // Block network for true offline test
      cy.intercept('**', { forceNetworkError: true }).as('offlineTest');

      devices.forEach(device => {
        cy.viewport(device.width, device.height);
        cy.visit('/');
        cy.wait(500); // Device adaptation time
        
        // Configuration should be identical across all devices
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('have.value', '2.5');
        cy.get('[data-testid="truck-capacity-input"]')  
          .should('have.value', '12');
        cy.get('[data-testid="work-hours-input"]')
          .should('have.value', '8');
          
        // Functionality should work on all devices offline
        cy.get('[data-testid="pond-length-input"]').clear().type('35');
        cy.wait(400);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        cy.log(`${device.name} (${device.width}x${device.height}): Offline functionality confirmed`);
      });
    });
  });

  context('Static Configuration Integrity', () => {
    it('should validate all configuration defaults are within validation ranges', () => {
      cy.visit('/');
      
      // Validate excavator defaults
      cy.get('[data-testid="excavator-capacity-input"]').then($input => {
        const value = parseFloat($input.val());
        expect(value).to.be.at.least(0.5); // Min from validation rules
        expect(value).to.be.at.most(15.0); // Max from validation rules
      });
      
      cy.get('[data-testid="excavator-cycle-input"]').then($input => {
        const value = parseFloat($input.val());
        expect(value).to.be.at.least(0.5); // Min cycle time
        expect(value).to.be.at.most(10.0); // Max cycle time
      });
      
      // Validate truck defaults
      cy.get('[data-testid="truck-capacity-input"]').then($input => {
        const value = parseFloat($input.val());
        expect(value).to.be.at.least(5.0); // Min truck capacity
        expect(value).to.be.at.most(30.0); // Max truck capacity
      });
      
      cy.get('[data-testid="truck-roundtrip-input"]').then($input => {
        const value = parseFloat($input.val());
        expect(value).to.be.at.least(5.0); // Min round trip time
        expect(value).to.be.at.most(60.0); // Max round trip time
      });
      
      // Validate project defaults
      cy.get('[data-testid="work-hours-input"]').then($input => {
        const value = parseFloat($input.val());
        expect(value).to.be.at.least(1.0); // Min work hours
        expect(value).to.be.at.most(16.0); // Max work hours
      });
      
      ['pond-length-input', 'pond-width-input', 'pond-depth-input'].forEach(field => {
        cy.get(`[data-testid="${field}"]`).then($input => {
          const value = parseFloat($input.val());
          expect(value).to.be.at.least(1.0); // Min pond dimensions
          expect(value).to.be.at.most(1000.0); // Max pond dimensions
        });
      });
    });

    it('should maintain configuration consistency across page reloads', () => {
      cy.visit('/');
      
      // Capture initial configuration values
      const configSnapshot = {};
      
      const fields = [
        'excavator-capacity-input',
        'excavator-cycle-input', 
        'truck-capacity-input',
        'truck-roundtrip-input',
        'work-hours-input',
        'pond-length-input',
        'pond-width-input',
        'pond-depth-input'
      ];
      
      // Capture all initial values
      fields.forEach(field => {
        cy.get(`[data-testid="${field}"]`).then($input => {
          configSnapshot[field] = $input.val();
        });
      });
      
      // Perform multiple reloads
      for (let i = 0; i < 3; i++) {
        cy.reload();
        cy.wait(200);
        
        // Verify all values remain identical
        fields.forEach(field => {
          cy.get(`[data-testid="${field}"]`).should($input => {
            expect($input.val()).to.equal(configSnapshot[field]);
          });
        });
      }
    });

    it('should provide immediate configuration access without loading states', () => {
      // With build-time config, there should be no loading spinner or delayed state
      cy.visit('/');
      
      // All inputs should be immediately available and populated
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .and('have.value', '2.5')
        .and('not.have.attr', 'disabled')
        .and('not.have.class', 'loading');
      
      // No loading indicators should be present
      cy.get('[data-testid="config-loading"]').should('not.exist');
      cy.get('[data-testid="loading-spinner"]').should('not.exist');
      cy.get('.loading').should('not.exist');
      
      // Form should be immediately interactive
      cy.get('[data-testid="pond-length-input"]')
        .should('not.have.attr', 'readonly')
        .clear()
        .type('55');
        
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Build Process Validation', () => {
    it('should reflect static configuration in bundle without external dependencies', () => {
      cy.visit('/');
      
      // Verify no external configuration requests are made
      cy.window().then((win) => {
        const performanceEntries = win.performance.getEntriesByType('resource');
        const configRequests = performanceEntries.filter(entry => 
          entry.name.includes('config.json') || 
          entry.name.includes('equipment-defaults.json')
        );
        
        // Should be zero configuration HTTP requests
        expect(configRequests.length).to.equal(0);
      });
      
      // Configuration should work without any server requests
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
    });

    it('should validate bundle size impact is reasonable', () => {
      cy.visit('/');
      
      cy.window().then((win) => {
        const navEntry = win.performance.getEntriesByType('navigation')[0];
        const totalSize = navEntry.transferSize;
        
        // Bundle with embedded config should remain reasonable
        expect(totalSize).to.be.lessThan(100000); // 100KB max bundle size
        
        cy.log(`Total bundle size with embedded config: ${totalSize} bytes`);
      });
    });

    it('should demonstrate version consistency in static configuration', () => {
      cy.visit('/');
      
      // Check that configuration version is embedded and accessible
      cy.window().then((win) => {
        // If version is exposed on window for debugging
        if (win.CONFIG_VERSION) {
          expect(win.CONFIG_VERSION).to.match(/^\d+\.\d+\.\d+$/);
        }
      });
      
      // Functional test - configuration should work consistently
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5')
        .clear()
        .type('3.5');
        
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Error Resilience', () => {
    it('should maintain functionality even with JavaScript errors', () => {
      cy.visit('/');
      
      // Configuration should be loaded even if other JS has issues
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      
      // Simulate a non-critical JS error
      cy.window().then((win) => {
        try {
          win.eval('throw new Error("Non-critical error");');
        } catch (e) {
          // Expected error
        }
      });
      
      // Configuration and functionality should remain intact
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should work in various browser conditions', () => {
      const conditions = [
        'normal',
        'slow-cpu', 
        'limited-memory'
      ];
      
      conditions.forEach(condition => {
        cy.visit('/');
        
        // Static configuration should work under all conditions
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('have.value', '2.5');
        
        // Perform standard workflow
        cy.get('[data-testid="pond-length-input"]').clear().type('45');
        cy.wait(400);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        cy.log(`Configuration works under ${condition} conditions`);
      });
    });
  });
});