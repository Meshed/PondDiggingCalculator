/// <reference types="cypress" />

describe('Comprehensive Scenario Testing', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  context('Realistic Project Scenarios', () => {
    it('should handle residential backyard pond project', () => {
      cy.loadTestDataScenario({
        equipment: 'residential',
        pond: 'backyard.medium',
        device: 'desktop'
      }).then(scenario => {
        cy.waitForCalculation();
        
        // Verify calculation results are reasonable for residential project
        cy.get('[data-testid="timeline-days"]').invoke('text').then(days => {
          const dayCount = parseFloat(days);
          expect(dayCount).to.be.within(1, 7); // Should complete in reasonable time
        });
        
        // Verify equipment configuration loaded correctly
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length', scenario.equipment.excavators.length);
        
        cy.log(`Residential project completed: ${scenario.pond.description}`);
      });
    });

    it('should handle commercial water feature project', () => {
      cy.loadTestDataScenario({
        equipment: 'commercial',
        pond: 'commercial.large',
        device: 'desktop'
      }).then(scenario => {
        cy.waitForCalculation();
        
        // Commercial projects should show reasonable timeline
        cy.get('[data-testid="timeline-days"]').invoke('text').then(days => {
          const dayCount = parseFloat(days);
          expect(dayCount).to.be.within(3, 30); // Larger project, longer timeline
        });
        
        // Should handle multiple equipment efficiently
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 1);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 1);
        
        cy.log(`Commercial project completed: ${scenario.pond.description}`);
      });
    });

    it('should handle industrial retention pond project', () => {
      cy.loadTestDataScenario({
        equipment: 'industrial',
        pond: 'industrial.medium',
        device: 'desktop'
      }).then(scenario => {
        cy.waitForCalculation();
        
        // Industrial projects with efficient equipment should be optimized
        cy.get('[data-testid="timeline-days"]').invoke('text').then(days => {
          const dayCount = parseFloat(days);
          expect(dayCount).to.be.within(5, 45); // Large but efficient
        });
        
        // Should have significant fleet
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 2);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 3);
        
        cy.log(`Industrial project completed: ${scenario.pond.description}`);
      });
    });

    it('should handle maximum performance scenario', () => {
      cy.loadTestDataScenario({
        equipment: 'maximum',
        pond: 'extreme.massive',
        device: 'desktop'
      }).then(scenario => {
        cy.waitForCalculation();
        
        // Maximum fleet should handle even massive projects efficiently
        cy.get('[data-testid="timeline-days"]').invoke('text').then(days => {
          const dayCount = parseFloat(days);
          expect(dayCount).to.be.within(8, 60); // Massive project but maximum fleet
          expect(dayCount).to.be.lessThan(100); // Should not take excessive time
        });
        
        // Should approach or reach fleet limits
        cy.get('[data-testid="excavator-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 4);
        
        cy.get('[data-testid="truck-list"]')
          .find('.equipment-item')
          .should('have.length.greaterThan', 6);
        
        cy.log(`Maximum performance project: ${scenario.pond.description}`);
      });
    });
  });

  context('Cross-Device Scenario Testing', () => {
    it('should provide consistent results across devices for same project', () => {
      const projectConfig = {
        equipment: 'commercial',
        pond: 'commercial.medium'
      };

      const results = {};

      // Test on desktop
      cy.loadTestDataScenario({ ...projectConfig, device: 'desktop' });
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').then(desktop => {
        results.desktop = desktop;
      });

      // Test on tablet
      cy.loadTestDataScenario({ ...projectConfig, device: 'tablet' });
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').then(tablet => {
        results.tablet = tablet;
      });

      // Test on mobile (simplified but same core calculation)
      cy.loadTestDataScenario({ ...projectConfig, device: 'mobile' });
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').then(mobile => {
        results.mobile = mobile;

        // All devices should produce identical core calculations
        expect(results.desktop).to.equal(results.tablet);
        // Mobile may show simplified view but core calc should be same
        expect(parseFloat(results.mobile)).to.equal(parseFloat(results.desktop));
        
        cy.log('Cross-device consistency verified');
      });
    });

    it('should adapt interface appropriately for each device', () => {
      const devices = ['mobile', 'tablet', 'desktop'];
      
      devices.forEach(deviceType => {
        cy.loadTestDataScenario({
          equipment: 'commercial',
          pond: 'backyard.large',
          device: deviceType
        }).then(scenario => {
          // Verify device-specific features
          if (deviceType === 'mobile') {
            cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
            cy.get('[data-testid="simplified-interface"]').should('exist');
          } else {
            cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
            cy.verifyFleetLimits();
          }
          
          // All devices should show results
          cy.waitForCalculation();
          cy.get('[data-testid="timeline-result"]').should('be.visible');
          
          cy.log(`${deviceType} interface verified`);
        });
      });
    });
  });

  context('Performance Testing with Realistic Data', () => {
    it('should maintain performance across different project complexities', () => {
      const complexityTests = [
        { name: 'Simple', equipment: 'residential', pond: 'backyard.small', maxTime: 1000 },
        { name: 'Moderate', equipment: 'commercial', pond: 'commercial.medium', maxTime: 2000 },
        { name: 'Complex', equipment: 'industrial', pond: 'industrial.large', maxTime: 3000 },
        { name: 'Maximum', equipment: 'maximum', pond: 'extreme.massive', maxTime: 5000 }
      ];

      complexityTests.forEach(test => {
        const startTime = performance.now();
        
        cy.loadTestDataScenario({
          equipment: test.equipment,
          pond: test.pond,
          device: 'desktop'
        });
        
        cy.waitForCalculation();
        
        cy.then(() => {
          const endTime = performance.now();
          const duration = endTime - startTime;
          
          expect(duration).to.be.lessThan(test.maxTime);
          cy.log(`${test.name} complexity completed in ${duration.toFixed(2)}ms`);
        });
      });
    });

    it('should handle rapid scenario switching', () => {
      const scenarios = [
        { equipment: 'residential', pond: 'backyard.small' },
        { equipment: 'commercial', pond: 'commercial.medium' },
        { equipment: 'industrial', pond: 'agricultural.large' },
        { equipment: 'commercial', pond: 'extreme.narrow' }
      ];

      const startTime = performance.now();

      scenarios.forEach((scenario, index) => {
        cy.loadTestDataScenario({ ...scenario, device: 'desktop' });
        cy.waitForCalculation();
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        if (index < scenarios.length - 1) {
          cy.reload(); // Switch scenarios
        }
      });

      cy.then(() => {
        const totalTime = performance.now() - startTime;
        expect(totalTime).to.be.lessThan(15000); // All scenarios in reasonable time
        cy.log(`Rapid scenario switching completed in ${totalTime.toFixed(2)}ms`);
      });
    });
  });

  context('Edge Case Scenario Testing', () => {
    it('should handle extreme pond dimensions', () => {
      const extremeCases = [
        { name: 'Tiny pond', pond: 'extreme.tiny' },
        { name: 'Long narrow pond', pond: 'extreme.narrow' },
        { name: 'Very deep pond', pond: 'extreme.deep' },
        { name: 'Massive pond', pond: 'extreme.massive' }
      ];

      extremeCases.forEach(testCase => {
        cy.loadTestDataScenario({
          equipment: 'commercial',
          pond: testCase.pond,
          device: 'desktop'
        }).then(scenario => {
          cy.waitForCalculation();
          
          // Should handle extreme cases without errors
          cy.get('[data-testid="timeline-result"]').should('be.visible');
          
          cy.get('[data-testid="timeline-days"]').invoke('text').then(result => {
            expect(result).to.not.contain('NaN');
            expect(result).to.not.contain('Infinity');
            expect(result).to.not.contain('undefined');
            
            const days = parseFloat(result);
            expect(days).to.be.greaterThan(0);
            expect(days).to.be.lessThan(1000); // Reasonable upper bound
            
            cy.log(`${testCase.name}: ${result} (${scenario.pond.description})`);
          });
        });
      });
    });

    it('should validate equipment efficiency scenarios', () => {
      // Test with various equipment efficiency combinations
      cy.loadTestDataScenario({
        equipment: 'maximum', // High-efficiency equipment
        pond: 'industrial.large',
        device: 'desktop'
      }).then(highEfficiencyScenario => {
        cy.waitForCalculation();
        cy.get('[data-testid="timeline-days"]').invoke('text').then(highEffResult => {
          
          // Compare with lower efficiency
          cy.loadTestDataScenario({
            equipment: 'residential', // Lower-efficiency equipment
            pond: 'industrial.large', // Same pond
            device: 'desktop'
          });
          
          cy.waitForCalculation();
          cy.get('[data-testid="timeline-days"]').invoke('text').then(lowEffResult => {
            const highEffDays = parseFloat(highEffResult);
            const lowEffDays = parseFloat(lowEffResult);
            
            // High-efficiency equipment should complete faster
            expect(highEffDays).to.be.lessThan(lowEffDays);
            
            // Difference should be significant but not extreme
            const improvement = ((lowEffDays - highEffDays) / lowEffDays) * 100;
            expect(improvement).to.be.greaterThan(10); // At least 10% improvement
            expect(improvement).to.be.lessThan(90); // Not unrealistically efficient
            
            cy.log(`Equipment efficiency test: ${improvement.toFixed(1)}% improvement`);
          });
        });
      });
    });
  });

  context('Data Consistency Testing', () => {
    it('should maintain calculation accuracy across page reloads', () => {
      cy.loadTestDataScenario({
        equipment: 'commercial',
        pond: 'commercial.medium',
        device: 'desktop'
      });
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-days"]').invoke('text').as('originalResult');
      
      cy.reload();
      
      // Data should persist and calculation should match
      cy.waitForCalculation();
      cy.get('@originalResult').then(originalResult => {
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .should('equal', originalResult);
        
        cy.log('Calculation consistency verified across reload');
      });
    });

    it('should handle scenario variations correctly', () => {
      // Base scenario
      cy.loadTestDataScenario({
        equipment: 'commercial',
        pond: 'commercial.medium',
        device: 'desktop'
      }).then(baseScenario => {
        cy.waitForCalculation();
        cy.get('[data-testid="timeline-days"]').invoke('text').then(baseResult => {
          const baseDays = parseFloat(baseResult);
          
          // Test variation: larger pond (should take longer)
          cy.setPondDimensions({
            length: Math.round(baseScenario.pond.length * 1.5),
            width: Math.round(baseScenario.pond.width * 1.5),
            depth: baseScenario.pond.depth,
            workHours: baseScenario.pond.workHours
          });
          
          cy.waitForCalculation();
          cy.get('[data-testid="timeline-days"]').invoke('text').then(largerResult => {
            const largerDays = parseFloat(largerResult);
            
            // Larger pond should take more time
            expect(largerDays).to.be.greaterThan(baseDays);
            
            // Test variation: more work hours (should take less time per day, fewer total days)
            cy.setPondDimensions({
              length: Math.round(baseScenario.pond.length * 1.5),
              width: Math.round(baseScenario.pond.width * 1.5),
              depth: baseScenario.pond.depth,
              workHours: Math.min(baseScenario.pond.workHours + 3, 12)
            });
            
            cy.waitForCalculation();
            cy.get('[data-testid="timeline-days"]').invoke('text').then(moreHoursResult => {
              const moreHoursDays = parseFloat(moreHoursResult);
              
              // More work hours should reduce total days
              expect(moreHoursDays).to.be.lessThan(largerDays);
              
              cy.log(`Variation testing: base=${baseDays}, larger=${largerDays}, more hours=${moreHoursDays}`);
            });
          });
        });
      });
    });
  });

  context('Integration Testing with Real Data', () => {
    it('should run comprehensive test matrix', () => {
      // Run a subset of the test matrix for integration testing
      cy.runTestMatrix({ maxTests: 6, priority: 4 }).then(results => {
        expect(results).to.have.length.greaterThan(0);
        
        // Verify all tests produced valid results
        results.forEach(result => {
          expect(result.result).to.not.contain('NaN');
          expect(result.result).to.not.contain('undefined');
          expect(parseFloat(result.result)).to.be.greaterThan(0);
          
          cy.log(`Matrix test ${result.testCase}: ${result.result}`);
        });
        
        cy.log(`Completed ${results.length} test matrix scenarios`);
      });
    });

    it('should validate realistic project timelines', () => {
      const projectTypes = [
        { name: 'Small Residential', equipment: 'residential', pond: 'backyard.small', expectedRange: [0.5, 5] },
        { name: 'Large Commercial', equipment: 'commercial', pond: 'commercial.large', expectedRange: [7, 40] },
        { name: 'Industrial', equipment: 'industrial', pond: 'industrial.medium', expectedRange: [10, 60] }
      ];

      projectTypes.forEach(project => {
        cy.loadTestDataScenario({
          equipment: project.equipment,
          pond: project.pond,
          device: 'desktop'
        });
        
        cy.waitForCalculation();
        cy.get('[data-testid="timeline-days"]').invoke('text').then(result => {
          const days = parseFloat(result);
          const [min, max] = project.expectedRange;
          
          expect(days).to.be.within(min, max, 
            `${project.name} timeline should be within ${min}-${max} days, got ${days}`);
          
          cy.log(`${project.name}: ${days} days (expected ${min}-${max})`);
        });
      });
    });
  });
});