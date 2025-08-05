# Security and Performance  

## Security Requirements

**Frontend Security:**
- **CSP Headers:** `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'`
- **XSS Prevention:** Elm's type system prevents XSS by design - no innerHTML or dangerouslySetInnerHTML equivalent
- **Secure Storage:** Local storage only for non-sensitive calculation data, no credentials or personal information stored

**Backend Security (Future F# Implementation):**
- **Input Validation:** All API inputs validated through F# type system and custom validation functions
- **Rate Limiting:** 100 requests per minute per IP address for calculation endpoints
- **CORS Policy:** `Access-Control-Allow-Origin: https://your-domain.github.io` (production frontend domain only)

**Authentication Security (Future):**
- **Token Storage:** JWT tokens in httpOnly cookies, never in localStorage
- **Session Management:** 24-hour token expiry with refresh token rotation
- **Password Policy:** Minimum 12 characters, mixed case, numbers, special characters required

## Performance Optimization

**Frontend Performance:**
- **Bundle Size Target:** < 250KB total JavaScript bundle size (current: ~180KB with Elm + dependencies)
- **Loading Strategy:** Critical path CSS inlined, non-critical CSS loaded asynchronously
- **Caching Strategy:** Static assets cached for 1 year with cache busting, HTML cached for 5 minutes

**Backend Performance (Future):**
- **Response Time Target:** < 200ms for calculation endpoints, < 100ms for data retrieval
- **Database Optimization:** Indexed queries on user_id and project_id, connection pooling with max 20 connections
- **Caching Strategy:** Redis cache for frequently accessed equipment presets and user sessions

**Core Web Vitals Targets:**
- First Contentful Paint (FCP) < 1.5s
- Largest Contentful Paint (LCP) < 2.5s  
- Cumulative Layout Shift (CLS) < 0.1
- First Input Delay (FID) < 100ms
