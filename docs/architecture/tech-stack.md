# Tech Stack

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| Frontend Language | Elm | 0.19.1 | Type-safe functional programming | Zero runtime exceptions, enforced immutability critical for reliability |
| Frontend Framework | Elm Architecture | Built-in | Model-View-Update pattern | Predictable state management, time-travel debugging |
| CSS Framework | Tailwind CSS | 3.4+ | Utility-first styling | Predictable utilities, responsive, small bundle with purging |
| CSS Type Safety | elm-css or typed modules | Latest | Type-safe CSS classes | Prevents class name typos and style bugs |
| State Management | Elm Runtime | Built-in | Immutable state management | Single source of truth, no state synchronization issues |
| Backend Language | N/A (F# future) | N/A | No backend in MVP | Pure client-side for zero infrastructure costs |
| Backend Framework | N/A (Giraffe future) | N/A | No backend in MVP | F# functional web framework planned post-MVP |
| API Style | N/A (REST future) | N/A | No API in MVP | RESTful API planned for F# backend |
| Database | N/A (PostgreSQL future) | N/A | No database in MVP | PostgreSQL planned for data persistence post-MVP |
| Cache | Browser LocalStorage | HTML5 | Client-side state cache | Simple persistence without backend |
| File Storage | JSON Config Files | Static | Configuration storage | Equipment defaults and validation rules |
| Authentication | N/A | N/A | No auth in MVP | No user accounts needed initially |
| Frontend Testing | elm-test | 0.19.1 | Unit and integration testing | Built-in test runner for Elm |
| Backend Testing | N/A | N/A | No backend in MVP | F# testing planned post-MVP |
| E2E Testing | Cypress | 13.0+ | End-to-end testing | Cross-browser automated testing |
| Build Tool | Elm Compiler | 0.19.1 | Compilation to JavaScript | Type checking and optimization |
| Bundler | Parcel | 2.0+ | Asset bundling | Zero-config bundling with hot reload |
| IaC Tool | GitHub Actions | N/A | CI/CD automation | Built into GitHub, no additional tools |
| CI/CD | GitHub Actions | Latest | Continuous deployment | Automated testing and deployment to GitHub Pages |
| Monitoring | Browser Console | Built-in | Error logging | Client-side error tracking |
| Logging | elm-log | 0.19.0 | Debug logging | Development-time logging |
| CSS Framework | CSS Grid/Flexbox | CSS3 | Responsive layout | Native browser layout without dependencies |
