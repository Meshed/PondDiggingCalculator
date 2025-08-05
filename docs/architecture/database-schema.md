# Database Schema

**No database in MVP phase** - All data exists in browser memory and local storage only.

## Current Data Storage (MVP)

**Browser Local Storage Structure:**
```elm
-- Local storage keys and data formats
type StorageKey
    = LastCalculationKey
    | UserPreferencesKey
    | EquipmentPresetsKey

-- Data stored in local storage (JSON serialized)
type alias StoredCalculation =
    { excavators : List Excavator
    , trucks : List Truck
    , projectConfig : ProjectConfiguration
    , result : CalculationResult
    , timestamp : String  -- ISO datetime
    }

-- JSON structure in localStorage
{
  "lastCalculation": {
    "excavators": [...],
    "trucks": [...],
    "projectConfig": {...},
    "result": {...},
    "timestamp": "2025-08-05T10:30:00Z"
  }
}
```

## Future Database Schema (Post-MVP with F# Backend)

When data persistence is added, the following PostgreSQL schema will be implemented:

**Users Table:**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Projects Table:**
```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    work_hours_per_day DECIMAL(4,2) NOT NULL DEFAULT 8.00,
    pond_length DECIMAL(8,2) NOT NULL,
    pond_width DECIMAL(8,2) NOT NULL,
    pond_depth DECIMAL(8,2) NOT NULL,
    pond_volume DECIMAL(12,2) NOT NULL, -- calculated field
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```
