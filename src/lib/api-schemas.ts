import { z } from 'zod'

export const contactSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100),
  email: z.string().email('Invalid email address').max(255),
  subject: z.string().max(200).optional().default(''),
  message: z.string().min(10, 'Message must be at least 10 characters').max(5000),
  website: z.string().max(255).optional().default(''),
})

export type ContactPayload = z.infer<typeof contactSchema>

export const leadSchema = z.object({
  contactName: z.string().min(2).max(120),
  organizationName: z.string().min(2).max(180),
  organizationType: z.string().min(3).max(80),
  email: z.string().email().max(255),
  phone: z.string().max(40).optional().default(''),
  teamSize: z.string().min(1).max(40),
  currentStack: z.string().min(3).max(300),
  criticalRisk: z.string().min(10).max(2000),
  timeline: z.string().min(1).max(120),
  budgetRange: z.string().min(3).max(120),
  preferredContact: z.string().min(3).max(80),
  notes: z.string().max(2000).optional().default(''),
  website: z.string().max(255).optional().default(''),
  attachmentPath: z.string().max(400).optional().default(''),
  utmSource: z.string().max(120).optional().default(''),
  utmMedium: z.string().max(120).optional().default(''),
  utmCampaign: z.string().max(120).optional().default(''),
})

export type LeadPayload = z.infer<typeof leadSchema>

export const adminLoginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
})

export type AdminLoginPayload = z.infer<typeof adminLoginSchema>

export const analyticsEventSchema = z.object({
  name: z.string().min(1).max(100),
  category: z.string().min(1).max(50),
  locale: z.enum(['fa', 'en']).optional(),
  variant: z.string().max(50).optional(),
  value: z.number().optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
})

export type AnalyticsEventPayload = z.infer<typeof analyticsEventSchema>

export const webVitalsSchema = z.object({
  name: z.string().min(1).max(50),
  value: z.number(),
  rating: z.enum(['good', 'needs-improvement', 'poor']),
  delta: z.number().optional(),
  id: z.string().max(100).optional(),
  navigationType: z.string().max(50).optional(),
})

export type WebVitalsPayload = z.infer<typeof webVitalsSchema>

export function normalizeContactPayload(input: ContactPayload): ContactPayload {
  return {
    name: input.name.trim().substring(0, 100),
    email: input.email.trim().toLowerCase().substring(0, 255),
    subject: input.subject.trim().substring(0, 200),
    message: input.message.trim().substring(0, 5000),
    website: input.website.trim().substring(0, 255),
  }
}

export function normalizeLeadPayload(input: LeadPayload): LeadPayload {
  return {
    contactName: input.contactName.trim().substring(0, 120),
    organizationName: input.organizationName.trim().substring(0, 180),
    organizationType: input.organizationType.trim().substring(0, 80),
    email: input.email.trim().toLowerCase().substring(0, 255),
    phone: input.phone.trim().substring(0, 40),
    teamSize: input.teamSize.trim().substring(0, 40),
    currentStack: input.currentStack.trim().substring(0, 300),
    criticalRisk: input.criticalRisk.trim().substring(0, 2000),
    timeline: input.timeline.trim().substring(0, 120),
    budgetRange: input.budgetRange.trim().substring(0, 120),
    preferredContact: input.preferredContact.trim().substring(0, 80),
    notes: input.notes.trim().substring(0, 2000),
    website: input.website.trim().substring(0, 255),
    attachmentPath: input.attachmentPath.trim().substring(0, 400),
    utmSource: input.utmSource.trim().substring(0, 120),
    utmMedium: input.utmMedium.trim().substring(0, 120),
    utmCampaign: input.utmCampaign.trim().substring(0, 120),
  }
}
