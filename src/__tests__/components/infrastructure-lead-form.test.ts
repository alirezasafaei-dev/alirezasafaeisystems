import { describe, expect, it } from 'vitest'
import { validateLeadAttachment } from '@/lib/lead-attachments'

describe('validateLeadAttachment', () => {
  it('accepts supported document and image attachments up to 5MB', () => {
    expect(validateLeadAttachment({
      name: 'audit-brief.pdf',
      size: 5 * 1024 * 1024,
      type: 'application/pdf',
    })).toEqual({ valid: true })

    expect(validateLeadAttachment({
      name: 'screenshot.jpeg',
      size: 1024,
      type: 'image/jpeg',
    })).toEqual({ valid: true })
  })

  it('rejects empty attachments', () => {
    expect(validateLeadAttachment({
      name: 'empty.pdf',
      size: 0,
      type: 'application/pdf',
    })).toEqual({ valid: false, reason: 'empty' })
  })

  it('rejects oversized attachments', () => {
    expect(validateLeadAttachment({
      name: 'large-audit.pdf',
      size: 5 * 1024 * 1024 + 1,
      type: 'application/pdf',
    })).toEqual({ valid: false, reason: 'size' })
  })

  it('rejects unsupported extensions even when a mime type is missing', () => {
    expect(validateLeadAttachment({
      name: 'payload.exe',
      size: 1024,
      type: '',
    })).toEqual({ valid: false, reason: 'type' })
  })

  it('rejects mismatched mime types and extensions', () => {
    expect(validateLeadAttachment({
      name: 'notes.txt',
      size: 1024,
      type: 'application/x-msdownload',
    })).toEqual({ valid: false, reason: 'type' })
  })
})
