/// <reference types="cypress" />

describe('Fleet UI Validation for 1920x1080 Firefox', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1920, 1080); // Your exact setup
  });

  context('Fleet Management UI Presence', () => {
    it('should now show fleet management buttons on 1920x1080', () => {
      // After the fix, these should now be visible
      cy.get('[data-testid="add-excavator-btn"]', { timeout: 5000 })
        .should('be.visible');
        
      cy.get('[data-testid="add-truck-btn"]', { timeout: 5000 })
        .should('be.visible');

      cy.log('✅ Fleet management buttons are now visible!');
    });

    it('should display fleet sections with proper headers', () => {
      // Check for fleet section headers
      cy.get('h2')
        .contains('Excavator Fleet')
        .should('be.visible');
        
      cy.get('h2')
        .contains('Truck Fleet')
        .should('be.visible');

      cy.log('✅ Fleet sections are properly displayed');
    });

    it('should show initial equipment in lists', () => {
      // Should have initial excavator and truck
      cy.get('[data-testid="excavator-list"]')
        .should('be.visible')
        .find('.equipment-item')
        .should('have.length', 1);
        
      cy.get('[data-testid="truck-list"]')
        .should('be.visible')
        .find('.equipment-item')
        .should('have.length', 1);

      cy.log('✅ Initial equipment items are displayed in lists');
    });
  });

  context('Fleet Operations Functionality', () => {
    it('should add excavators when button is clicked', () => {
      // Add an excavator
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      // Should now have 2 excavators
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);

      // Check for proper numbering
      cy.get('[data-testid="excavator-list"]')
        .should('contain', 'Excavator 1')
        .and('contain', 'Excavator 2');

      cy.log('✅ Excavator addition works correctly');
    });

    it('should add trucks when button is clicked', () => {
      // Add a truck
      cy.get('[data-testid="add-truck-btn"]').click();
      
      // Should now have 2 trucks
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .should('have.length', 2);

      // Check for proper numbering
      cy.get('[data-testid="truck-list"]')
        .should('contain', 'Truck 1')
        .and('contain', 'Truck 2');

      cy.log('✅ Truck addition works correctly');
    });

    it('should show remove buttons for equipment', () => {
      // Add some equipment first
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="add-truck-btn"]').click();
      
      // Should show remove buttons (but first ones might be disabled due to minimum rules)
      cy.get('[data-testid="excavator-list"]')
        .find('[data-testid*="remove-excavator"]')
        .should('exist');
        
      cy.get('[data-testid="truck-list"]')
        .find('[data-testid*="remove-truck"]')
        .should('exist');

      cy.log('✅ Remove buttons are present');
    });

    it('should enforce minimum equipment rules', () => {
      // Try to remove the only excavator (should be disabled or not work)
      cy.get('[data-testid="excavator-list"]')
        .find('[data-testid*="remove-excavator"]')
        .first()
        .should('be.disabled');
        
      cy.get('[data-testid="truck-list"]')
        .find('[data-testid*="remove-truck"]')
        .first()
        .should('be.disabled');

      cy.log('✅ Minimum equipment rules are enforced');
    });
  });

  context('Visual Design and Layout', () => {
    it('should show proper desktop layout with fleet sections', () => {
      // Check for desktop 3-column grid layout
      cy.get('.grid-cols-3').should('exist');
      
      // All three main sections should be visible
      cy.get('h2').contains('Excavator Fleet').should('be.visible');
      cy.get('h2').contains('Project Configuration').should('be.visible'); 
      cy.get('h2').contains('Truck Fleet').should('be.visible');

      cy.log('✅ Desktop 3-column layout is working');
    });

    it('should display equipment with visual indicators', () => {
      // Add some equipment to test visual indicators
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="add-truck-btn"]').click();
      
      // Check for equipment icons or visual indicators
      cy.get('[data-testid="excavator-list"]')
        .should('contain', '🚛') // Excavator icon
        .or('contain', 'Excavator');
        
      cy.get('[data-testid="truck-list"]')
        .should('contain', '🚚') // Truck icon
        .or('contain', 'Truck');

      cy.log('✅ Equipment visual indicators are present');
    });

    it('should have proper styling for equipment items', () => {
      // Check that equipment items have proper CSS classes
      cy.get('[data-testid="excavator-list"] .equipment-item')
        .should('have.class', 'equipment-item')
        .and('be.visible');
        
      cy.get('[data-testid="truck-list"] .equipment-item')
        .should('have.class', 'equipment-item')
        .and('be.visible');

      cy.log('✅ Equipment items have proper styling');
    });
  });

  context('Fleet Configuration and Calculations', () => {
    it('should allow configuration of individual equipment', () => {
      // Add some equipment
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      // Configure the second excavator
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.5');
        
      // Value should be saved
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .should('have.value', '3.5');

      cy.log('✅ Individual equipment configuration works');
    });

    it('should update calculations with fleet changes', () => {
      // Set pond dimensions
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('6');
      
      cy.wait(500);
      
      // Get initial calculation
      cy.get('[data-testid="timeline-days"]').invoke('text').then(originalDays => {
        const original = parseFloat(originalDays);
        
        // Add an excavator (should reduce timeline)
        cy.get('[data-testid="add-excavator-btn"]').click();
        
        cy.wait(500);
        
        // Timeline should change
        cy.get('[data-testid="timeline-days"]').invoke('text').then(newDays => {
          const updated = parseFloat(newDays);
          expect(updated).to.be.lessThan(original);
          
          cy.log(`✅ Fleet changes update calculations: ${original} → ${updated} days`);
        });
      });
    });
  });

  context('Firefox-Specific Behavior', () => {
    it('should work properly in Firefox at 1920x1080', () => {
      cy.window().then((win) => {
        const isFirefox = win.navigator.userAgent.toLowerCase().includes('firefox');
        
        if (isFirefox) {
          cy.log('✅ Running in Firefox');
          
          // Test Firefox-specific interactions
          cy.get('[data-testid="add-excavator-btn"]')
            .trigger('mouseover')
            .should('be.visible')
            .click();
            
          cy.get('[data-testid="excavator-list"]')
            .find('.equipment-item')
            .should('have.length', 2);
            
          cy.log('✅ Firefox interactions work correctly');
        } else {
          cy.log('⚠️ Not running in Firefox - results may vary');
        }
      });
    });

    it('should maintain performance in Firefox', () => {
      const startTime = performance.now();
      
      // Perform multiple fleet operations
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.wait(100);
      }
      
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="add-truck-btn"]').click();
        cy.wait(100);
      }
      
      // Set pond dimensions
      cy.get('[data-testid="pond-length-input"]').clear().type('75');
      cy.get('[data-testid="pond-width-input"]').clear().type('45');
      
      cy.wait(1000);
      
      cy.then(() => {
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        expect(duration).to.be.lessThan(10000); // Should complete in reasonable time
        
        cy.log(`✅ Performance in Firefox: ${duration.toFixed(2)}ms`);
      });
    });
  });

  context('Resolution-Specific Testing', () => {
    it('should use full screen real estate at 1920x1080', () => {
      // Check that layout adapts to large screen
      cy.get('.max-w-7xl').should('exist'); // Desktop max-width
      
      // Fleet sections should have adequate spacing
      cy.get('[data-testid="excavator-list"]')
        .should('be.visible')
        .and('have.css', 'padding');
        
      cy.get('[data-testid="truck-list"]')
        .should('be.visible')
        .and('have.css', 'padding');

      cy.log('✅ Layout utilizes large screen properly');
    });

    it('should show all fleet features without scrolling', () => {
      // Add several equipment items
      for (let i = 0; i < 4; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
      }
      
      // All should be visible without scrolling at 1920x1080
      cy.get('[data-testid="excavator-list"] .equipment-item')
        .should('have.length', 5) // 1 initial + 4 added
        .each($item => {
          cy.wrap($item).should('be.visible');
        });
        
      cy.get('[data-testid="truck-list"] .equipment-item')
        .should('have.length', 5)
        .each($item => {
          cy.wrap($item).should('be.visible');
        });

      cy.log('✅ All equipment visible without scrolling on large screen');
    });
  });

  context('User Experience Validation', () => {
    it('should provide clear visual feedback for fleet operations', () => {
      // Test button states and feedback
      cy.get('[data-testid="add-excavator-btn"]')
        .should('not.be.disabled')
        .and('contain.text', 'Add Excavator');
        
      cy.get('[data-testid="add-truck-btn"]')
        .should('not.be.disabled')
        .and('contain.text', 'Add Truck');
        
      // Click and verify state changes
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);
        
      // Remove button should now be enabled for the first item
      cy.get('[data-testid="excavator-list"]')
        .find('[data-testid*="remove-excavator"]')
        .first()
        .should('not.be.disabled');

      cy.log('✅ Clear visual feedback provided for operations');
    });

    it('should show proper labeling and numbering', () => {
      // Add multiple items and check numbering
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      // Should show proper numbering
      cy.get('[data-testid="excavator-list"]')
        .should('contain', 'Excavator 1')
        .and('contain', 'Excavator 2')
        .and('contain', 'Excavator 3');
        
      cy.get('[data-testid="add-truck-btn"]').click();
      
      cy.get('[data-testid="truck-list"]')
        .should('contain', 'Truck 1')
        .and('contain', 'Truck 2');

      cy.log('✅ Proper labeling and numbering displayed');
    });
  });
});