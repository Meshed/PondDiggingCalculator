/// <reference types="cypress" />

describe('Debug Dev Server - Fleet UI Check', () => {
  it('should connect to your dev server and check for fleet UI', () => {
    // Connect to your actual dev server
    cy.visit('http://localhost:63989', { timeout: 10000 });
    cy.viewport(1920, 1080); // Your exact setup
    
    cy.log('=== DEBUGGING DEV SERVER CONTENT ===');
    
    // Wait for page to load
    cy.wait(2000);
    
    // Check what's actually in the DOM
    cy.get('body').then($body => {
      const bodyText = $body.text();
      const hasFleetTerms = bodyText.toLowerCase().includes('fleet');
      const hasAddButtons = $body.find('[data-testid*="add-"]').length > 0;
      const hasDesktopGrid = $body.find('.grid-cols-3').length > 0;
      const hasExcavatorSection = bodyText.toLowerCase().includes('excavator');
      const hasTruckSection = bodyText.toLowerCase().includes('truck');
      
      cy.log('=== DOM ANALYSIS ===');
      cy.log(`Fleet terminology present: ${hasFleetTerms}`);
      cy.log(`Add buttons found: ${hasAddButtons}`);
      cy.log(`Desktop grid layout: ${hasDesktopGrid}`);
      cy.log(`Excavator section: ${hasExcavatorSection}`);
      cy.log(`Truck section: ${hasTruckSection}`);
      
      // Log all h1 and h2 elements
      const headers = [];
      $body.find('h1, h2').each((i, el) => {
        headers.push(el.textContent);
      });
      cy.log('Headers found:', headers);
      
      // Log all data-testid attributes
      const testIds = [];
      $body.find('[data-testid]').each((i, el) => {
        testIds.push(el.getAttribute('data-testid'));
      });
      cy.log('Test IDs found:', testIds);
      
      // Check specific fleet elements
      cy.log('=== FLEET ELEMENT CHECK ===');
      cy.log(`add-excavator-btn exists: ${$body.find('[data-testid="add-excavator-btn"]').length > 0}`);
      cy.log(`add-truck-btn exists: ${$body.find('[data-testid="add-truck-btn"]').length > 0}`);
      cy.log(`excavator-list exists: ${$body.find('[data-testid="excavator-list"]').length > 0}`);
      cy.log(`truck-list exists: ${$body.find('[data-testid="truck-list"]').length > 0}`);
    });
    
    // Check if we're getting the old version or new version
    cy.get('body').then($body => {
      const isOldVersion = $body.find('.container.mx-auto').length > 0 && $body.find('.grid-cols-3').length === 0;
      const isNewVersion = $body.find('.grid-cols-3').length > 0;
      
      if (isOldVersion) {
        cy.log('❌ SERVING OLD VERSION: Basic container layout without fleet');
        cy.log('Issue: Dev server may be serving cached version');
        cy.log('Solution: Hard refresh browser (Ctrl+Shift+R) or clear cache');
      } else if (isNewVersion) {
        cy.log('✅ SERVING NEW VERSION: Desktop grid layout with fleet management');
      } else {
        cy.log('❓ UNKNOWN VERSION: Unable to determine layout type');
      }
    });
    
    // Try to take a screenshot for visual debugging
    cy.screenshot('dev-server-debug', { 
      capture: 'fullPage',
      overwrite: true 
    });
    
    cy.log('Screenshot saved as dev-server-debug.png');
  });
  
  it('should check browser cache and force refresh', () => {
    // First load
    cy.visit('http://localhost:63989');
    cy.viewport(1920, 1080);
    
    // Check initial state
    cy.get('body').then($body1 => {
      const initialHasFleet = $body1.find('[data-testid="add-excavator-btn"]').length > 0;
      cy.log(`Initial load - Fleet UI present: ${initialHasFleet}`);
      
      if (!initialHasFleet) {
        cy.log('Fleet UI not found - trying cache bypass methods...');
        
        // Method 1: Reload with cache disabled
        cy.reload(true); // Force reload
        cy.wait(2000);
        
        cy.get('body').then($body2 => {
          const afterReload = $body2.find('[data-testid="add-excavator-btn"]').length > 0;
          cy.log(`After forced reload - Fleet UI present: ${afterReload}`);
          
          if (!afterReload) {
            // Method 2: Add cache busting parameter
            cy.visit('http://localhost:63989?v=' + Date.now());
            cy.wait(2000);
            
            cy.get('body').then($body3 => {
              const afterCacheBust = $body3.find('[data-testid="add-excavator-btn"]').length > 0;
              cy.log(`After cache bust - Fleet UI present: ${afterCacheBust}`);
            });
          }
        });
      } else {
        cy.log('✅ Fleet UI found on initial load!');
      }
    });
  });
  
  it('should verify dev server compilation is using latest code', () => {
    cy.visit('http://localhost:63989');
    cy.viewport(1920, 1080);
    
    // Check for evidence that Pages/Desktop.elm is being used
    const desktopPageIndicators = [
      '.grid-cols-3',                    // Desktop page layout
      'h2:contains("Excavator Fleet")',  // Desktop page headers
      'h2:contains("Truck Fleet")',      // Desktop page headers  
      '.max-w-7xl',                     // Desktop page max-width
      '[data-testid="add-excavator-btn"]' // Fleet management buttons
    ];
    
    const oldVersionIndicators = [
      '.container.mx-auto:not(.max-w-7xl)', // Old Main.elm container
      'h1:contains("Pond Digging Calculator"):not(.text-5xl)' // Basic header vs Desktop page header
    ];
    
    cy.log('=== CHECKING FOR DESKTOP PAGE INDICATORS ===');
    let desktopScore = 0;
    let oldScore = 0;
    
    desktopPageIndicators.forEach((selector, index) => {
      cy.get('body').then($body => {
        const found = $body.find(selector.replace(':contains', '')).length > 0;
        if (found) desktopScore++;
        cy.log(`${found ? '✅' : '❌'} Desktop indicator ${index + 1}: ${selector}`);
      });
    });
    
    cy.log('=== CHECKING FOR OLD VERSION INDICATORS ===');
    oldVersionIndicators.forEach((selector, index) => {
      cy.get('body').then($body => {
        const found = $body.find(selector.replace(':contains', '').replace(':not', '')).length > 0;
        if (found) oldScore++;
        cy.log(`${found ? '⚠️' : '✅'} Old version indicator ${index + 1}: ${selector}`);
      });
    });
    
    cy.then(() => {
      cy.log(`=== COMPILATION DIAGNOSIS ===`);
      cy.log(`Desktop page score: ${desktopScore}/${desktopPageIndicators.length}`);
      cy.log(`Old version score: ${oldScore}/${oldVersionIndicators.length}`);
      
      if (desktopScore >= 3) {
        cy.log('✅ DIAGNOSIS: Dev server is serving NEW version with Desktop page');
      } else if (oldScore >= 1) {
        cy.log('❌ DIAGNOSIS: Dev server is serving OLD version from cache');
        cy.log('SOLUTION: Stop dev server, clear .parcel-cache, restart server');
      } else {
        cy.log('❓ DIAGNOSIS: Unable to determine version');
      }
    });
  });
});