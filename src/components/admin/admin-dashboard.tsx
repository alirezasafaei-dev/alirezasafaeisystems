'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { MessageSquare, Briefcase, BarChart3, Users, Trash2, LogOut, ClipboardList, Search, Compass } from 'lucide-react'
import { toast } from '@/hooks/use-toast'
import { DiscoverManager } from '@/components/admin/discover-manager'
import { ProjectManager } from '@/components/admin/project-manager'
import { useI18n } from '@/lib/i18n-context'

interface LeadData {
  id: string
  status: 'new' | 'qualified' | 'disqualified' | 'archived'
  source: string
  contactName: string
  organizationName: string
  organizationType: string
  email: string
  phone: string | null
  teamSize: string
  currentStack: string
  criticalRisk: string
  timeline: string
  budgetRange: string
  preferredContact: string
  notes: string | null
  attachmentPath: string | null
  utmSource: string | null
  utmMedium: string | null
  utmCampaign: string | null
  createdAt: string
  updatedAt: string
}

interface Message {
  id: string
  name: string
  email: string
  subject?: string
  message: string
  createdAt: string
}

type LeadStatusFilter = 'all' | LeadData['status']

export function AdminDashboard() {
  const router = useRouter()
  const { language, t } = useI18n()
  const [activeTab, setActiveTab] = useState<'leads' | 'messages' | 'projects' | 'discover' | 'stats'>('leads')
  const [leads, setLeads] = useState<LeadData[]>([])
  const [messages, setMessages] = useState<Message[]>([])
  const [leadsLoading, setLeadsLoading] = useState(false)
  const [messagesLoading, setMessagesLoading] = useState(false)
  const [statusFilter, setStatusFilter] = useState<LeadStatusFilter>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedLead, setSelectedLead] = useState<LeadData | null>(null)
  const [detailOpen, setDetailOpen] = useState(false)
  const dir = language === 'fa' ? 'rtl' : 'ltr'
  const dateLocale = language === 'fa' ? 'fa-IR' : 'en-US'

  const loadData = useCallback(async () => {
    setLeadsLoading(true)
    setMessagesLoading(true)
    try {
      const [leadsRes, messagesRes] = await Promise.all([
        fetch('/api/admin/leads'),
        fetch('/api/admin/messages'),
      ])
      if (leadsRes.status === 401 || messagesRes.status === 401) {
        router.replace('/admin/login')
        return
      }
      const leadsData = await leadsRes.json()
      const messagesData = await messagesRes.json()
      setLeads(leadsData.leads || [])
      setMessages(messagesData.messages || [])
    } catch {
      toast({
        title: t('admin.dashboard.toast.error'),
        description: t('admin.dashboard.toast.loadFailed'),
        variant: 'destructive',
      })
    } finally {
      setLeadsLoading(false)
      setMessagesLoading(false)
    }
  }, [router, t])

  const initialised = useRef(false)
  useEffect(() => {
    if (initialised.current) return
    initialised.current = true
    void loadData()
  }, [loadData])

  const logout = async () => {
    await fetch('/api/admin/auth/logout', { method: 'POST' })
    router.replace('/admin/login')
    router.refresh()
  }

  const updateLeadStatus = async (id: string, status: LeadData['status']) => {
    try {
      const response = await fetch('/api/admin/leads', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status }),
      })
      if (!response.ok) throw new Error('update failed')
      const data = await response.json()
      setLeads((prev) => prev.map((lead) => (lead.id === id ? data.lead : lead)))
      if (selectedLead?.id === id) setSelectedLead(data.lead)
      toast({ title: t('admin.dashboard.toast.updated'), description: t('admin.dashboard.toast.leadStatusUpdated') })
    } catch {
      toast({
        title: t('admin.dashboard.toast.error'),
        description: t('admin.dashboard.toast.updateLeadStatusFailed'),
        variant: 'destructive',
      })
    }
  }

  const deleteMessage = async (id: string) => {
    try {
      const response = await fetch(`/api/admin/messages?id=${id}`, { method: 'DELETE' })
      if (!response.ok) throw new Error('delete failed')
      setMessages((current) => current.filter((message) => message.id !== id))
      toast({
        title: t('admin.dashboard.toast.success'),
        description: t('admin.dashboard.toast.messageDeleted'),
      })
    } catch {
      toast({
        title: t('admin.dashboard.toast.error'),
        description: t('admin.dashboard.toast.deleteMessageFailed'),
        variant: 'destructive',
      })
    }
  }

  const filteredLeads = leads.filter((lead) => {
    if (statusFilter !== 'all' && lead.status !== statusFilter) return false
    if (searchQuery) {
      const q = searchQuery.toLowerCase()
      return (
        lead.organizationName.toLowerCase().includes(q) ||
        lead.contactName.toLowerCase().includes(q) ||
        lead.email.toLowerCase().includes(q) ||
        lead.organizationType.toLowerCase().includes(q) ||
        lead.currentStack.toLowerCase().includes(q)
      )
    }
    return true
  })

  const statusCounts = {
    all: leads.length,
    new: leads.filter((l) => l.status === 'new').length,
    qualified: leads.filter((l) => l.status === 'qualified').length,
    disqualified: leads.filter((l) => l.status === 'disqualified').length,
    archived: leads.filter((l) => l.status === 'archived').length,
  }

  const statusBadgeVariant: Record<string, 'default' | 'destructive' | 'secondary' | 'outline'> = {
    new: 'default',
    qualified: 'default',
    disqualified: 'destructive',
    archived: 'outline',
  }
  const statusOptions: LeadStatusFilter[] = ['all', 'new', 'qualified', 'disqualified', 'archived']
  const statusLabel = (status: LeadStatusFilter) => t(`admin.dashboard.status.${status}`)

  return (
    <section className="py-20" dir={dir} data-testid="admin-dashboard">
      <div className="container mx-auto px-4">
        <div className="mb-8">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h1 className="mb-2 text-3xl font-bold">{t('admin.dashboard.title')}</h1>
              <p className="text-muted-foreground">{t('admin.dashboard.description')}</p>
            </div>
            <Button variant="outline" onClick={logout}>
              <LogOut className="me-2 h-4 w-4" />
              {t('admin.dashboard.logout')}
            </Button>
          </div>
        </div>

        <div className="mb-8 grid grid-cols-1 gap-6 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{t('admin.dashboard.totalMessages')}</CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{messages.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{t('admin.dashboard.totalLeads')}</CardTitle>
              <ClipboardList className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{leads.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{t('admin.dashboard.newLeads')}</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{statusCounts.new}</div>
              <p className="mt-1 text-xs text-muted-foreground">
                {statusCounts.qualified} {t('admin.dashboard.qualifiedSummary')} &middot; {statusCounts.archived} {t('admin.dashboard.archivedSummary')}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{t('admin.dashboard.conversionRate')}</CardTitle>
              <BarChart3 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {leads.length > 0
                  ? `${Math.round((statusCounts.qualified / leads.length) * 100)}%`
                  : '—'}
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {statusCounts.qualified} / {leads.length} {t('admin.dashboard.leadsQualified')}
              </p>
            </CardContent>
          </Card>
        </div>

        <div className="mb-6 flex flex-wrap gap-2">
          <Button
            variant={activeTab === 'leads' ? 'default' : 'outline'}
            onClick={() => setActiveTab('leads')}
          >
            <ClipboardList className="me-2 h-4 w-4" />
            {t('admin.dashboard.tabs.leads')}
            {statusCounts.new > 0 && (
              <Badge variant="secondary" className="ms-2 text-xs">{statusCounts.new}</Badge>
            )}
          </Button>
          <Button
            variant={activeTab === 'messages' ? 'default' : 'outline'}
            onClick={() => setActiveTab('messages')}
          >
            <MessageSquare className="me-2 h-4 w-4" />
            {t('admin.dashboard.tabs.messages')}
          </Button>
          <Button
            variant={activeTab === 'projects' ? 'default' : 'outline'}
            onClick={() => setActiveTab('projects')}
          >
            <Briefcase className="me-2 h-4 w-4" />
            {t('admin.dashboard.tabs.projects')}
          </Button>
          <Button
            variant={activeTab === 'discover' ? 'default' : 'outline'}
            onClick={() => setActiveTab('discover')}
          >
            <Compass className="me-2 h-4 w-4" />
            {t('admin.dashboard.tabs.discover')}
          </Button>
          <Button
            variant={activeTab === 'stats' ? 'default' : 'outline'}
            onClick={() => setActiveTab('stats')}
          >
            <BarChart3 className="me-2 h-4 w-4" />
            {t('admin.dashboard.tabs.analytics')}
          </Button>
        </div>

        {activeTab === 'leads' && (
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <CardTitle>{t('admin.dashboard.leads.title')}</CardTitle>
                  <CardDescription>{t('admin.dashboard.leads.description')}</CardDescription>
                </div>
                <div className="flex flex-col gap-2 lg:flex-row lg:items-center">
                  <div className="relative">
                    <Search className="absolute start-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder={t('admin.dashboard.leads.searchPlaceholder')}
                      value={searchQuery}
                      onChange={(event) => setSearchQuery(event.target.value)}
                      className="h-9 w-full ps-8 sm:w-48"
                    />
                  </div>
                  <div className="flex max-w-full gap-1 overflow-x-auto pb-1">
                    {statusOptions.map((status) => (
                      <Button
                        key={status}
                        variant={statusFilter === status ? 'default' : 'outline'}
                        size="sm"
                        onClick={() => setStatusFilter(status)}
                        className="h-9 shrink-0 text-xs"
                      >
                        {statusLabel(status)}
                        {statusCounts[status] > 0 && (
                          <span className="ms-1 text-xs opacity-70">{statusCounts[status]}</span>
                        )}
                      </Button>
                    ))}
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {leadsLoading ? (
                <div className="py-8 text-center text-muted-foreground">{t('admin.dashboard.leads.loading')}</div>
              ) : filteredLeads.length === 0 ? (
                <div className="py-8 text-center text-muted-foreground">
                  {leads.length === 0 ? t('admin.dashboard.leads.empty') : t('admin.dashboard.leads.noMatch')}
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>{t('admin.dashboard.leads.organization')}</TableHead>
                        <TableHead>{t('admin.dashboard.leads.contact')}</TableHead>
                        <TableHead>{t('admin.dashboard.leads.type')}</TableHead>
                        <TableHead>{t('admin.dashboard.leads.budget')}</TableHead>
                        <TableHead>{t('admin.dashboard.leads.status')}</TableHead>
                        <TableHead>{t('admin.dashboard.leads.date')}</TableHead>
                        <TableHead className="text-end">{t('admin.dashboard.leads.actions')}</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredLeads.map((lead) => (
                        <TableRow
                          key={lead.id}
                          className="cursor-pointer"
                          onClick={() => {
                            setSelectedLead(lead)
                            setDetailOpen(true)
                          }}
                        >
                          <TableCell className="font-medium">{lead.organizationName}</TableCell>
                          <TableCell>
                            <div className="space-y-1">
                              <div>{lead.contactName}</div>
                              <div dir="ltr" className="text-xs text-muted-foreground">{lead.email}</div>
                            </div>
                          </TableCell>
                          <TableCell><span className="text-sm">{lead.organizationType}</span></TableCell>
                          <TableCell><span className="text-sm">{lead.budgetRange}</span></TableCell>
                          <TableCell>
                            <Badge variant={statusBadgeVariant[lead.status] || 'secondary'}>{statusLabel(lead.status)}</Badge>
                          </TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {new Date(lead.createdAt).toLocaleDateString(dateLocale)}
                          </TableCell>
                          <TableCell className="text-end">
                            <div className="flex justify-end gap-2" onClick={(event) => event.stopPropagation()}>
                              <Button variant="outline" size="sm" onClick={() => void updateLeadStatus(lead.id, 'qualified')}>
                                {t('admin.dashboard.leads.qualify')}
                              </Button>
                              <Button variant="ghost" size="sm" onClick={() => void updateLeadStatus(lead.id, 'archived')}>
                                {t('admin.dashboard.leads.archive')}
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
          <DialogContent className="max-h-[80vh] max-w-2xl overflow-y-auto" dir={dir}>
            <DialogHeader>
              <DialogTitle>{selectedLead?.organizationName || t('admin.dashboard.leads.leadDetails')}</DialogTitle>
              <DialogDescription>
                {selectedLead?.contactName} &middot; <span dir="ltr">{selectedLead?.email}</span>
              </DialogDescription>
            </DialogHeader>
            {selectedLead && (
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <Badge variant={statusBadgeVariant[selectedLead.status] || 'secondary'}>{statusLabel(selectedLead.status)}</Badge>
                  <span className="text-xs text-muted-foreground">
                    {t('admin.dashboard.leads.submitted')} {new Date(selectedLead.createdAt).toLocaleDateString(dateLocale)}
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <DetailField label={t('admin.dashboard.leads.organizationType')} value={selectedLead.organizationType} />
                  <DetailField label={t('admin.dashboard.leads.teamSize')} value={selectedLead.teamSize} />
                  <DetailField label={t('admin.dashboard.leads.timeline')} value={selectedLead.timeline} />
                  <DetailField label={t('admin.dashboard.leads.budgetRange')} value={selectedLead.budgetRange} />
                  <DetailField label={t('admin.dashboard.leads.preferredContact')} value={selectedLead.preferredContact} />
                  <DetailField label={t('admin.dashboard.leads.phone')} value={selectedLead.phone || '—'} />
                </div>

                <div>
                  <h4 className="mb-1 text-sm font-semibold">{t('admin.dashboard.leads.currentStack')}</h4>
                  <p className="rounded-md bg-muted/50 p-3 text-sm text-muted-foreground">{selectedLead.currentStack || '—'}</p>
                </div>

                <div>
                  <h4 className="mb-1 text-sm font-semibold">{t('admin.dashboard.leads.criticalRisk')}</h4>
                  <p className="rounded-md bg-muted/50 p-3 text-sm text-muted-foreground">{selectedLead.criticalRisk || '—'}</p>
                </div>

                {selectedLead.notes && (
                  <div>
                    <h4 className="mb-1 text-sm font-semibold">{t('admin.dashboard.leads.notes')}</h4>
                    <p className="rounded-md bg-muted/50 p-3 text-sm text-muted-foreground">{selectedLead.notes}</p>
                  </div>
                )}

                {(selectedLead.utmSource || selectedLead.utmMedium || selectedLead.utmCampaign) && (
                  <div>
                    <h4 className="mb-1 text-sm font-semibold">{t('admin.dashboard.leads.utmParameters')}</h4>
                    <div className="flex flex-wrap gap-2" dir="ltr">
                      {selectedLead.utmSource && <Badge variant="outline">{t('admin.dashboard.leads.source')}: {selectedLead.utmSource}</Badge>}
                      {selectedLead.utmMedium && <Badge variant="outline">{t('admin.dashboard.leads.medium')}: {selectedLead.utmMedium}</Badge>}
                      {selectedLead.utmCampaign && <Badge variant="outline">{t('admin.dashboard.leads.campaign')}: {selectedLead.utmCampaign}</Badge>}
                    </div>
                  </div>
                )}

                <div className="flex flex-wrap gap-2 border-t pt-2">
                  {selectedLead.status !== 'qualified' && (
                    <Button size="sm" onClick={() => { void updateLeadStatus(selectedLead.id, 'qualified'); setDetailOpen(false) }}>
                      {t('admin.dashboard.leads.markQualified')}
                    </Button>
                  )}
                  {selectedLead.status !== 'archived' && (
                    <Button variant="outline" size="sm" onClick={() => { void updateLeadStatus(selectedLead.id, 'archived'); setDetailOpen(false) }}>
                      {t('admin.dashboard.leads.archive')}
                    </Button>
                  )}
                  {selectedLead.status !== 'disqualified' && (
                    <Button variant="ghost" size="sm" onClick={() => { void updateLeadStatus(selectedLead.id, 'disqualified'); setDetailOpen(false) }}>
                      {t('admin.dashboard.leads.disqualify')}
                    </Button>
                  )}
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {activeTab === 'messages' && (
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.dashboard.messages.title')}</CardTitle>
              <CardDescription>{t('admin.dashboard.messages.description')}</CardDescription>
            </CardHeader>
            <CardContent>
              {messagesLoading ? (
                <div className="py-8 text-center text-muted-foreground">{t('admin.dashboard.messages.loading')}</div>
              ) : messages.length === 0 ? (
                <div className="py-8 text-center text-muted-foreground">{t('admin.dashboard.messages.empty')}</div>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>{t('admin.dashboard.messages.name')}</TableHead>
                        <TableHead>{t('admin.dashboard.messages.email')}</TableHead>
                        <TableHead>{t('admin.dashboard.messages.subject')}</TableHead>
                        <TableHead>{t('admin.dashboard.messages.date')}</TableHead>
                        <TableHead className="text-end">{t('admin.dashboard.messages.actions')}</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {messages.map((message) => (
                        <TableRow key={message.id}>
                          <TableCell className="font-medium">{message.name}</TableCell>
                          <TableCell dir="ltr">{message.email}</TableCell>
                          <TableCell>{message.subject || <span className="text-muted-foreground">—</span>}</TableCell>
                          <TableCell>{new Date(message.createdAt).toLocaleDateString(dateLocale)}</TableCell>
                          <TableCell className="text-end">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => void deleteMessage(message.id)}
                              aria-label={`${t('admin.dashboard.messages.delete')} ${message.name}`}
                            >
                              <Trash2 className="h-4 w-4 text-destructive" />
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {activeTab === 'projects' && <ProjectManager />}
        {activeTab === 'discover' && <DiscoverManager />}

        {activeTab === 'stats' && (
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.dashboard.analytics.title')}</CardTitle>
              <CardDescription>{t('admin.dashboard.analytics.description')}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <AnalyticsRow label={t('admin.dashboard.analytics.totalLeads')} description={t('admin.dashboard.analytics.allTime')} value={leads.length} />
                <AnalyticsRow label={t('admin.dashboard.analytics.qualifiedLeads')} description={t('admin.dashboard.analytics.readyForFollowUp')} value={statusCounts.qualified} />
                <AnalyticsRow
                  label={t('admin.dashboard.analytics.qualificationRate')}
                  description={t('admin.dashboard.analytics.qualifiedOverTotal')}
                  value={leads.length > 0 ? `${Math.round((statusCounts.qualified / leads.length) * 100)}%` : '—'}
                />
                <AnalyticsRow label={t('admin.dashboard.analytics.contactFormSubmissions')} description={t('admin.dashboard.analytics.allTime')} value={messages.length} />
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </section>
  )
}

function DetailField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <h4 className="mb-0.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">{label}</h4>
      <p className="text-sm">{value || '—'}</p>
    </div>
  )
}

function AnalyticsRow({ label, description, value }: { label: string; description: string; value: string | number }) {
  return (
    <div className="flex items-center justify-between rounded-lg bg-muted/50 p-4">
      <div>
        <div className="font-semibold">{label}</div>
        <div className="text-sm text-muted-foreground">{description}</div>
      </div>
      <Badge variant="secondary" className="text-lg">{value}</Badge>
    </div>
  )
}
