import { ImageResponse } from 'next/og'

export const runtime = 'edge'

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          fontSize: 72,
          background: 'linear-gradient(to bottom right, #0f172a, #1e3a8a)',
          color: 'white',
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: 'system-ui, sans-serif',
        }}
      >
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '24px',
          }}
        >
          <div
            style={{
              fontSize: '64px',
              fontWeight: 'bold',
              background: 'linear-gradient(to right, #60a5fa, #34d399)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
            }}
          >
            AliReza Safaei
          </div>
          <div
            style={{
              fontSize: '30px',
              opacity: 0.9,
              textAlign: 'center',
            }}
          >
            Web Systems Engineer
          </div>
          <div
            style={{
              fontSize: '22px',
              opacity: 0.7,
              marginTop: '16px',
            }}
          >
            Architecture | End-to-End Delivery | Production Readiness
          </div>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  )
}
