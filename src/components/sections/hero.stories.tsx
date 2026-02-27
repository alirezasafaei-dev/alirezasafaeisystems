import type { Meta, StoryObj } from '@storybook/nextjs-vite'
import { Hero } from './hero'

const meta = {
  title: 'Sections/Hero',
  component: Hero,
  tags: ['autodocs'],
  parameters: {
    layout: 'fullscreen',
  },
} satisfies Meta<typeof Hero>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {}
