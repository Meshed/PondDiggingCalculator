/// <reference types="cypress" />

describe('Screen Reader Compatibility Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.injectAxe(); // Inject axe-core for accessibility testing
  });

  context('ARIA Labels and Roles', () => {
    it('should provide proper ARIA labels for all interactive elements', () => {
      const inputFields = [
        { testId: 'excavator-capacity-input', expectedLabel: /excavator.*capacity/i },
        { testId: 'excavator-cycle-input', expectedLabel: /cycle.*time/i },
        { testId: 'truck-capacity-input', expectedLabel: /truck.*capacity/i },
        { testId: 'truck-roundtrip-input', expectedLabel: /round.*trip/i },
        { testId: 'work-hours-input', expectedLabel: /work.*hours/i },
        { testId: 'pond-length-input', expectedLabel: /length/i },
        { testId: 'pond-width-input', expectedLabel: /width/i },
        { testId: 'pond-depth-input', expectedLabel: /depth/i }
      ];

      inputFields.forEach(({ testId, expectedLabel }) => {
        cy.get(`[data-testid="${testId}"]`).should($input => {
          const element = $input[0];
          
          // Check for aria-label
          const ariaLabel = element.getAttribute('aria-label');
          
          // Check for aria-labelledby
          const labelledById = element.getAttribute('aria-labelledby');
          let labelledByText = '';
          if (labelledById) {
            const labelElement = document.getElementById(labelledById);
            labelledByText = labelElement ? labelElement.textContent : '';
          }
          
          // Check for associated label element
          const labelElement = document.querySelector(`label[for="${element.id}"]`);
          const labelText = labelElement ? labelElement.textContent : '';
          
          // At least one labeling method should exist and match expected pattern
          const hasValidLabel = 
            (ariaLabel && expectedLabel.test(ariaLabel)) ||
            (labelledByText && expectedLabel.test(labelledByText)) ||
            (labelText && expectedLabel.test(labelText));
          
          expect(hasValidLabel, 
            `${testId} should have accessible label. Found: aria-label="${ariaLabel}", labelledBy="${labelledByText}", label="${labelText}"`
          ).to.be.true;
        });
      });
    });

    it('should provide appropriate roles for complex UI elements', () => {
      // Check results panel has proper role
      cy.get('[data-testid="timeline-result"]').should($result => {
        const role = $result.attr('role');
        // Results should be marked as a region or status for screen readers
        expect(['region', 'status', 'alert', 'log']).to.include(role);
      });
      
      // Check form groupings have proper roles
      cy.get('form, [role="form"]').should('exist');
      
      // Navigation elements should have nav role
      cy.get('nav, [role="navigation"]').each($nav => {
        expect($nav.attr('role')).to.equal('navigation');
      });
    });

    it('should provide descriptive text for calculation results', () => {
      // Trigger calculation
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.wait(450);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then($result => {
        const resultText = $result.text();
        
        // Result should include units and context
        expect(resultText).to.match(/\d+.*day/i);
        expect(resultText).to.match(/cubic.*yard/i);
        
        // Should have appropriate ARIA attributes for screen readers
        const hasAriaLive = $result.attr('aria-live') || $result.parents('[aria-live]').length > 0;
        expect(hasAriaLive, 'Results should announce changes to screen readers').to.be.true;
      });
    });

    it('should announce validation errors accessibly', () => {
      // Trigger validation error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('999999');
      cy.wait(200);
      
      // Check for error announcement
      cy.get('[role="alert"], [aria-live="assertive"], [aria-live="polite"]').should($announcements => {
        const hasErrorAnnouncement = $announcements.toArray().some(el => {
          const text = el.textContent.toLowerCase();
          return text.includes('error') || text.includes('invalid') || text.includes('maximum') || text.includes('minimum');
        });
        expect(hasErrorAnnouncement, 'Validation errors should be announced to screen readers').to.be.true;
      });
      
      // Error message should be associated with input
      cy.get('[data-testid="excavator-capacity-input"]').should($input => {
        const describedBy = $input.attr('aria-describedby');
        const invalid = $input.attr('aria-invalid');
        
        expect(describedBy || invalid === 'true', 'Input should be marked as invalid or described by error').to.be.true;
      });
    });
  });

  context('Live Regions and Dynamic Updates', () => {
    it('should announce calculation results to screen readers', () => {
      // Check for live region setup
      cy.get('[aria-live], [role="status"], [role="alert"]').should('exist');
      
      // Perform calculation that should trigger announcement
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-width-input"]').clear().type('25');
      cy.wait(450);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then($result => {
        // Check that result is in a live region or has live attributes
        const hasLiveRegion = 
          $result.attr('aria-live') ||
          $result.parents('[aria-live]').length > 0 ||
          $result.attr('role') === 'status' ||
          $result.attr('role') === 'alert';
        
        expect(hasLiveRegion, 'Results should be announced via live regions').to.be.true;
        
        // Result text should be meaningful for screen readers
        const text = $result.text();
        expect(text).to.not.be.empty;
        expect(text).to.match(/\d/); // Should contain numbers
      });
    });

    it('should handle rapid input changes with appropriate announcements', () => {
      // Test that rapid changes don't spam screen readers
      cy.get('[data-testid="pond-length-input"]').clear().type('35');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      
      cy.wait(500); // Wait for debounce
      
      // Should only announce final result, not every keystroke
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Live regions should be set to "polite" to avoid interrupting
      cy.get('[aria-live="polite"]').should('exist');
      cy.get('[aria-live="assertive"]').should($assertive => {
        // Assertive live regions should be used sparingly (errors only)
        if ($assertive.length > 0) {
          $assertive.each((i, el) => {
            const text = el.textContent.toLowerCase();
            const isError = text.includes('error') || text.includes('invalid');
            expect(isError, 'Assertive announcements should be for errors only').to.be.true;
          });
        }
      });
    });

    it('should provide status updates for long calculations', () => {
      // Test with large values that might take longer to calculate
      cy.get('[data-testid="pond-length-input"]').clear().type('1000');
      cy.get('[data-testid="pond-width-input"]').clear().type('800');
      cy.get('[data-testid="pond-depth-input"]').clear().type('15');
      
      // Should provide loading/calculating status if applicable
      cy.wait(100);
      
      // Check for loading indicators that are accessible
      cy.get('[role="status"], [aria-live], [aria-busy="true"]').then($statusElements => {
        if ($statusElements.length > 0) {
          // If loading states exist, they should be accessible
          $statusElements.each((i, el) => {
            const text = el.textContent;
            if (text) {
              expect(text.toLowerCase()).to.match(/(calculating|loading|working)/);
            }
          });
        }
      });
      
      cy.wait(450);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Keyboard Navigation and Focus Management', () => {
    it('should maintain logical focus order throughout the application', () => {
      // Start from first focusable element
      cy.get('body').tab();
      
      const expectedTabOrder = [
        'excavator-capacity-input',
        'excavator-cycle-input',
        'truck-capacity-input',
        'truck-roundtrip-input',
        'work-hours-input',
        'pond-length-input',
        'pond-width-input',
        'pond-depth-input'
      ];
      
      expectedTabOrder.forEach((expectedId, index) => {
        cy.focused().should('have.attr', 'data-testid', expectedId);
        
        // Each focused element should have visible focus indicator
        cy.focused().should($el => {
          const computedStyle = window.getComputedStyle($el[0]);
          const hasVisibleFocus = 
            computedStyle.outlineStyle !== 'none' ||
            computedStyle.borderStyle !== 'none' ||
            computedStyle.boxShadow !== 'none' ||
            $el.attr('aria-describedby'); // Or has describedby for screen readers
          
          expect(hasVisibleFocus, `${expectedId} should have visible focus indicator`).to.be.true;
        });
        
        if (index < expectedTabOrder.length - 1) {
          cy.focused().tab();
        }
      });
    });

    it('should handle focus trapping appropriately', () => {
      // Test that focus doesn't escape to browser UI unexpectedly
      cy.get('[data-testid="excavator-capacity-input"]').focus();
      
      // Tab through all elements
      const tabCycles = 15; // More than the number of inputs
      for (let i = 0; i < tabCycles; i++) {
        cy.focused().tab();
      }
      
      // Focus should remain within the application content
      cy.focused().should($focused => {
        const isInApp = $focused.closest('body').length > 0 && 
                       !$focused.is('body') && 
                       !$focused.is('html');
        expect(isInApp, 'Focus should remain within application').to.be.true;
      });
    });

    it('should support skip links for efficient navigation', () => {
      // Check for skip links at the beginning of the page
      cy.get('body').tab(); // Focus first element
      
      cy.focused().then($first => {
        const text = $first.text().toLowerCase();
        if (text.includes('skip') && (text.includes('content') || text.includes('main'))) {
          // Skip link exists - test it works
          cy.focused().type('{enter}');
          
          cy.focused().should($focused => {
            // Should skip to main content
            const isInMainContent = 
              $focused.closest('main').length > 0 ||
              $focused.closest('[role="main"]').length > 0 ||
              $focused.is('[data-testid*="input"]'); // Form inputs are main content
            
            expect(isInMainContent, 'Skip link should move focus to main content').to.be.true;
          });
        } else {
          // No skip link found - log recommendation
          cy.log('Recommendation: Consider adding skip links for screen reader efficiency');
        }
      });
    });

    it('should announce focus changes appropriately', () => {
      const inputFields = [
        'excavator-capacity-input',
        'pond-length-input',
        'truck-capacity-input'
      ];
      
      inputFields.forEach(fieldId => {
        cy.get(`[data-testid="${fieldId}"]`).focus().then($input => {
          // Input should have accessible name for screen reader announcement
          const accessibleName = 
            $input.attr('aria-label') ||
            $input.attr('placeholder') ||
            ($input.attr('aria-labelledby') && 
             document.getElementById($input.attr('aria-labelledby'))?.textContent) ||
            (document.querySelector(`label[for="${$input.attr('id')}"]`)?.textContent);
          
          expect(accessibleName, `${fieldId} should have accessible name for focus announcements`).to.not.be.empty;
        });
      });
    });
  });

  context('High Contrast and Visual Accessibility', () => {
    it('should maintain functionality in high contrast mode', () => {
      // Simulate high contrast mode
      cy.get('body').then($body => {
        $body.addClass('high-contrast-mode');
        
        // Add CSS to simulate high contrast
        const style = document.createElement('style');
        style.textContent = `
          .high-contrast-mode * {
            background-color: black !important;
            color: white !important;
            border-color: white !important;
          }
          .high-contrast-mode input {
            border: 2px solid white !important;
          }
        `;
        document.head.appendChild(style);
        
        // Test that inputs are still visible and functional
        cy.get('[data-testid="pond-length-input"]')
          .should('be.visible')
          .clear()
          .type('50');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        // Clean up
        document.head.removeChild(style);
        $body.removeClass('high-contrast-mode');
      });
    });

    it('should support zoom levels up to 200%', () => {
      // Test different zoom levels
      const zoomLevels = [150, 200];
      
      zoomLevels.forEach(zoom => {
        cy.get('html').invoke('css', 'zoom', `${zoom}%`);
        
        // All interactive elements should remain accessible
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('be.visible')
          .click()
          .clear()
          .type('3.0');
        
        cy.get('[data-testid="pond-length-input"]')
          .should('be.visible')
          .clear()
          .type('45');
        
        cy.wait(450);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        
        cy.log(`Zoom level ${zoom}% tested successfully`);
      });
      
      // Reset zoom
      cy.get('html').invoke('css', 'zoom', '100%');
    });

    it('should provide sufficient color contrast ratios', () => {
      // Run axe-core accessibility audit
      cy.checkA11y(null, {
        rules: {
          'color-contrast': { enabled: true }
        }
      });
      
      // Manual checks for critical elements
      const criticalElements = [
        '[data-testid="excavator-capacity-input"]',
        '[data-testid="timeline-result"]',
        'label'
      ];
      
      criticalElements.forEach(selector => {
        cy.get(selector).first().then($el => {
          const element = $el[0];
          const computedStyle = window.getComputedStyle(element);
          const color = computedStyle.color;
          const backgroundColor = computedStyle.backgroundColor;
          
          // Log color information for manual review
          cy.log(`${selector}: color=${color}, backgroundColor=${backgroundColor}`);
          
          // Basic contrast check - ensure colors are not too similar
          expect(color).to.not.equal(backgroundColor);
        });
      });
    });
  });

  context('Screen Reader Specific Testing', () => {
    it('should provide proper heading structure', () => {
      // Check for logical heading hierarchy
      cy.get('h1, h2, h3, h4, h5, h6, [role="heading"]').then($headings => {
        if ($headings.length === 0) {
          cy.log('Recommendation: Add headings for better screen reader navigation');
          return;
        }
        
        const headingLevels = Array.from($headings).map(h => {
          return parseInt(h.tagName.replace('H', '')) || 
                 parseInt(h.getAttribute('aria-level')) || 1;
        });
        
        // Check for logical progression (no skipping levels)
        let maxSeen = 0;
        headingLevels.forEach(level => {
          expect(level - maxSeen).to.be.at.most(1, 
            'Heading levels should not skip (e.g., h1 -> h3)');
          maxSeen = Math.max(maxSeen, level);
        });
      });
    });

    it('should provide landmarks for page navigation', () => {
      // Check for ARIA landmarks
      const landmarks = [
        'main', '[role="main"]',
        'nav', '[role="navigation"]',
        'form', '[role="form"]',
        '[role="region"]'
      ];
      
      let foundLandmarks = 0;
      landmarks.forEach(selector => {
        cy.get('body').then($body => {
          if ($body.find(selector).length > 0) {
            foundLandmarks++;
          }
        });
      });
      
      cy.then(() => {
        if (foundLandmarks === 0) {
          cy.log('Recommendation: Add ARIA landmarks for better screen reader navigation');
        } else {
          cy.log(`Found ${foundLandmarks} landmark(s) for navigation`);
        }
      });
    });

    it('should handle screen reader virtual cursor navigation', () => {
      // Test that all content is accessible via virtual cursor
      cy.get('body').within(() => {
        // All interactive elements should be accessible
        cy.get('input, button, select, textarea, [tabindex]').each($el => {
          // Element should not be hidden from screen readers
          expect($el.attr('aria-hidden')).to.not.equal('true');
          expect($el.css('display')).to.not.equal('none');
          
          // Should have accessible text content or label
          const hasAccessibleText = 
            $el.text().trim() ||
            $el.attr('aria-label') ||
            $el.attr('aria-labelledby') ||
            $el.attr('title') ||
            $el.attr('placeholder');
          
          expect(hasAccessibleText, 'Interactive element should have accessible text').to.be.truthy;
        });
      });
    });

    it('should provide context for form fields and groups', () => {
      // Check for field grouping and context
      cy.get('fieldset, [role="group"]').then($groups => {
        $groups.each((i, group) => {
          const $group = Cypress.$(group);
          
          // Group should have accessible name
          const groupName = 
            $group.find('legend').text() ||
            $group.attr('aria-label') ||
            $group.attr('aria-labelledby');
          
          expect(groupName, 'Field groups should have accessible names').to.not.be.empty;
        });
      });
      
      // Check for required field indicators
      cy.get('input[required], [aria-required="true"]').each($input => {
        // Required fields should be announced as such
        const hasRequiredIndication = 
          $input.attr('required') !== undefined ||
          $input.attr('aria-required') === 'true' ||
          $input.siblings(':contains("required")').length > 0;
        
        expect(hasRequiredIndication, 'Required fields should be indicated accessibly').to.be.true;
      });
    });
  });

  context('Accessibility Testing with axe-core', () => {
    it('should pass comprehensive accessibility audit', () => {
      // Run full axe-core audit
      cy.checkA11y();
    });

    it('should pass WCAG 2.1 AA compliance', () => {
      // Run audit with WCAG 2.1 AA rules
      cy.checkA11y(null, {
        tags: ['wcag2a', 'wcag2aa', 'wcag21aa']
      });
    });

    it('should have no accessibility violations in interactive states', () => {
      // Test accessibility during user interaction
      cy.get('[data-testid="excavator-capacity-input"]').focus();
      cy.checkA11y();
      
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.wait(450);
      cy.checkA11y();
      
      // Test with validation error state
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('99999');
      cy.wait(200);
      cy.checkA11y();
    });
  });
});