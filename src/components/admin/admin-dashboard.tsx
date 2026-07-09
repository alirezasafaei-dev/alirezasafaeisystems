'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { MessageSquare, Briefcase, BarChart3, Users, Trash2, LogOut, ClipboardList, Search, ExternalLink } from 'lucide-react'
import { toast } from '@/hooks/use-toast'

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

export function AdminDashboard() {
  const router = useRouter()
  const [activeTab, setActiveTab] = useState<'leads' | 'messages' | 'projects' | 'stats'>('leads')
  const [leads, setLeads] = useState<LeadData[]>([])
  const [messages, setMessages] = useState<Message[]>([])
  const [leadsLoading, setLeadsLoading] = useState(false)
  const [messagesLoading, setMessagesLoading] = useState(false)
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedLead, setSelectedLead] = useState<LeadData | null>(null)
  const [detailOpen, setDetailOpen] = useState(false)

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
        title: 'Error',
        description: 'Failed to load data',
        variant: 'destructive',
      })
    } finally {
      setLeadsLoading(false)
      setMessagesLoading(false)
    }
  }, [router])

  const initialised = useRef(false)
  useEffect(() => {
    if (initialised.current) return
    initialised.current = true
    loadData()
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
      toast({ title: 'Updated', description: 'Lead status updated' })
    } catch {
      toast({
        title: 'Error',
        description: 'Failed to update lead status',
        variant: 'destructive',
      })
    }
  }

  const deleteMessage = async (id: string) => {
    try {
      await fetch(`/api/admin/messages?id=${id}`, { method: 'DELETE' })
      setMessages(messages.filter(m => m.id !== id))
      toast({
        title: 'Success',
        description: 'Message deleted successfully',
      })
    } catch {
      toast({
        title: 'Error',
        description: 'Failed to delete message',
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

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <div className="mb-8">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h1 className="text-3xl font-bold mb-2">Admin Dashboard</h1>
              <p className="text-muted-foreground">Manage leads, messages, and portfolio content</p>
            </div>
            <Button variant="outline" onClick={logout}>
              <LogOut className="h-4 w-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Messages</CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{messages.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Leads</CardTitle>
              <ClipboardList className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{leads.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">New Leads</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{statusCounts.new}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {statusCounts.qualified} qualified &middot; {statusCounts.archived} archived
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Conversion Rate</CardTitle>
              <BarChart3 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {leads.length > 0
                  ? `${Math.round((statusCounts.qualified / leads.length) * 100)}%`
                  : '—'}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {statusCounts.qualified} / {leads.length} leads qualified
              </p>
            </CardContent>
          </Card>
        </div>

        <div className="flex gap-2 mb-6 flex-wrap">
          <Button
            variant={activeTab === 'leads' ? 'default' : 'outline'}
            onClick={() => setActiveTab('leads')}
          >
            <ClipboardList className="h-4 w-4 mr-2" />
            Leads
            {statusCounts.new > 0 && (
              <Badge variant="secondary" className="ml-2 text-xs">{statusCounts.new}</Badge>
            )}
          </Button>
          <Button
            variant={activeTab === 'messages' ? 'default' : 'outline'}
            onClick={() => setActiveTab('messages')}
          >
            <MessageSquare className="h-4 w-4 mr-2" />
            Messages
          </Button>
          <Button
            variant={activeTab === 'projects' ? 'default' : 'outline'}
            onClick={() => setActiveTab('projects')}
          >
            <Briefcase className="h-4 w-4 mr-2" />
            Projects
          </Button>
          <Button
            variant={activeTab === 'stats' ? 'default' : 'outline'}
            onClick={() => setActiveTab('stats')}
          >
            <BarChart3 className="h-4 w-4 mr-2" />
            Analytics
          </Button>
        </div>

        {activeTab === 'leads' && (
          <Card>
            <CardHeader>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <CardTitle>Leads</CardTitle>
                  <CardDescription>
                    Qualification submissions captured from high-intent funnels
                  </CardDescription>
                </div>
                <div className="flex items-center gap-2">
                  <div className="relative">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search leads..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-8 h-9 w-48"
                    />
                  </div>
                  <div className="flex gap-1">
                    {['all', 'new', 'qualified', 'disqualified', 'archived'].map((s) => (
                      <Button
                        key={s}
                        variant={statusFilter === s ? 'default' : 'outline'}
                        size="sm"
                        onClick={() => setStatusFilter(s)}
                        className="h-9 text-xs"
                      >
                        {s === 'all' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}
                        {statusCounts[s as keyof typeof statusCounts] > 0 && (
                          <span className="ml-1 text-xs opacity-70">
                            {statusCounts[s as keyof typeof statusCounts]}
                          </span>
                        )}
                      </Button>
                    ))}
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {leadsLoading ? (
                <div className="text-center py-8 text-muted-foreground">Loading leads...</div>
              ) : filteredLeads.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  {leads.length === 0 ? 'No leads yet' : 'No leads match the current filter'}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Organization</TableHead>
                      <TableHead>Contact</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Budget</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
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
                            <div className="text-xs text-muted-foreground">{lead.email}</div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <span className="text-sm">{lead.organizationType}</span>
                        </TableCell>
                        <TableCell>
                          <span className="text-sm">{lead.budgetRange}</span>
                        </TableCell>
                        <TableCell>
                          <Badge variant={statusBadgeVariant[lead.status] || 'secondary'}>
                            {lead.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {new Date(lead.createdAt).toLocaleDateString('fa-IR')}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2" onClick={(e) => e.stopPropagation()}>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => updateLeadStatus(lead.id, 'qualified')}
                            >
                              Qualify
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => updateLeadStatus(lead.id, 'archived')}
                            >
                              Archive
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        )}

        <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
          <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{selectedLead?.organizationName || 'Lead Details'}</DialogTitle>
              <DialogDescription>
                {selectedLead?.contactName} &middot; {selectedLead?.email}
              </DialogDescription>
            </DialogHeader>
            {selectedLead && (
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <Badge variant={statusBadgeVariant[selectedLead.status] || 'secondary'}>
                    {selectedLead.status}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    Submitted {new Date(selectedLead.createdAt).toLocaleDateString('fa-IR')}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <DetailField label="Organization Type" value={selectedLead.organizationType} />
                  <DetailField label="Team Size" value={selectedLead.teamSize} />
                  <DetailField label="Timeline" value={selectedLead.timeline} />
                  <DetailField label="Budget Range" value={selectedLead.budgetRange} />
                  <DetailField label="Preferred Contact" value={selectedLead.preferredContact} />
                  <DetailField label="Phone" value={selectedLead.phone || '—'} />
                </div>

                <div>
                  <h4 className="text-sm font-semibold mb-1">Current Stack</h4>
                  <p className="text-sm text-muted-foreground bg-muted/50 rounded-md p-3">
                    {selectedLead.currentStack || '—'}
                  </p>
                </div>

                <div>
                  <h4 className="text-sm font-semibold mb-1">Critical Risk / Issue</h4>
                  <p className="text-sm text-muted-foreground bg-muted/50 rounded-md p-3">
                    {selectedLead.criticalRisk || '—'}
                  </p>
                </div>

                {selectedLead.notes && (
                  <div>
                    <h4 className="text-sm font-semibold mb-1">Notes</h4>
                    <p className="text-sm text-muted-foreground bg-muted/50 rounded-md p-3">
                      {selectedLead.notes}
                    </p>
                  </div>
                )}

                {(selectedLead.utmSource || selectedLead.utmMedium || selectedLead.utmCampaign) && (
                  <div>
                    <h4 className="text-sm font-semibold mb-1">UTM Parameters</h4>
                    <div className="flex flex-wrap gap-2">
                      {selectedLead.utmSource && (
                        <Badge variant="outline">source: {selectedLead.utmSource}</Badge>
                      )}
                      {selectedLead.utmMedium && (
                        <Badge variant="outline">medium: {selectedLead.utmMedium}</Badge>
                      )}
                      {selectedLead.utmCampaign && (
                        <Badge variant="outline">campaign: {selectedLead.utmCampaign}</Badge>
                      )}
                    </div>
                  </div>
                )}

                <div className="flex gap-2 pt-2 border-t">
                  {selectedLead.status !== 'qualified' && (
                    <Button
                      size="sm"
                      onClick={() => {
                        updateLeadStatus(selectedLead.id, 'qualified')
                        setDetailOpen(false)
                      }}
                    >
                      Mark as Qualified
                    </Button>
                  )}
                  {selectedLead.status !== 'archived' && (
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        updateLeadStatus(selectedLead.id, 'archived')
                        setDetailOpen(false)
                      }}
                    >
                      Archive
                    </Button>
                  )}
                  {selectedLead.status !== 'disqualified' && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        updateLeadStatus(selectedLead.id, 'disqualified')
                        setDetailOpen(false)
                      }}
                    >
                      Disqualify
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
              <CardTitle>Contact Messages</CardTitle>
              <CardDescription>
                Messages received through the contact form
              </CardDescription>
            </CardHeader>
            <CardContent>
              {messagesLoading ? (
                <div className="text-center py-8 text-muted-foreground">Loading messages...</div>
              ) : messages.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">No messages yet</div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Subject</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {messages.map((message) => (
                      <TableRow key={message.id}>
                        <TableCell className="font-medium">{message.name}</TableCell>
                        <TableCell>{message.email}</TableCell>
                        <TableCell>
                          {message.subject || <span className="text-muted-foreground">—</span>}
                        </TableCell>
                        <TableCell>
                          {new Date(message.createdAt).toLocaleDateString('fa-IR')}
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => deleteMessage(message.id)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        )}

        {activeTab === 'projects' && (
          <Card>
            <CardHeader>
              <CardTitle>Manage Projects</CardTitle>
              <CardDescription>
                Add, edit, or remove portfolio projects
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <p className="text-muted-foreground mb-4">
                  Project management interface — currently read-only. Manage projects via the GitHub repo.
                </p>
                <Button asChild variant="outline">
                  <a
                    href="https://github.com/alirezasafaei-dev/alirezasafaeisystems"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <ExternalLink className="h-4 w-4 mr-2" />
                    Open Repository
                  </a>
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {activeTab === 'stats' && (
          <Card>
            <CardHeader>
              <CardTitle>Analytics Overview</CardTitle>
              <CardDescription>
                Lead acquisition and engagement metrics
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex justify-between items-center p-4 bg-muted/50 rounded-lg">
                  <div>
                    <div className="font-semibold">Total Leads</div>
                    <div className="text-sm text-muted-foreground">All time</div>
                  </div>
                  <Badge variant="secondary" className="text-lg">{leads.length}</Badge>
                </div>
                <div className="flex justify-between items-center p-4 bg-muted/50 rounded-lg">
                  <div>
                    <div className="font-semibold">Qualified Leads</div>
                    <div className="text-sm text-muted-foreground">Ready for follow-up</div>
                  </div>
                  <Badge variant="secondary" className="text-lg">{statusCounts.qualified}</Badge>
                </div>
                <div className="flex justify-between items-center p-4 bg-muted/50 rounded-lg">
                  <div>
                    <div className="font-semibold">Qualification Rate</div>
                    <div className="text-sm text-muted-foreground">Qualified / Total</div>
                  </div>
                  <Badge variant="secondary" className="text-lg">
                    {leads.length > 0 ? `${Math.round((statusCounts.qualified / leads.length) * 100)}%` : '—'}
                  </Badge>
                </div>
                <div className="flex justify-between items-center p-4 bg-muted/50 rounded-lg">
                  <div>
                    <div className="font-semibold">Contact Form Submissions</div>
                    <div className="text-sm text-muted-foreground">All time</div>
                  </div>
                  <Badge variant="secondary" className="text-lg">{messages.length}</Badge>
                </div>
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
      <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-0.5">
        {label}
      </h4>
      <p className="text-sm">{value || '—'}</p>
    </div>
  )
}
