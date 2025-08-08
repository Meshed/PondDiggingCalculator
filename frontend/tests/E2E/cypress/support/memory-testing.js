// Memory testing utilities for Cypress

// Memory measurement command
Cypress.Commands.add('measureMemory', { prevSubject: 'optional' }, (subject, label = 'measurement') => {
  cy.window().then((win) => {
    // Force garbage collection if available (Chrome DevTools)
    if (win.gc) {
      win.gc();
    }
    
    const memory = win.performance.memory;
    const measurement = {
      label,
      timestamp: Date.now(),
      usedJSHeapSize: memory ? memory.usedJSHeapSize : 0,
      totalJSHeapSize: memory ? memory.totalJSHeapSize : 0,
      jsHeapSizeLimit: memory ? memory.jsHeapSizeLimit : 0
    };
    
    cy.wrap(measurement).as(`memory_${label.replace(/\s+/g, '_')}`);
    cy.log(`Memory ${label}: ${measurement.usedJSHeapSize} bytes`);
    
    return cy.wrap(measurement);
  });
});

// Compare memory measurements
Cypress.Commands.add('compareMemory', (startAlias, endAlias, maxIncreasePercent = 50) => {
  cy.get(`@${startAlias}`).then(startMem => {
    cy.get(`@${endAlias}`).then(endMem => {
      const increase = endMem.usedJSHeapSize - startMem.usedJSHeapSize;
      const increasePercent = (increase / startMem.usedJSHeapSize) * 100;
      
      cy.log(`Memory change: ${increase} bytes (${increasePercent.toFixed(2)}%)`);
      
      expect(increasePercent).to.be.lessThan(maxIncreasePercent, 
        `Memory increase should be less than ${maxIncreasePercent}%`);
      
      return cy.wrap({
        start: startMem,
        end: endMem,
        increase,
        increasePercent
      });
    });
  });
});

// Memory stress testing
Cypress.Commands.add('stressTestMemory', (operations = 100, description = 'stress test') => {
  cy.measureMemory('stress_start');
  
  // Perform stress operations
  for (let i = 0; i < operations; i++) {
    cy.get('[data-testid="pond-length-input"]').clear().type(String(40 + (i % 20)));
    
    if (i % 10 === 0) {
      cy.wait(50); // Occasional pause
    }
  }
  
  cy.wait(500); // Allow processing
  cy.measureMemory('stress_end');
  
  cy.compareMemory('memory_stress_start', 'memory_stress_end', 100);
});

// Monitor memory during operation
Cypress.Commands.add('monitorMemoryDuring', (operationCallback, maxIncrease = 50) => {
  cy.measureMemory('monitor_start');
  
  // Execute the operation
  operationCallback();
  
  cy.measureMemory('monitor_end');
  cy.compareMemory('memory_monitor_start', 'memory_monitor_end', maxIncrease);
});

// DOM node counting
Cypress.Commands.add('countDOMNodes', (selector = '*') => {
  cy.get('body').then($body => {
    const count = $body.find(selector).length;
    cy.wrap(count).as('domNodeCount');
    cy.log(`DOM nodes (${selector}): ${count}`);
    return cy.wrap(count);
  });
});

// Performance timing measurement
Cypress.Commands.add('measurePerformance', (label = 'performance') => {
  cy.window().then(win => {
    const timing = win.performance.timing;
    const navigation = win.performance.getEntriesByType('navigation')[0];
    
    const metrics = {
      label,
      loadEventEnd: timing.loadEventEnd - timing.navigationStart,
      domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
      firstPaint: navigation ? navigation.responseEnd - navigation.requestStart : 0,
      timestamp: Date.now()
    };
    
    cy.wrap(metrics).as(`performance_${label.replace(/\s+/g, '_')}`);
    cy.log(`Performance ${label}: Load=${metrics.loadEventEnd}ms, DOMReady=${metrics.domContentLoaded}ms`);
    
    return cy.wrap(metrics);
  });
});

// Resource monitoring
Cypress.Commands.add('monitorResources', () => {
  cy.window().then(win => {
    const resources = win.performance.getEntriesByType('resource');
    const resourceSummary = {
      totalResources: resources.length,
      totalSize: resources.reduce((sum, resource) => sum + (resource.transferSize || 0), 0),
      scripts: resources.filter(r => r.name.includes('.js')).length,
      styles: resources.filter(r => r.name.includes('.css')).length,
      images: resources.filter(r => r.name.match(/\.(png|jpg|jpeg|gif|svg|webp)$/)).length,
      timestamp: Date.now()
    };
    
    cy.wrap(resourceSummary).as('resourceMonitoring');
    cy.log(`Resources: ${resourceSummary.totalResources} total, ${resourceSummary.totalSize} bytes`);
    
    return cy.wrap(resourceSummary);
  });
});

// Event listener counting (approximation)
Cypress.Commands.add('estimateEventListeners', () => {
  cy.window().then(win => {
    // This is an approximation - actual event listener counting is complex
    const elementsWithListeners = win.document.querySelectorAll('[onclick], [onchange], [oninput]').length;
    
    // Count data attributes that might indicate event listeners
    const dataEventElements = win.document.querySelectorAll('[data-testid]').length;
    
    const estimate = {
      explicitListeners: elementsWithListeners,
      potentialListeners: dataEventElements,
      timestamp: Date.now()
    };
    
    cy.wrap(estimate).as('eventListenerEstimate');
    cy.log(`Event listeners estimate: ${elementsWithListeners} explicit, ${dataEventElements} potential`);
    
    return cy.wrap(estimate);
  });
});

// Memory leak detection over time
Cypress.Commands.add('detectMemoryLeaks', (iterations = 5, operationCallback) => {
  const measurements = [];
  
  // Take multiple measurements over time
  for (let i = 0; i < iterations; i++) {
    cy.measureMemory(`leak_detection_${i}`);
    
    // Perform the operation
    operationCallback();
    
    cy.wait(200);
    
    cy.get(`@memory_leak_detection_${i}`).then(measurement => {
      measurements.push(measurement.usedJSHeapSize);
    });
  }
  
  cy.then(() => {
    // Analyze trend
    const firstMeasurement = measurements[0];
    const lastMeasurement = measurements[measurements.length - 1];
    const growthRate = (lastMeasurement - firstMeasurement) / firstMeasurement * 100;
    
    cy.log(`Memory growth over ${iterations} iterations: ${growthRate.toFixed(2)}%`);
    
    // Memory should not grow consistently (indicating a leak)
    expect(growthRate).to.be.lessThan(100, 
      `Memory growth rate should be less than 100% over ${iterations} iterations`);
    
    return cy.wrap({
      measurements,
      growthRate,
      firstMeasurement,
      lastMeasurement
    });
  });
});

// Cleanup command
Cypress.Commands.add('cleanupMemoryTest', () => {
  cy.window().then(win => {
    // Force garbage collection if available
    if (win.gc) {
      win.gc();
    }
    
    // Clear any test data
    if (win.testData) {
      win.testData = null;
    }
    
    // Clear large arrays if they exist
    ['memoryPressure', 'testArrays', 'benchmarkData'].forEach(prop => {
      if (win[prop]) {
        win[prop] = null;
      }
    });
    
    cy.log('Memory test cleanup completed');
  });
});

// Performance baseline establishment
Cypress.Commands.add('establishPerformanceBaseline', () => {
  cy.measureMemory('baseline_memory');
  cy.measurePerformance('baseline_performance');
  cy.countDOMNodes().as('baseline_dom_nodes');
  cy.monitorResources();
  cy.estimateEventListeners();
  
  cy.log('Performance baseline established');
});