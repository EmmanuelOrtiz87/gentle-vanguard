import { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import { LayoutDashboard, Activity, Store, BookOpen, Bot, ListTodo, History } from 'lucide-react';
import { useSharedState } from './hooks/useSharedState';

const Dashboard = lazy(() => import('./components/Dashboard'));
const TracingDashboard = lazy(() => import('./components/TracingDashboard'));
const Marketplace = lazy(() => import('./components/Marketplace'));
const InteractiveDocs = lazy(() => import('./components/InteractiveDocs'));
const AgentChat = lazy(() => import('./components/AgentChat'));
const TaskControl = lazy(() => import('./components/TaskControl'));
const SessionTimeline = lazy(() => import('./components/SessionTimeline'));

const PageLoader = () => (
  <div className="flex items-center justify-center h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
  </div>
);

function Navigation() {
  return (
    <nav className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center">
            <span className="text-xl font-bold text-gray-900 dark:text-white">GV Dashboard</span>
          </div>
          <div className="flex items-center space-x-4">
            <Link to="/" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <LayoutDashboard className="w-4 h-4" />
              Dashboard
            </Link>
            <Link to="/tracing" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <Activity className="w-4 h-4" />
              Tracing
            </Link>
            <Link to="/marketplace" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <Store className="w-4 h-4" />
              Marketplace
            </Link>
            <Link to="/agents" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <Bot className="w-4 h-4" />
              Agents
            </Link>
            <Link to="/tasks" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <ListTodo className="w-4 h-4" />
              Tasks
            </Link>
            <Link to="/timeline" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <History className="w-4 h-4" />
              Timeline
            </Link>
            <Link to="/docs" className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700">
              <BookOpen className="w-4 h-4" />
              Docs
            </Link>
          </div>
        </div>
      </div>
    </nav>
  );
}

function TasksPage() {
  const { tasks, connected, emitEvent } = useSharedState();
  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Agent Tasks</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Monitor and control active agent tasks</p>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <TaskControl tasks={tasks} connected={connected} onEmitEvent={emitEvent} />
      </div>
    </div>
  );
}

function TimelinePage() {
  const { events, connected } = useSharedState();
  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Event Timeline</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Real-time event history from the event bus</p>
        <div className="flex items-center gap-2 mt-2">
          <span className={`w-2 h-2 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'}`} />
          <span className="text-xs text-gray-500">{connected ? 'Connected' : 'Disconnected'}</span>
        </div>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <SessionTimeline events={events} />
      </div>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <Navigation />
        <Suspense fallback={<PageLoader />}>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/tracing" element={<TracingDashboard />} />
            <Route path="/marketplace" element={<Marketplace />} />
            <Route path="/docs" element={<InteractiveDocs />} />
            <Route path="/agents" element={<AgentChat />} />
            <Route path="/tasks" element={<TasksPage />} />
            <Route path="/timeline" element={<TimelinePage />} />
          </Routes>
        </Suspense>
      </div>
    </BrowserRouter>
  );
}

export default App;
