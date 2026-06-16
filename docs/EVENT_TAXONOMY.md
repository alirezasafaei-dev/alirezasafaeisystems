# Event Taxonomy - AlirezaSafaeiSystems

**Last Updated**: 2026-06-16
**Status**: ✅ Frozen and Active
**Owner**: `platform-owner`

---

## Taxonomy Structure

All analytics and business events must follow this taxonomy structure:
- `source`: Where the event originated
- `stage`: User journey stage
- `intent`: User intention or action
- `outcome`: Result of the action

---

## Source Values

### Source Categories
- `organic_search`: Organic search traffic
- `direct`: Direct traffic (typed URL, bookmarks)
- `referral:external`: External website referrals
- `referral:social`: Social media referrals
- `referral:internal`: Internal site navigation
- `paid_search`: Paid search campaigns
- `paid_social`: Paid social campaigns
- `email`: Email campaigns
- `direct_nav`: Direct navigation to specific pages

### Source Metadata
- Campaign UTM parameters when available
- Referrer domain for external referrals
- Device type (mobile/desktop/tablet)
- Geographic location (country/city level)

---

## Stage Values

### User Journey Stages
- `awareness`: First-time visitor, exploring site
- `consideration`: Returning visitor, evaluating services
- `intent`: User shows purchase/lead intent
- `conversion`: User completes desired action
- `retention`: Returning customer/lead

### Stage Transition Criteria
- **awareness → consideration**: 2+ page views, >30s session
- **consideration → intent**: Views services/case studies, scrolls deep
- **intent → conversion**: Submits form, initiates contact
- **conversion → retention**: Follow-up engagement, return visits

---

## Intent Values

### Business Intents
- `service_inquiry`: Asking about specific services
- `case_study_request`: Requesting case study details
- `pricing_inquiry`: Asking about pricing/packages
- `consultation_request`: Requesting consultation
- `partnership_inquiry`: Partnership or collaboration interest
- `support_request`: Technical or customer support
- `general_inquiry`: General information request

### Navigation Intents
- `nav_home`: Navigating to home page
- `nav_services`: Navigating to services pages
- `nav_case_studies`: Navigating to case studies
- `nav_about`: Navigating to about/brand pages
- `nav_contact`: Navigating to contact/qualification pages

### Content Intents
- `content_read`: Reading content (articles, case studies)
- `content_share`: Sharing content (social, email)
- `content_download`: Downloading resources
- `content_print`: Printing content

---

## Outcome Values

### Business Outcomes
- `lead_generated`: New lead created
- `lead_qualified`: Lead qualified as potential customer
- `lead_converted`: Lead converted to customer
- `opportunity_created`: Sales opportunity created
- `deal_closed`: Deal closed successfully
- `deal_lost`: Deal lost to competition or other reasons

### User Experience Outcomes
- `form_completed`: Form successfully submitted
- `form_abandoned`: Form started but not completed
- `error_encountered`: User encountered error
- `success_message`: User received success message
- `redirect_triggered`: User redirected to another page

### Engagement Outcomes
- `engagement_low`: Low engagement (<30s session, 1-2 pages)
- `engagement_medium`: Medium engagement (30s-2min, 3-5 pages)
- `engagement_high`: High engagement (>2min, 5+ pages)
- `engagement_return`: Returning user with previous engagement

---

## Event Format

### Standard Event Schema
```typescript
{
  source: string;           // Source taxonomy value
  stage: string;           // Stage taxonomy value
  intent: string;          // Intent taxonomy value
  outcome: string;         // Outcome taxonomy value
  timestamp: ISO8601;      // Event timestamp
  userId?: string;        // Anonymous or identified user ID
  sessionId: string;       // Session identifier
  metadata?: {             // Additional context
    page: string;          // Current page URL
    referrer?: string;     // Referrer URL
    device: string;        // Device type
    locale: string;        // User locale (fa-IR, en-US)
    campaign?: string;     // Campaign identifier
    // ... additional context
  };
}
```

### Event Examples
```typescript
// Lead form submission
{
  source: "organic_search",
  stage: "intent",
  intent: "consultation_request",
  outcome: "lead_generated",
  timestamp: "2026-06-16T10:30:00Z",
  sessionId: "sess_12345",
  metadata: {
    page: "/qualification",
    referrer: "https://google.com",
    device: "desktop",
    locale: "fa-IR"
  }
}

// Service page navigation
{
  source: "direct_nav",
  stage: "consideration",
  intent: "nav_services",
  outcome: "engagement_medium",
  timestamp: "2026-06-16T11:15:00Z",
  sessionId: "sess_12345",
  metadata: {
    page: "/services",
    device: "mobile",
    locale: "fa-IR"
  }
}
```

---

## Implementation Guidelines

### Event Naming Convention
- Use snake_case for event names
- Prefix with domain: `site:page_view`, `form:submit`, `nav:click`
- Include taxonomy in metadata for filtering

### Required Events
1. **Page View**: Track every page view with source/stage/intent
2. **Form Events**: Track form start, progress, submit, abandon
3. **Navigation Events**: Track menu clicks, internal links
4. **Error Events**: Track user-facing errors
5. **Conversion Events**: Track all conversion actions

### Privacy & Compliance
- No PII in event data without explicit consent
- Anonymize IP addresses
- Respect user preferences (do not track)
- Comply with GDPR/local privacy regulations

---

## Governance Rules

1. **New Events**: Must be added to this taxonomy before implementation
2. **Event Deprecation**: Deprecated events must be maintained for 90 days
3. **Schema Validation**: All events must pass schema validation
4. **Documentation**: All events must be documented with examples
5. **Review**: Taxonomy reviewed quarterly for relevance

---

## Success Criteria

- ✅ All events follow taxonomy structure
- ✅ Event documentation complete and up to date
- ✅ Schema validation implemented
- ✅ Privacy guidelines established
- ✅ Event tracking covers critical user journeys

---

*This taxonomy freezes the event structure as of 2026-06-16. Changes require explicit approval and documentation updates.*