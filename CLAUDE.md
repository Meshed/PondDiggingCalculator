# Development Workflow for Claude Code

## Project Overview
Pond Digging Calculator - Elm frontend application with comprehensive cross-device testing and functionality validation.

## Development Standards

### Code Quality Validation Workflow
**CRITICAL**: Before marking any story as "Ready for Review", run ALL of the following validation steps:

1. **Format Check**: `npm run format:check` (validates elm-format compliance)
2. **Build Validation**: `npm run build` (ensures compilation succeeds)  
3. **Test Suite**: `npm run test` (all tests must pass)
4. **Full Validation**: `npm run validate` (runs all above in sequence)

### Available NPM Scripts
```bash
# Development
npm run dev              # Start development server
npm run build           # Production build

# Testing
npm test                # Run all tests
npm run test:watch      # Watch mode testing
npm run test:e2e        # Cypress E2E tests
npm run test:e2e:open   # Cypress UI

# Code Quality
npm run format          # Auto-format all Elm files
npm run format:check    # Validate formatting (fails if not formatted)
npm run lint            # Alias for format:check
npm run validate        # Complete validation: format + build + test
```

### Git Pre-commit Hook
A pre-commit hook is configured that automatically runs formatting validation and tests before allowing commits.

### Story Completion Checklist
When implementing stories, ensure:

- [ ] All task checkboxes marked [x]
- [ ] Code formatted with elm-format (`npm run format:check` passes)
- [ ] All tests passing (`npm test` succeeds)
- [ ] Build successful (`npm run build` works)
- [ ] Dev Agent Record updated with completion notes
- [ ] File List complete with all new/modified files
- [ ] Story status updated to "Ready for Review"

### Project Structure
```
frontend/
├── src/                 # Elm source code
├── tests/              # Test files (Unit, Integration, E2E)
├── public/             # Static assets and config
└── package.json        # Dependencies and scripts
```

### Testing Standards
- Unit tests: `frontend/tests/Unit/`
- Integration tests: `frontend/tests/Integration/`
- E2E tests: `frontend/tests/E2E/`
- All tests must pass before story completion
- Cross-device functionality must be validated for device-responsive features

### Development Notes
- Elm 0.19.1 with functional programming patterns
- Tailwind CSS for styling
- Cypress for E2E testing
- Real-time calculation updates within 100ms target
- Mobile/Tablet/Desktop responsive design with device-specific features