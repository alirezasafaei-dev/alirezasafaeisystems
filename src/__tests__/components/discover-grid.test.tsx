import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { DiscoverGrid } from '@/components/discover/discover-grid'

const items = [
  {
    slug: 'notebooklm',
    title: 'NotebookLM',
    description: 'Research assistant grounded in your sources',
    category: 'AI',
    tags: ['research', 'productivity'],
    featured: true,
    imageUrl: null,
  },
  {
    slug: 'canva',
    title: 'Canva',
    description: 'Visual design platform',
    category: 'Design',
    tags: ['design'],
    featured: false,
    imageUrl: null,
  },
]

describe('DiscoverGrid', () => {
  it('renders internal detail links with approved Instagram attribution', () => {
    render(
      <DiscoverGrid
        items={items}
        isEn={false}
        attribution={{
          utm_source: 'instagram',
          utm_medium: 'social',
          utm_campaign: 'ai-tools',
          utm_content: 'reel-42',
        }}
      />,
    )

    const links = screen.getAllByRole('link', { name: /توضیح کوتاه و لینک رسمی/ })
    const href = links[0]?.getAttribute('href') || ''
    const parsed = new URL(href, 'https://alirezasafaeisystems.ir')

    expect(parsed.pathname).toBe('/discover/notebooklm')
    expect(parsed.searchParams.get('utm_source')).toBe('instagram')
    expect(parsed.searchParams.get('utm_medium')).toBe('social')
    expect(parsed.searchParams.get('utm_campaign')).toBe('ai-tools')
    expect(parsed.searchParams.get('utm_content')).toBe('reel-42')
  })

  it('filters cards by category and search without creating query-page URLs', () => {
    render(<DiscoverGrid items={items} isEn={false} attribution={{}} />)

    fireEvent.click(screen.getByRole('button', { name: 'Design' }))
    expect(screen.getByText('Canva')).toBeInTheDocument()
    expect(screen.queryByText('NotebookLM')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'همه' }))
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'research' } })
    expect(screen.getByText('NotebookLM')).toBeInTheDocument()
    expect(screen.queryByText('Canva')).not.toBeInTheDocument()
  })

  it('provides accessible search/filter controls and exposes the active category state', () => {
    render(<DiscoverGrid items={items} isEn={false} attribution={{}} />)

    expect(screen.getByRole('searchbox', { name: 'جستجو بین ابزارها و سرویس‌ها' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'همه' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByRole('button', { name: 'AI' })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByRole('button', { name: 'Design' })).toHaveAttribute('aria-pressed', 'false')

    fireEvent.click(screen.getByRole('button', { name: 'AI' }))

    expect(screen.getByRole('button', { name: 'همه' })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByRole('button', { name: 'AI' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByText('1 مورد')).toHaveAttribute('aria-live', 'polite')
  })
})
