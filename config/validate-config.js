#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Load ajv from the frontend node_modules
const frontendDir = path.join(__dirname, '..', 'frontend');
const Ajv = require(path.join(frontendDir, 'node_modules', 'ajv'));

// Get the directory of this script
const configDir = __dirname;
const schemaPath = path.join(configDir, 'equipment-defaults.schema.json');
const configPath = path.join(configDir, 'equipment-defaults.json');

console.log('🔍 Validating equipment configuration...');

try {
  // Load schema and config files
  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

  // Initialize AJV validator
  const ajv = new Ajv({ allErrors: true, verbose: true });
  const validate = ajv.compile(schema);

  // Validate the configuration
  const valid = validate(config);

  if (valid) {
    console.log('✅ Configuration is valid!');
    console.log(`   Version: ${config.version}`);
    console.log(`   Excavators: ${config.defaults.excavators.length}`);
    console.log(`   Trucks: ${config.defaults.trucks.length}`);
    console.log(`   Fleet limits: ${config.fleetLimits.maxExcavators} excavators, ${config.fleetLimits.maxTrucks} trucks`);
    process.exit(0);
  } else {
    console.error('❌ Configuration validation failed!');
    console.error('Errors:');
    validate.errors.forEach((error, index) => {
      console.error(`  ${index + 1}. ${error.instancePath || 'root'}: ${error.message}`);
      if (error.data !== undefined) {
        console.error(`     Current value: ${JSON.stringify(error.data)}`);
      }
      if (error.params) {
        console.error(`     Details: ${JSON.stringify(error.params)}`);
      }
    });
    process.exit(1);
  }
} catch (error) {
  console.error('💥 Error during validation:');
  console.error(error.message);
  process.exit(1);
}