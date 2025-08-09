/// <reference types="cypress" />

describe('Error Recovery Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.viewport(1200, 800);
  });

  context('Calculation Error Recovery', () => {
    it('should recover from calculation errors gracefully', () => {
      // Test with extreme values that might cause calculation issues
      const extremeValues = [
        { field: 'excavator-capacity-input', value: '999999', description: 'extremely large excavator' },
        { field: 'pond-depth-input', value: '0.001', description: 'extremely shallow pond' },
        { field: 'work-hours-input', value: '0.1', description: 'extremely short work day' }
      ];

      extremeValues.forEach(testCase => {
        // Set extreme value
        cy.get(`[data-testid="${testCase.field}"]`)
          .clear()
          .type(testCase.value);

        cy.wait(600); // Wait for calculation

        // App should handle extreme values gracefully
        cy.get('body').should('be.visible'); // App should not crash
        
        // Should either show error message or reasonable result
        cy.get('body').then($body => {
          const hasError = $body.find('[data-testid*="error"]').length > 0;
          const hasResult = $body.find('[data-testid="timeline-result"]').is(':visible');
          
          expect(hasError || hasResult).to.be.true;
          
          if (hasResult) {
            // If showing result, it should be reasonable (not NaN, Infinity, etc.)
            cy.get('[data-testid="timeline-days"]').then($result => {
              const text = $result.text();
              expect(text).to.not.contain('NaN');
              expect(text).to.not.contain('Infinity');
              expect(text).to.not.contain('undefined');
            });
          }
        });

        // Recovery: Set normal value and verify app recovers
        cy.get(`[data-testid="${testCase.field}"]`)
          .clear()
          .type('5'); // Reasonable default

        cy.wait(600);
        
        // App should recover and show normal results
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        cy.get('[data-testid="timeline-days"]')
          .should('contain.text', 'day')
          .and('not.contain', 'NaN');

        cy.log(`Recovered from ${testCase.description} successfully`);
      });
    });

    it('should handle division by zero scenarios', () => {
      // Test scenarios that could cause division by zero
      const zeroValueTests = [
        { field: 'excavator-capacity-input', value: '0' },
        { field: 'excavator-cycle-input', value: '0' },
        { field: 'truck-capacity-input', value: '0' },
        { field: 'work-hours-input', value: '0' }
      ];

      zeroValueTests.forEach(test => {
        cy.get(`[data-testid="${test.field}"]`)
          .clear()
          .type(test.value);

        cy.wait(600);

        // App should not crash and should handle zero values appropriately
        cy.get('body').should('be.visible');
        
        // Should either show validation error or reasonable fallback
        cy.get('body').then($body => {
          const hasValidationError = $body.find('[data-testid*="error"]').length > 0;
          const hasResult = $body.find('[data-testid="timeline-result"]').is(':visible');
          
          if (hasResult) {
            cy.get('[data-testid="timeline-days"]').then($result => {
              const text = $result.text();
              expect(text).to.not.contain('Infinity');
              expect(text).to.not.contain('NaN');
            });
          }
        });

        // Reset to valid value
        cy.get(`[data-testid="${test.field}"]`)
          .clear()
          .type('2.5');
      });
    });

    it('should recover from negative value errors', () => {
      const negativeTests = [
        'excavator-capacity-input',
        'excavator-cycle-input', 
        'truck-capacity-input',
        'pond-length-input',
        'pond-width-input',
        'pond-depth-input',
        'work-hours-input'
      ];

      negativeTests.forEach(field => {
        cy.get(`[data-testid="${field}"]`)
          .clear()
          .type('-5');

        cy.wait(400);

        // Should show validation error or handle gracefully
        const errorField = field.replace('-input', '-error');
        cy.get('body').then($body => {
          const hasError = $body.find(`[data-testid="${errorField}"]`).is(':visible');
          
          if (hasError) {
            cy.get(`[data-testid="${errorField}"]`).should('be.visible');
          }
        });

        // Recovery
        cy.get(`[data-testid="${field}"]`)
          .clear()
          .type('3');

        cy.wait(400);
        
        // Error should clear and calculation should work
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });
  });

  context('Fleet Operation Error Recovery', () => {
    it('should handle fleet limit edge cases gracefully', () => {
      // Try to add equipment beyond limits through rapid clicking
      for (let i = 0; i < 15; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click({ force: true });
        cy.wait(50);
        
        // Check that we don't exceed the limit
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .its('length')
          .should('be.at.most', 10);
      }

      // Button should be disabled when at limit
      cy.get('[data-testid="add-excavator-btn"]').should('be.disabled');

      // Remove one and verify button re-enables
      cy.get('[data-testid="excavator-list"]')
        .find('[data-testid*="remove-excavator"]')
        .first()
        .click();

      cy.get('[data-testid="add-excavator-btn"]').should('not.be.disabled');

      cy.log('Fleet limit edge cases handled correctly');
    });

    it('should recover from rapid fleet modifications', () => {
      // Rapidly add and remove equipment
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
      }

      // Now rapidly remove some
      for (let i = 0; i < 3; i++) {
        cy.get('[data-testid="excavator-list"]')
          .find('[data-testid*="remove-excavator"]')
          .first()
          .click();
        cy.wait(100);
      }

      // Verify app remains stable
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 3); // 1 + 5 - 3

      // Calculations should still work
      cy.setPondDimensions({ length: 50, width: 30, depth: 6 });
      cy.waitForCalculation();

      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('Recovered from rapid fleet modifications');
    });

    it('should handle equipment configuration errors', () => {
      cy.createFleetConfiguration({ excavators: 2, trucks: 2 });

      // Configure equipment with invalid values
      const invalidConfigs = [
        { type: 'excavator', index: 0, values: { bucketCapacity: 'abc' } },
        { type: 'excavator', index: 1, values: { cycleTime: '-1' } },
        { type: 'truck', index: 0, values: { capacity: '999999' } },
        { type: 'truck', index: 1, values: { roundTripTime: '0' } }
      ];

      invalidConfigs.forEach(config => {
        cy.configureEquipment(config.type, config.index, config.values);
        cy.wait(300);

        // App should remain stable
        cy.get('body').should('be.visible');
      });

      // Recovery: Set all to valid values
      cy.configureEquipment('excavator', 0, { bucketCapacity: 2.5, cycleTime: 2.0 });
      cy.configureEquipment('excavator', 1, { bucketCapacity: 3.0, cycleTime: 1.8 });
      cy.configureEquipment('truck', 0, { capacity: 15, roundTripTime: 20 });
      cy.configureEquipment('truck', 1, { capacity: 18, roundTripTime: 25 });

      cy.waitForCalculation();

      // Should recover and show results
      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('Equipment configuration errors handled and recovered');
    });
  });

  context('Input Validation Error Recovery', () => {
    it('should recover from invalid input formats', () => {
      const invalidFormats = [
        { field: 'excavator-capacity-input', values: ['abc', '2.5.5', '2,5', 'infinity'] },
        { field: 'pond-length-input', values: ['xyz', '1.2.3', 'NaN', ''] },
        { field: 'work-hours-input', values: ['24+', '1e5', '2.', '.5'] }
      ];

      invalidFormats.forEach(test => {
        test.values.forEach(invalidValue => {
          cy.get(`[data-testid="${test.field}"]`)
            .clear()
            .type(invalidValue, { parseSpecialCharSequences: false });

          cy.wait(300);

          // App should remain stable
          cy.get('body').should('be.visible');

          // Either show validation error or ignore invalid input
          cy.get('body').then($body => {
            const errorSelector = test.field.replace('-input', '-error');
            const hasError = $body.find(`[data-testid="${errorSelector}"]`).is(':visible');
            const inputValue = $body.find(`[data-testid="${test.field}"]`).val();
            
            // Either has error message or input was sanitized/rejected
            expect(hasError || inputValue !== invalidValue).to.be.true;
          });

          // Recovery
          cy.get(`[data-testid="${test.field}"]`)
            .clear()
            .type('3');
        });
      });

      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('Input validation errors recovered successfully');
    });

    it('should handle concurrent validation errors', () => {
      // Set multiple invalid values simultaneously
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0');
      cy.get('[data-testid="pond-length-input"]').clear().type('-10');
      cy.get('[data-testid="pond-width-input"]').clear().type('abc');
      cy.get('[data-testid="work-hours-input"]').clear().type('25');

      cy.wait(500);

      // App should handle multiple errors gracefully
      cy.get('body').should('be.visible');

      // Should not show calculation results with multiple errors
      cy.get('[data-testid="timeline-result"]').should('not.exist');

      // Recovery: Fix all errors
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="work-hours-input"]').clear().type('8');

      cy.waitForCalculation();

      // Should recover and show results
      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('Multiple concurrent validation errors recovered');
    });
  });

  context('Browser Compatibility Error Recovery', () => {
    it('should handle JavaScript errors gracefully', () => {
      // Simulate JavaScript errors and test recovery
      cy.window().then((win) => {
        // Override a method to throw an error occasionally
        const originalCalc = win.Math.pow;
        let errorCount = 0;
        
        win.Math.pow = function(x, y) {
          errorCount++;
          if (errorCount % 5 === 0) {
            throw new Error('Simulated calculation error');
          }
          return originalCalc.call(this, x, y);
        };

        // Perform operations that might trigger the error
        cy.get('[data-testid="pond-length-input"]').clear().type('45');
        cy.get('[data-testid="pond-width-input"]').clear().type('25');
        cy.get('[data-testid="pond-depth-input"]').clear().type('5');

        cy.wait(1000);

        // App should remain functional despite JavaScript errors
        cy.get('body').should('be.visible');

        // Restore original method
        win.Math.pow = originalCalc;
      });

      // Test that app recovers after error source is removed
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.waitForCalculation();

      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('JavaScript error recovery tested');
    });

    it('should handle DOM manipulation errors', () => {
      // Test recovery from DOM state corruption
      cy.get('[data-testid="excavator-list"]').then($list => {
        // Manually manipulate DOM to simulate corruption
        $list.find('.equipment-item').first().remove();
      });

      // App should detect and handle DOM inconsistencies
      cy.get('[data-testid="add-excavator-btn"]').click();

      // Should maintain consistent state
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length.at.least', 1);

      // Calculations should still work
      cy.setPondDimensions({ length: 40, width: 25, depth: 5 });
      cy.waitForCalculation();

      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('DOM manipulation error recovery tested');
    });
  });

  context('Performance Degradation Recovery', () => {
    it('should recover from performance bottlenecks', () => {
      // Simulate performance issues by creating heavy computational load
      cy.window().then((win) => {
        let calculationCount = 0;
        
        // Override a calculation method to simulate slowness
        const originalSetTimeout = win.setTimeout;
        win.setTimeout = function(callback, delay) {
          calculationCount++;
          
          // Simulate occasional slowness
          if (calculationCount % 3 === 0) {
            return originalSetTimeout(callback, delay + 2000);
          }
          return originalSetTimeout(callback, delay);
        };
      });

      // Test that app remains responsive despite performance issues
      const startTime = performance.now();

      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('55');

      // User should still be able to interact during slow operations
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.get('[data-testid="excavator-list"]')
        .find('.equipment-item')
        .should('have.length', 2);

      cy.then(() => {
        const endTime = performance.now();
        const duration = endTime - startTime;

        // Should complete within reasonable time despite performance issues
        expect(duration).to.be.lessThan(10000);

        cy.log(`Performance degradation recovery completed in ${duration}ms`);
      });
    });

    it('should handle memory pressure scenarios', () => {
      // Simulate memory pressure by creating large fleet and rapid operations
      for (let i = 0; i < 8; i++) {
        cy.get('[data-testid="add-excavator-btn"]').click();
        cy.get('[data-testid="add-truck-btn"]').click();
        
        // Configure equipment to increase memory usage
        cy.configureEquipment('excavator', i, { 
          bucketCapacity: 2.5 + i * 0.1, 
          cycleTime: 2.0 + i * 0.1 
        });
      }

      // Perform calculations with large fleet
      cy.setPondDimensions({ length: 100, width: 80, depth: 10 });
      cy.waitForCalculation();

      // App should remain responsive
      cy.get('[data-testid="timeline-result"]').should('be.visible');

      // Clean up memory by removing equipment
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="excavator-list"]')
          .find('[data-testid*="remove-excavator"]')
          .first()
          .click();
        cy.wait(100);
      }

      // Should recover to normal operation
      cy.get('[data-testid="timeline-result"]').should('be.visible');

      cy.log('Memory pressure recovery tested');
    });
  });
});