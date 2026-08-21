'use client'

import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Save, Trash2, X } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { toast } from '@/hooks/use-toast'
import { useI18n } from '@/lib/i18n-context'

type Project = {
  id: string
  title: string
  description: string
  longDescription: string | null
  githubUrl: string | null
  liveUrl: string | null
  tags: string
  contentType: 'portfolio' | 'discover'
  featured: boolean
  published: boolean
  order: number
}

type ProjectForm = Omit<Project, 'id' | 'longDescription' | 'githubUrl' | 'liveUrl' | 'tags'> & {
  id?: string
  longDescription: string
  githubUrl: string
  liveUrl: string
  tags: string
}

const emptyForm: ProjectForm = {
  title: '',
  description: '',
  longDescription: '',
  githubUrl: '',
  liveUrl: '',
  tags: '',
  contentType: 'portfolio',
  featured: false,
  published: false,
  order: 0,
}

function toForm(project: Project): ProjectForm {
  return {
    id: project.id,
    title: project.title,
    description: project.description,
    longDescription: project.longDescription || '',
    githubUrl: project.githubUrl || '',
    liveUrl: project.liveUrl || '',
    tags: project.tags,
    contentType: project.contentType,
    featured: project.featured,
    published: project.published,
    order: project.order,
  }
}

export function ProjectManager() {
  const { language, t } = useI18n()
  const [projects, setProjects] = useState<Project[]>([])
  const [form, setForm] = useState<ProjectForm>(emptyForm)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const dir = language === 'fa' ? 'rtl' : 'ltr'

  const loadProjects = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await fetch('/api/admin/projects?contentType=portfolio&published=all', { cache: 'no-store' })
      if (response.status === 401) throw new Error(t('admin.projects.authRequired'))
      if (!response.ok) throw new Error(t('admin.projects.loadFailed'))
      const data = await response.json() as { projects?: Project[] }
      setProjects(data.projects || [])
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : t('admin.projects.loadFailed'))
    } finally {
      setLoading(false)
    }
  }, [t])

  useEffect(() => {
    const timer = window.setTimeout(() => { void loadProjects() }, 0)
    return () => window.clearTimeout(timer)
  }, [loadProjects])

  function updateForm<K extends keyof ProjectForm>(key: K, value: ProjectForm[K]) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  async function saveProject(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSaving(true)
    try {
      const method = form.id ? 'PATCH' : 'POST'
      const response = await fetch('/api/admin/projects', {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, contentType: 'portfolio' }),
      })
      const data = await response.json() as { project?: Project }
      if (!response.ok || !data.project) throw new Error(t('admin.projects.saveFailed'))
      const savedProject = data.project
      setProjects((current) => form.id
        ? current.map((project) => project.id === savedProject.id ? savedProject : project)
        : [savedProject, ...current])
      setForm(emptyForm)
      toast({ title: t('admin.projects.saved'), description: t('admin.projects.savedDescription') })
    } catch (saveError) {
      toast({ title: t('admin.projects.error'), description: saveError instanceof Error ? saveError.message : t('admin.projects.saveFailed'), variant: 'destructive' })
    } finally {
      setSaving(false)
    }
  }

  async function deleteProject(id: string) {
    if (!window.confirm(t('admin.projects.deleteConfirm'))) return
    const response = await fetch(`/api/admin/projects?id=${encodeURIComponent(id)}`, { method: 'DELETE' })
    if (!response.ok) {
      toast({ title: t('admin.projects.error'), description: t('admin.projects.deleteFailed'), variant: 'destructive' })
      return
    }
    setProjects((current) => current.filter((project) => project.id !== id))
    if (form.id === id) setForm(emptyForm)
    toast({ title: t('admin.projects.deleted'), description: t('admin.projects.deletedDescription') })
  }

  return (
    <div className="space-y-6" dir={dir} data-testid="project-manager">
      <Card>
        <CardHeader>
          <CardTitle>{form.id ? t('admin.projects.editTitle') : t('admin.projects.newTitle')}</CardTitle>
          <CardDescription>{t('admin.projects.description')}</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4 md:grid-cols-2" onSubmit={saveProject}>
            <label className="space-y-1 text-sm font-medium">{t('admin.projects.title')}<Input required maxLength={140} value={form.title} onChange={(event) => updateForm('title', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">{t('admin.projects.summary')}<Textarea required maxLength={400} value={form.description} onChange={(event) => updateForm('description', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">{t('admin.projects.longDescription')}<Textarea maxLength={2000} value={form.longDescription} onChange={(event) => updateForm('longDescription', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">{t('admin.projects.liveUrl')}<Input dir="ltr" type="url" placeholder="https://" value={form.liveUrl} onChange={(event) => updateForm('liveUrl', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">{t('admin.projects.githubUrl')}<Input dir="ltr" type="url" placeholder="https://github.com/" value={form.githubUrl} onChange={(event) => updateForm('githubUrl', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">{t('admin.projects.tags')}<Input placeholder="web, automation" value={form.tags} onChange={(event) => updateForm('tags', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">{t('admin.projects.sortOrder')}<Input type="number" min={0} value={form.order} onChange={(event) => updateForm('order', Number(event.target.value))} /></label>
            <div className="flex flex-wrap items-center gap-4 md:col-span-2">
              <label className="inline-flex items-center gap-2 text-sm"><input type="checkbox" checked={form.published} onChange={(event) => updateForm('published', event.target.checked)} /> {t('admin.projects.published')}</label>
              <label className="inline-flex items-center gap-2 text-sm"><input type="checkbox" checked={form.featured} onChange={(event) => updateForm('featured', event.target.checked)} /> {t('admin.projects.featured')}</label>
            </div>
            <div className="flex gap-2 md:col-span-2">
              <Button type="submit" disabled={saving}><Save className="me-2 h-4 w-4" />{saving ? t('admin.projects.saving') : t('admin.projects.save')}</Button>
              {form.id && <Button type="button" variant="outline" onClick={() => setForm(emptyForm)}><X className="me-2 h-4 w-4" />{t('admin.projects.cancel')}</Button>}
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('admin.projects.listTitle')}</CardTitle>
          <CardDescription>{loading ? t('admin.projects.loading') : `${projects.length} ${t('admin.projects.countSuffix')}`}</CardDescription>
        </CardHeader>
        <CardContent>
          {error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}
          {!loading && !error && projects.length === 0 ? <div className="rounded-md border border-dashed p-6 text-center text-muted-foreground">{t('admin.projects.empty')}</div> : null}
          <div className="space-y-3">
            {projects.map((project) => (
              <div key={project.id} className="flex flex-col gap-3 rounded-lg border p-4 md:flex-row md:items-center md:justify-between">
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <strong>{project.title}</strong>
                    <Badge variant="outline">{t('admin.projects.portfolio')}</Badge>
                    <Badge variant={project.published ? 'default' : 'secondary'}>{project.published ? t('admin.projects.published') : t('admin.projects.draft')}</Badge>
                    {project.featured && <Badge>{t('admin.projects.featured')}</Badge>}
                  </div>
                  <p className="mt-1 truncate text-sm text-muted-foreground">#{project.order} · {project.description}</p>
                </div>
                <div className="flex shrink-0 gap-2">
                  <Button type="button" variant="outline" size="sm" onClick={() => setForm(toForm(project))}><Pencil className="me-2 h-4 w-4" />{t('admin.projects.edit')}</Button>
                  <Button type="button" variant="ghost" size="sm" onClick={() => void deleteProject(project.id)} aria-label={`${t('admin.projects.delete')} ${project.title}`}><Trash2 className="h-4 w-4 text-destructive" /></Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
