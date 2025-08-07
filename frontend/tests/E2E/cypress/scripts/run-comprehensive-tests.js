#!/usr/bin/env node

/**
 * Comprehensive E2E Test Runner
 * Runs all E2E tests across multiple browsers and generates reports
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class TestRunner {
  constructor() {
    this.results = {
      startTime: new Date().toISOString(),
      browsers: {},
      testSuites: {},
      summary: {}
    };
    
    this.browsers = ['chrome', 'firefox', 'edge'];
    this.testSuites = {
      'user-journeys': 'tests/E2E/cypress/integration/user-journeys.spec.js',
      'performance': 'tests/E2E/cypress/integration/performance-validation.spec.js',
      'accessibility': 'tests/E2E/cypress/integration/accessibility.spec.js',
      'error-handling': 'tests/E2E/cypress/integration/error-handling.spec.js',
      'mobile-workflows': 'tests/E2E/cypress/integration/mobile-device-workflows.spec.js',
      'cross-browser': 'tests/E2E/cypress/integration/cross-browser.spec.js',
      'visual-regression': 'tests/E2E/cypress/integration/visual-regression.spec.js'
    };
  }

  async run() {
    console.log('🚀 Starting Comprehensive E2E Test Suite');
    console.log('==========================================');
    
    try {
      // Run tests for each browser
      for (const browser of this.browsers) {
        await this.runBrowserTests(browser);
      }
      
      // Generate comprehensive report
      await this.generateReport();
      
      console.log('✅ All tests completed successfully!');
      process.exit(0);
      
    } catch (error) {
      console.error('❌ Test suite failed:', error.message);
      process.exit(1);
    }
  }

  async runBrowserTests(browser) {
    console.log(`\n🔍 Testing with ${browser.toUpperCase()}`);
    console.log('-'.repeat(40));
    
    this.results.browsers[browser] = {
      startTime: new Date().toISOString(),
      tests: {},
      summary: { passed: 0, failed: 0, total: 0 }
    };

    for (const [suiteName, specFile] of Object.entries(this.testSuites)) {
      console.log(`  📋 Running ${suiteName} tests...`);
      
      try {
        const startTime = Date.now();
        
        const command = `npx cypress run --browser ${browser} --spec "${specFile}" --reporter json --quiet`;
        const result = execSync(command, { 
          encoding: 'utf8',
          stdio: 'pipe'
        });
        
        const duration = Date.now() - startTime;
        
        // Parse Cypress JSON output
        const testResult = this.parseCypressOutput(result);
        
        this.results.browsers[browser].tests[suiteName] = {
          status: 'passed',
          duration,
          ...testResult
        };
        
        this.results.browsers[browser].summary.passed++;
        console.log(`    ✅ ${suiteName} passed (${duration}ms)`);
        
      } catch (error) {
        this.results.browsers[browser].tests[suiteName] = {
          status: 'failed',
          error: error.message
        };
        
        this.results.browsers[browser].summary.failed++;
        console.log(`    ❌ ${suiteName} failed`);
      }
      
      this.results.browsers[browser].summary.total++;
    }

    const browserSummary = this.results.browsers[browser].summary;
    console.log(`\n  📊 ${browser} Summary: ${browserSummary.passed}/${browserSummary.total} passed`);
  }

  parseCypressOutput(output) {
    try {
      const jsonOutput = JSON.parse(output);
      return {
        tests: jsonOutput.tests?.length || 0,
        passes: jsonOutput.stats?.passes || 0,
        failures: jsonOutput.stats?.failures || 0,
        duration: jsonOutput.stats?.duration || 0
      };
    } catch {
      return {
        tests: 0,
        passes: 0,
        failures: 0,
        duration: 0
      };
    }
  }

  async generateReport() {
    console.log('\n📊 Generating Comprehensive Report');
    console.log('-'.repeat(40));
    
    // Calculate overall summary
    let totalPassed = 0;
    let totalFailed = 0;
    let totalTests = 0;
    
    for (const [browser, results] of Object.entries(this.results.browsers)) {
      totalPassed += results.summary.passed;
      totalFailed += results.summary.failed;
      totalTests += results.summary.total;
    }
    
    this.results.summary = {
      totalTests,
      totalPassed,
      totalFailed,
      passRate: ((totalPassed / totalTests) * 100).toFixed(1),
      endTime: new Date().toISOString()
    };
    
    // Generate HTML report
    const htmlReport = this.generateHtmlReport();
    const reportPath = path.join(__dirname, '../reports/comprehensive-report.html');
    
    // Ensure reports directory exists
    const reportsDir = path.dirname(reportPath);
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }
    
    fs.writeFileSync(reportPath, htmlReport);
    
    // Generate JSON report for CI/CD
    const jsonReportPath = path.join(__dirname, '../reports/test-results.json');
    fs.writeFileSync(jsonReportPath, JSON.stringify(this.results, null, 2));
    
    // Console summary
    console.log(`\n🎯 Final Results:`);
    console.log(`   Total Tests: ${totalTests}`);
    console.log(`   Passed: ${totalPassed}`);
    console.log(`   Failed: ${totalFailed}`);
    console.log(`   Pass Rate: ${this.results.summary.passRate}%`);
    console.log(`\n📋 Reports generated:`);
    console.log(`   HTML: ${reportPath}`);
    console.log(`   JSON: ${jsonReportPath}`);
    
    if (totalFailed > 0) {
      throw new Error(`${totalFailed} test suites failed`);
    }
  }

  generateHtmlReport() {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pond Digging Calculator - E2E Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { border-bottom: 2px solid #2196F3; padding-bottom: 20px; margin-bottom: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 15px; border-radius: 6px; text-align: center; }
        .metric h3 { margin: 0 0 10px 0; color: #495057; }
        .metric .value { font-size: 24px; font-weight: bold; color: #2196F3; }
        .browser-section { margin-bottom: 30px; }
        .browser-header { background: #e3f2fd; padding: 15px; border-radius: 6px; margin-bottom: 15px; }
        .test-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; }
        .test-card { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 6px; padding: 15px; }
        .test-card.passed { border-left: 4px solid #28a745; }
        .test-card.failed { border-left: 4px solid #dc3545; }
        .test-name { font-weight: bold; margin-bottom: 8px; }
        .test-status { font-size: 12px; text-transform: uppercase; padding: 4px 8px; border-radius: 4px; }
        .status-passed { background: #d4edda; color: #155724; }
        .status-failed { background: #f8d7da; color: #721c24; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #dee2e6; text-align: center; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Pond Digging Calculator E2E Test Report</h1>
            <p>Generated on ${new Date(this.results.summary.endTime).toLocaleString()}</p>
        </div>
        
        <div class="summary">
            <div class="metric">
                <h3>Total Tests</h3>
                <div class="value">${this.results.summary.totalTests}</div>
            </div>
            <div class="metric">
                <h3>Passed</h3>
                <div class="value" style="color: #28a745">${this.results.summary.totalPassed}</div>
            </div>
            <div class="metric">
                <h3>Failed</h3>
                <div class="value" style="color: #dc3545">${this.results.summary.totalFailed}</div>
            </div>
            <div class="metric">
                <h3>Pass Rate</h3>
                <div class="value">${this.results.summary.passRate}%</div>
            </div>
        </div>
        
        ${Object.entries(this.results.browsers).map(([browser, data]) => `
            <div class="browser-section">
                <div class="browser-header">
                    <h2>🌐 ${browser.toUpperCase()} Results</h2>
                    <p>${data.summary.passed}/${data.summary.total} test suites passed</p>
                </div>
                
                <div class="test-grid">
                    ${Object.entries(data.tests).map(([testName, testData]) => `
                        <div class="test-card ${testData.status}">
                            <div class="test-name">${testName.replace('-', ' ').toUpperCase()}</div>
                            <div class="test-status status-${testData.status}">${testData.status}</div>
                            ${testData.duration ? `<div style="margin-top: 8px; font-size: 12px; color: #6c757d;">Duration: ${testData.duration}ms</div>` : ''}
                            ${testData.error ? `<div style="margin-top: 8px; font-size: 12px; color: #dc3545;">${testData.error}</div>` : ''}
                        </div>
                    `).join('')}
                </div>
            </div>
        `).join('')}
        
        <div class="footer">
            <p>Generated by Pond Digging Calculator Comprehensive Test Suite</p>
            <p>Testing: User Journeys • Performance • Accessibility • Error Handling • Mobile Workflows • Cross-Browser • Visual Regression</p>
        </div>
    </div>
</body>
</html>
    `.trim();
  }
}

// Run the comprehensive test suite
if (require.main === module) {
  const runner = new TestRunner();
  runner.run().catch(console.error);
}

module.exports = TestRunner;