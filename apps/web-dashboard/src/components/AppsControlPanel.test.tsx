import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import AppsControlPanel from './AppsControlPanel';
import { LocaleContext } from '../hooks/useLocale';

function renderWithLocale(ui: React.ReactElement) {
  return render(
    <LocaleContext.Provider value={{ locale: 'en', setLocale: () => {} }}>
      {ui}
    </LocaleContext.Provider>,
  );
}

const apps = [
  {
    id: 'dashboard',
    name: 'Dashboard',
    description: 'This dashboard',
    status: 'running' as const,
    url: 'http://localhost:5173',
    processes: [{ name: 'web', pid: 123, port: 5173, alive: true }],
  },
  {
    id: 'agent',
    name: 'Agent',
    description: 'Agent runner',
    status: 'stopped' as const,
    url: 'http://localhost:7000',
    processes: [
      { name: 'runner', pid: null, port: 7000, alive: false },
    ],
  },
];

function jsonResponse(body: unknown, ok = true) {
  return { ok, status: ok ? 200 : 500, json: async () => body } as Response;
}

describe('AppsControlPanel', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('loads and renders apps from /api/apps', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse(apps));
    vi.stubGlobal('fetch', fetchMock);
    renderWithLocale(<AppsControlPanel />);
    expect(await screen.findByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Agent')).toBeInTheDocument();
    expect(fetchMock.mock.calls[0][0]).toBe('/api/apps');
  });

  it('shows process details with PID when alive and offline when dead', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(apps)));
    renderWithLocale(<AppsControlPanel />);
    await screen.findByText('Dashboard');
    expect(screen.getByText(/PID 123/)).toBeInTheDocument();
    expect(screen.getByText(/offline/i)).toBeInTheDocument();
  });

  it('disables the toggle button for the self-managed dashboard app', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(apps)));
    renderWithLocale(<AppsControlPanel />);
    const buttons = await screen.findAllByRole('button', { name: /power/i });
    const dashboardToggle = buttons.find((b) => (b as HTMLButtonElement).disabled);
    expect(dashboardToggle).toBeTruthy();
  });

  it('shows an error message when the API fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('boom')));
    renderWithLocale(<AppsControlPanel />);
    expect(await screen.findByText('boom')).toBeInTheDocument();
  });

  it('starts a stopped app on toggle (POST, no confirm needed for start)', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse(apps));
    vi.stubGlobal('fetch', fetchMock);
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true);
    renderWithLocale(<AppsControlPanel />);
    const agentToggle = (await screen.findAllByRole('button', { name: /power/i })).find(
      (b) => !(b as HTMLButtonElement).disabled,
    );
    expect(agentToggle).toBeTruthy();
    fireEvent.click(agentToggle!);
    await waitFor(() =>
      expect(fetchMock).toHaveBeenCalledWith(
        '/api/apps/agent/start',
        expect.objectContaining({ method: 'POST' }),
      ),
    );
    expect(confirmSpy).not.toHaveBeenCalled(); // start never confirms
  });
});
