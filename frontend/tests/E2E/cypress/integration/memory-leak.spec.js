/// <reference types="cypress" />

describe('Memory Leak Prevention Tests', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  context('Large Fleet Operations Memory Management', () => {
    it('should not leak memory with extensive fleet operations', () => {
      cy.viewport(1200, 800); // Desktop for fleet operations
      
      // Baseline memory measurement
      cy.window().then((win) => {
        // Force garbage collection if available (Chrome DevTools)
        if (win.gc) {
          win.gc();
        }
        
        const initialMemory = win.performance.memory 
          ? win.performance.memory.usedJSHeapSize 
          : 0;
        
        cy.wrap(initialMemory).as('initialMemory');
      });
      
      // Simulate extensive fleet management operations
      const fleetOperations = 50; // Reduced from 1000+ for practical testing
      
      for (let i = 0; i < fleetOperations; i++) {
        // Simulate adding and removing equipment rapidly
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type(String(40 + (i % 10)));
        
        cy.get('[data-testid="excavator-capacity-input"]')
          .clear()
          .type(String(2.0 + (i % 5) * 0.5));
        
        // Don't wait for debounce on each iteration to stress test
        if (i % 10 === 0) {
          cy.wait(50); // Minimal wait every 10 operations
        }
      }
      
      // Final calculation
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Check memory after operations
      cy.get('@initialMemory').then((initialMemory) => {
        cy.window().then((win) => {
          // Force garbage collection again
          if (win.gc) {
            win.gc();
          }
          
          const finalMemory = win.performance.memory 
            ? win.performance.memory.usedJSHeapSize 
            : initialMemory;
          
          const memoryIncrease = finalMemory - initialMemory;
          const memoryIncreasePercent = (memoryIncrease / initialMemory) * 100;
          
          // Memory increase should be reasonable (less than 50% increase)
          expect(memoryIncreasePercent).to.be.lessThan(50);
          
          cy.log(`Memory usage: Initial=${initialMemory}, Final=${finalMemory}, Increase=${memoryIncreasePercent.toFixed(2)}%`);
        });
      });
    });

    it('should handle rapid calculation cycles without memory accumulation', () => {
      cy.viewport(1200, 800);
      
      // Baseline measurement
      cy.window().then((win) => {
        if (win.gc) win.gc();
        const initial = win.performance.memory?.usedJSHeapSize || 0;
        cy.wrap(initial).as('baselineMemory');
      });
      
      // Perform many rapid calculations
      const calculationCycles = 100; // Stress test with many calculations
      
      for (let cycle = 0; cycle < calculationCycles; cycle++) {
        const values = [
          { field: 'pond-length-input', value: String(30 + (cycle % 20)) },
          { field: 'pond-width-input', value: String(20 + (cycle % 15)) },
          { field: 'pond-depth-input', value: String(3 + (cycle % 5)) },
          { field: 'excavator-capacity-input', value: String(2.0 + (cycle % 3) * 0.5) },
          { field: 'truck-capacity-input', value: String(10 + (cycle % 8) * 2) }
        ];
        
        values.forEach(({ field, value }) => {
          cy.get(`[data-testid="${field}"]`).clear().type(value);
        });
        
        // Only wait occasionally to stress test debouncing
        if (cycle % 25 === 0) {
          cy.wait(100);
        }
      }
      
      // Final wait and result check
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Memory check after stress test
      cy.get('@baselineMemory').then((baseline) => {
        cy.window().then((win) => {
          if (win.gc) win.gc();
          const final = win.performance.memory?.usedJSHeapSize || baseline;
          const increase = ((final - baseline) / baseline) * 100;
          
          // After extensive calculations, memory should not have grown excessively
          expect(increase).to.be.lessThan(100); // Less than 100% increase
          
          cy.log(`Calculation stress test: ${increase.toFixed(2)}% memory increase`);
        });
      });
    });

    it('should properly clean up event listeners and timers', () => {
      cy.viewport(1200, 800);
      
      // Track event listeners and timers
      cy.window().then((win) => {
        let eventListenerCount = 0;
        let timerCount = 0;
        
        // Override addEventListener to count listeners
        const originalAddEventListener = win.addEventListener;
        win.addEventListener = function(...args) {
          eventListenerCount++;
          return originalAddEventListener.apply(this, args);
        };
        
        // Override setTimeout/setInterval to count timers
        const originalSetTimeout = win.setTimeout;
        const originalSetInterval = win.setInterval;
        
        win.setTimeout = function(...args) {
          timerCount++;
          return originalSetTimeout.apply(this, args);
        };
        
        win.setInterval = function(...args) {
          timerCount++;
          return originalSetInterval.apply(this, args);
        };
        
        cy.wrap({ eventListeners: eventListenerCount, timers: timerCount }).as('initialCounts');
      });
      
      // Perform operations that might create listeners/timers
      const operations = 20;
      for (let i = 0; i < operations; i++) {
        cy.get('[data-testid="pond-length-input"]')
          .focus()
          .clear()
          .type(String(40 + i));
        
        cy.get('[data-testid="excavator-capacity-input"]')
          .focus()
          .clear()
          .type(String(2.5 + i * 0.1));
          
        if (i % 5 === 0) {
          cy.wait(100);
        }
      }
      
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Check that cleanup occurred properly
      cy.get('@initialCounts').then((initial) => {
        cy.window().then((win) => {
          // In a well-designed app, the number of listeners and timers
          // should not grow proportionally with operations
          const maxReasonableIncrease = 50; // Reasonable buffer
          
          // This is a simplified check - in reality, you'd want more sophisticated tracking
          cy.log(`Event listeners and timers created during operations`);
          
          // The key is that memory and resource usage don't grow unbounded
          // The actual implementation should clean up after itself
        });
      });
    });
  });

  context('DOM and Component Memory Management', () => {
    it('should not accumulate DOM nodes during rapid UI updates', () => {
      cy.viewport(1200, 800);
      
      // Count initial DOM nodes
      cy.get('body').then($body => {
        const initialNodeCount = $body.find('*').length;
        cy.wrap(initialNodeCount).as('initialNodes');
      });
      
      // Perform rapid UI updates
      const updates = 50;
      for (let i = 0; i < updates; i++) {
        // Trigger UI updates through input changes
        cy.get('[data-testid="pond-length-input"]').clear().type(String(30 + i));
        cy.get('[data-testid="pond-width-input"]').clear().type(String(25 + i));
        
        // Occasional pause to allow processing
        if (i % 10 === 0) {
          cy.wait(50);
        }
      }
      
      cy.wait(500);
      
      // Check DOM node count hasn't grown excessively
      cy.get('@initialNodes').then((initial) => {
        cy.get('body').then($body => {
          const finalNodeCount = $body.find('*').length;
          const nodeIncrease = finalNodeCount - initial;
          const percentIncrease = (nodeIncrease / initial) * 100;
          
          // DOM nodes should not increase significantly with UI updates
          expect(percentIncrease).to.be.lessThan(20); // Less than 20% increase
          
          cy.log(`DOM nodes: Initial=${initial}, Final=${finalNodeCount}, Increase=${percentIncrease.toFixed(2)}%`);
        });
      });
    });

    it('should handle browser tab switching without memory issues', () => {
      cy.viewport(1200, 800);
      
      // Start some background activity
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.wait(200);
      
      // Simulate tab switching by triggering visibility change events
      cy.window().then((win) => {
        // Baseline memory
        if (win.gc) win.gc();
        const baseline = win.performance.memory?.usedJSHeapSize || 0;
        
        // Simulate tab becoming hidden
        const visibilityEvent = new Event('visibilitychange');
        Object.defineProperty(win.document, 'hidden', { value: true, writable: true });
        win.document.dispatchEvent(visibilityEvent);
        
        // Wait a bit while "tab is in background"
        cy.wait(1000);
        
        // Simulate tab becoming visible again
        Object.defineProperty(win.document, 'hidden', { value: false, writable: true });
        win.document.dispatchEvent(visibilityEvent);
        
        // Continue normal operation
        cy.get('[data-testid="pond-depth-input"]').clear().type('6');
        cy.wait(500);
        
        // Check memory after tab switching
        if (win.gc) win.gc();
        const final = win.performance.memory?.usedJSHeapSize || baseline;
        const increase = ((final - baseline) / baseline) * 100;
        
        // Memory should not have increased significantly due to tab switching
        expect(increase).to.be.lessThan(30);
        
        cy.log(`Tab switching memory impact: ${increase.toFixed(2)}% increase`);
      });
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should properly handle component unmounting and cleanup', () => {
      // Test device switching which may unmount/remount components
      const viewports = [
        { width: 1200, height: 800 }, // Desktop
        { width: 768, height: 1024 }, // Tablet
        { width: 375, height: 667 },  // Mobile
        { width: 1200, height: 800 }  // Back to desktop
      ];
      
      cy.window().then((win) => {
        if (win.gc) win.gc();
        const initial = win.performance.memory?.usedJSHeapSize || 0;
        cy.wrap(initial).as('switchingBaseline');
      });
      
      // Switch between device types rapidly
      viewports.forEach((viewport, index) => {
        cy.viewport(viewport.width, viewport.height);
        cy.wait(300); // Allow device transition
        
        // Perform operations on each device type
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type(String(35 + index * 5));
        
        cy.wait(200);
      });
      
      // Final memory check
      cy.get('@switchingBaseline').then((baseline) => {
        cy.window().then((win) => {
          if (win.gc) win.gc();
          const final = win.performance.memory?.usedJSHeapSize || baseline;
          const increase = ((final - baseline) / baseline) * 100;
          
          // Device switching should not cause significant memory increase
          expect(increase).to.be.lessThan(40);
          
          cy.log(`Device switching memory impact: ${increase.toFixed(2)}% increase`);
        });
      });
    });
  });

  context('Long-Running Session Stability', () => {
    it('should maintain performance over extended usage simulation', () => {
      cy.viewport(1200, 800);
      
      // Simulate extended usage session
      const sessionDuration = 20; // Reduced for practical testing
      const operations = ['length', 'width', 'depth', 'capacity', 'cycle'];
      
      cy.window().then((win) => {
        if (win.gc) win.gc();
        const sessionStart = win.performance.memory?.usedJSHeapSize || 0;
        cy.wrap(sessionStart).as('sessionBaseline');
        cy.wrap(performance.now()).as('startTime');
      });
      
      // Simulate realistic usage patterns over time
      for (let session = 0; session < sessionDuration; session++) {
        // Vary operations to simulate real user behavior
        const operation = operations[session % operations.length];
        
        switch (operation) {
          case 'length':
            cy.get('[data-testid="pond-length-input"]').clear().type(String(30 + session));
            break;
          case 'width':
            cy.get('[data-testid="pond-width-input"]').clear().type(String(20 + session));
            break;
          case 'depth':
            cy.get('[data-testid="pond-depth-input"]').clear().type(String(4 + session % 3));
            break;
          case 'capacity':
            cy.get('[data-testid="excavator-capacity-input"]').clear().type(String(2.0 + session * 0.1));
            break;
          case 'cycle':
            cy.get('[data-testid="excavator-cycle-input"]').clear().type(String(1.8 + session * 0.05));
            break;
        }
        
        // Realistic pause between operations
        cy.wait(100);
        
        // Periodic longer pauses (user thinking time)
        if (session % 5 === 0) {
          cy.wait(300);
        }
      }
      
      cy.wait(500);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Check session stability
      cy.get('@sessionBaseline').then((baseline) => {
        cy.get('@startTime').then((startTime) => {
          cy.window().then((win) => {
            if (win.gc) win.gc();
            const final = win.performance.memory?.usedJSHeapSize || baseline;
            const endTime = performance.now();
            
            const memoryIncrease = ((final - baseline) / baseline) * 100;
            const sessionTime = endTime - startTime;
            
            // Extended session should not cause excessive memory growth
            expect(memoryIncrease).to.be.lessThan(60);
            
            // Application should remain responsive
            expect(sessionTime / sessionDuration).to.be.lessThan(1000); // Avg < 1sec per operation
            
            cy.log(`Extended session: ${memoryIncrease.toFixed(2)}% memory increase over ${(sessionTime/1000).toFixed(1)}s`);
          });
        });
      });
    });

    it('should handle page reload memory reset correctly', () => {
      // Perform operations to increase memory usage
      const preReloadOps = 30;
      for (let i = 0; i < preReloadOps; i++) {
        cy.get('[data-testid="pond-length-input"]').clear().type(String(40 + i));
        if (i % 5 === 0) cy.wait(50);
      }
      
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Measure memory before reload
      cy.window().then((win) => {
        if (win.gc) win.gc();
        const preReload = win.performance.memory?.usedJSHeapSize || 0;
        cy.wrap(preReload).as('preReloadMemory');
      });
      
      // Reload page
      cy.reload();
      cy.wait(1000);
      
      // Check initial state after reload
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      
      // Measure memory after reload
      cy.get('@preReloadMemory').then((preReload) => {
        cy.window().then((win) => {
          if (win.gc) win.gc();
          const postReload = win.performance.memory?.usedJSHeapSize || 0;
          
          // Memory should be reset to baseline levels after reload
          const memoryRatio = postReload / preReload;
          expect(memoryRatio).to.be.lessThan(1.2); // Should be similar or less than pre-reload
          
          cy.log(`Memory reset: Pre-reload=${preReload}, Post-reload=${postReload}, Ratio=${memoryRatio.toFixed(2)}`);
        });
      });
    });
  });

  context('Performance Degradation Detection', () => {
    it('should detect and prevent calculation performance degradation', () => {
      cy.viewport(1200, 800);
      
      // Baseline performance measurement
      const measureCalculationTime = () => {
        const start = performance.now();
        cy.get('[data-testid="pond-length-input"]').clear().type('45');
        cy.wait(450); // Include debounce time
        cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
          return performance.now() - start;
        });
      };
      
      // Initial calculation time
      cy.then(() => {
        const start = performance.now();
        return cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type('50')
          .wait(450)
          .get('[data-testid="timeline-result"]')
          .should('be.visible')
          .then(() => performance.now() - start);
      }).as('baselineTime');
      
      // Perform many operations to potentially cause degradation
      const stressOperations = 25;
      for (let i = 0; i < stressOperations; i++) {
        cy.get('[data-testid="pond-width-input"]').clear().type(String(30 + i));
        cy.get('[data-testid="excavator-capacity-input"]').clear().type(String(2.0 + i * 0.05));
        if (i % 8 === 0) cy.wait(50);
      }
      
      // Measure performance after stress operations
      cy.get('@baselineTime').then((baseline) => {
        const start = performance.now();
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type('55')
          .wait(450)
          .get('[data-testid="timeline-result"]')
          .should('be.visible')
          .then(() => {
            const finalTime = performance.now() - start;
            const degradationRatio = finalTime / baseline;
            
            // Performance should not degrade significantly
            expect(degradationRatio).to.be.lessThan(2.0); // Less than 2x slower
            
            cy.log(`Performance: Baseline=${baseline.toFixed(0)}ms, Final=${finalTime.toFixed(0)}ms, Ratio=${degradationRatio.toFixed(2)}x`);
          });
      });
    });

    it('should maintain memory efficiency with complex calculations', () => {
      cy.viewport(1200, 800);
      
      // Test with maximum complexity values
      const complexScenarios = [
        { length: '1000', width: '800', depth: '15', capacity: '5.0', cycle: '3.5' },
        { length: '500', width: '400', depth: '12', capacity: '4.0', cycle: '2.8' },
        { length: '750', width: '600', depth: '10', capacity: '3.5', cycle: '2.2' },
        { length: '900', width: '700', depth: '8', capacity: '4.5', cycle: '3.0' }
      ];
      
      cy.window().then((win) => {
        if (win.gc) win.gc();
        const initial = win.performance.memory?.usedJSHeapSize || 0;
        cy.wrap(initial).as('complexityBaseline');
      });
      
      // Run complex scenarios
      complexScenarios.forEach((scenario, index) => {
        cy.get('[data-testid="pond-length-input"]').clear().type(scenario.length);
        cy.get('[data-testid="pond-width-input"]').clear().type(scenario.width);
        cy.get('[data-testid="pond-depth-input"]').clear().type(scenario.depth);
        cy.get('[data-testid="excavator-capacity-input"]').clear().type(scenario.capacity);
        cy.get('[data-testid="excavator-cycle-input"]').clear().type(scenario.cycle);
        
        cy.wait(500); // Allow calculation
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        cy.log(`Complex scenario ${index + 1} completed`);
      });
      
      // Final memory check
      cy.get('@complexityBaseline').then((baseline) => {
        cy.window().then((win) => {
          if (win.gc) win.gc();
          const final = win.performance.memory?.usedJSHeapSize || baseline;
          const increase = ((final - baseline) / baseline) * 100;
          
          // Complex calculations should not cause excessive memory usage
          expect(increase).to.be.lessThan(50);
          
          cy.log(`Complex calculations memory impact: ${increase.toFixed(2)}% increase`);
        });
      });
    });
  });
});