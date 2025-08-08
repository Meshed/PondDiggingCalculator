# Epic 3: Mixed Equipment Fleet Management

Add multi-equipment configuration capabilities for complex project scenarios on desktop/tablet interfaces, enabling construction professionals to model realistic job sites with different excavator and truck combinations while maintaining the simplified single-equipment approach on mobile devices.

## Epic Status: 75% Complete
- ✅ Story 3.1: Equipment Configuration File Structure (Done)
- ✅ Story 3.2: Static Configuration Integration (Done)  
- ⚠️ Story 3.3: Equipment Fleet Data Model (Done - requires alignment update)
- 🔄 Story 3.4: Desktop/Tablet Fleet Management Interface (Remaining)
- ❌ Story 3.5: Removed (redundant with 3.3)
- ❌ Story 3.6: Removed (redundant with 3.3)

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

### Prerequisites
- Story 3.1: Equipment Configuration File Structure (Done)
- Story 3.2: Static Configuration Integration (Done)  
- Story 3.3: Equipment Fleet Data Model (Done - with static config alignment)

### Acceptance Criteria
1. "Add Excavator" and "Add Truck" buttons available on desktop/tablet interfaces only
2. Each equipment item displays in organized list with individual input fields
3. Remove buttons allow deletion of individual equipment items (minimum one of each type maintained)
4. Visual indicators distinguish different equipment items (numbering, icons, or grouping)
5. Interface remains usable and organized even with multiple equipment items

## ~~Story 3.5: Mixed Fleet Calculation Engine~~ (REMOVED - Redundant)
**Reason for Removal:** Calculation engine for fleet management was already implemented in Story 3.3: Equipment Fleet Data Model. The fleet calculation functionality including multiple excavators, trucks, coordination, and real-time updates is complete.

## ~~Story 3.6: Mobile Interface Preservation~~ (REMOVED - Redundant)  
**Reason for Removal:** Mobile interface preservation was already implemented in Story 3.3: Equipment Fleet Data Model. The mobile interface maintains single-equipment simplicity while using the same underlying fleet data model.
