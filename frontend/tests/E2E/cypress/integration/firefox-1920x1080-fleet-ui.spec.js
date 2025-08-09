/// <reference types="cypress" />

describe('Firefox 1920x1080 Fleet UI Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    // Set exact Firefox 1920x1080 resolution
    cy.viewport(1920, 1080);
  });

  context('Critical Issue Detection', () => {
    it('should identify missing fleet management UI on large desktop screens', () => {
      // This test SHOULD FAIL initially - it's designed to catch the integration issue
      
      // Verify we're on a large desktop screen
      cy.window().then((win) => {
        expect(win.innerWidth).to.equal(1920);
        expect(win.innerHeight).to.equal(1080);
      });

      // Check device type detection
      cy.get('[data-testid="device-type"]').should('be.visible');

      // Critical Test: Fleet management UI should be present on 1920x1080
      // These selectors WILL FAIL because the fleet UI isn't actually shown
      cy.get('body').then($body => {
        const hasFleetUI = $body.find('[data-testid="add-excavator-btn"]').length > 0;
        const hasExcavatorList = $body.find('[data-testid="excavator-list"]').length > 0;
        const hasTruckList = $body.find('[data-testid="truck-list"]').length > 0;
        
        if (!hasFleetUI) {
          cy.log('❌ CRITICAL ISSUE: Fleet management UI not found on 1920x1080 screen');
          cy.log('Expected: Fleet management buttons and lists should be visible');
          cy.log('Actual: Only basic ProjectForm visible');
          
          // Log what's actually present
          const hasProjectForm = $body.find('[data-testid*="input"]').length > 0;
          const hasResults = $body.find('[data-testid="timeline-result"]').length > 0;
          
          cy.log(`Present components: ProjectForm=${hasProjectForm}, Results=${hasResults}`);
          cy.log('Diagnosis: Main.elm is not using Pages/Desktop.elm view');
        }
        
        // This assertion will fail and highlight the issue
        expect(hasFleetUI, 'Fleet management UI should be visible on desktop').to.be.true;
      });
    });

    it('should detect device type correctly for 1920x1080', () => {
      // Verify device detection logic is working
      cy.window().then((win) => {
        // Check viewport dimensions
        expect(win.innerWidth).to.be.greaterThan(1024);
        
        // Based on DeviceType.elm logic: width > 1024 = Desktop
        const expectedDeviceType = win.innerWidth > 1024 ? 'Desktop' : 
                                   win.innerWidth > 768 ? 'Tablet' : 'Mobile';
        
        cy.log(`Window size: ${win.innerWidth}x${win.innerHeight}`);
        cy.log(`Expected device type: ${expectedDeviceType}`);
      });

      // Check if device type is being displayed (might not be visible in current impl)
      cy.get('body').then($body => {
        const deviceTypeElement = $body.find('[data-testid="device-type"]');
        if (deviceTypeElement.length > 0) {
          cy.wrap(deviceTypeElement).should('contain', 'Desktop');
        } else {
          cy.log('⚠️ Device type indicator not found in DOM');
        }
      });
    });
  });

  context('Current Implementation Analysis', () => {
    it('should document what is actually shown on 1920x1080', () => {
      // Comprehensive analysis of current UI state
      cy.get('body').then($body => {
        const analysis = {
          viewport: { width: 1920, height: 1080 },
          elements: {
            projectForm: $body.find('[data-testid*="input"]').length,
            calculationResults: $body.find('[data-testid="timeline"]').length,
            fleetManagement: {
              addButtons: $body.find('[data-testid*="add-"]').length,
              equipmentLists: $body.find('[data-testid*="-list"]').length,
              removeButtons: $body.find('[data-testid*="remove-"]').length
            },
            navigation: $body.find('nav').length,
            headers: $body.find('h1, h2, h3').length
          },
          textContent: {
            hasFleetTerminology: $body.text().toLowerCase().includes('fleet'),
            hasExcavatorPlural: $body.text().toLowerCase().includes('excavators'),
            hasTruckPlural: $body.text().toLowerCase().includes('trucks')
          }
        };

        cy.log('=== CURRENT UI ANALYSIS ===');
        cy.log('Viewport:', analysis.viewport);
        cy.log('Input Elements:', analysis.elements.projectForm);
        cy.log('Fleet Management Elements:');
        cy.log('- Add Buttons:', analysis.elements.fleetManagement.addButtons);
        cy.log('- Equipment Lists:', analysis.elements.fleetManagement.equipmentLists);
        cy.log('- Remove Buttons:', analysis.elements.fleetManagement.removeButtons);
        cy.log('Fleet Terminology Present:', analysis.textContent.hasFleetTerminology);

        // Save analysis for debugging
        cy.writeFile('cypress/results/ui-analysis-1920x1080.json', analysis);
      });
    });

    it('should identify which view is currently being used', () => {
      // Check for specific CSS classes or structure that indicates which view
      cy.get('body').then($body => {
        const hasDesktopPageStructure = $body.find('.grid.grid-cols-3').length > 0; // Desktop page layout
        const hasMobileStructure = $body.find('[data-testid="simplified-interface"]').length > 0;
        const hasGenericStructure = $body.find('.container.mx-auto').length > 0; // Main.elm structure

        const viewAnalysis = {
          structures: {
            desktopPage: hasDesktopPageStructure,
            mobileView: hasMobileStructure,
            mainElmGeneric: hasGenericStructure
          },
          diagnosis: hasDesktopPageStructure ? 'Pages/Desktop.elm' :
                    hasMobileStructure ? 'Views/MobileView.elm' :
                    hasGenericStructure ? 'Main.elm basic view' : 'Unknown view'
        };

        cy.log('=== VIEW IDENTIFICATION ===');
        cy.log('Desktop Page Structure:', viewAnalysis.structures.desktopPage);
        cy.log('Mobile View Structure:', viewAnalysis.structures.mobileView);
        cy.log('Main.elm Generic Structure:', viewAnalysis.structures.mainElmGeneric);
        cy.log('Current View:', viewAnalysis.diagnosis);

        // This will help confirm the diagnosis
        if (viewAnalysis.diagnosis === 'Main.elm basic view') {
          cy.log('✅ CONFIRMED: Using Main.elm basic view instead of Pages/Desktop.elm');
          cy.log('🔧 SOLUTION: Update Main.elm to use Pages.Desktop.view for Desktop/Tablet');
        }
      });
    });
  });

  context('Missing Features Documentation', () => {
    it('should list expected fleet management features that are missing', () => {
      const expectedFeatures = [
        'Add Excavator button',
        'Add Truck button', 
        'Multiple excavator display',
        'Multiple truck display',
        'Equipment removal buttons',
        'Equipment numbering (Excavator 1, 2, etc.)',
        'Equipment name fields',
        'Fleet section headers',
        'Visual equipment indicators',
        'Fleet limits enforcement UI'
      ];

      expectedFeatures.forEach(feature => {
        cy.log(`❌ Missing: ${feature}`);
      });

      // Document what should be present
      cy.writeFile('cypress/results/missing-features-1920x1080.json', {
        resolution: '1920x1080',
        browser: 'Firefox',
        expectedFeatures,
        issue: 'Fleet management UI not integrated into Main.elm view',
        solution: 'Update Main.elm to use Pages.Desktop.view instead of inline view'
      });
    });
  });

  context('Firefox-Specific Testing', () => {
    it('should work correctly in Firefox browser', () => {
      // Test Firefox-specific behavior
      cy.window().then((win) => {
        const isFirefox = win.navigator.userAgent.toLowerCase().includes('firefox');
        if (isFirefox) {
          cy.log('✅ Running in Firefox browser');
          
          // Test that device detection works in Firefox
          expect(win.innerWidth).to.equal(1920);
          expect(win.innerHeight).to.equal(1080);
          
          // Test that basic functionality works
          cy.get('[data-testid="pond-length-input"]')
            .should('be.visible')
            .clear()
            .type('50');
            
          cy.get('[data-testid="pond-width-input"]')
            .clear()
            .type('30');
            
          cy.wait(500);
          
          // Should show calculation results
          cy.get('body').then($body => {
            const hasResults = $body.find('[data-testid*="timeline"]').length > 0;
            if (hasResults) {
              cy.log('✅ Basic calculations working in Firefox');
            }
          });
        } else {
          cy.log('⚠️ Not running in Firefox - test may behave differently');
        }
      });
    });

    it('should handle Firefox viewport changes correctly', () => {
      // Test responsive behavior in Firefox
      const viewports = [
        { width: 1920, height: 1080, expected: 'Desktop' },
        { width: 1024, height: 768, expected: 'Tablet' },
        { width: 768, height: 1024, expected: 'Mobile' },
        { width: 1920, height: 1080, expected: 'Desktop' } // Return to original
      ];

      viewports.forEach((viewport, index) => {
        cy.viewport(viewport.width, viewport.height);
        cy.wait(500); // Allow for resize handling
        
        cy.window().then((win) => {
          cy.log(`Viewport ${index + 1}: ${viewport.width}x${viewport.height} (expected: ${viewport.expected})`);
          
          // The current implementation might not show device type
          // but we can infer it from the view structure
          cy.get('body').then($body => {
            const isMobileView = $body.find('[data-testid="simplified-interface"]').length > 0;
            const actualType = isMobileView ? 'Mobile' : 'Desktop/Tablet';
            
            cy.log(`Detected view type: ${actualType}`);
            
            if (viewport.expected === 'Mobile') {
              // For mobile, should use MobileView
              expect(isMobileView).to.be.true;
            } else {
              // For Desktop/Tablet, should NOT be mobile view
              // Note: Both Desktop and Tablet use the same view in current impl
              expect(isMobileView).to.be.false;
            }
          });
        });
      });
    });
  });

  context('Integration Test Recommendations', () => {
    it('should provide specific fix recommendations', () => {
      const recommendations = {
        primaryIssue: 'Fleet management UI implemented in Pages/Desktop.elm but not used by Main.elm',
        immediateAction: 'Update Main.elm view function to use Pages.Desktop.view',
        codeChanges: {
          file: 'frontend/src/Main.elm',
          change: 'Import Pages.Desktop and use Desktop.view model instead of inline view',
          affectedLines: 'view function around lines 580-630'
        },
        testingRequired: [
          'Verify fleet buttons appear on 1920x1080',
          'Test device detection continues working',
          'Ensure mobile view still uses MobileView.view',
          'Validate fleet operations work end-to-end'
        ],
        riskAssessment: 'Low risk - Fleet logic already implemented, just needs UI integration'
      };

      cy.log('=== FIX RECOMMENDATIONS ===');
      Object.entries(recommendations).forEach(([key, value]) => {
        cy.log(`${key}:`, value);
      });

      cy.writeFile('cypress/results/fix-recommendations.json', recommendations);
    });
  });
});