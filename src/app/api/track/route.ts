import { NextRequest, NextResponse } from 'next/server';
import { db as prisma } from '@/lib/db';

interface TrackingPayload {
  site: 'toolbox' | 'portfolio' | 'audit';
  event: string;
  properties?: Record<string, any>;
  timestamp: number;
  sessionId: string;
  userId?: string;
}

export async function POST(request: NextRequest) {
  try {
    const payload: TrackingPayload = await request.json();

    // Validate payload
    if (!payload.site || !payload.event || !payload.sessionId) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Extract IP and User-Agent
    const ip =
      request.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
      request.headers.get('x-real-ip') ||
      'unknown';
    const userAgent = request.headers.get('user-agent') || 'unknown';

    // Store analytics event
    await prisma.analyticsEvent.create({
      data: {
        site: payload.site,
        event: payload.event,
        properties: JSON.stringify(payload.properties || {}),
        sessionId: payload.sessionId,
        userId: payload.userId || null,
        timestamp: new Date(payload.timestamp),
        ip,
        userAgent,
      },
    });

    // Update funnel conversion tracking
    await updateFunnelConversion(payload);

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error('[Analytics API] Error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * Update funnel conversion state based on event
 */
async function updateFunnelConversion(payload: TrackingPayload) {
  try {
    // Find or create funnel record
    const funnel = await prisma.funnelConversion.findUnique({
      where: { sessionId: payload.sessionId },
    });

    const updates: any = {};

    // Determine entry point
    if (!funnel) {
      updates.entryPoint = payload.site;
    }

    // Track site visits
    if (payload.site === 'toolbox' && payload.event === 'page_view') {
      updates.visitedToolbox = true;
    }
    if (payload.site === 'portfolio' && payload.event === 'page_view') {
      updates.visitedPortfolio = true;
    }
    if (payload.site === 'audit' && payload.event === 'page_view') {
      updates.visitedAudit = true;
    }

    // Track contact/conversion
    if (payload.event === 'contact_submit') {
      updates.contacted = true;
    }
    if (payload.event === 'conversion') {
      updates.converted = true;
      updates.conversionValue = payload.properties?.value || 0;
    }

    // Upsert funnel record
    await prisma.funnelConversion.upsert({
      where: { sessionId: payload.sessionId },
      create: {
        sessionId: payload.sessionId,
        entryPoint: updates.entryPoint || payload.site,
        visitedToolbox: updates.visitedToolbox || false,
        visitedPortfolio: updates.visitedPortfolio || false,
        visitedAudit: updates.visitedAudit || false,
        contacted: updates.contacted || false,
        converted: updates.converted || false,
        conversionValue: updates.conversionValue || null,
      },
      update: updates,
    });
  } catch (error) {
    console.error('[Funnel Tracking] Error:', error);
    // Don't throw - analytics failures shouldn't break the app
  }
}
