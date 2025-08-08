// Custom Cypress commands for accessibility testing

// Add axe-core support for accessibility testing
import 'cypress-axe';

// Enhanced tab navigation command
Cypress.Commands.add('tab', { prevSubject: 'optional' }, (subject, options = {}) => {
  const key = options.shift ? '{shift}{tab}' : '{tab}';
  
  if (subject) {
    cy.wrap(subject).type(key);
  } else {
    cy.focused().type(key);
  }
  
  return cy.focused();
});

// Check for visible focus indicator
Cypress.Commands.add('shouldHaveVisibleFocus', { prevSubject: true }, (subject) => {
  cy.wrap(subject).should($el => {
    const computedStyle = window.getComputedStyle($el[0]);
    
    const hasOutline = computedStyle.outlineStyle !== 'none' && computedStyle.outlineWidth !== '0px';
    const hasBorder = computedStyle.borderStyle !== 'none' && computedStyle.borderWidth !== '0px';
    const hasBoxShadow = computedStyle.boxShadow !== 'none';
    const hasCustomFocus = $el.hasClass('focus') || $el.hasClass('focused') || $el.attr('data-focus');
    
    const hasVisibleFocus = hasOutline || hasBorder || hasBoxShadow || hasCustomFocus;
    
    expect(hasVisibleFocus, 'Element should have visible focus indicator').to.be.true;
  });
});

// Check for accessible name
Cypress.Commands.add('shouldHaveAccessibleName', { prevSubject: true }, (subject) => {
  cy.wrap(subject).should($el => {
    const element = $el[0];
    
    const ariaLabel = element.getAttribute('aria-label');
    const ariaLabelledBy = element.getAttribute('aria-labelledby');
    const title = element.getAttribute('title');
    const placeholder = element.getAttribute('placeholder');
    
    let labelText = '';
    if (ariaLabelledBy) {
      const labelElement = document.getElementById(ariaLabelledBy);
      labelText = labelElement ? labelElement.textContent.trim() : '';
    }
    
    const associatedLabel = document.querySelector(`label[for="${element.id}"]`);
    const labelFromFor = associatedLabel ? associatedLabel.textContent.trim() : '';
    
    const wrappingLabel = element.closest('label');
    const labelFromWrapper = wrappingLabel ? wrappingLabel.textContent.trim() : '';
    
    const accessibleName = ariaLabel || labelText || labelFromFor || labelFromWrapper || title || placeholder;
    
    expect(accessibleName, 'Element should have an accessible name').to.not.be.empty;
  });
});

// Check ARIA live region functionality
Cypress.Commands.add('shouldAnnounceChanges', { prevSubject: true }, (subject) => {
  cy.wrap(subject).should($el => {
    const element = $el[0];
    
    const hasAriaLive = element.getAttribute('aria-live');
    const hasRole = ['status', 'alert', 'log'].includes(element.getAttribute('role'));
    const parentHasLive = element.closest('[aria-live]') !== null;
    
    const canAnnounce = hasAriaLive || hasRole || parentHasLive;
    
    expect(canAnnounce, 'Element should be able to announce changes to screen readers').to.be.true;
  });
});

// Comprehensive accessibility check
Cypress.Commands.add('checkAccessibilityCompliance', () => {
  // Check for basic accessibility requirements
  cy.get('img').each($img => {
    cy.wrap($img).should($el => {
      const alt = $el.attr('alt');
      const ariaLabel = $el.attr('aria-label');
      const ariaHidden = $el.attr('aria-hidden') === 'true';
      const role = $el.attr('role');
      
      if (!ariaHidden && role !== 'presentation') {
        expect(alt !== undefined || ariaLabel, 'Images should have alt text or aria-label').to.be.true;
      }
    });
  });
  
  // Check form controls have labels
  cy.get('input, select, textarea').each($control => {
    cy.wrap($control).shouldHaveAccessibleName();
  });
  
  // Check headings are properly structured
  cy.get('h1, h2, h3, h4, h5, h6, [role="heading"]').then($headings => {
    if ($headings.length > 0) {
      let previousLevel = 0;
      
      $headings.each((index, heading) => {
        const level = parseInt(heading.tagName?.replace('H', '')) || 
                     parseInt(heading.getAttribute('aria-level')) || 1;
        
        if (index === 0) {
          expect(level).to.equal(1, 'First heading should be h1');
        } else {
          expect(level - previousLevel).to.be.at.most(1, 
            'Heading levels should not skip (e.g., h1 -> h3)');
        }
        
        previousLevel = level;
      });
    }
  });
});

// Keyboard navigation testing
Cypress.Commands.add('testKeyboardNavigation', () => {
  // Get all focusable elements
  cy.get('a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])').then($focusable => {
    if ($focusable.length === 0) return;
    
    // Start from first element
    cy.wrap($focusable.first()).focus();
    
    // Tab through all elements
    for (let i = 1; i < $focusable.length; i++) {
      cy.focused().tab();
    }
    
    // Test shift+tab backwards
    for (let i = $focusable.length - 2; i >= 0; i--) {
      cy.focused().tab({ shift: true });
    }
  });
});

// Screen reader simulation helpers
Cypress.Commands.add('simulateScreenReader', () => {
  cy.window().then(win => {
    // Add screen reader simulation class
    win.document.body.classList.add('screen-reader-simulation');
    
    // Hide visual elements that shouldn't be announced
    const style = win.document.createElement('style');
    style.textContent = `
      .screen-reader-simulation *:not([aria-hidden="false"]) {
        opacity: 0.1;
      }
      .screen-reader-simulation [aria-live],
      .screen-reader-simulation [role="status"],
      .screen-reader-simulation [role="alert"] {
        opacity: 1;
        border: 2px solid red;
      }
    `;
    win.document.head.appendChild(style);
  });
});

// Color contrast checking
Cypress.Commands.add('checkColorContrast', { prevSubject: true }, (subject) => {
  cy.wrap(subject).should($el => {
    const element = $el[0];
    const computedStyle = window.getComputedStyle(element);
    
    const color = computedStyle.color;
    const backgroundColor = computedStyle.backgroundColor;
    
    // Basic contrast check - ensure they're not identical
    expect(color).to.not.equal(backgroundColor, 'Text and background colors should differ');
    
    // Log for manual review
    console.log(`Color contrast check: color=${color}, background=${backgroundColor}`);
  });
});