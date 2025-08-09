/// <reference types="cypress" />

describe('Memory Usage Monitoring Tests', () => {
  let initialMemory = null;

  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1200, 800);
    
    // Capture initial memory usage
    cy.window().then((win) => {
      if (win.performance.memory) {
        initialMemory = {
          used: win.performance.memory.usedJSHeapSize,
          total: win.performance.memory.totalJSHeapSize,
          limit: win.performance.memory.jsHeapSizeLimit
        };
        
        cy.log(`Initial memory: ${(initialMemory.used / 1024 / 1024).toFixed(2)} MB`);
      } else {
        cy.log('Memory monitoring not available in this browser');
      }
    });
  });

  afterEach(() => {
    // Force garbage collection if available (in Chrome with --enable-precise-memory-info flag)
    cy.window().then((win) => {
      if (win.gc) {
        win.gc();
        cy.log('Garbage collection triggered');
      }
    });
  });

  context('Fleet Operations Memory Usage', () => {
    it('should not leak memory when adding multiple equipment items', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory test - not available in this browser');
          return;
        }

        const memorySnapshots = [];
        
        // Take initial snapshot
        memorySnapshots.push({
          step: 'initial',
          used: win.performance.memory.usedJSHeapSize
        });

        // Add equipment and monitor memory
        for (let i = 0; i < 8; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
          cy.wait(200);
          
          memorySnapshots.push({
            step: `excavator-${i + 1}`,
            used: win.performance.memory.usedJSHeapSize
          });
        }

        for (let i = 0; i < 5; i++) {
          cy.get('[data-testid="add-truck-btn"]').click();
          cy.wait(200);
          
          memorySnapshots.push({
            step: `truck-${i + 1}`,
            used: win.performance.memory.usedJSHeapSize
          });
        }

        cy.then(() => {
          const finalMemory = win.performance.memory.usedJSHeapSize;
          const memoryIncrease = finalMemory - memorySnapshots[0].used;
          const memoryIncreaseMB = memoryIncrease / 1024 / 1024;

          // Log memory progression
          memorySnapshots.forEach(snapshot => {
            const mb = (snapshot.used / 1024 / 1024).toFixed(2);
            cy.log(`${snapshot.step}: ${mb} MB`);
          });

          // Memory increase should be reasonable for fleet operations
          // Allow up to 10MB increase for complex fleet (generous threshold)
          expect(memoryIncreaseMB).to.be.lessThan(10);
          
          cy.log(`Total memory increase: ${memoryIncreaseMB.toFixed(2)} MB`);
        });
      });
    });

    it('should release memory when removing equipment items', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory test - not available in this browser');
          return;
        }

        // Add large fleet first
        for (let i = 0; i < 6; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
          cy.wait(100);
        }

        for (let i = 0; i < 8; i++) {
          cy.get('[data-testid="add-truck-btn"]').click();
          cy.wait(100);
        }

        cy.wait(1000); // Let memory settle

        const afterAddingMemory = win.performance.memory.usedJSHeapSize;
        
        // Now remove equipment
        for (let i = 0; i < 4; i++) {
          cy.get('[data-testid="excavator-list"]')
            .find('[data-testid*="remove-excavator"]')
            .first()
            .click();
          cy.wait(200);
        }

        for (let i = 0; i < 6; i++) {
          cy.get('[data-testid="truck-list"]')
            .find('[data-testid*="remove-truck"]')
            .first()
            .click();
          cy.wait(200);
        }

        cy.wait(2000); // Allow time for cleanup

        cy.then(() => {
          const afterRemovalMemory = win.performance.memory.usedJSHeapSize;
          const memoryReduction = afterAddingMemory - afterRemovalMemory;
          const memoryReductionMB = memoryReduction / 1024 / 1024;

          cy.log(`Memory after adding fleet: ${(afterAddingMemory / 1024 / 1024).toFixed(2)} MB`);
          cy.log(`Memory after removing equipment: ${(afterRemovalMemory / 1024 / 1024).toFixed(2)} MB`);
          cy.log(`Memory reduction: ${memoryReductionMB.toFixed(2)} MB`);

          // Memory should reduce or at least not continue growing significantly
          // Allow for some garbage collection variance
          expect(memoryReduction).to.be.greaterThan(-1024 * 1024); // Less than 1MB increase
        });
      });
    });

    it('should handle rapid fleet operations without memory buildup', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory test - not available in this browser');
          return;
        }

        const startMemory = win.performance.memory.usedJSHeapSize;
        const memoryChecks = [];

        // Perform rapid add/remove cycles
        for (let cycle = 0; cycle < 5; cycle++) {
          // Add equipment
          for (let i = 0; i < 3; i++) {
            cy.get('[data-testid="add-excavator-btn"]').click();
            cy.wait(50);
          }

          // Remove equipment
          for (let i = 0; i < 2; i++) {
            cy.get('[data-testid="excavator-list"]')
              .find('[data-testid*="remove-excavator"]')
              .first()
              .click();
            cy.wait(50);
          }

          cy.wait(200);

          memoryChecks.push({
            cycle: cycle + 1,
            memory: win.performance.memory.usedJSHeapSize
          });
        }

        cy.then(() => {
          const endMemory = win.performance.memory.usedJSHeapSize;
          const memoryChange = endMemory - startMemory;
          const memoryChangeMB = memoryChange / 1024 / 1024;

          memoryChecks.forEach(check => {
            const mb = (check.memory / 1024 / 1024).toFixed(2);
            cy.log(`Cycle ${check.cycle}: ${mb} MB`);
          });

          // After rapid operations, memory should not have grown significantly
          expect(Math.abs(memoryChangeMB)).to.be.lessThan(5);
          
          cy.log(`Memory change after rapid operations: ${memoryChangeMB.toFixed(2)} MB`);
        });
      });
    });
  });

  context('Calculation Memory Usage', () => {
    it('should not accumulate memory during repeated calculations', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory test - not available in this browser');
          return;
        }

        const startMemory = win.performance.memory.usedJSHeapSize;
        
        // Create a moderate fleet for calculations
        cy.createFleetConfiguration({ excavators: 3, trucks: 4 });
        
        // Perform many calculation iterations
        for (let i = 0; i < 20; i++) {
          cy.get('[data-testid="pond-length-input"]')
            .clear()
            .type(`${40 + i * 2}`);
          
          cy.get('[data-testid="pond-width-input"]')
            .clear()
            .type(`${30 + i}`);
            
          cy.wait(300); // Wait for calculation
        }

        cy.wait(1000); // Let calculations settle

        cy.then(() => {
          const endMemory = win.performance.memory.usedJSHeapSize;
          const memoryIncrease = endMemory - startMemory;
          const memoryIncreaseMB = memoryIncrease / 1024 / 1024;

          cy.log(`Start memory: ${(startMemory / 1024 / 1024).toFixed(2)} MB`);
          cy.log(`End memory: ${(endMemory / 1024 / 1024).toFixed(2)} MB`);

          // Repeated calculations should not cause memory buildup
          expect(memoryIncreaseMB).to.be.lessThan(3);
          
          cy.log(`Memory increase from calculations: ${memoryIncreaseMB.toFixed(2)} MB`);
        });
      });
    });

    it('should handle complex fleet calculations efficiently', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory test - not available in this browser');
          return;
        }

        const beforeFleetMemory = win.performance.memory.usedJSHeapSize;

        // Create maximum complexity fleet
        for (let i = 0; i < 8; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
          cy.wait(50);
        }

        for (let i = 0; i < 12; i++) {
          cy.get('[data-testid="add-truck-btn"]').click();
          cy.wait(50);
        }

        // Configure equipment with diverse values
        for (let i = 0; i < 3; i++) {
          cy.configureEquipment('excavator', i, {
            bucketCapacity: 2.5 + i * 0.3,
            cycleTime: 1.8 + i * 0.2
          });
        }

        for (let i = 0; i < 3; i++) {
          cy.configureEquipment('truck', i, {
            capacity: 15 + i * 2,
            roundTripTime: 20 + i * 3
          });
        }

        // Perform complex calculation
        cy.setPondDimensions({ length: 120, width: 80, depth: 10 });
        cy.waitForCalculation();

        cy.wait(2000); // Allow calculation to complete fully

        cy.then(() => {
          const afterCalculationMemory = win.performance.memory.usedJSHeapSize;
          const memoryForComplexFleet = afterCalculationMemory - beforeFleetMemory;
          const memoryMB = memoryForComplexFleet / 1024 / 1024;

          cy.log(`Memory for complex fleet calculation: ${memoryMB.toFixed(2)} MB`);

          // Complex fleet should use reasonable memory
          expect(memoryMB).to.be.lessThan(15); // Generous threshold for complex calculations

          // Verify calculation completed successfully
          cy.get('[data-testid="timeline-result"]').should('be.visible');
          cy.get('[data-testid="timeline-days"]')
            .should('not.contain', 'NaN')
            .and('not.contain', 'undefined');
        });
      });
    });
  });

  context('DOM Memory Management', () => {
    it('should clean up DOM elements efficiently', () => {
      // This test focuses on DOM memory usage
      let domElementCount = 0;
      
      cy.document().then(doc => {
        domElementCount = doc.querySelectorAll('*').length;
        cy.log(`Initial DOM elements: ${domElementCount}`);
      });

      // Add many equipment items to increase DOM complexity
      for (let i = 0; i < 6; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
        cy.wait(100);
      }

      let maxDomElements = 0;
      cy.document().then(doc => {
        maxDomElements = doc.querySelectorAll('*').length;
        cy.log(`DOM elements after adding fleet: ${maxDomElements}`);
      });

      // Remove most equipment
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="excavator-list"]')
          .find('[data-testid*="remove-excavator"]')
          .first()
          .click();
          
        cy.get('[data-testid="truck-list"]')
          .find('[data-testid*="remove-truck"]')
          .first()
          .click();
        cy.wait(100);
      }

      cy.wait(1000); // Allow DOM cleanup

      cy.document().then(doc => {
        const finalDomElements = doc.querySelectorAll('*').length;
        const domReduction = maxDomElements - finalDomElements;
        
        cy.log(`DOM elements after removal: ${finalDomElements}`);
        cy.log(`DOM elements cleaned up: ${domReduction}`);

        // Should have cleaned up significant number of DOM elements
        expect(domReduction).to.be.greaterThan(0);
        
        // Final count should be closer to initial count
        const finalIncrease = finalDomElements - domElementCount;
        expect(finalIncrease).to.be.lessThan(maxDomElements - domElementCount);
      });
    });

    it('should handle event listener cleanup', () => {
      cy.window().then((win) => {
        // Mock addEventListener to count event listeners
        let eventListenerCount = 0;
        const originalAddEventListener = win.addEventListener;
        const originalRemoveEventListener = win.removeEventListener;
        
        win.addEventListener = function(...args) {
          eventListenerCount++;
          return originalAddEventListener.apply(this, args);
        };
        
        win.removeEventListener = function(...args) {
          eventListenerCount--;
          return originalRemoveEventListener.apply(this, args);
        };

        const startListenerCount = eventListenerCount;

        // Add equipment (which may add event listeners)
        for (let i = 0; i < 4; i++) {
          cy.get('[data-testid="add-excavator-btn"]').click();
          cy.wait(100);
        }

        const maxListenerCount = eventListenerCount;

        // Remove equipment (should clean up listeners)
        for (let i = 0; i < 3; i++) {
          cy.get('[data-testid="excavator-list"]')
            .find('[data-testid*="remove-excavator"]')
            .first()
            .click();
          cy.wait(100);
        }

        cy.then(() => {
          const finalListenerCount = eventListenerCount;
          
          cy.log(`Event listeners - Start: ${startListenerCount}, Max: ${maxListenerCount}, Final: ${finalListenerCount}`);

          // Should not accumulate excessive event listeners
          const listenerIncrease = finalListenerCount - startListenerCount;
          expect(listenerIncrease).to.be.lessThan(50); // Reasonable threshold
        });

        // Restore original methods
        win.addEventListener = originalAddEventListener;
        win.removeEventListener = originalRemoveEventListener;
      });
    });
  });

  context('Memory Leak Detection', () => {
    it('should not leak memory across multiple page interactions', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping memory leak test - not available in this browser');
          return;
        }

        const memorySnapshots = [];
        
        // Perform multiple interaction cycles
        for (let cycle = 0; cycle < 3; cycle++) {
          // Build up state
          cy.createFleetConfiguration({ excavators: 2, trucks: 3 });
          cy.setPondDimensions({ length: 50 + cycle * 10, width: 30 + cycle * 5, depth: 5 + cycle });
          
          // Configure equipment
          cy.configureEquipment('excavator', 0, { bucketCapacity: 3.0 + cycle * 0.2 });
          cy.configureEquipment('truck', 0, { capacity: 15 + cycle * 2 });
          
          cy.waitForCalculation();
          cy.wait(500);
          
          // Take memory snapshot
          memorySnapshots.push({
            cycle: cycle + 1,
            memory: win.performance.memory.usedJSHeapSize
          });
          
          // Reset state
          cy.reload();
          cy.wait(1000);
        }

        cy.then(() => {
          // Analyze memory trend
          const memoryProgression = memorySnapshots.map(s => s.memory / 1024 / 1024);
          
          memorySnapshots.forEach((snapshot, index) => {
            cy.log(`Cycle ${snapshot.cycle}: ${memoryProgression[index].toFixed(2)} MB`);
          });

          // Check for memory leak pattern (consistently increasing memory)
          if (memoryProgression.length >= 3) {
            const trend1to2 = memoryProgression[1] - memoryProgression[0];
            const trend2to3 = memoryProgression[2] - memoryProgression[1];
            
            // Both trends should not be large increases
            expect(trend1to2).to.be.lessThan(5); // Less than 5MB increase
            expect(trend2to3).to.be.lessThan(5);
            
            // Overall trend should not show consistent large increases
            const overallTrend = memoryProgression[2] - memoryProgression[0];
            expect(overallTrend).to.be.lessThan(8); // Less than 8MB total increase
            
            cy.log(`Memory trend analysis: ${trend1to2.toFixed(2)} MB, ${trend2to3.toFixed(2)} MB (overall: ${overallTrend.toFixed(2)} MB)`);
          }
        });
      });
    });

    it('should maintain stable memory usage during long sessions', () => {
      cy.window().then((win) => {
        if (!win.performance.memory) {
          cy.log('Skipping long session test - not available in this browser');
          return;
        }

        const sessionStart = win.performance.memory.usedJSHeapSize;
        let peakMemory = sessionStart;
        
        // Simulate long session with various operations
        const operations = [
          () => cy.get('[data-testid="add-excavator-btn"]').click(),
          () => cy.get('[data-testid="add-truck-btn"]').click(),
          () => cy.get('[data-testid="pond-length-input"]').clear().type('45'),
          () => cy.get('[data-testid="pond-width-input"]').clear().type('35'),
          () => {
            cy.get('[data-testid="excavator-list"]')
              .find('[data-testid*="remove-excavator"]')
              .first()
              .click({ force: true });
          }
        ];

        // Perform 30 random operations
        for (let i = 0; i < 30; i++) {
          const operation = operations[i % operations.length];
          operation();
          cy.wait(100);
          
          // Check memory every 5 operations
          if (i % 5 === 0) {
            cy.then(() => {
              const currentMemory = win.performance.memory.usedJSHeapSize;
              if (currentMemory > peakMemory) {
                peakMemory = currentMemory;
              }
            });
          }
        }

        cy.wait(2000); // Let operations settle

        cy.then(() => {
          const sessionEnd = win.performance.memory.usedJSHeapSize;
          const sessionIncrease = sessionEnd - sessionStart;
          const peakIncrease = peakMemory - sessionStart;
          
          const sessionIncreaseMB = sessionIncrease / 1024 / 1024;
          const peakIncreaseMB = peakIncrease / 1024 / 1024;

          cy.log(`Session memory increase: ${sessionIncreaseMB.toFixed(2)} MB`);
          cy.log(`Peak memory increase: ${peakIncreaseMB.toFixed(2)} MB`);

          // Long session should maintain reasonable memory usage
          expect(sessionIncreaseMB).to.be.lessThan(10);
          expect(peakIncreaseMB).to.be.lessThan(15);
        });
      });
    });
  });
});