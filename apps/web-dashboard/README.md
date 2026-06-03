# Gentle Vanguard Web Dashboard

Real-time metrics dashboard for Gentle-Vanguard with WebSocket support.

## Features

- **Real-time Metrics**: Live updates via WebSocket every 5 seconds
- **Responsive Design**: Mobile-first with Tailwind CSS
- **Dark Mode**: Toggle between light and dark themes
- **Interactive Charts**: Historical data visualization with Recharts
- **Session Monitoring**: Active sessions table with status indicators

## Quick Start

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build
```

## WebSocket Server

Start the WebSocket server for real-time updates:

```bash
# Terminal 1: Start WebSocket server
node server/websocket-server.ts

# Terminal 2: Start dev server
pnpm dev
```

The dashboard will automatically connect to `ws://localhost:8080`.

## Architecture

```
apps/web-dashboard/
├── server/
│   └── websocket-server.ts    # WebSocket server for real-time metrics
├── src/
│   ├── components/
│   │   ├── Dashboard.tsx      # Main dashboard layout
│   │   ├── MetricsCard.tsx    # Metric display cards
│   │   ├── LiveChart.tsx      # Real-time charts
│   │   └── SessionTable.tsx   # Sessions table
│   ├── hooks/
│   │   ├── useMetrics.ts      # Metrics fetching (HTTP/WebSocket)
│   │   └── useWebSocket.ts    # WebSocket connection hook
│   ├── types/
│   │   └── dashboard.ts       # TypeScript types
│   └── styles/
│       └── index.css          # Tailwind styles
```

## Environment Variables

- `WS_PORT`: WebSocket server port (default: 8080)
- `VITE_API_URL`: API base URL for HTTP fallback

## Scripts

- `pnpm dev` - Start development server
- `pnpm build` - Build for production
- `pnpm preview` - Preview production build
- `pnpm lint` - Run ESLint
