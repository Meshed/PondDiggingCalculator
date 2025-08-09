/// <reference types="cypress" />

describe('Integration Fix Validation', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1920, 1080);
  });

  context('Main.elm and Pages/Desktop.elm Integration', () => {
    it('should confirm Main.elm is now using Pages/Desktop.elm view', () => {
      // After the fix, we should see the Desktop page structure
      
      // Check for Desktop page specific layout classes
      cy.get('.grid-cols-3', { timeout: 5000 })
        .should('exist')
        .and('be.visible');
        
      // Check for Desktop page header structure
      cy.get('h1')
        .contains('Pond Digging Calculator')
        .should('be.visible');
        
      // Check for fleet sections that are unique to Desktop page
      cy.get('h2').contains('Excavator Fleet').should('be.visible');
      cy.get('h2').contains('Truck Fleet').should('be.visible');
      
      cy.log('✅ Main.elm is successfully using Pages/Desktop.elm view');
    });

    it('should show fleet management components that were previously missing', () => {
      // These elements should now be present after the fix
      const expectedElements = [
        '[data-testid="add-excavator-btn"]',
        '[data-testid="add-truck-btn"]', 
        '[data-testid="excavator-list"]',
        '[data-testid="truck-list"]'
      ];

      expectedElements.forEach(selector => {
        cy.get(selector, { timeout: 5000 })
          .should('exist')
          .and('be.visible');
        
        cy.log(`✅ Found: ${selector}`);
      });
    });

    it('should maintain mobile view routing', () => {
      // Test that mobile still uses MobileView, not Desktop page
      cy.viewport(375, 667); // Mobile size
      cy.reload();
      
      // Should NOT show desktop grid layout on mobile
      cy.get('.grid-cols-3').should('not.exist');
      
      // Should show mobile-specific indicators
      cy.get('body').then($body => {
        const hasMobileStructure = $body.find('[data-testid="simplified-interface"]').length > 0;
        const hasDesktopStructure = $body.find('.grid-cols-3').length > 0;
        
        // Mobile should use simplified interface, not desktop structure
        expect(hasMobileStructure || !hasDesktopStructure).to.be.true;
      });
      
      cy.log('✅ Mobile view routing still works correctly');
    });
  });

  context('Before vs After Fix Validation', () => {
    it('should document what changed in the integration', () => {
      const integrationChanges = {
        before: {
          view: 'Main.elm inline view function',
          structure: 'Simple ProjectForm + ResultsPanel layout',
          fleetManagement: 'Not visible (implemented but not integrated)',
          layout: 'Basic container with space-y-8',
          sections: 2 // ProjectForm and ResultsPanel only
        },
        after: {
          view: 'Pages.Desktop.view model',
          structure: 'Full desktop page with 3-column grid',
          fleetManagement: 'Fully integrated and visible',
          layout: 'Responsive grid layout with fleet sections',
          sections: 4 // Excavator Fleet, Project Config, Truck Fleet, Results
        }
      };

      // Verify "after" state is now active
      cy.get('.grid-cols-3').should('exist'); // New layout
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible'); // Fleet management
      
      // Count visible sections
      cy.get('h2').should('have.length.greaterThan', 2); // More than just basic sections
      
      cy.writeFile('cypress/results/integration-fix-validation.json', {
        integrationChanges,
        status: 'Integration successful',
        timestamp: new Date().toISOString(),
        fix: 'Updated Main.elm to use Pages.Desktop.view instead of inline view'
      });
      
      cy.log('✅ Integration changes documented and validated');
    });

    it('should confirm all fleet features are now accessible', () => {
      const fleetFeatures = {
        'Add Excavator Button': '[data-testid="add-excavator-btn"]',
        'Add Truck Button': '[data-testid="add-truck-btn"]',
        'Excavator Fleet List': '[data-testid="excavator-list"]',
        'Truck Fleet List': '[data-testid="truck-list"]',
        'Equipment Numbering': '.equipment-item', // Should contain numbered items
        'Fleet Section Headers': 'h2', // Should have fleet headers
        'Individual Equipment Config': '[data-testid*="capacity"]', // Equipment config inputs
        'Remove Equipment Buttons': '[data-testid*="remove"]' // Remove buttons when applicable
      };

      const results = {};
      
      Object.entries(fleetFeatures).forEach(([feature, selector]) => {
        cy.get(selector).then($elements => {
          const exists = $elements.length > 0;
          const isVisible = exists && $elements.is(':visible');
          
          results[feature] = { exists, isVisible, count: $elements.length };
          
          const status = isVisible ? '✅' : '❌';
          cy.log(`${status} ${feature}: ${exists ? 'found' : 'not found'} (${$elements.length} elements)`);
        });
      });
      
      // Add equipment to test dynamic features
      cy.get('[data-testid="add-excavator-btn"]').click();
      
      // Now remove buttons should be present
      cy.get('[data-testid*="remove-excavator"]').should('exist');
      
      cy.log('✅ All fleet features are now accessible after integration');
    });
  });

  context('Functional Validation After Integration', () => {
    it('should perform end-to-end fleet operations', () => {
      // Test complete fleet workflow now that integration is fixed
      
      // 1. Add equipment
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="add-truck-btn"]').click();
      
      // 2. Configure equipment
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.8');
        
      cy.get('[data-testid="truck-list"]')
        .find('.equipment-item')
        .eq(1)
        .find('[data-testid*="truck-capacity"]')
        .clear()
        .type('20');
      
      // 3. Set project parameters
      cy.get('[data-testid="pond-length-input"]').clear().type('80');
      cy.get('[data-testid="pond-width-input"]').clear().type('50');
      cy.get('[data-testid="pond-depth-input"]').clear().type('8');
      
      // 4. Verify calculations work with fleet
      cy.wait(1000);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]')
        .should('contain.text', 'day')
        .and('not.contain', 'NaN');
      
      // 5. Test removal (should work now that we have multiple items)
      cy.get('[data-testid="excavator-list"]')
        .find('[data-testid*="remove-excavator"]')
        .first()
        .click();
        
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 1); // Back to 1 excavator
      
      cy.log('✅ Complete fleet workflow operational after integration');
    });

    it('should maintain performance with integrated fleet features', () => {
      const startTime = performance.now();
      
      // Perform comprehensive fleet operations
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
        cy.wait(100);
      }
      
      // Configure multiple equipment items
      cy.get('[data-testid="excavator-list"] .equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.2');
        
      cy.get('[data-testid="truck-list"] .equipment-item')
        .eq(2)
        .find('[data-testid*="truck-capacity"]')
        .clear()
        .type('18');
      
      // Trigger calculation
      cy.get('[data-testid="pond-length-input"]').clear().type('100');
      cy.wait(1000);
      
      cy.then(() => {
        const endTime = performance.now();
        const duration = endTime - startTime;
        
        expect(duration).to.be.lessThan(10000);
        cy.log(`✅ Performance maintained: ${duration.toFixed(2)}ms for full fleet operations`);
      });
    });
  });

  context('Regression Testing', () => {
    it('should confirm no existing functionality was broken', () => {
      // Test that basic functionality still works
      cy.get('[data-testid="pond-length-input"]')
        .should('be.visible')
        .clear()
        .type('45');
        
      cy.get('[data-testid="pond-width-input"]')
        .clear()
        .type('30');
        
      cy.get('[data-testid="pond-depth-input"]')
        .clear()
        .type('5');
        
      cy.wait(500);
      
      // Basic calculation should still work
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Equipment inputs should still work
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('2.8')
        .should('have.value', '2.8');
        
      cy.get('[data-testid="truck-capacity-input"]')
        .clear()
        .type('14')
        .should('have.value', '14');
      
      cy.log('✅ No regression - existing functionality intact');
    });

    it('should validate device detection still works correctly', () => {
      // Test different viewport sizes
      const viewports = [
        { width: 375, height: 667, expected: 'Mobile' },
        { width: 768, height: 1024, expected: 'Tablet' },
        { width: 1920, height: 1080, expected: 'Desktop' }
      ];

      viewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.reload();
        
        cy.wait(1000);
        
        if (viewport.expected === 'Mobile') {
          // Mobile should not show fleet buttons
          cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
          cy.get('.grid-cols-3').should('not.exist');
        } else {
          // Desktop/Tablet should show fleet features
          cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
          cy.get('.grid-cols-3').should('exist');
        }
        
        cy.log(`✅ ${viewport.expected} layout works correctly at ${viewport.width}x${viewport.height}`);
      });
    });
  });

  context('Integration Success Metrics', () => {
    it('should measure integration success', () => {
      const metrics = {
        fleetButtonsVisible: false,
        fleetSectionsPresent: 0,
        equipmentConfigurable: false,
        calculationsWorkWithFleet: false,
        layoutProperlyStructured: false,
        performanceAcceptable: false
      };

      // Test fleet buttons
      cy.get('[data-testid="add-excavator-btn"]').should('be.visible').then(() => {
        metrics.fleetButtonsVisible = true;
      });

      // Count fleet sections
      cy.get('h2').then($headers => {
        const fleetHeaders = $headers.filter((i, el) => 
          el.textContent.includes('Fleet') || el.textContent.includes('Excavator') || el.textContent.includes('Truck')
        );
        metrics.fleetSectionsPresent = fleetHeaders.length;
      });

      // Test equipment configuration
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"] .equipment-item')
        .eq(1)
        .find('[data-testid*="excavator-capacity"]')
        .clear()
        .type('3.5')
        .should('have.value', '3.5')
        .then(() => {
          metrics.equipmentConfigurable = true;
        });

      // Test calculations with fleet
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      cy.wait(1000);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        metrics.calculationsWorkWithFleet = true;
      });

      // Test layout structure
      cy.get('.grid-cols-3').should('exist').then(() => {
        metrics.layoutProperlyStructured = true;
      });

      // Performance test
      const startTime = performance.now();
      cy.get('[data-testid="add-truck-btn"]').click();
      cy.wait(500);
      
      cy.then(() => {
        const duration = performance.now() - startTime;
        metrics.performanceAcceptable = duration < 2000;
        
        // Calculate success score
        const totalMetrics = Object.keys(metrics).length;
        const passedMetrics = Object.values(metrics).filter(Boolean).length;
        const successRate = (passedMetrics / totalMetrics) * 100;
        
        cy.log('=== INTEGRATION SUCCESS METRICS ===');
        Object.entries(metrics).forEach(([key, value]) => {
          const status = value ? '✅' : '❌';
          cy.log(`${status} ${key}: ${value}`);
        });
        
        cy.log(`Overall Success Rate: ${successRate.toFixed(1)}% (${passedMetrics}/${totalMetrics})`);
        
        // Integration is successful if we pass all metrics
        expect(successRate).to.equal(100);
        
        cy.writeFile('cypress/results/integration-success-metrics.json', {
          metrics,
          successRate,
          status: successRate === 100 ? 'INTEGRATION_SUCCESSFUL' : 'NEEDS_ATTENTION',
          timestamp: new Date().toISOString()
        });
      });
    });
  });
});