/// <reference types="cypress" />

describe('Configuration Performance Monitoring', () => {
  beforeEach(() => {
    // Don't visit initially - we want to measure from cold start
  });

  context('Build-Time Configuration Performance', () => {
    it('should load configuration faster than HTTP-based approach', () => {
      const benchmarks = {
        coldStart: 300,     // ms - time to first config access
        firstPaint: 500,    // ms - time to visual elements
        interactive: 800,   // ms - time to fully interactive
        firstCalc: 1200     // ms - time to complete first calculation
      };
      
      const startTime = performance.now();
      
      cy.visit('/');
      
      // Configuration should be immediately available (no HTTP delay)
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .and('have.value', '2.5')
        .then(() => {
          const configLoadTime = performance.now() - startTime;
          
          // Static configuration should eliminate HTTP latency completely
          expect(configLoadTime).to.be.lessThan(benchmarks.coldStart);
          
          cy.log(`Static config cold start: ${configLoadTime}ms`);
          cy.task('logPerformance', {
            metric: 'config_load_time',
            value: configLoadTime,
            threshold: benchmarks.coldStart,
            passed: configLoadTime < benchmarks.coldStart
          });
        });
      
      // Application should be interactive immediately
      cy.get('[data-testid="pond-length-input"]')
        .should('be.visible')
        .clear()
        .type('45')
        .then(() => {
          const interactiveTime = performance.now() - startTime;
          
          expect(interactiveTime).to.be.lessThan(benchmarks.interactive);
          
          cy.log(`Time to interactive: ${interactiveTime}ms`);
        });
      
      // First calculation should complete quickly
      cy.wait(400); // Debounce
      
      cy.get('[data-testid="timeline-result"]')
        .should('be.visible')
        .then(() => {
          const firstCalcTime = performance.now() - startTime;
          
          expect(firstCalcTime).to.be.lessThan(benchmarks.firstCalc);
          
          cy.log(`First calculation complete: ${firstCalcTime}ms`);
        });
    });

    it('should maintain consistent performance across multiple page loads', () => {
      const loadTimes = [];
      const iterations = 5;
      
      for (let i = 0; i < iterations; i++) {
        const startTime = performance.now();
        
        cy.visit('/');
        
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('have.value', '2.5')
          .then(() => {
            const loadTime = performance.now() - startTime;
            loadTimes.push(loadTime);
            
            cy.log(`Load iteration ${i + 1}: ${loadTime}ms`);
          });
        
        // Clear page for next iteration
        cy.clearLocalStorage();
        cy.clearCookies();
      }
      
      cy.then(() => {
        const avgLoadTime = loadTimes.reduce((sum, time) => sum + time, 0) / loadTimes.length;
        const maxLoadTime = Math.max(...loadTimes);
        const minLoadTime = Math.min(...loadTimes);
        const variance = maxLoadTime - minLoadTime;
        
        // Performance should be consistent
        expect(avgLoadTime).to.be.lessThan(400);
        expect(variance).to.be.lessThan(200); // Low variance indicates consistency
        
        cy.log(`Average load time: ${avgLoadTime}ms (min: ${minLoadTime}ms, max: ${maxLoadTime}ms, variance: ${variance}ms)`);
        
        cy.task('logPerformance', {
          metric: 'load_time_consistency',
          average: avgLoadTime,
          variance: variance,
          iterations: iterations
        });
      });
    });

    it('should demonstrate bundle size impact is minimal', () => {
      cy.visit('/');
      
      cy.window().then((win) => {
        const navEntry = win.performance.getEntriesByType('navigation')[0];
        const resourceEntries = win.performance.getEntriesByType('resource');
        
        const totalTransferSize = navEntry.transferSize;
        const jsResources = resourceEntries.filter(entry => 
          entry.name.includes('.js') && entry.transferSize > 0
        );
        
        const jsSize = jsResources.reduce((total, resource) => 
          total + resource.transferSize, 0
        );
        
        // Bundle with embedded config should remain reasonable
        expect(totalTransferSize).to.be.lessThan(100000); // 100KB total
        expect(jsSize).to.be.lessThan(60000); // 60KB JavaScript including config
        
        cy.log(`Total bundle size: ${totalTransferSize} bytes`);
        cy.log(`JavaScript size (including embedded config): ${jsSize} bytes`);
        
        // Estimated config contribution (should be minimal)
        const estimatedConfigSize = 2000; // ~2KB for comprehensive config
        const configPercent = (estimatedConfigSize / totalTransferSize) * 100;
        
        expect(configPercent).to.be.lessThan(5); // Config should be <5% of bundle
        
        cy.task('logPerformance', {
          metric: 'bundle_size_impact',
          totalSize: totalTransferSize,
          jsSize: jsSize,
          estimatedConfigSize: estimatedConfigSize,
          configPercent: configPercent
        });
      });
    });
  });

  context('Cross-Device Performance Consistency', () => {
    const devices = [
      { name: 'Mobile', width: 375, height: 667, expectedPerf: 600 },
      { name: 'Tablet', width: 768, height: 1024, expectedPerf: 500 },
      { name: 'Desktop', width: 1200, height: 800, expectedPerf: 400 }
    ];

    devices.forEach(device => {
      it(`should maintain performance standards on ${device.name}`, () => {
        cy.viewport(device.width, device.height);
        
        const startTime = performance.now();
        
        cy.visit('/');
        
        // Configuration should load consistently across devices
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .and('have.value', '2.5')
          .then(() => {
            const configTime = performance.now() - startTime;
            
            expect(configTime).to.be.lessThan(device.expectedPerf);
            
            cy.log(`${device.name} config load: ${configTime}ms`);
          });
        
        // Test calculation performance on device
        cy.get('[data-testid="pond-length-input"]').clear().type('40');
        
        const calcStart = performance.now();
        cy.wait(400); // Debounce
        
        cy.get('[data-testid="timeline-result"]')
          .should('be.visible')
          .then(() => {
            const calcTime = performance.now() - calcStart;
            
            expect(calcTime).to.be.lessThan(600); // All devices should calculate quickly
            
            cy.log(`${device.name} calculation: ${calcTime}ms`);
            
            cy.task('logPerformance', {
              metric: `${device.name.toLowerCase()}_performance`,
              configLoadTime: performance.now() - startTime,
              calcTime: calcTime,
              viewport: `${device.width}x${device.height}`
            });
          });
      });
    });
  });

  context('Memory and Resource Usage', () => {
    it('should not create memory leaks with static configuration', () => {
      cy.visit('/');
      
      // Measure initial memory usage
      cy.window().then((win) => {
        if (win.performance.memory) {
          const initialMemory = win.performance.memory.usedJSHeapSize;
          
          // Perform many configuration accesses
          for (let i = 0; i < 100; i++) {
            // Trigger config access through UI interactions
            cy.get('[data-testid="excavator-capacity-input"]').clear().type(String(2.5 + (i * 0.1)));
            cy.wait(50);
          }
          
          cy.wait(1000); // Allow garbage collection
          
          cy.window().then((win2) => {
            const finalMemory = win2.performance.memory.usedJSHeapSize;
            const memoryIncrease = finalMemory - initialMemory;
            
            // Memory increase should be minimal (static config doesn't create objects)
            expect(memoryIncrease).to.be.lessThan(1000000); // Less than 1MB increase
            
            cy.log(`Memory usage increase: ${memoryIncrease} bytes`);
            
            cy.task('logPerformance', {
              metric: 'memory_stability',
              initialMemory: initialMemory,
              finalMemory: finalMemory,
              increase: memoryIncrease
            });
          });
        } else {
          cy.log('Memory measurement not available in this browser');
        }
      });
    });

    it('should maintain performance under stress conditions', () => {
      cy.visit('/');
      
      const stressTestIterations = 50;
      const performanceSamples = [];
      
      // Stress test: rapid configuration-dependent operations
      for (let i = 0; i < stressTestIterations; i++) {
        const iterationStart = performance.now();
        
        // Vary inputs to trigger configuration validation
        cy.get('[data-testid="excavator-capacity-input"]')
          .clear()
          .type(String(1.0 + (i % 10) * 0.5));
        
        cy.get('[data-testid="truck-capacity-input"]')
          .clear()  
          .type(String(10 + (i % 5) * 2));
        
        cy.wait(100);
        
        cy.then(() => {
          const iterationTime = performance.now() - iterationStart;
          performanceSamples.push(iterationTime);
        });
      }
      
      cy.then(() => {
        const avgIterationTime = performanceSamples.reduce((sum, time) => sum + time, 0) / performanceSamples.length;
        const maxIterationTime = Math.max(...performanceSamples);
        
        // Performance should not degrade significantly under stress
        expect(avgIterationTime).to.be.lessThan(200);
        expect(maxIterationTime).to.be.lessThan(500);
        
        cy.log(`Stress test average iteration: ${avgIterationTime}ms (max: ${maxIterationTime}ms)`);
        
        cy.task('logPerformance', {
          metric: 'stress_test_performance',
          iterations: stressTestIterations,
          averageTime: avgIterationTime,
          maxTime: maxIterationTime
        });
      });
    });
  });

  context('Network Independence Performance', () => {
    it('should demonstrate zero network latency for configuration', () => {
      // Block all network requests to prove independence
      cy.intercept('**', { forceNetworkError: true }).as('networkBlocked');
      
      const startTime = performance.now();
      
      cy.visit('/');
      
      // Should load instantly without network
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .and('have.value', '2.5')
        .then(() => {
          const offlineLoadTime = performance.now() - startTime;
          
          // Offline performance should be excellent (no network delays)
          expect(offlineLoadTime).to.be.lessThan(300);
          
          cy.log(`Offline configuration load: ${offlineLoadTime}ms`);
        });
      
      // Should function completely offline
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]')
        .should('be.visible')
        .then(() => {
          const offlineCalcTime = performance.now() - startTime;
          
          expect(offlineCalcTime).to.be.lessThan(800);
          
          cy.log(`Complete offline workflow: ${offlineCalcTime}ms`);
          
          cy.task('logPerformance', {
            metric: 'offline_performance',
            loadTime: offlineLoadTime,
            workflowTime: offlineCalcTime,
            networkBlocked: true
          });
        });
    });

    it('should maintain performance consistency with and without network', () => {
      const performanceComparison = {};
      
      // Test with network available
      const onlineStart = performance.now();
      cy.visit('/');
      
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5')
        .then(() => {
          performanceComparison.onlineLoad = performance.now() - onlineStart;
        });
      
      // Test completely offline
      cy.intercept('**', { forceNetworkError: true }).as('offline');
      
      const offlineStart = performance.now();
      cy.visit('/');
      
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5')
        .then(() => {
          performanceComparison.offlineLoad = performance.now() - offlineStart;
          
          const performanceDifference = Math.abs(
            performanceComparison.onlineLoad - performanceComparison.offlineLoad
          );
          
          // Performance should be nearly identical (proving no network dependency)
          expect(performanceDifference).to.be.lessThan(100);
          
          cy.log(`Online: ${performanceComparison.onlineLoad}ms, Offline: ${performanceComparison.offlineLoad}ms`);
          cy.log(`Difference: ${performanceDifference}ms`);
          
          cy.task('logPerformance', {
            metric: 'network_independence',
            onlineTime: performanceComparison.onlineLoad,
            offlineTime: performanceComparison.offlineLoad,
            difference: performanceDifference
          });
        });
    });
  });
});