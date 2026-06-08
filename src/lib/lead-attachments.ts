export const leadAttachmentMaxBytes = 5 * 1024 * 1024

export const allowedLeadAttachmentMimeTypes = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'text/plain',
  'image/png',
  'image/jpeg',
])

export const allowedLeadAttachmentExtensions = new Set(['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'])

export type LeadAttachmentValidationResult =
  | { valid: true }
  | { valid: false; reason: 'empty' | 'size' | 'type' }

export type LeadAttachmentCandidate = Pick<File, 'name' | 'size' | 'type'>

export function getLeadAttachmentExtension(name: string): string {
  return name.split('.').pop()?.toLowerCase() ?? ''
}

export function validateLeadAttachment(file: LeadAttachmentCandidate): LeadAttachmentValidationResult {
  if (file.size === 0) {
    return { valid: false, reason: 'empty' }
  }

  if (file.size > leadAttachmentMaxBytes) {
    return { valid: false, reason: 'size' }
  }

  const extension = getLeadAttachmentExtension(file.name)
  const hasAllowedMimeType = file.type.length === 0 || allowedLeadAttachmentMimeTypes.has(file.type)
  const hasAllowedExtension = allowedLeadAttachmentExtensions.has(extension)

  if (!hasAllowedMimeType || !hasAllowedExtension) {
    return { valid: false, reason: 'type' }
  }

  return { valid: true }
}

export function sanitizeLeadAttachmentFileName(name: string): string {
  const safeName = name.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 120)
  return safeName.length > 0 ? safeName : 'attachment'
}
