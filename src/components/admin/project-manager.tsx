'use client'

import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Save, Trash2, X } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { toast } from '@/hooks/use-toast'

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
  const [projects, setProjects] = useState<Project[]>([])
  const [form, setForm] = useState<ProjectForm>(emptyForm)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const loadProjects = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await fetch('/api/admin/projects?contentType=portfolio&published=all', { cache: 'no-store' })
      if (response.status === 401) throw new Error('Authentication required')
      if (!response.ok) throw new Error('Failed to load projects')
      const data = await response.json() as { projects?: Project[] }
      setProjects(data.projects || [])
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Failed to load projects')
    } finally {
      setLoading(false)
    }
  }, [])

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
      const data = await response.json() as { project?: Project; error?: string }
      if (!response.ok || !data.project) throw new Error(data.error || 'Failed to save project')
      const savedProject = data.project
      setProjects((current) => form.id
        ? current.map((project) => project.id === savedProject.id ? savedProject : project)
        : [savedProject, ...current])
      setForm(emptyForm)
      toast({ title: 'Saved', description: 'Portfolio project saved successfully' })
    } catch (saveError) {
      toast({ title: 'Error', description: saveError instanceof Error ? saveError.message : 'Failed to save project', variant: 'destructive' })
    } finally {
      setSaving(false)
    }
  }

  async function deleteProject(id: string) {
    if (!window.confirm('Delete this portfolio project permanently?')) return
    const response = await fetch(`/api/admin/projects?id=${encodeURIComponent(id)}`, { method: 'DELETE' })
    if (!response.ok) {
      toast({ title: 'Error', description: 'Failed to delete project', variant: 'destructive' })
      return
    }
    setProjects((current) => current.filter((project) => project.id !== id))
    if (form.id === id) setForm(emptyForm)
    toast({ title: 'Deleted', description: 'Portfolio project deleted successfully' })
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{form.id ? 'Edit portfolio project' : 'New portfolio project'}</CardTitle>
          <CardDescription>Manage portfolio projects separately from the Discover acquisition library.</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4 md:grid-cols-2" onSubmit={saveProject}>
            <label className="space-y-1 text-sm font-medium">Title<Input required maxLength={140} value={form.title} onChange={(event) => updateForm('title', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">Description<Textarea required maxLength={400} value={form.description} onChange={(event) => updateForm('description', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">Long description<Textarea maxLength={2000} value={form.longDescription} onChange={(event) => updateForm('longDescription', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">Live HTTPS URL<Input type="url" placeholder="https://" value={form.liveUrl} onChange={(event) => updateForm('liveUrl', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">GitHub HTTPS URL<Input type="url" placeholder="https://github.com/" value={form.githubUrl} onChange={(event) => updateForm('githubUrl', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">Tags<Input placeholder="web, automation" value={form.tags} onChange={(event) => updateForm('tags', event.target.value)} /></label>
            <label className="space-y-1 text-sm font-medium">Sort order<Input type="number" min={0} value={form.order} onChange={(event) => updateForm('order', Number(event.target.value))} /></label>
            <div className="flex flex-wrap items-center gap-4 md:col-span-2">
              <label className="inline-flex items-center gap-2 text-sm"><input type="checkbox" checked={form.published} onChange={(event) => updateForm('published', event.target.checked)} /> Published</label>
              <label className="inline-flex items-center gap-2 text-sm"><input type="checkbox" checked={form.featured} onChange={(event) => updateForm('featured', event.target.checked)} /> Featured</label>
            </div>
            <div className="flex gap-2 md:col-span-2">
              <Button type="submit" disabled={saving}><Save className="me-2 h-4 w-4" />{saving ? 'Saving…' : 'Save project'}</Button>
              {form.id && <Button type="button" variant="outline" onClick={() => setForm(emptyForm)}><X className="me-2 h-4 w-4" />Cancel</Button>}
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Portfolio projects</CardTitle><CardDescription>{loading ? 'Loading…' : `${projects.length} project(s)`}</CardDescription></CardHeader>
        <CardContent>
          {error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}
          {!loading && !error && projects.length === 0 ? <div className="rounded-md border border-dashed p-6 text-center text-muted-foreground">No portfolio projects yet.</div> : null}
          <div className="space-y-3">
            {projects.map((project) => (
              <div key={project.id} className="flex flex-col gap-3 rounded-lg border p-4 md:flex-row md:items-center md:justify-between">
                <div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><strong>{project.title}</strong><Badge variant="outline">portfolio</Badge><Badge variant={project.published ? 'default' : 'secondary'}>{project.published ? 'Published' : 'Draft'}</Badge>{project.featured && <Badge>Featured</Badge>}</div><p className="mt-1 truncate text-sm text-muted-foreground">#{project.order} · {project.description}</p></div>
                <div className="flex shrink-0 gap-2"><Button type="button" variant="outline" size="sm" onClick={() => setForm(toForm(project))}><Pencil className="me-2 h-4 w-4" />Edit</Button><Button type="button" variant="ghost" size="sm" onClick={() => void deleteProject(project.id)} aria-label={`Delete ${project.title}`}><Trash2 className="h-4 w-4 text-destructive" /></Button></div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
