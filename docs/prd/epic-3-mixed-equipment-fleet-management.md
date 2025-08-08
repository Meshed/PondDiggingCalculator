# Epic 3: Mixed Equipment Fleet Management

Add multi-equipment configuration capabilities for complex project scenarios on desktop/tablet interfaces, enabling construction professionals to model realistic job sites with different excavator and truck combinations while maintaining the simplified single-equipment approach on mobile devices.

## Story 3.1: Equipment Configuration File Structure
As a developer maintaining equipment defaults,
I want a clean, readable configuration file that's integrated at build time,
so that I can easily modify defaults without HTTP dependencies and deploy a truly standalone application.

### Acceptance Criteria
1. Create `/config/equipment-defaults.json` with clear structure for excavators, trucks, project defaults, fleet limits, and validation rules
2. File is well-commented and easily readable/editable by non-developers
3. JSON schema validates equipment default values and ranges
4. Build process integrates config file into application bundle (no runtime HTTP requests)
5. Configuration changes require rebuild and redeploy (no runtime config changes)

## Story 3.2: Static Configuration Integration
As a developer building a standalone application,
I want equipment defaults compiled into the application,
so that the app works without any external HTTP dependencies.

### Acceptance Criteria
1. Refactor `Utils.Config.elm` to import config statically instead of HTTP loading
2. Remove HTTP-related code and dependencies from config module
3. Maintain same Config type structure and fallback behavior
4. Build process successfully embeds config into Elm application
5. Application works identically but without network dependencies

## Story 3.3: Equipment Fleet Data Model
As a developer,
I want to implement flexible data structures for multiple equipment configurations,
so that the application can handle complex fleet scenarios while maintaining calculation accuracy.

### Acceptance Criteria
1. Data model supports multiple excavators with varying bucket capacities and cycle times
2. Data model supports multiple trucks with varying capacities and round-trip times
3. Fleet configurations maintain immutable functional programming patterns
4. Add/remove equipment operations preserve calculation state and user inputs
5. Data validation ensures all equipment entries maintain positive numeric values

## Story 3.4: Desktop/Tablet Fleet Management Interface
As a construction estimator planning complex projects,
I want to add and configure multiple pieces of equipment,
so that I can model realistic job sites with mixed equipment fleets.

### Acceptance Criteria
1. "Add Excavator" and "Add Truck" buttons available on desktop/tablet interfaces only
2. Each equipment item displays in organized list with individual input fields
3. Remove buttons allow deletion of individual equipment items (minimum one of each type maintained)
4. Visual indicators distinguish different equipment items (numbering, icons, or grouping)
5. Interface remains usable and organized even with multiple equipment items

## Story 3.5: Mixed Fleet Calculation Engine
As a construction professional with varied equipment,
I want accurate timeline calculations that account for all my equipment working together,
so that I can create realistic project estimates for complex scenarios.

### Acceptance Criteria
1. Calculation engine processes multiple excavators working simultaneously
2. Calculation engine processes multiple trucks serving the excavation operation
3. Timeline calculation accounts for equipment coordination and potential bottlenecks
4. Mixed fleet calculations produce results consistent with single equipment calculations when one of each is used
5. Real-time updates work correctly as equipment is added, removed, or modified

## Story 3.6: Mobile Interface Preservation
As a mobile user,
I want to continue using the simple single-equipment interface,
so that my quick field calculations remain fast and uncomplicated.

### Acceptance Criteria
1. Mobile interface maintains single excavator and single truck inputs only
2. Fleet management features hidden/disabled on mobile breakpoints
3. Mobile calculations remain accurate and consistent with desktop single-equipment results
4. Switching from desktop mixed fleet to mobile preserves first equipment settings as defaults
5. Mobile interface performance unaffected by mixed fleet code complexity
