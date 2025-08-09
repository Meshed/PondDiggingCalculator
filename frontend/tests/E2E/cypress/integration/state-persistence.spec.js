/// <reference types="cypress" />

describe('State Persistence Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1200, 800);
  });

  context('Fleet Configuration Persistence', () => {
    it('should persist fleet configuration across browser refresh', () => {
      // Create a complex fleet configuration
      cy.createFleetConfiguration({ excavators: 3, trucks: 2 });
      
      // Configure specific equipment with unique values
      cy.configureEquipment('excavator', 0, { 
        bucketCapacity: 2.8, 
        cycleTime: 1.9,
        name: 'Excavator Alpha'
      });
      cy.configureEquipment('excavator', 1, { 
        bucketCapacity: 3.2, 
        cycleTime: 2.1,
        name: 'Excavator Beta'
      });
      cy.configureEquipment('truck', 0, { 
        capacity: 16, 
        roundTripTime: 22,
        name: 'Truck One'
      });

      // Set pond configuration
      cy.setPondDimensions({ length: 65, width: 45, depth: 7, workHours: 9 });
      
      // Wait for state to settle
      cy.wait(1000);
      
      // Capture current calculation result
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').as('originalResult');
      
      // Refresh the page
      cy.reload();
      
      // Verify fleet configuration persisted
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 4); // 1 initial + 3 added
        
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 3); // 1 initial + 2 added
      
      // Verify specific equipment values persisted
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(0)
        .find('[data-testid*="excavator-capacity"]')
        .should('have.value', '2.8');
      
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .should('have.value', '3.2');
      
      // Verify pond dimensions persisted
      cy.get('[data-testid="pond-length-input"]').should('have.value', '65');
      cy.get('[data-testid="pond-width-input"]').should('have.value', '45');
      cy.get('[data-testid="pond-depth-input"]').should('have.value', '7');
      cy.get('[data-testid="work-hours-input"]').should('have.value', '9');
      
      // Verify calculation result is consistent
      cy.waitForCalculation();
      cy.get('@originalResult').then(originalResult => {
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .should('equal', originalResult);
      });
      
      cy.log('Fleet configuration persistence verified across refresh');
    });

    it('should persist state across browser tab close/reopen', () => {
      // Set up test configuration
      cy.createFleetConfiguration({ excavators: 2, trucks: 1 });
      cy.setPondDimensions({ length: 55, width: 35, depth: 6 });
      
      cy.configureEquipment('excavator', 0, { bucketCapacity: 3.5, cycleTime: 1.7 });
      
      cy.wait(1000);
      
      // Store reference values
      let equipmentCount, pondLength, excavatorCapacity;
      
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .its('length')
        .then(count => equipmentCount = count);
        
      cy.get('[data-testid="pond-length-input"]')
        .invoke('val')
        .then(value => pondLength = value);
        
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(0)
        .find('[data-testid*="excavator-capacity"]')
        .invoke('val')
        .then(value => excavatorCapacity = value);
      
      // Simulate tab close/reopen by visiting a different page then returning
      cy.visit('data:text/html,<html><body>Different Page</body></html>');
      cy.wait(500);
      cy.visit('/');
      
      // Verify state was restored
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', equipmentCount);
        
      cy.get('[data-testid="pond-length-input"]')
        .should('have.value', pondLength);
        
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(0)
        .find('[data-testid*="excavator-capacity"]')
        .should('have.value', excavatorCapacity);
      
      cy.log('State persistence verified across tab close/reopen');
    });

    it('should handle partial state corruption gracefully', () => {
      // Set up complex state
      cy.createFleetConfiguration({ excavators: 2, trucks: 2 });
      cy.setPondDimensions({ length: 50, width: 30, depth: 5 });
      
      // Corrupt part of the stored state
      cy.window().then((win) => {
        const currentState = win.localStorage.getItem('pondDiggingCalculator');
        if (currentState) {
          try {
            const state = JSON.parse(currentState);
            // Corrupt excavator data
            state.excavators = 'corrupted-data';
            win.localStorage.setItem('pondDiggingCalculator', JSON.stringify(state));
          } catch (e) {
            // If parsing fails, set completely invalid data
            win.localStorage.setItem('pondDiggingCalculator', '{"corrupted": true}');
          }
        }
      });
      
      cy.reload();
      
      // App should recover with defaults or partial valid state
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length.at.least', 1); // Should have at least default
        
      // Pond dimensions might persist if they were valid
      cy.get('[data-testid="pond-length-input"]').should('be.visible');
      
      // App should be functional
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('Partial state corruption handled gracefully');
    });
  });

  context('Device State Persistence', () => {
    it('should persist device-specific configurations', () => {
      // Test on desktop first
      cy.setDevice('desktop');
      cy.createFleetConfiguration({ excavators: 3, trucks: 2 });
      cy.setPondDimensions({ length: 80, width: 50, depth: 8 });
      
      cy.wait(1000);
      
      // Switch to tablet and verify fleet features available
      cy.setDevice('tablet');
      cy.reload();
      
      // Fleet configuration should persist on tablet
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 4);
        
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
      
      // Switch to mobile
      cy.setDevice('mobile');
      cy.reload();
      
      // Basic configuration should persist but fleet buttons hidden
      cy.get('[data-testid="pond-length-input"]').should('have.value', '80');
      cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
      
      // Only single equipment should be shown on mobile
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 1);
      
      cy.log('Device-specific state persistence verified');
    });

    it('should handle device transition scenarios', () => {
      // Start on mobile with basic configuration
      cy.setDevice('mobile');
      cy.setPondDimensions({ length: 35, width: 25, depth: 4 });
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.7');
      
      cy.wait(500);
      
      // Switch to desktop
      cy.setDevice('desktop');
      cy.reload();
      
      // Basic configuration should persist
      cy.get('[data-testid="pond-length-input"]').should('have.value', '35');
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.7');
      
      // Now can add fleet on desktop
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      // Switch back to mobile
      cy.setDevice('mobile');
      cy.reload();
      
      // Should show simplified view but maintain calculation accuracy
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 1);
        
      // Core calculation parameters should persist
      cy.get('[data-testid="pond-length-input"]').should('have.value', '35');
      
      cy.log('Device transition scenarios handled correctly');
    });
  });

  context('Calculation State Persistence', () => {
    it('should persist calculation results across sessions', () => {
      // Set up calculation parameters
      cy.setPondDimensions({ length: 60, width: 40, depth: 6 });
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('18');
      
      cy.waitForCalculation();
      
      // Store calculation result
      let originalTimeline, originalProductivity;
      cy.get('[data-testid="timeline-days"]')
        .invoke('text')
        .then(text => originalTimeline = text);
        
      // If productivity metrics are displayed, capture them too
      cy.get('body').then($body => {
        if ($body.find('[data-testid="productivity-result"]').length > 0) {
          cy.get('[data-testid="productivity-result"]')
            .invoke('text')
            .then(text => originalProductivity = text);
        }
      });
      
      // Clear calculation display temporarily
      cy.get('[data-testid="pond-length-input"]').clear();
      cy.wait(300);
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Refresh page
      cy.reload();
      
      // Verify parameters were restored
      cy.get('[data-testid="pond-length-input"]').should('have.value', '60');
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '3.0');
      
      // Calculation should be restored automatically
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]')
        .invoke('text')
        .should('equal', originalTimeline);
      
      cy.log('Calculation state persistence verified');
    });

    it('should persist validation states correctly', () => {
      // Create validation errors
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="pond-depth-input"]').clear().type('0');
      
      cy.wait(500);
      
      // Should show validation errors
      cy.get('body').then($body => {
        const hasErrors = $body.find('[data-testid*="error"]').length > 0;
        if (hasErrors) {
          cy.log('Validation errors present before refresh');
        }
      });
      
      // Refresh page
      cy.reload();
      
      // Invalid values should be restored but validation should run
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '-1');
      cy.get('[data-testid="pond-depth-input"]').should('have.value', '0');
      
      // Validation errors should reappear or invalid values should be sanitized
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Fix errors and verify recovery
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      cy.log('Validation state persistence verified');
    });
  });

  context('Session Storage Integration', () => {
    it('should handle localStorage unavailable scenarios', () => {
      // Disable localStorage
      cy.window().then((win) => {
        cy.stub(win.Storage.prototype, 'setItem').throws(new Error('Storage not available'));
        cy.stub(win.Storage.prototype, 'getItem').returns(null);
      });
      
      // App should still work without persistence
      cy.setPondDimensions({ length: 45, width: 30, depth: 5 });
      cy.createFleetConfiguration({ excavators: 1, trucks: 1 });
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Configuration should work for the session
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 3);
      
      cy.log('App functions without localStorage persistence');
    });

    it('should migrate from old storage format gracefully', () => {
      // Set up old format data in localStorage
      cy.window().then((win) => {
        const oldFormatData = {
          excavatorCapacity: '2.5',
          truckCapacity: '15',
          pondLength: '50',
          pondWidth: '30'
          // Missing new fleet structure
        };
        
        win.localStorage.setItem('pondDiggingCalculator', JSON.stringify(oldFormatData));
      });
      
      cy.reload();
      
      // App should migrate old format gracefully
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '15');
      cy.get('[data-testid="pond-length-input"]').should('have.value', '50');
      
      // Should have default fleet structure
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 1);
      
      // Modern features should work
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
      
      cy.log('Storage format migration handled gracefully');
    });
  });

  context('Cross-Session Consistency', () => {
    it('should maintain consistency across multiple browser sessions', () => {
      // Set up configuration in session 1
      const sessionConfig = {
        fleet: { excavators: 2, trucks: 3 },
        pond: { length: 75, width: 55, depth: 7 },
        equipment: { capacity: 3.2, cycle: 1.8 }
      };
      
      cy.createFleetConfiguration(sessionConfig.fleet);
      cy.setPondDimensions(sessionConfig.pond);
      cy.configureEquipment('excavator', 0, { 
        bucketCapacity: sessionConfig.equipment.capacity,
        cycleTime: sessionConfig.equipment.cycle
      });
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').as('session1Result');
      
      // Simulate session end/start by clearing memory but keeping localStorage
      cy.window().then((win) => {
        win.location.reload(true); // Hard reload to clear memory
      });
      
      // Verify configuration restored in session 2
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 3); // 1 + 2 added
        
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 4); // 1 + 3 added
      
      cy.get('[data-testid="pond-length-input"]').should('have.value', '75');
      
      // Calculation should be identical
      cy.waitForCalculation();
      cy.get('@session1Result').then(session1Result => {
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .should('equal', session1Result);
      });
      
      cy.log('Cross-session consistency verified');
    });

    it('should handle concurrent tab scenarios', () => {
      // This test simulates having multiple tabs open
      // Set configuration
      cy.setPondDimensions({ length: 40, width: 25, depth: 5 });
      cy.createFleetConfiguration({ excavators: 1, trucks: 1 });
      
      // Store current state reference
      let currentFleetSize;
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .its('length')
        .then(count => currentFleetSize = count);
      
      // Simulate another tab making changes by directly modifying localStorage
      cy.window().then((win) => {
        const currentData = JSON.parse(win.localStorage.getItem('pondDiggingCalculator') || '{}');
        currentData.pond = currentData.pond || {};
        currentData.pond.length = '60'; // Simulate change from another tab
        win.localStorage.setItem('pondDiggingCalculator', JSON.stringify(currentData));
        
        // Trigger storage event to simulate cross-tab communication
        win.dispatchEvent(new StorageEvent('storage', {
          key: 'pondDiggingCalculator',
          newValue: JSON.stringify(currentData),
          oldValue: JSON.stringify(currentData)
        }));
      });
      
      // App should handle external localStorage changes
      // This might involve refreshing or detecting changes
      cy.wait(1000);
      
      // Fleet should remain consistent
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', currentFleetSize);
      
      cy.log('Concurrent tab scenarios handled');
    });
  });
});