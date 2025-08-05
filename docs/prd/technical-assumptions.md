# Technical Assumptions

## Repository Structure: Monorepo
Single repository approach aligns with the client-side architecture and single-developer capacity, simplifying development and deployment workflows for the MVP scope.

## Service Architecture
Client-side functional architecture using Elm for MVP phase. The application operates entirely within the browser with pure functional calculation logic, immutable data structures, and clear separation between calculation engine and UI components. Future phases will add F# backend maintaining functional programming consistency across the full stack.

## Testing Requirements
Unit + Integration testing approach using Elm's built-in testing framework for calculation accuracy validation and UI component testing. Focus on test-driven development for calculation logic to ensure professional-grade reliability. Manual testing protocols for cross-device compatibility and user experience validation.

## Additional Technical Assumptions and Requests
- **Language Choice:** Elm frontend selected for type safety, reliability, and zero runtime exceptions critical for professional construction tool credibility
- **Functional Programming Patterns:** Pure functions for all calculations, immutable data structures throughout, and functional composition for complex equipment fleet calculations
- **Static Hosting:** Client-side architecture enables deployment via GitHub Pages, Netlify, or similar static hosting services, eliminating server infrastructure costs for MVP
- **Configuration Management:** Easily updateable configuration file system for default equipment values, allowing post-deployment updates without code changes
- **Browser Compatibility:** Target modern browsers (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+) without polyfills, leveraging native ES6+ features through Elm compilation
- **Performance Optimization:** Sub-second calculation updates through efficient functional algorithms and minimal DOM manipulation via Elm Architecture
- **Future F# Integration:** Backend architecture planned for F# when data persistence, analytics, or API integrations are needed in post-MVP phases
