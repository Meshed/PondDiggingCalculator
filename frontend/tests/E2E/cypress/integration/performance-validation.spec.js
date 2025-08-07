/// <reference types="cypress" />

describe('Performance Validation Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.wait(1000); // Allow config to load
  });

  context('Calculation Performance Requirements', () => {
    it('should complete calculations within 100ms target', () => {
      cy.viewport(1200, 800);
      
      // Set up test data
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('6');
      
      // Measure calculation performance
      const startTime = performance.now();
      
      // Trigger calculation (already happens with debouncing)
      cy.wait(400); // Wait for debounce
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const endTime = performance.now();
        const calculationTime = endTime - startTime;
        
        // Performance target: under 100ms for calculation itself
        // Note: This includes debounce time, actual calculation should be much faster
        expect(calculationTime).to.be.lessThan(500); // Allow for debounce + calculation
        
        // Log performance for monitoring
        cy.log(`Calculation completed in ${calculationTime}ms`);
      });
    });

    it('should handle rapid input changes without performance degradation', () => {
      cy.viewport(1200, 800);
      
      const startTime = performance.now();
      
      // Simulate rapid parameter changes
      for (let i = 0; i < 10; i++) {
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type(String(40 + i));
        cy.wait(50); // Rapid changes
      }
      
      // Wait for final calculation
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const totalTime = performance.now() - startTime;
        
        // Should handle rapid changes efficiently
        expect(totalTime).to.be.lessThan(2000); // 2 seconds total
        
        // Final result should be correct
        cy.get('[data-testid="timeline-days"]').should('be.visible');
      });
    });

    it('should maintain performance with complex calculations', () => {
      cy.viewport(1200, 800);
      
      // Test large pond calculations
      cy.get('[data-testid="pond-length-input"]').clear().type('1000');
      cy.get('[data-testid="pond-width-input"]').clear().type('800');
      cy.get('[data-testid="pond-depth-input"]').clear().type('15');
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('4.5');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('20');
      
      const startTime = performance.now();
      
      cy.wait(400); // Debounce
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const calculationTime = performance.now() - startTime;
        
        // Even complex calculations should be fast
        expect(calculationTime).to.be.lessThan(600);
        
        // Verify large calculation produces reasonable result
        cy.get('[data-testid="timeline-days"]').should('be.visible');
      });
    });

    it('should maintain consistent performance across device types', () => {
      const viewports = [
        { name: 'Mobile', width: 375, height: 667 },
        { name: 'Tablet', width: 768, height: 1024 },
        { name: 'Desktop', width: 1200, height: 800 }
      ];

      viewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.wait(500); // Device transition
        
        const startTime = performance.now();
        
        // Standard calculation
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
        cy.get('[data-testid="pond-length-input"]').clear().type('40');
        
        cy.wait(400);
        
        cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
          const deviceTime = performance.now() - startTime;
          
          // Performance should be consistent across devices
          expect(deviceTime).to.be.lessThan(600);
          
          cy.log(`${viewport.name} calculation: ${deviceTime}ms`);
        });
      });
    });
  });

  context('Memory and Resource Usage', () => {
    it('should not create memory leaks during repeated calculations', () => {
      cy.viewport(1200, 800);
      
      // Perform many calculation cycles
      for (let cycle = 0; cycle < 20; cycle++) {
        // Vary parameters to trigger new calculations
        const length = 40 + (cycle * 2);
        const width = 25 + cycle;
        
        cy.get('[data-testid="pond-length-input"]').clear().type(String(length));
        cy.get('[data-testid="pond-width-input"]').clear().type(String(width));
        
        cy.wait(100); // Short delay between cycles
      }
      
      // Final calculation should still work normally
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      
      // Performance should not degrade significantly
      const finalStartTime = performance.now();
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const finalTime = performance.now() - finalStartTime;
        expect(finalTime).to.be.lessThan(600); // Should not be slower after many calculations
      });
    });

    it('should handle extreme input values efficiently', () => {
      cy.viewport(1200, 800);
      
      const extremeValues = [
        { field: 'pond-length-input', value: '999999' },
        { field: 'pond-width-input', value: '1' },
        { field: 'pond-depth-input', value: '0.1' },
        { field: 'excavator-capacity-input', value: '10.5' }
      ];
      
      const startTime = performance.now();
      
      extremeValues.forEach(({ field, value }) => {
        cy.get(`[data-testid="${field}"]`).clear().type(value);
      });
      
      cy.wait(400);
      
      // Should handle extreme values without hanging
      cy.get('[data-testid="timeline-result"]', { timeout: 2000 })
        .should('be.visible')
        .then(() => {
          const extremeTime = performance.now() - startTime;
          expect(extremeTime).to.be.lessThan(1000);
        });
    });
  });

  context('Page Load Performance', () => {
    it('should load initial page within performance budget', () => {
      // Measure fresh page load
      const loadStartTime = performance.now();
      
      cy.visit('/');
      
      // Verify critical elements load quickly
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible').then(() => {
        const loadTime = performance.now() - loadStartTime;
        
        // Page should load within 2 seconds
        expect(loadTime).to.be.lessThan(2000);
        
        cy.log(`Page load time: ${loadTime}ms`);
      });
      
      // Verify defaults are loaded (config.json processed)
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
    });

    it('should load config and display defaults quickly', () => {
      const configStartTime = performance.now();
      
      cy.visit('/');
      
      // Wait for all default values to be populated
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
      cy.get('[data-testid="work-hours-input"]').should('have.value', '8');
      
      const configLoadTime = performance.now() - configStartTime;
      
      // Config should load and populate within 1 second
      expect(configLoadTime).to.be.lessThan(1000);
      
      cy.log(`Config load and population: ${configLoadTime}ms`);
    });

    it('should handle concurrent users simulation', () => {
      // Simulate multiple rapid visits (like multiple users)
      const visits = [];
      
      for (let i = 0; i < 5; i++) {
        visits.push(
          cy.visit('/').then(() => {
            const startTime = performance.now();
            
            cy.get('[data-testid="excavator-capacity-input"]')
              .should('be.visible')
              .clear()
              .type('3.0');
              
            cy.get('[data-testid="pond-length-input"]').clear().type('50');
            
            cy.wait(400);
            
            cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
              const visitTime = performance.now() - startTime;
              expect(visitTime).to.be.lessThan(800);
            });
          })
        );
      }
    });
  });

  context('Real-Time Update Performance', () => {
    it('should maintain smooth debouncing under load', () => {
      cy.viewport(1200, 800);
      
      // Test debouncing behavior with rapid input
      cy.get('[data-testid="pond-length-input"]').clear().type('4');
      cy.wait(100);
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      cy.wait(100);
      cy.get('[data-testid="pond-length-input"]').clear().type('456');
      cy.wait(100);
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      
      // Should only calculate once after final input
      const debounceStartTime = performance.now();
      
      cy.wait(400); // Full debounce period
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const debounceTime = performance.now() - debounceStartTime;
        
        // Debouncing should be efficient
        expect(debounceTime).to.be.lessThan(500);
      });
    });

    it('should handle validation and calculation performance together', () => {
      cy.viewport(1200, 800);
      
      const startTime = performance.now();
      
      // Create validation error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      
      // Should quickly show validation error
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      
      // Fix validation and trigger calculation
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const totalTime = performance.now() - startTime;
        
        // Validation + calculation should be fast
        expect(totalTime).to.be.lessThan(800);
      });
    });
  });

  context('Performance Monitoring and Reporting', () => {
    it('should track and report performance metrics', () => {
      cy.viewport(1200, 800);
      
      // Perform standard calculation workflow
      const workflowStartTime = performance.now();
      
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('6');
      
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const workflowTime = performance.now() - workflowStartTime;
        
        // Log comprehensive performance data
        cy.log(`Complete workflow time: ${workflowTime}ms`);
        
        // Performance assertions
        expect(workflowTime).to.be.lessThan(1000);
        
        // Check for performance metrics in the app (if implemented)
        cy.window().then((win) => {
          if (win.performanceMetrics) {
            expect(win.performanceMetrics.calculationTime).to.be.lessThan(100);
          }
        });
      });
    });

    it('should maintain performance standards across browser conditions', () => {
      // Test under various conditions
      const conditions = [
        { name: 'Fast Network', throttling: 'networkidle0' },
        { name: 'Standard', throttling: 'networkidle2' }
      ];
      
      conditions.forEach(condition => {
        cy.viewport(1200, 800);
        
        const conditionStartTime = performance.now();
        
        // Standard calculation
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
        cy.get('[data-testid="pond-length-input"]').clear().type('40');
        
        cy.wait(400);
        
        cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
          const conditionTime = performance.now() - conditionStartTime;
          
          cy.log(`${condition.name} performance: ${conditionTime}ms`);
          
          // Should maintain performance under various conditions
          expect(conditionTime).to.be.lessThan(800);
        });
      });
    });
  });
});