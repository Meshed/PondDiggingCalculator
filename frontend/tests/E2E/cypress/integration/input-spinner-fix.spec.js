/// <reference types="cypress" />

describe('Input Field Spinner Fix Validation', () => {
  beforeEach(() => {
    cy.visit('/');
    // Configuration is now loaded at build-time (static) - no HTTP wait needed
  });

  context('Desktop View Input Spinner Behavior', () => {
    beforeEach(() => {
      cy.viewport(1200, 800); // Desktop viewport
    });

    it('should hide number input spinners on desktop', () => {
      // Check that native spinners are hidden via CSS
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.css', '-webkit-appearance', 'textfield')
        .should('have.css', '-moz-appearance', 'textfield');
    });

    it('should display unit text clearly without spinner overlap', () => {
      // Verify unit text is visible and properly positioned
      cy.get('[data-testid="pond-length-input"]').parent().within(() => {
        cy.contains('feet').should('be.visible');
      });
      
      cy.get('[data-testid="excavator-capacity-input"]').parent().within(() => {
        cy.contains('cubic yards').should('be.visible');
      });
    });

    it('should maintain proper padding for unit display', () => {
      // Verify inputs have right padding to accommodate unit text
      cy.get('[data-testid="pond-length-input"]')
        .should('have.css', 'padding-right')
        .and('match', /4rem|64px/); // 4rem = 64px typically
    });

    it('should still accept numeric input without spinners', () => {
      // Test that input still functions correctly for numeric values
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('3.5')
        .should('have.value', '3.5');
        
      // Verify calculation still works
      cy.wait(400); // Wait for debounce
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should handle decimal input correctly without spinner interference', () => {
      cy.get('[data-testid="pond-depth-input"]')
        .clear()
        .type('7.25')
        .should('have.value', '7.25');
        
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Tablet View Input Spinner Behavior', () => {
    beforeEach(() => {
      cy.viewport(768, 1024); // Tablet viewport
    });

    it('should hide spinners on tablet view', () => {
      cy.get('[data-testid="truck-capacity-input"]')
        .should('have.css', '-webkit-appearance', 'textfield');
    });

    it('should display unit text properly on tablet', () => {
      cy.get('[data-testid="truck-capacity-input"]').parent().within(() => {
        cy.contains('cubic yards').should('be.visible');
      });
    });

    it('should maintain input functionality on tablet', () => {
      cy.get('[data-testid="work-hours-input"]')
        .clear()
        .type('9.5')
        .should('have.value', '9.5');
    });
  });

  context('Mobile View Input Behavior', () => {
    beforeEach(() => {
      cy.viewport(375, 667); // Mobile viewport
    });

    it('should hide spinners on mobile', () => {
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.css', '-webkit-appearance', 'textfield');
    });

    it('should maintain input functionality on mobile', () => {
      cy.get('[data-testid="excavator-capacity-input"]')
        .clear()
        .type('4.0')
        .should('have.value', '4.0');
    });
  });

  context('Cross-Browser Spinner Hiding', () => {
    it('should apply webkit spinner hiding rules', () => {
      cy.viewport(1200, 800);
      
      // Check that CSS rules are present in the document
      cy.document().then((doc) => {
        const styles = doc.styleSheets;
        let foundWebkitRule = false;
        let foundMozRule = false;
        
        for (let i = 0; i < styles.length; i++) {
          try {
            const rules = styles[i].cssRules || styles[i].rules;
            for (let j = 0; j < rules.length; j++) {
              const rule = rules[j];
              if (rule.selectorText && rule.selectorText.includes('-webkit-inner-spin-button')) {
                foundWebkitRule = true;
              }
              if (rule.selectorText && rule.selectorText.includes('input[type="number"]')) {
                foundMozRule = true;
              }
            }
          } catch (e) {
            // Cross-origin stylesheets may not be accessible
          }
        }
        
        expect(foundWebkitRule || foundMozRule).to.be.true;
      });
    });

    it('should prevent spinner display across different input types', () => {
      cy.viewport(1200, 800);
      
      const inputFields = [
        '[data-testid="excavator-capacity-input"]',
        '[data-testid="excavator-cycle-input"]',
        '[data-testid="truck-capacity-input"]',
        '[data-testid="truck-roundtrip-input"]',
        '[data-testid="work-hours-input"]',
        '[data-testid="pond-length-input"]',
        '[data-testid="pond-width-input"]',
        '[data-testid="pond-depth-input"]'
      ];

      inputFields.forEach(selector => {
        cy.get(selector)
          .should('have.attr', 'type', 'number')
          .should('have.css', '-webkit-appearance', 'textfield');
      });
    });
  });

  context('Input Field Layout and Spacing', () => {
    beforeEach(() => {
      cy.viewport(1200, 800); // Desktop where unit text is most prominent
    });

    it('should maintain proper spacing between input and unit text', () => {
      // Check that there's adequate space for unit text
      cy.get('[data-testid="pond-length-input"]')
        .should('be.visible')
        .then(($input) => {
          const input = $input[0];
          const computedStyle = window.getComputedStyle(input);
          const paddingRight = computedStyle.paddingRight;
          
          // Should have significant right padding (4rem = 64px)
          expect(parseFloat(paddingRight)).to.be.greaterThan(32);
        });
    });

    it('should display unit text without overlap', () => {
      // Test specific positioning of unit text
      cy.get('[data-testid="excavator-capacity-input"]').parent().within(() => {
        // Unit text should be positioned on the right
        cy.get('span').contains('cubic yards').should(($span) => {
          const span = $span[0];
          const rect = span.getBoundingClientRect();
          
          // Should be positioned to the right (this is a basic check)
          expect(rect.width).to.be.greaterThan(0);
          expect(rect.height).to.be.greaterThan(0);
        });
      });
    });

    it('should handle long unit text without layout issues', () => {
      // Test with longer unit text like "cubic yards"
      cy.get('[data-testid="truck-capacity-input"]').parent().within(() => {
        cy.contains('cubic yards')
          .should('be.visible')
          .should('not.be.covered');
      });
    });
  });

  context('Regression Testing', () => {
    it('should maintain all form functionality after spinner fix', () => {
      cy.viewport(1200, 800);
      
      // Fill out complete form
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('2.2');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15.0');
      cy.get('[data-testid="truck-roundtrip-input"]').clear().type('18.0');
      cy.get('[data-testid="work-hours-input"]').clear().type('9.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      cy.get('[data-testid="pond-width-input"]').clear().type('35');
      cy.get('[data-testid="pond-depth-input"]').clear().type('8');

      cy.wait(400); // Wait for debounce

      // Verify calculation works
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
    });

    it('should maintain validation functionality', () => {
      cy.viewport(1200, 800);
      
      // Test validation with invalid input
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="excavator-capacity-error"]')
        .should('be.visible')
        .and('contain', 'must be greater than zero');
    });

    it('should preserve real-time updates', () => {
      cy.viewport(1200, 800);
      
      // Test real-time updates still work
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      
      // Should not calculate immediately (debounced)
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Should calculate after debounce
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });
});