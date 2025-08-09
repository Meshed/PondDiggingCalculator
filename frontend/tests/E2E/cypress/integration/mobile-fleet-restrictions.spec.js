/// <reference types="cypress" />

describe('Mobile Fleet Restrictions Tests', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  context('Fleet Button Visibility by Device Type', () => {
    it('should hide fleet management buttons on mobile devices', () => {
      // Test various mobile viewport sizes
      const mobileViewports = [
        { width: 375, height: 667, device: 'iPhone SE' },
        { width: 414, height: 896, device: 'iPhone XR' },
        { width: 360, height: 640, device: 'Galaxy S5' },
        { width: 375, height: 812, device: 'iPhone X' }
      ];

      mobileViewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.reload();
        
        // Verify device type is detected as mobile
        cy.get('[data-testid="device-type"]', { timeout: 1000 })
          .should('contain', 'Mobile');
        
        // Fleet management buttons should not exist on mobile
        cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
        cy.get('[data-testid="add-truck-btn"]').should('not.exist');
        
        // Verify only single equipment items are shown (no fleet management)
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', 1);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .should('have.length', 1);
        
        // Remove buttons should not exist on mobile
        cy.get('[data-testid*="remove-excavator"]').should('not.exist');
        cy.get('[data-testid*="remove-truck"]').should('not.exist');
        
        cy.log(`Verified fleet restrictions on ${viewport.device} (${viewport.width}x${viewport.height})`);
      });
    });

    it('should show fleet management buttons on tablet devices', () => {
      // Test tablet viewport sizes
      const tabletViewports = [
        { width: 768, height: 1024, device: 'iPad' },
        { width: 1024, height: 768, device: 'iPad Landscape' },
        { width: 800, height: 1280, device: 'Galaxy Tab' },
        { width: 834, height: 1112, device: 'iPad Air' }
      ];

      tabletViewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.reload();
        
        // Verify device type is detected as tablet
        cy.get('[data-testid="device-type"]', { timeout: 1000 })
          .should('contain', 'Tablet');
        
        // Fleet management buttons should be visible on tablet
        cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
        cy.get('[data-testid="add-truck-btn"]').should('be.visible');
        
        // Test that buttons are functional
        cy.get('[data-testid="add-excavator-btn"]').click();
        
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', 2);
        
        // Remove buttons should be available (but last one disabled)
        cy.get('[data-testid*="remove-excavator"]').should('exist');
        
        cy.log(`Verified fleet features on ${viewport.device} (${viewport.width}x${viewport.height})`);
      });
    });

    it('should show fleet management buttons on desktop devices', () => {
      // Test desktop viewport sizes
      const desktopViewports = [
        { width: 1200, height: 800, device: 'Small Desktop' },
        { width: 1440, height: 900, device: 'Medium Desktop' },
        { width: 1920, height: 1080, device: 'Large Desktop' },
        { width: 2560, height: 1440, device: 'QHD Desktop' }
      ];

      desktopViewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.reload();
        
        // Verify device type is detected as desktop
        cy.get('[data-testid="device-type"]', { timeout: 1000 })
          .should('contain', 'Desktop');
        
        // Fleet management buttons should be visible on desktop
        cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
        cy.get('[data-testid="add-truck-btn"]').should('be.visible');
        
        // Test full fleet functionality
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
        
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', 2);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .should('have.length', 2);
        
        cy.log(`Verified full fleet features on ${viewport.device} (${viewport.width}x${viewport.height})`);
      });
    });
  });

  context('Mobile Interface Optimization', () => {
    it('should optimize input fields for mobile touch interaction', () => {
      cy.viewport(375, 667); // iPhone SE
      
      // Verify input fields have appropriate size for touch
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .and('have.css', 'min-height')
        .and('match', /44px|48px|2\.75rem|3rem/); // iOS/Android recommended touch target
      
      // Verify proper input types for numeric keyboards
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.attr', 'type', 'number')
        .or('have.attr', 'inputmode', 'decimal');
      
      cy.get('[data-testid="pond-length-input"]')
        .should('have.attr', 'type', 'number')
        .or('have.attr', 'inputmode', 'decimal');
      
      // Test touch interaction
      cy.get('[data-testid="excavator-capacity-input"]')
        .tap()
        .should('be.focused')
        .clear()
        .type('2.5');
      
      // Verify mobile-optimized results display
      cy.wait(500);
      
      cy.get('[data-testid="timeline-result"]')
        .should('be.visible')
        .and('have.css', 'font-size')
        .and('match', /18px|24px|1\.125rem|1\.5rem/); // Large, readable text
    });

    it('should provide mobile-optimized layout without fleet features', () => {
      cy.viewport(375, 667); // iPhone SE
      
      // Verify simplified interface structure
      cy.get('[data-testid="simplified-interface"]').should('exist');
      
      // Should not have complex multi-column layouts on mobile
      cy.get('body').should('not.have.class', 'grid-cols-3');
      cy.get('body').should('not.have.class', 'grid-cols-2');
      
      // Equipment sections should be streamlined
      cy.get('[data-testid="excavator-section"]')
        .should('be.visible')
        .find('.equipment-item')
        .should('have.length', 1); // Only one excavator on mobile
      
      cy.get('[data-testid="truck-section"]')
        .should('be.visible')
        .find('.equipment-item')
        .should('have.length', 1); // Only one truck on mobile
      
      // Form should be optimized for vertical scrolling
      cy.get('[data-testid="project-form"]')
        .should('have.css', 'display', 'flex')
        .and('have.css', 'flex-direction', 'column');
    });

    it('should handle orientation changes properly', () => {
      // Start in portrait
      cy.viewport(375, 667);
      
      // Verify mobile restrictions apply
      cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
      
      // Change to landscape
      cy.viewport(667, 375);
      
      // Should still be mobile (width < 768px) and restrictions should apply
      cy.get('[data-testid="device-type"]')
        .should('contain', 'Mobile');
      
      cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
      
      // Interface should adapt to landscape
      cy.get('[data-testid="project-form"]').should('be.visible');
      
      // Change to tablet landscape
      cy.viewport(1024, 768);
      
      // Now should show fleet features
      cy.get('[data-testid="device-type"]')
        .should('contain', 'Tablet');
      
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
    });
  });

  context('Device Detection Accuracy', () => {
    it('should accurately detect device breakpoints', () => {
      const breakpointTests = [
        { width: 320, expected: 'Mobile', description: 'Small mobile' },
        { width: 375, expected: 'Mobile', description: 'Standard mobile' },
        { width: 414, expected: 'Mobile', description: 'Large mobile' },
        { width: 767, expected: 'Mobile', description: 'Max mobile width' },
        { width: 768, expected: 'Tablet', description: 'Min tablet width' },
        { width: 1023, expected: 'Tablet', description: 'Max tablet width' },
        { width: 1024, expected: 'Desktop', description: 'Min desktop width' },
        { width: 1200, expected: 'Desktop', description: 'Standard desktop' },
        { width: 1920, expected: 'Desktop', description: 'Large desktop' }
      ];

      breakpointTests.forEach(test => {
        cy.viewport(test.width, 800);
        cy.reload();
        
        cy.get('[data-testid="device-type"]', { timeout: 1000 })
          .should('contain', test.expected);
        
        // Verify corresponding fleet button visibility
        if (test.expected === 'Mobile') {
          cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
        } else {
          cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
        }
        
        cy.log(`${test.description} (${test.width}px): ${test.expected} ✓`);
      });
    });

    it('should maintain consistent device detection across page reloads', () => {
      cy.viewport(375, 667); // Mobile
      
      // Check initial detection
      cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
      
      // Reload and verify consistency
      cy.reload();
      
      cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
      
      // Change to desktop
      cy.viewport(1200, 800);
      cy.reload();
      
      cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
      
      // Test multiple reloads maintain consistency
      for (let i = 0; i < 3; i++) {
        cy.reload();
        cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
        cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
      }
    });
  });

  context('Cross-Device Feature Parity', () => {
    it('should maintain calculation accuracy across all device types', () => {
      const devices = [
        { width: 375, height: 667, type: 'Mobile' },
        { width: 768, height: 1024, type: 'Tablet' },
        { width: 1200, height: 800, type: 'Desktop' }
      ];

      const calculationResults = [];

      devices.forEach(device => {
        cy.viewport(device.width, device.height);
        cy.reload();
        
        // Set identical calculation parameters
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
        cy.get('[data-testid="excavator-cycle-input"]').clear().type('2.0');
        cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
        cy.get('[data-testid="truck-roundtrip-input"]').clear().type('20');
        cy.get('[data-testid="pond-length-input"]').clear().type('50');
        cy.get('[data-testid="pond-width-input"]').clear().type('30');
        cy.get('[data-testid="pond-depth-input"]').clear().type('6');
        cy.get('[data-testid="work-hours-input"]').clear().type('8');
        
        cy.wait(600);
        
        // Capture calculation result
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .then((result) => {
            calculationResults.push({
              device: device.type,
              result: result.trim()
            });
            
            cy.log(`${device.type}: ${result}`);
          });
      });
      
      // Verify all devices produce identical results
      cy.then(() => {
        const mobileResult = calculationResults.find(r => r.device === 'Mobile')?.result;
        const tabletResult = calculationResults.find(r => r.device === 'Tablet')?.result;
        const desktopResult = calculationResults.find(r => r.device === 'Desktop')?.result;
        
        expect(mobileResult).to.equal(tabletResult);
        expect(tabletResult).to.equal(desktopResult);
        
        cy.log('Calculation consistency verified across all devices');
      });
    });
  });
});