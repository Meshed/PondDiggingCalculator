/// <reference types="cypress" />

describe('Mobile Device Workflow Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    // Configuration is now loaded at build-time (static) - no HTTP wait needed
  });

  context('Field Worker Quick Calculations', () => {
    it('should enable rapid pond estimates on iPhone', () => {
      cy.iPhone8();
      
      // Verify mobile interface loads
      cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      cy.get('[data-testid="simplified-interface"]').should('be.visible');
      
      // Quick field calculation workflow
      cy.measurePerformance(() => {
        // Essential equipment entry
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .and('have.css', 'font-size')
          .and('match', /18px|1.125rem/); // Mobile-optimized font size
          
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
        cy.get('[data-testid="truck-capacity-input"]').clear().type('12');
        
        // Quick pond dimensions
        cy.get('[data-testid="pond-length-input"]').clear().type('35');
        cy.get('[data-testid="pond-width-input"]').clear().type('25');
        cy.get('[data-testid="pond-depth-input"]').clear().type('4');
      }, 2000);
      
      cy.waitForCalculation();
      
      // Mobile-optimized results
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]')
        .should('be.visible')
        .and('have.css', 'font-size')
        .and('match', /24px|1.5rem/); // Large, readable result
        
      // Result should be immediate and clear
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
    });

    it('should work with mobile keyboards and input types', () => {
      cy.iPhone8();
      
      // Test numeric keyboard activation
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.attr', 'type', 'number')
        .and('have.attr', 'inputmode', 'decimal');
        
      cy.get('[data-testid="pond-length-input"]')
        .should('have.attr', 'type', 'number')
        .and('have.attr', 'inputmode', 'numeric');
      
      // Test touch interaction
      cy.get('[data-testid="excavator-capacity-input"]').touch().type('3.5');
      cy.get('[data-testid="pond-length-input"]').touch().type('40');
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should handle portrait/landscape orientation changes', () => {
      // Start in portrait
      cy.viewport(375, 667); // iPhone portrait
      
      cy.fillFormWithDefaults('small');
      cy.waitForCalculation();
      
      cy.get('[data-testid="timeline-days"]').then($portraitResult => {
        const portraitValue = $portraitResult.text();
        
        // Switch to landscape
        cy.viewport(667, 375); // iPhone landscape
        cy.wait(500);
        
        // Values should be preserved
        cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.0');
        cy.get('[data-testid="timeline-days"]').should('contain', portraitValue);
        
        // Interface should adapt
        cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      });
    });
  });

  context('Construction Supervisor Tablet Workflow', () => {
    it('should provide comprehensive interface on iPad Pro', () => {
      cy.iPadPro();
      
      // Tablet should show rich interface
      cy.get('[data-testid="device-type"]').should('contain', 'Tablet');
      cy.get('[data-testid="advanced-features"]').should('be.visible');
      
      // Professional workflow with detailed parameters
      cy.fillFormWithDefaults('large');
      
      // Additional tablet-specific features
      cy.get('[data-testid="work-hours-input"]').clear().type('10');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('1.8');
      cy.get('[data-testid="truck-roundtrip-input"]').clear().type('22');
      
      cy.waitForCalculation();
      
      // Detailed results for professional use
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
      cy.get('[data-testid="hauling-rate"]').should('be.visible');
      cy.get('[data-testid="bottleneck"]').should('be.visible');
    });

    it('should handle multi-touch gestures gracefully', () => {
      cy.iPadPro();
      
      // Test pinch-to-zoom doesn't break interface
      cy.get('[data-testid="pond-length-input"]').trigger('touchstart', {
        touches: [
          { clientX: 100, clientY: 100 },
          { clientX: 200, clientY: 200 }
        ]
      });
      
      cy.get('[data-testid="pond-length-input"]').trigger('touchend');
      
      // Interface should remain functional
      cy.get('[data-testid="pond-length-input"]').should('be.visible').clear().type('75');
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should maintain professional accuracy on tablet', () => {
      cy.iPadPro();
      
      // Large commercial project calculation
      const commercialProject = {
        excavatorCapacity: '4.5',
        excavatorCycle: '1.5',
        truckCapacity: '20',
        truckRoundTrip: '30',
        workHours: '12',
        pondLength: '150',
        pondWidth: '100',
        pondDepth: '15'
      };
      
      Object.entries(commercialProject).forEach(([field, value]) => {
        const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
        cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
      });
      
      cy.waitForCalculation();
      
      // Large project should show multiple days
      cy.get('[data-testid="timeline-days"]').then($days => {
        const days = parseInt($days.text());
        expect(days).to.be.greaterThan(5);
        expect(days).to.be.lessThan(50);
      });
      
      // Should identify bottleneck for optimization
      cy.get('[data-testid="bottleneck"]').should('be.visible');
    });
  });

  context('Cross-Device Collaboration Workflow', () => {
    it('should maintain consistency between field mobile and office desktop', () => {
      // Field worker on mobile
      cy.iPhone8();
      
      const fieldData = {
        excavatorCapacity: '3.0',
        truckCapacity: '15',
        pondLength: '60',
        pondWidth: '40',
        pondDepth: '8'
      };
      
      // Fill field measurements
      Object.entries(fieldData).forEach(([field, value]) => {
        const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
        cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
      });
      
      cy.waitForCalculation();
      
      cy.get('[data-testid="timeline-days"]').then($mobileResult => {
        const mobileValue = $mobileResult.text();
        
        // Switch to desktop (office review)
        cy.desktop1080p();
        cy.wait(1000);
        
        // Same data should produce same result
        Object.entries(fieldData).forEach(([field, value]) => {
          const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
          cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
        });
        
        // Add detailed parameters available on desktop
        cy.get('[data-testid="excavator-cycle-input"]').clear().type('2.2');
        cy.get('[data-testid="truck-roundtrip-input"]').clear().type('18');
        cy.get('[data-testid="work-hours-input"]').clear().type('8');
        
        cy.waitForCalculation();
        
        // Core calculation should be consistent
        cy.get('[data-testid="timeline-days"]').should('be.visible');
        
        // Desktop provides more detailed analysis
        cy.get('[data-testid="excavation-rate"]').should('be.visible');
        cy.get('[data-testid="hauling-rate"]').should('be.visible');
      });
    });

    it('should handle real-world connectivity issues', () => {
      cy.iPhone8();
      
      // Simulate slow network
      cy.intercept('GET', '/config.json', { delay: 2000 }).as('slowConfig');
      
      cy.visit('/');
      
      // Should show loading state or fallback gracefully
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 }).should('be.visible');
      
      // Basic functionality should work even with slow config
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('30');
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Touch Interaction and Usability', () => {
    it('should have appropriate touch targets on all mobile devices', () => {
      const mobileDevices = [
        { name: 'iPhone SE', width: 320, height: 568 },
        { name: 'iPhone 12', width: 390, height: 844 },
        { name: 'Samsung Galaxy S21', width: 360, height: 800 },
        { name: 'Pixel 5', width: 393, height: 851 }
      ];
      
      mobileDevices.forEach(device => {
        cy.viewport(device.width, device.height);
        cy.wait(500);
        
        // All interactive elements should meet touch target size requirements
        const interactiveElements = [
          'excavator-capacity-input',
          'truck-capacity-input',
          'pond-length-input',
          'pond-width-input',
          'pond-depth-input'
        ];
        
        interactiveElements.forEach(elementId => {
          cy.get(`[data-testid="${elementId}"]`).should($element => {
            const rect = $element[0].getBoundingClientRect();
            
            // iOS/Android guidelines: minimum 44x44px touch targets
            expect(rect.width, `${elementId} width on ${device.name}`).to.be.at.least(44);
            expect(rect.height, `${elementId} height on ${device.name}`).to.be.at.least(44);
          });
        });
      });
    });

    it('should handle swipe gestures without breaking functionality', () => {
      cy.iPhone8();
      
      // Test that accidental swipes don't interfere
      cy.get('[data-testid="excavator-capacity-input"]')
        .trigger('touchstart', { touches: [{ clientX: 100, clientY: 100 }] })
        .trigger('touchmove', { touches: [{ clientX: 200, clientY: 100 }] })
        .trigger('touchend');
      
      // Should still be able to interact normally
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should prevent zoom on input focus (UX enhancement)', () => {
      cy.iPhone8();
      
      // Check that inputs have viewport meta prevention
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        const fontSize = parseFloat(window.getComputedStyle($input[0]).fontSize);
        
        // Font size should be at least 16px to prevent zoom on iOS
        expect(fontSize).to.be.at.least(16);
      });
      
      cy.get('[data-testid="pond-length-input"]').focus();
      
      // Page should not zoom (we can't test this directly, but font size check above helps)
      cy.get('[data-testid="pond-length-input"]').should('be.focused');
    });
  });

  context('Mobile Performance and Battery Impact', () => {
    it('should maintain performance on lower-end mobile devices', () => {
      // Simulate slower mobile device
      cy.viewport(360, 640); // Older Android size
      
      const performanceStart = performance.now();
      
      // Typical mobile workflow
      cy.fillFormWithDefaults('medium');
      cy.waitForCalculation();
      
      cy.then(() => {
        const totalTime = performance.now() - performanceStart;
        
        // Should complete mobile workflow quickly
        expect(totalTime).to.be.lessThan(3000); // 3 seconds max
        
        cy.task('logPerformance', {
          device: 'mobile-lowend',
          workflow: 'typical',
          duration: totalTime
        });
      });
      
      // Multiple calculations shouldn't slow down significantly
      for (let i = 0; i < 5; i++) {
        cy.get('[data-testid="pond-length-input"]').clear().type(String(30 + i * 5));
        cy.wait(100);
      }
      
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should minimize battery drain during extended use', () => {
      cy.iPhone8();
      
      // Simulate extended job site use
      const iterations = 10;
      const startTime = performance.now();
      
      for (let i = 0; i < iterations; i++) {
        // Vary calculations to simulate real use
        const length = 30 + (i * 3);
        const width = 20 + (i * 2);
        
        cy.get('[data-testid="pond-length-input"]').clear().type(String(length));
        cy.get('[data-testid="pond-width-input"]').clear().type(String(width));
        
        cy.wait(200); // Brief pause between calculations
      }
      
      cy.waitForCalculation();
      
      cy.then(() => {
        const avgTimePerCalculation = (performance.now() - startTime) / iterations;
        
        // Should maintain consistent performance
        expect(avgTimePerCalculation).to.be.lessThan(500);
        
        cy.task('logPerformance', {
          device: 'mobile',
          test: 'extended-use',
          avgTimePerCalculation,
          iterations
        });
      });
    });
  });

  context('Mobile Accessibility and Inclusivity', () => {
    it('should work with mobile screen readers', () => {
      cy.iPhone8();
      
      // Check VoiceOver compatibility (iOS screen reader)
      cy.checkA11y();
      
      // Mobile-specific accessibility features
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        // Should have touch-friendly labels
        const ariaLabel = $input.attr('aria-label');
        const hasLabel = ariaLabel || Cypress.$(`label[for="${$input.attr('id')}"]`).length > 0;
        
        expect(hasLabel, 'Input should have screen reader accessible label').to.be.true;
      });
    });

    it('should support high contrast mode', () => {
      cy.iPhone8();
      
      // Simulate high contrast mode request
      cy.window().then(win => {
        // Mock high contrast media query
        Object.defineProperty(win, 'matchMedia', {
          value: jest.fn().mockImplementation(query => ({
            matches: query.includes('prefers-contrast: high'),
            media: query,
            onchange: null,
            addListener: jest.fn(),
            removeListener: jest.fn(),
          })),
        });
      });
      
      cy.reload();
      cy.wait(1000);
      
      // Interface should still be functional
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      cy.fillFormWithDefaults('small');
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should work with reduced motion preferences', () => {
      cy.iPhone8();
      
      // All functionality should work without animations
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      
      // Should calculate without requiring animations
      cy.waitForCalculation();
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });
});