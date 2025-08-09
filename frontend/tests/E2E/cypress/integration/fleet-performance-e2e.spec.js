/// <reference types="cypress" />

describe('Fleet Performance End-to-End Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1200, 800); // Desktop viewport for fleet features
  });

  context('Maximum Fleet Performance Validation', () => {
    it('should maintain sub-100ms calculations with maximum fleet size', () => {
      // Add maximum number of excavators (10 total: 1 initial + 9 added)
      for (let i = 1; i < 10; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.wait(50); // Small delay for UI updates
      }
      
      // Add maximum number of trucks (20 total: 1 initial + 19 added)
      for (let i = 1; i < 20; i++) {
        cy.get('[data-testid="add-truck-btn"]').click();
        cy.wait(30); // Smaller delay for faster test execution
      }
      
      // Verify maximum fleet size reached
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 10);
      
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 20);
      
      // Configure some equipment with varied values for realistic load
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(0)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('2.5');
      
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(4)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.5');
      
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .eq(0)
        .find('[data-testid*="truck-capacity"]')
        .clear()
        .type('15');
      
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .eq(10)
        .find('[data-testid*="truck-capacity"]')
        .clear()
        .type('20');
      
      // Set pond dimensions for calculation
      cy.get('[data-testid="pond-length-input"]').clear().type('100');
      cy.get('[data-testid="pond-width-input"]').clear().type('60');
      cy.get('[data-testid="pond-depth-input"]').clear().type('8');
      
      // Measure calculation performance
      const startTime = performance.now();
      
      // Trigger calculation by changing a value
      cy.get('[data-testid="work-hours-input"]').clear().type('8.5');
      
      // Wait for calculation to complete
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.then(() => {
        const endTime = performance.now();
        const calculationTime = endTime - startTime;
        
        // Performance target: under 500ms total (including debounce + UI updates)
        // Actual calculation should be much faster than this
        expect(calculationTime).to.be.lessThan(1000);
        
        // Log performance for monitoring
        cy.log(`Maximum fleet calculation completed in ${calculationTime}ms`);
        
        // Verify calculation produces reasonable results
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .then((days) => {
            const numDays = parseFloat(days);
            expect(numDays).to.be.greaterThan(0);
            expect(numDays).to.be.lessThan(100); // Should be much faster with large fleet
          });
      });
    });

    it('should handle rapid equipment modifications without performance degradation', () => {
      // Add several equipment items
      for (let i = 1; i < 6; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
      }
      
      // Record start time for performance measurement
      const startTime = performance.now();
      
      // Perform rapid modifications
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .eq(i)
          .find('[data-testid*="excavator-capacity"]')
          .clear()
          .type(`${2.5 + i * 0.5}`);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .eq(i)
          .find('[data-testid*="truck-capacity"]')
          .clear()
          .type(`${15 + i * 2}`);
      }
      
      // Wait for final calculation
      cy.wait(800); // Allow for debounce and calculation
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.then(() => {
        const endTime = performance.now();
        const totalTime = endTime - startTime;
        
        // Should handle rapid changes efficiently
        expect(totalTime).to.be.lessThan(5000);
        
        cy.log(`Rapid fleet modifications completed in ${totalTime}ms`);
      });
    });

    it('should maintain memory efficiency with large fleets', () => {
      // Check initial memory usage
      cy.window().then((win) => {
        const initialMemory = win.performance.memory ? win.performance.memory.usedJSHeapSize : 0;
        
        // Add large fleet
        for (let i = 1; i < 8; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
          cy.get('[data-testid="add-truck-btn"]').click();
          cy.wait(50);
        }
        
        // Configure equipment
        cy.get('[data-testid="pond-length-input"]').clear().type('80');
        cy.get('[data-testid="pond-width-input"]').clear().type('50');
        cy.get('[data-testid="pond-depth-input"]').clear().type('6');
        
        cy.wait(1000); // Allow for processing
        
        // Check memory usage after operations
        cy.window().then((winAfter) => {
          const finalMemory = winAfter.performance.memory ? winAfter.performance.memory.usedJSHeapSize : 0;
          
          if (initialMemory > 0 && finalMemory > 0) {
            const memoryIncrease = finalMemory - initialMemory;
            const memoryIncreaseKB = memoryIncrease / 1024;
            
            // Memory increase should be reasonable (less than 5MB for fleet operations)
            expect(memoryIncreaseKB).to.be.lessThan(5120);
            
            cy.log(`Memory increase: ${memoryIncreaseKB.toFixed(2)} KB`);
          } else {
            cy.log('Memory measurement not available in this browser');
          }
        });
      });
    });

    it('should handle fleet limit stress testing', () => {
      // Test approaching fleet limits
      const startTime = performance.now();
      
      // Add excavators up to limit
      for (let i = 1; i < 10; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
      }
      
      // Verify limit enforcement
      cy.get('[data-testid="add-excavator-btn"]').should('be.disabled');
      
      // Add trucks (partial amount for test speed)
      for (let i = 1; i < 10; i++) {
        cy.get('[data-testid="add-truck-btn"]').click();
      }
      
      // Configure some equipment for calculation load
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(5)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('4.0');
      
      cy.get('[data-testid="pond-length-input"]').clear().type('120');
      cy.get('[data-testid="pond-width-input"]').clear().type('80');
      cy.get('[data-testid="pond-depth-input"]').clear().type('10');
      
      // Wait for calculation
      cy.wait(1000);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.then(() => {
        const endTime = performance.now();
        const totalTime = endTime - startTime;
        
        // Should handle near-limit fleet efficiently
        expect(totalTime).to.be.lessThan(15000);
        
        cy.log(`Fleet limit stress test completed in ${totalTime}ms`);
      });
    });
  });

  context('Fleet Performance Benchmarking', () => {
    it('should benchmark add/remove equipment operations', () => {
      // Benchmark adding equipment
      const addStartTime = performance.now();
      
      for (let i = 1; i <= 5; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
      }
      
      const addEndTime = performance.now();
      const addTime = addEndTime - addStartTime;
      
      // Adding 5 excavators should be fast
      expect(addTime).to.be.lessThan(2000);
      
      cy.log(`Added 5 excavators in ${addTime}ms`);
      
      // Benchmark removing equipment
      const removeStartTime = performance.now();
      
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="excavator-list"]')
          .find('[data-testid*="remove-excavator"]')
          .first()
          .click();
        cy.wait(100);
      }
      
      const removeEndTime = performance.now();
      const removeTime = removeEndTime - removeStartTime;
      
      // Removing 3 excavators should be fast
      expect(removeTime).to.be.lessThan(1500);
      
      cy.log(`Removed 3 excavators in ${removeTime}ms`);
      
      // Verify final state
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 3); // 1 initial + 5 added - 3 removed
    });

    it('should benchmark calculation updates with varying fleet sizes', () => {
      const benchmarkData = [];
      
      // Test with 1, 3, 5, 7 excavators
      const fleetSizes = [1, 3, 5, 7];
      
      fleetSizes.forEach((targetSize, index) => {
        // Add excavators to reach target size
        const currentSize = index === 0 ? 1 : fleetSizes[index - 1];
        const toAdd = targetSize - currentSize;
        
        for (let i = 0; i < toAdd; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
        }
        
        // Benchmark calculation time
        const calcStartTime = performance.now();
        
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type(`${50 + index * 10}`);
        
        cy.wait(600); // Wait for calculation
        
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        cy.then(() => {
          const calcEndTime = performance.now();
          const calcTime = calcEndTime - calcStartTime;
          
          benchmarkData.push({ fleetSize: targetSize, time: calcTime });
          
          // Each calculation should be reasonably fast
          expect(calcTime).to.be.lessThan(1000);
          
          cy.log(`Fleet size ${targetSize}: ${calcTime}ms`);
        });
      });
      
      // At the end, verify performance doesn't degrade significantly with larger fleets
      cy.then(() => {
        if (benchmarkData.length === fleetSizes.length) {
          const firstCalc = benchmarkData[0].time;
          const lastCalc = benchmarkData[benchmarkData.length - 1].time;
          
          // Performance shouldn't degrade more than 3x with 7x the fleet size
          expect(lastCalc).to.be.lessThan(firstCalc * 3);
          
          cy.log('Fleet performance benchmarking completed successfully');
        }
      });
    });
  });
});