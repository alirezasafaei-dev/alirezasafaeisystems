# Lead Qualification Criteria - AlirezaSafaeiSystems

**Last Updated**: 2026-06-16
**Status**: ✅ Frozen and Active
**Owner**: `platform-owner`

---

## Qualified Lead Definition

A **Qualified Lead** is a potential customer who has:
1. Demonstrated genuine interest in services
2. Provided valid contact information
3. Meets minimum business requirements
4. Has realistic project scope and budget alignment

---

## Acceptance Criteria

### A. Contact Information Validation ✅
- [ ] **Valid Email Address**: Must pass email format validation
- [ ] **Working Phone Number**: Iranian mobile number format (09xxxxxxxxx)
- [ ] **Company/Organization**: Valid company name or organization
- [ ] **Geographic Location**: Location within service coverage area

**Scoring**: All 4 criteria must be met (100% required)

---

### B. Service Interest Alignment ✅
- [ ] **Service Category**: Selected service category matches offerings
- [ ] **Project Timeline**: Realistic project timeline (1-12 months)
- [ ] **Project Scope**: Clearly defined project scope or requirements
- [ ] **Budget Range**: Budget range aligns with service pricing

**Scoring**: Minimum 3 of 4 criteria must be met (75% required)

---

### C. Engagement Quality ✅
- [ ] **Form Completion**: Form completed without abandonment
- [ ] **Session Duration**: Minimum 30 seconds on qualification page
- [ ] **Page Depth**: Minimum 3 pages viewed during session
- [ ] **Return Visit**: Either first visit with high engagement or return visit

**Scoring**: Minimum 2 of 4 criteria must be met (50% required)

---

### D. Business Fit Assessment ✅
- [ ] **Company Size**: Company size matches target customer segment
- [ ] **Industry Alignment**: Industry aligns with expertise areas
- [ ] **Project Complexity**: Project complexity matches service capabilities
- [ ] **Decision Maker**: Contact appears to be decision maker or influencer

**Scoring**: Minimum 2 of 4 criteria must be met (50% required)

---

## Lead Scoring System

### Score Calculation
```
Total Score = (Contact Information × 0.30) + 
              (Service Interest × 0.25) + 
              (Engagement Quality × 0.20) + 
              (Business Fit × 0.25)
```

### Score Ranges
- **90-100**: Hot Lead (Immediate follow-up within 4 hours)
- **75-89**: Warm Lead (Follow-up within 24 hours)
- **50-74**: Cold Lead (Follow-up within 72 hours)
- **Below 50**: Unqualified Lead (Archive or nurture campaign)

---

## Disqualification Criteria

A lead is **automatically disqualified** if:

### Automatic Disqualifiers ❌
- [ ] Invalid email format or bounced email
- [ ] Missing or invalid phone number
- [ ] Offensive or inappropriate content
- [ ] Clearly spam or bot submission
- [ ] Outside geographic service area
- [ ] Requesting services not offered
- [ ] Budget significantly below minimum project size

### Manual Review Required ⚠️
- [ ] Unclear project scope or requirements
- [ ] Budget information not provided
- [ ] Timeline seems unrealistic
- [ ] Company information missing or vague
- [ ] Low engagement but strong business fit

---

## Lead Classification

### Lead Types
1. **MQL (Marketing Qualified Lead)**
   - Score: 50-74
   - Action: Nurture campaign, content marketing

2. **SQL (Sales Qualified Lead)**
   - Score: 75-89
   - Action: Sales outreach, consultation scheduling

3. **PQL (Product Qualified Lead)**
   - Score: 90-100
   - Action: Immediate sales engagement, priority treatment

4. **DQL (Disqualified Lead)**
   - Score: Below 50
   - Action: Archive or generic nurture

---

## Validation Process

### Automated Validation (Real-time)
1. Form input validation (format, required fields)
2. Email syntax validation
3. Phone number format validation
4. Spam detection (honeypot, rate limiting)
5. Duplicate detection (email, phone)

### Manual Validation (Within 24 hours)
1. Review lead details against criteria
2. Verify contact information if needed
3. Assess business fit and project scope
4. Assign lead score and classification
5. Route to appropriate follow-up workflow

---

## Follow-up SLAs

### Response Time Targets
- **Hot Leads (90-100)**: Within 4 hours
- **Warm Leads (75-89)**: Within 24 hours
- **Cold Leads (50-74)**: Within 72 hours
- **Unqualified**: No immediate follow-up

### Follow-up Sequence
1. **First Contact**: As per SLA above
2. **Second Contact**: If no response, 3 days later
3. **Third Contact**: If no response, 7 days later
4. **Final Attempt**: If no response, 14 days later
5. **Archive**: If no response after final attempt

---

## Data Quality Requirements

### Required Fields
- Name (First + Last)
- Email address
- Phone number
- Company/Organization
- Service category interest
- Project timeline
- Budget range

### Optional Fields
- Company website
- Project description
- Specific requirements
- How did you hear about us
- Preferred contact method

---

## Governance Rules

1. **Criteria Updates**: Any criteria change requires business justification
2. **Score Thresholds**: Threshold changes require A/B testing validation
3. **Disqualification**: Manual disqualification must be documented
4. **Review Process**: Criteria reviewed quarterly for effectiveness
5. **Data Privacy**: All lead data handled per privacy policy

---

## Success Metrics

### Lead Quality Metrics
- **Qualified Lead Rate**: (Qualified Leads / Total Leads) × 100
- **Conversion Rate**: (Converted Leads / Qualified Leads) × 100
- **Response Time**: Average time to first contact
- **Lead-to-Customer Rate**: (Customers / Qualified Leads) × 100

### Target Metrics
- Qualified Lead Rate: ≥60%
- Conversion Rate: ≥25%
- Average Response Time: ≤12 hours
- Lead-to-Customer Rate: ≥15%

---

*This document freezes the lead qualification criteria as of 2026-06-16. Changes require explicit approval and documentation updates.*