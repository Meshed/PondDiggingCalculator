#!/usr/bin/env node

/**
 * Build Validation Script
 * 
 * Purpose: Detect build cache issues and validate that builds contain expected features
 * Run after builds to ensure we're not serving stale assets
 */

const fs = require('fs')
const path = require('path')

const FRONTEND_DIR = path.join(__dirname, '../frontend')
const DIST_DIR = path.join(FRONTEND_DIR, 'dist')
const SRC_DIR = path.join(FRONTEND_DIR, 'src')

// Features that should be present in builds after Story 3.4
const REQUIRED_FEATURES = {
  'Fleet Management': [
    'EquipmentList.elm',
    'viewExcavatorFleet',
    'viewTruckFleet',
    'Add Excavator',
    'Add Truck'
  ],
  'Updated Architecture': [
    'Desktop.elm',
    'MobileView.elm', 
    'parseModelData'
  ]
}

function validateBuildExists() {
  if (!fs.existsSync(DIST_DIR)) {
    console.error('❌ Build directory not found. Run npm run build first.')
    process.exit(1)
  }
  
  const htmlFiles = fs.readdirSync(DIST_DIR).filter(f => f.endsWith('.html'))
  const jsFiles = fs.readdirSync(DIST_DIR).filter(f => f.endsWith('.js'))
  
  if (htmlFiles.length === 0) {
    console.error('❌ No HTML files found in build directory')
    process.exit(1)
  }
  
  if (jsFiles.length === 0) {
    console.error('❌ No JavaScript files found in build directory')  
    process.exit(1)
  }
  
  console.log(`✅ Build directory contains ${htmlFiles.length} HTML and ${jsFiles.length} JS files`)
}

function validateSourceFeatures() {
  console.log('🔍 Validating source code features...')
  
  // Check that critical files exist
  const criticalFiles = [
    'src/Components/EquipmentList.elm',
    'src/Pages/Desktop.elm', 
    'src/Views/MobileView.elm'
  ]
  
  for (const file of criticalFiles) {
    const fullPath = path.join(FRONTEND_DIR, file)
    if (!fs.existsSync(fullPath)) {
      console.error(`❌ Critical file missing: ${file}`)
      process.exit(1) 
    }
  }
  
  // Check that EquipmentList contains fleet functions
  const equipmentListPath = path.join(FRONTEND_DIR, 'src/Components/EquipmentList.elm')
  const equipmentListContent = fs.readFileSync(equipmentListPath, 'utf8')
  
  const requiredFunctions = ['viewExcavatorFleet', 'viewTruckFleet', 'Add Excavator', 'Add Truck']
  for (const func of requiredFunctions) {
    if (!equipmentListContent.includes(func)) {
      console.error(`❌ EquipmentList.elm missing required feature: ${func}`)
      process.exit(1)
    }
  }
  
  console.log('✅ All critical source features present')
}

function validateBuildContent() {
  console.log('🔍 Validating build content...')
  
  // Read the main JavaScript bundle
  const jsFiles = fs.readdirSync(DIST_DIR).filter(f => f.endsWith('.js'))
  let bundleContent = ''
  
  for (const jsFile of jsFiles) {
    const content = fs.readFileSync(path.join(DIST_DIR, jsFile), 'utf8')
    bundleContent += content
  }
  
  // Check for key functions that indicate fleet management is compiled in
  const requiredInBundle = [
    'viewExcavatorFleet', 
    'viewTruckFleet',
    'shouldShowAdvancedFeatures'
  ]
  
  const missing = requiredInBundle.filter(feature => !bundleContent.includes(feature))
  
  if (missing.length > 0) {
    console.error(`❌ Build bundle missing features: ${missing.join(', ')}`)
    console.error('   This indicates a build cache issue or compilation problem')
    process.exit(1)
  }
  
  console.log('✅ Build bundle contains all required features')
}

function checkBuildFreshness() {
  console.log('🔍 Checking build freshness...')
  
  // Get the newest source file timestamp  
  function getNewestFileTime(dir) {
    let newest = 0
    
    function scan(currentDir) {
      const items = fs.readdirSync(currentDir)
      for (const item of items) {
        const fullPath = path.join(currentDir, item)
        const stat = fs.statSync(fullPath)
        
        if (stat.isDirectory() && !item.includes('node_modules')) {
          scan(fullPath)
        } else if (stat.isFile() && (item.endsWith('.elm') || item.endsWith('.js'))) {
          newest = Math.max(newest, stat.mtime.getTime())
        }
      }
    }
    
    scan(dir)
    return newest
  }
  
  const newestSourceTime = getNewestFileTime(SRC_DIR)
  
  // Get build file timestamps
  const jsFiles = fs.readdirSync(DIST_DIR).filter(f => f.endsWith('.js'))
  let oldestBuildTime = Date.now()
  
  for (const jsFile of jsFiles) {
    const stat = fs.statSync(path.join(DIST_DIR, jsFile))
    oldestBuildTime = Math.min(oldestBuildTime, stat.mtime.getTime())
  }
  
  if (newestSourceTime > oldestBuildTime) {
    console.error('❌ Build appears stale - source files are newer than build files')
    console.error('   Run npm run build:clean to force a clean rebuild')
    process.exit(1)
  }
  
  console.log('✅ Build appears fresh')
}

// Main execution
console.log('🏗️  Starting build validation...\n')

try {
  validateBuildExists()
  validateSourceFeatures() 
  validateBuildContent()
  checkBuildFreshness()
  
  console.log('\n🎉 Build validation passed! All features present and build is fresh.')
  
} catch (error) {
  console.error('\n💥 Build validation failed:', error.message)
  process.exit(1)
}