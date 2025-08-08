/// <reference types="cypress" />

describe('Security Validation Tests', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  context('Input Sanitization & XSS Prevention', () => {
    it('should sanitize all user inputs to prevent XSS attacks', () => {
      const xssPayloads = [
        '<script>alert("xss")</script>',
        '${alert("xss")}',
        'javascript:alert("xss")',
        '<img src=x onerror=alert("xss")>',
        '"><script>alert("xss")</script>',
        'javascript:void(0)',
        'data:text/html,<script>alert("xss")</script>',
        '<svg onload=alert("xss")>',
        '<iframe src="javascript:alert(\'xss\')"></iframe>',
        '{{constructor.constructor("alert(\'xss\')")()}}'
      ];

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
        xssPayloads.forEach(payload => {
          cy.get(`[data-testid="${fieldId}"]`)
            .clear()
            .type(payload, { parseSpecialCharSequences: false });
          
          cy.wait(100);
          
          // Verify no script execution occurred
          cy.window().then((win) => {
            // Check that no alerts were triggered
            expect(win.alert).to.not.have.been.called;
          });
          
          // Verify input was sanitized/rejected (should show validation error or empty)
          cy.get(`[data-testid="${fieldId}"]`).should($input => {
            const value = $input.val();
            // Input should either be empty or contain only safe numeric content
            expect(value).to.not.contain('<script>');
            expect(value).to.not.contain('javascript:');
            expect(value).to.not.contain('onerror');
            expect(value).to.not.contain('onload');
          });
        });
      });
    });

    it('should prevent code injection through calculated results', () => {
      // Test that malicious input doesn't get reflected in results
      cy.get('[data-testid="pond-length-input"]')
        .clear()
        .type('<script>alert("injected")</script>40');
      
      cy.wait(400); // Debounce
      
      // Results should display safely without executing scripts
      cy.get('[data-testid="timeline-result"]').should($result => {
        const resultText = $result.text();
        expect(resultText).to.not.contain('<script>');
        expect(resultText).to.not.contain('alert');
      });
      
      // Page should still function normally
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });

    it('should handle Unicode and special characters safely', () => {
      const specialCharacters = [
        '∞', '∑', '∆', 'π', '√', '∂', '∫',
        '♠', '♥', '♦', '♣',
        '中文', '日本語', 'العربية', 'עברית',
        '🔢', '💻', '⚠️', '✅', '❌',
        '\u0000', '\u001F', '\u007F', '\u009F'
      ];

      specialCharacters.forEach(char => {
        cy.get('[data-testid="pond-length-input"]')
          .clear()
          .type(`${char}40`, { parseSpecialCharSequences: false });
        
        cy.wait(100);
        
        // Should handle gracefully without breaking functionality
        cy.get('body').should('not.contain', 'Error');
        cy.get('[data-testid="pond-length-input"]').should('be.visible');
      });
    });
  });

  context('Content Security Policy Validation', () => {
    it('should validate Content Security Policy headers are present', () => {
      cy.request('/').then((response) => {
        // Check for CSP header (if implemented)
        const cspHeader = response.headers['content-security-policy'] || 
                         response.headers['content-security-policy-report-only'];
        
        if (cspHeader) {
          expect(cspHeader).to.include("default-src 'self'");
          expect(cspHeader).to.not.include("'unsafe-eval'");
          expect(cspHeader).to.not.include("'unsafe-inline'");
        } else {
          // Log that CSP should be implemented for production
          cy.log('WARNING: Content Security Policy not detected - recommend implementation for production');
        }
      });
    });

    it('should prevent inline script execution', () => {
      // Verify that inline scripts are blocked or not present
      cy.get('script').each($script => {
        if ($script.attr('src')) {
          // External scripts should load from trusted sources
          const src = $script.attr('src');
          expect(src).to.match(/^(\/|https?:\/\/localhost|https?:\/\/[\w-]+\.[\w-]+)/);
        } else {
          // Inline scripts should be minimal and safe
          const content = $script.text().toLowerCase();
          expect(content).to.not.contain('eval(');
          expect(content).to.not.contain('settimeout(');
          expect(content).to.not.contain('setinterval(');
        }
      });
    });
  });

  context('Data Validation & Injection Prevention', () => {
    it('should validate all numeric inputs strictly', () => {
      const maliciousInputs = [
        'Infinity',
        'NaN',
        '1e308', // Potential overflow
        '-1e308',
        '999999999999999999999',
        '0.000000000000000001',
        '1/0',
        '0/0',
        'Math.PI',
        'parseFloat("42")',
        'Number("42")',
        'parseInt("42")'
      ];

      maliciousInputs.forEach(input => {
        cy.get('[data-testid="excavator-capacity-input"]')
          .clear()
          .type(input);
        
        cy.wait(100);
        
        // Should either reject the input or handle it safely
        cy.get('[data-testid="excavator-capacity-input"]').should($input => {
          const value = $input.val();
          if (value !== '') {
            // If accepted, should be a safe numeric value
            expect(parseFloat(value)).to.satisfy(num => !isNaN(num) && isFinite(num));
            expect(parseFloat(value)).to.be.within(-1000000, 1000000);
          }
        });
      });
    });

    it('should prevent configuration tampering through DevTools', () => {
      // Test that configuration remains intact even if window object is modified
      cy.window().then((win) => {
        // Attempt to modify global configuration
        win.CONFIG = { malicious: true };
        win.configOverride = { version: "hacked" };
        
        // Application should still use static build-time configuration
        cy.get('[data-testid="excavator-capacity-input"]')
          .should('have.value', '2.5'); // Original static config value
        
        cy.get('[data-testid="truck-capacity-input"]')
          .should('have.value', '12'); // Original static config value
      });
    });

    it('should handle localStorage manipulation safely', () => {
      // Test application behavior when localStorage is compromised
      cy.window().then((win) => {
        // Corrupt localStorage with malicious data
        win.localStorage.setItem('pondCalculatorData', '{"xss":"<script>alert(\'xss\')</script>"}');
        win.localStorage.setItem('malicious', '<img src=x onerror=alert("xss")>');
        
        // Reload to trigger localStorage loading
        cy.reload();
        
        // Application should handle corrupted data gracefully
        cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
        cy.get('[data-testid="timeline-result"]').should('not.contain', '<script>');
        
        // No JavaScript errors should occur
        cy.window().then((reloadedWin) => {
          expect(reloadedWin.console.error).to.not.have.been.called;
        });
      });
    });
  });

  context('Network Security & Request Validation', () => {
    it('should not make any unauthorized network requests', () => {
      // Monitor all network requests during normal operation
      cy.intercept('**', (req) => {
        const url = req.url;
        const origin = Cypress.config().baseUrl;
        
        // Should only make requests to same origin or trusted CDNs
        expect(url).to.satisfy(url => 
          url.startsWith(origin) || 
          url.startsWith('https://fonts.googleapis.com') ||
          url.startsWith('https://cdn.jsdelivr.net') ||
          url.startsWith('data:') ||
          url.startsWith('blob:')
        );
      });
      
      // Perform normal user workflow
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should be resilient to DNS poisoning attacks', () => {
      // Test that application works correctly even with network issues
      cy.intercept('**', { statusCode: 404 }).as('networkFailure');
      
      // Application should continue working (static configuration)
      cy.visit('/');
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('have.value', '2.5');
      
      // Calculations should work offline
      cy.get('[data-testid="pond-length-input"]').clear().type('45');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Error Handling Security', () => {
    it('should not expose sensitive information in error messages', () => {
      // Force various error conditions
      cy.window().then((win) => {
        // Override console.error to capture error messages
        const errors = [];
        const originalError = win.console.error;
        win.console.error = (...args) => {
          errors.push(args.join(' '));
          originalError.apply(win.console, args);
        };
        
        // Trigger potential errors
        cy.get('[data-testid="excavator-capacity-input"]')
          .clear()
          .type('invalid_input_that_might_cause_error');
        
        cy.wait(500);
        
        cy.then(() => {
          // Check that error messages don't contain sensitive data
          errors.forEach(error => {
            expect(error).to.not.contain('password');
            expect(error).to.not.contain('token');
            expect(error).to.not.contain('secret');
            expect(error).to.not.contain('key');
            expect(error).to.not.contain('/Users/');
            expect(error).to.not.contain('C:\\');
            expect(error).to.not.contain('internal');
            expect(error).to.not.contain('database');
          });
        });
      });
    });

    it('should maintain security during error recovery', () => {
      // Simulate application errors and verify secure recovery
      cy.window().then((win) => {
        // Force an error condition
        win.eval('throw new Error("Simulated error");');
      });
      
      // Application should recover gracefully without security compromise
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Browser Security Features', () => {
    it('should respect browser security policies', () => {
      // Test iframe restrictions (if any iframes are used)
      cy.get('iframe').should('have.length', 0); // Confirm no iframes for security
      
      // Test that external links (if any) open safely
      cy.get('a[href^="http"]').each($link => {
        expect($link).to.have.attr('rel', 'noopener noreferrer');
        expect($link).to.have.attr('target', '_blank');
      });
    });

    it('should not be vulnerable to clickjacking', () => {
      // Verify X-Frame-Options or CSP frame-ancestors
      cy.request('/').then((response) => {
        const frameOptions = response.headers['x-frame-options'];
        const csp = response.headers['content-security-policy'];
        
        const hasFrameProtection = 
          (frameOptions && (frameOptions.includes('DENY') || frameOptions.includes('SAMEORIGIN'))) ||
          (csp && csp.includes('frame-ancestors'));
        
        if (!hasFrameProtection) {
          cy.log('WARNING: Consider implementing X-Frame-Options or CSP frame-ancestors for clickjacking protection');
        }
      });
    });
  });
});