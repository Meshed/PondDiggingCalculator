/// <reference types="cypress" />

describe('Accessibility Validation Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    // Configuration is now loaded at build-time (static) - no HTTP wait needed
  });

  context('Keyboard Navigation', () => {
    it('should be fully navigable by keyboard only', () => {
      cy.viewport(1200, 800);
      
      // Start from body and tab through all interactive elements
      cy.get('body').focus();
      
      // Tab to first interactive element
      cy.get('body').tab();
      cy.focused().should('have.attr', 'data-testid', 'excavator-capacity-input');
      
      // Continue tabbing through form elements
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'excavator-cycle-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'truck-capacity-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'truck-roundtrip-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'work-hours-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'pond-length-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'pond-width-input');
      
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid', 'pond-depth-input');
      
      // Test that we can use the form with keyboard only
      cy.focused().clear().type('6');
      cy.wait(400);
      
      // Should be able to see results
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should support reverse tabbing (Shift+Tab)', () => {
      cy.viewport(1200, 800);
      
      // Navigate to last input
      cy.get('[data-testid="pond-depth-input"]').focus();
      
      // Shift+Tab backwards
      cy.focused().tab({ shift: true });
      cy.focused().should('have.attr', 'data-testid', 'pond-width-input');
      
      cy.focused().tab({ shift: true });
      cy.focused().should('have.attr', 'data-testid', 'pond-length-input');
      
      cy.focused().tab({ shift: true });
      cy.focused().should('have.attr', 'data-testid', 'work-hours-input');
    });

    it('should have proper focus indicators', () => {
      cy.viewport(1200, 800);
      
      // Check each input has visible focus indicator
      const inputFields = [
        'excavator-capacity-input',
        'excavator-cycle-input', 
        'truck-capacity-input',
        'truck-roundtrip-input',
        'work-hours-input',
        'pond-length-input',
        'pond-width-input',
        'pond-depth-input'
      ];
      
      inputFields.forEach(fieldId => {
        cy.get(`[data-testid="${fieldId}"]`).focus();
        
        // Should have visible focus styling
        cy.focused().should('have.css', 'outline-style')
          .and('match', /solid|auto/);
        
        // Or should have custom focus styling
        cy.focused().should($input => {
          const styles = window.getComputedStyle($input[0]);
          const hasOutline = styles.outlineStyle !== 'none';
          const hasBorder = styles.borderColor !== 'initial';
          const hasBoxShadow = styles.boxShadow !== 'none';
          
          expect(hasOutline || hasBorder || hasBoxShadow).to.be.true;
        });
      });
    });

    it('should support Enter key for form interaction', () => {
      cy.viewport(1200, 800);
      
      // Focus on input and use Enter (should not cause page reload)
      cy.get('[data-testid="excavator-capacity-input"]').focus().clear().type('3.5');
      cy.focused().type('{enter}');
      
      // Page should not reload, calculation should work
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '3.5');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Screen Reader Support', () => {
    it('should have proper ARIA labels for all inputs', () => {
      cy.viewport(1200, 800);
      
      const expectedLabels = [
        { input: 'excavator-capacity-input', label: /excavator.*capacity/i },
        { input: 'excavator-cycle-input', label: /excavator.*cycle/i },
        { input: 'truck-capacity-input', label: /truck.*capacity/i },
        { input: 'truck-roundtrip-input', label: /truck.*round.*trip/i },
        { input: 'work-hours-input', label: /work.*hours/i },
        { input: 'pond-length-input', label: /pond.*length/i },
        { input: 'pond-width-input', label: /pond.*width/i },
        { input: 'pond-depth-input', label: /pond.*depth/i }
      ];
      
      expectedLabels.forEach(({ input, label }) => {
        cy.get(`[data-testid="${input}"]`).should($input => {
          // Check for aria-label or associated label element
          const ariaLabel = $input.attr('aria-label');
          const ariaLabelledby = $input.attr('aria-labelledby');
          
          if (ariaLabel) {
            expect(ariaLabel).to.match(label);
          } else if (ariaLabelledby) {
            const labelElement = Cypress.$(`#${ariaLabelledby}`);
            expect(labelElement.text()).to.match(label);
          } else {
            // Check for associated label element
            const id = $input.attr('id');
            if (id) {
              const labelElement = Cypress.$(`label[for="${id}"]`);
              expect(labelElement.length).to.be.greaterThan(0);
              expect(labelElement.text()).to.match(label);
            } else {
              // Should have some form of label
              expect(false, `Input ${input} should have proper labeling`).to.be.true;
            }
          }
        });
      });
    });

    it('should have proper ARIA descriptions for units', () => {
      cy.viewport(1200, 800);
      
      // Check that unit information is accessible to screen readers
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        const ariaDescribedby = $input.attr('aria-describedby');
        
        if (ariaDescribedby) {
          const descriptionElement = Cypress.$(`#${ariaDescribedby}`);
          expect(descriptionElement.text()).to.match(/cubic yards/i);
        }
      });
      
      cy.get('[data-testid="pond-length-input"]').should($input => {
        const ariaDescribedby = $input.attr('aria-describedby');
        
        if (ariaDescribedby) {
          const descriptionElement = Cypress.$(`#${ariaDescribedby}`);
          expect(descriptionElement.text()).to.match(/feet/i);
        }
      });
    });

    it('should announce validation errors to screen readers', () => {
      cy.viewport(1200, 800);
      
      // Create validation error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      
      cy.get('[data-testid="excavator-capacity-error"]').should($error => {
        // Error should be associated with the input
        const errorId = $error.attr('id');
        const inputAriaDescribedby = Cypress.$('[data-testid="excavator-capacity-input"]').attr('aria-describedby');
        
        if (errorId && inputAriaDescribedby) {
          expect(inputAriaDescribedby).to.include(errorId);
        }
        
        // Error should have proper role
        const role = $error.attr('role');
        if (role) {
          expect(role).to.equal('alert');
        }
      });
    });

    it('should have proper heading structure', () => {
      cy.viewport(1200, 800);
      
      // Check for proper heading hierarchy
      cy.get('h1').should('exist');
      
      // Check that headings are in logical order
      cy.get('h1, h2, h3, h4, h5, h6').then($headings => {
        let previousLevel = 0;
        
        $headings.each((index, heading) => {
          const currentLevel = parseInt(heading.tagName.charAt(1));
          
          // Heading levels should not skip (e.g., h1 -> h3)
          expect(currentLevel).to.be.at.most(previousLevel + 1);
          previousLevel = Math.max(previousLevel, currentLevel);
        });
      });
    });

    it('should have accessible results announcement', () => {
      cy.viewport(1200, 800);
      
      // Fill form and get results
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      
      // Results should be announced to screen readers
      cy.get('[data-testid="timeline-result"]').should($result => {
        // Should have role="status" or aria-live for announcements
        const ariaLive = $result.attr('aria-live');
        const role = $result.attr('role');
        
        expect(ariaLive === 'polite' || role === 'status').to.be.true;
      });
    });
  });

  context('Visual Accessibility', () => {
    it('should have sufficient color contrast', () => {
      cy.viewport(1200, 800);
      
      // Check input field contrast
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        const styles = window.getComputedStyle($input[0]);
        const backgroundColor = styles.backgroundColor;
        const color = styles.color;
        const borderColor = styles.borderColor;
        
        // These values should provide good contrast (would need color contrast library for exact calculation)
        expect(backgroundColor).to.not.equal(color);
        expect(borderColor).to.not.equal(backgroundColor);
      });
      
      // Check error message contrast
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      
      cy.get('[data-testid="excavator-capacity-error"]').should($error => {
        const styles = window.getComputedStyle($error[0]);
        const color = styles.color;
        
        // Error text should be clearly visible (typically red with good contrast)
        expect(color).to.not.equal('rgb(0, 0, 0)'); // Should not be default black
      });
    });

    it('should be usable at 200% zoom level', () => {
      // Simulate 200% zoom by using smaller viewport
      cy.viewport(600, 400); // Half size = 200% zoom equivalent
      
      // All elements should still be visible and usable
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      cy.get('[data-testid="truck-capacity-input"]').should('be.visible');
      cy.get('[data-testid="pond-length-input"]').should('be.visible');
      
      // Form should still be functional
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should have readable font sizes', () => {
      cy.viewport(1200, 800);
      
      // Check minimum font sizes for readability
      const textElements = [
        'excavator-capacity-input',
        'pond-length-input',
        'timeline-result'
      ];
      
      textElements.forEach(elementId => {
        cy.get(`[data-testid="${elementId}"]`).should($element => {
          const styles = window.getComputedStyle($element[0]);
          const fontSize = parseFloat(styles.fontSize);
          
          // Minimum 16px for body text, 14px for input text
          const minSize = elementId.includes('input') ? 14 : 16;
          expect(fontSize).to.be.at.least(minSize);
        });
      });
    });

    it('should work without CSS (graceful degradation)', () => {
      // Disable CSS to test base HTML structure
      cy.get('head').then($head => {
        $head.find('link[rel="stylesheet"]').remove();
        $head.find('style').remove();
      });
      
      // Basic functionality should still work
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      cy.get('[data-testid="pond-length-input"]').should('be.visible');
      
      // Form should still submit/calculate
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      
      // Results might not be styled but should be present
      cy.get('[data-testid="timeline-result"]').should('exist');
    });
  });

  context('Mobile Accessibility', () => {
    it('should be accessible on mobile devices', () => {
      cy.viewport(375, 667); // Mobile viewport
      
      // Touch targets should be large enough (minimum 44x44px)
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
          
          // Minimum touch target size
          expect(rect.width).to.be.at.least(44);
          expect(rect.height).to.be.at.least(44);
        });
      });
    });

    it('should work with mobile screen readers', () => {
      cy.viewport(375, 667);
      
      // Mobile simplified interface should still have proper labels
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        const ariaLabel = $input.attr('aria-label');
        const id = $input.attr('id');
        
        // Should have labeling even in mobile view
        expect(ariaLabel || Cypress.$(`label[for="${id}"]`).length > 0).to.be.true;
      });
    });

    it('should announce device type changes', () => {
      // Start desktop
      cy.viewport(1200, 800);
      
      // Transition to mobile
      cy.viewport(375, 667);
      cy.wait(500);
      
      // Device type change should be announced if implemented
      cy.get('[data-testid="device-type"]').should($deviceType => {
        const ariaLive = $deviceType.attr('aria-live');
        if (ariaLive) {
          expect(ariaLive).to.equal('polite');
        }
      });
    });
  });

  context('Focus Management', () => {
    it('should manage focus during validation errors', () => {
      cy.viewport(1200, 800);
      
      // Create validation error
      cy.get('[data-testid="excavator-capacity-input"]').focus().clear().type('-1');
      
      // Focus should remain on input or move to error
      cy.wait(100);
      
      cy.focused().should($focused => {
        const testId = $focused.attr('data-testid');
        expect(['excavator-capacity-input', 'excavator-capacity-error']).to.include(testId);
      });
    });

    it('should maintain logical focus order during dynamic updates', () => {
      cy.viewport(1200, 800);
      
      // Start calculation
      cy.get('[data-testid="excavator-capacity-input"]').focus().clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      
      // Results appear - focus order should still be logical
      cy.get('body').tab();
      cy.focused().should('have.attr', 'data-testid');
      
      // Continue tabbing through form
      cy.focused().tab();
      cy.focused().should('have.attr', 'data-testid');
    });

    it('should not trap focus unintentionally', () => {
      cy.viewport(1200, 800);
      
      // Tab through entire form
      let tabCount = 0;
      const maxTabs = 20; // Reasonable limit
      
      cy.get('body').focus();
      
      function tabNext() {
        if (tabCount < maxTabs) {
          cy.focused().tab();
          cy.focused().then($focused => {
            const testId = $focused.attr('data-testid');
            if (testId) {
              tabCount++;
              tabNext();
            }
          });
        }
      }
      
      tabNext();
      
      // Should eventually reach end of form or body
      cy.focused().should('exist');
    });
  });
});