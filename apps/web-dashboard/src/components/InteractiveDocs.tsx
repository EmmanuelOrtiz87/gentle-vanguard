import { useState } from 'react';
import { ChevronRight, ChevronDown, Play, CheckCircle, Book, Code, Terminal } from 'lucide-react';

interface Tutorial {
  id: string;
  title: string;
  description: string;
  steps: Step[];
  completed: boolean;
}

interface Step {
  id: string;
  title: string;
  content: string;
  code?: string;
  completed: boolean;
}

const tutorials: Tutorial[] = [
  {
    id: 'getting-started',
    title: 'Getting Started',
    description: 'Learn the basics of Gentle-Vanguard',
    completed: false,
    steps: [
      {
        id: 'step1',
        title: 'What is Gentle-Vanguard?',
        content: 'Gentle-Vanguard is an AI orchestration layer that provides structure, memory, and governance to AI-assisted development.',
        completed: false,
      },
      {
        id: 'step2',
        title: 'Your First Skill',
        content: 'Skills are the building blocks. Let us create your first skill.',
        code: 'gv skill create my-first-skill',
        completed: false,
      },
      {
        id: 'step3',
        title: 'Execute a Skill',
        content: 'Now let us run your skill.',
        code: 'gv skill run my-first-skill',
        completed: false,
      },
    ],
  },
  {
    id: 'advanced-features',
    title: 'Advanced Features',
    description: 'Master advanced capabilities',
    completed: false,
    steps: [
      {
        id: 'step1',
        title: 'Team Mode',
        content: 'Use multiple agents in parallel for complex tasks.',
        code: 'gv team-mode --agents DEV,QA,DOC',
        completed: false,
      },
      {
        id: 'step2',
        title: 'Tracing',
        content: 'Monitor execution with OpenTelemetry tracing.',
        code: 'gv tracing status',
        completed: false,
      },
    ],
  },
];

export function InteractiveDocs() {
  const [activeTutorial, setActiveTutorial] = useState<string | null>(null);
  const [completedSteps, setCompletedSteps] = useState<Set<string>>(new Set());
  const [expandedTutorials, setExpandedTutorials] = useState<Set<string>>(new Set());

  const toggleTutorial = (id: string) => {
    const newExpanded = new Set(expandedTutorials);
    if (newExpanded.has(id)) {
      newExpanded.delete(id);
    } else {
      newExpanded.add(id);
    }
    setExpandedTutorials(newExpanded);
  };

  const completeStep = (tutorialId: string, stepId: string) => {
    const key = `${tutorialId}-${stepId}`;
    const newCompleted = new Set(completedSteps);
    newCompleted.add(key);
    setCompletedSteps(newCompleted);
  };

  const isStepCompleted = (tutorialId: string, stepId: string) => {
    return completedSteps.has(`${tutorialId}-${stepId}`);
  };

  const getProgress = (tutorial: Tutorial) => {
    const completed = tutorial.steps.filter((s) => isStepCompleted(tutorial.id, s.id)).length;
    return Math.round((completed / tutorial.steps.length) * 100);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Interactive Documentation</h1>
        <p className="text-gray-600 dark:text-gray-400">Learn Gentle-Vanguard through guided tutorials</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Tutorial List */}
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <Book className="w-5 h-5" />
            Tutorials
          </h2>
          {tutorials.map((tutorial) => (
            <div
              key={tutorial.id}
              className="card cursor-pointer"
              onClick={() => toggleTutorial(tutorial.id)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  {expandedTutorials.has(tutorial.id) ? (
                    <ChevronDown className="w-5 h-5 text-gray-500" />
                  ) : (
                    <ChevronRight className="w-5 h-5 text-gray-500" />
                  )}
                  <div>
                    <h3 className="font-medium text-gray-900 dark:text-white">{tutorial.title}</h3>
                    <p className="text-sm text-gray-500">{tutorial.description}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-500">{getProgress(tutorial)}%</span>
                  {getProgress(tutorial) === 100 && (
                    <CheckCircle className="w-5 h-5 text-green-500" />
                  )}
                </div>
              </div>

              {/* Progress Bar */}
              <div className="mt-3 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-600 transition-all duration-300"
                  style={{ width: `${getProgress(tutorial)}%` }}
                />
              </div>

              {/* Steps */}
              {expandedTutorials.has(tutorial.id) && (
                <div className="mt-4 space-y-2">
                  {tutorial.steps.map((step, index) => (
                    <div
                      key={step.id}
                      className={`flex items-center gap-3 p-2 rounded-lg cursor-pointer transition-colors ${
                        activeTutorial === `${tutorial.id}-${step.id}`
                          ? 'bg-blue-50 dark:bg-blue-900/20'
                          : 'hover:bg-gray-50 dark:hover:bg-gray-800'
                      }`}
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveTutorial(`${tutorial.id}-${step.id}`);
                      }}
                    >
                      <span className="flex-shrink-0 w-6 h-6 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-sm font-medium text-gray-600 dark:text-gray-400">
                        {index + 1}
                      </span>
                      <span className={`flex-1 ${isStepCompleted(tutorial.id, step.id) ? 'line-through text-gray-400' : ''}`}>
                        {step.title}
                      </span>
                      {isStepCompleted(tutorial.id, step.id) && (
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Active Step Content */}
        <div className="lg:col-span-2">
          {activeTutorial ? (
            (() => {
              const [tutorialId, stepId] = activeTutorial.split('-');
              const tutorial = tutorials.find((t) => t.id === tutorialId);
              const step = tutorial?.steps.find((s) => s.id === stepId);

              if (!step) return null;

              return (
                <div className="card">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white">{step.title}</h2>
                    {!isStepCompleted(tutorialId, stepId) && (
                      <button
                        onClick={() => completeStep(tutorialId, stepId)}
                        className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                      >
                        <CheckCircle className="w-4 h-4" />
                        Mark Complete
                      </button>
                    )}
                  </div>

                  <div className="prose dark:prose-invert max-w-none mb-6">
                    <p className="text-gray-700 dark:text-gray-300">{step.content}</p>
                  </div>

                  {step.code && (
                    <div className="bg-gray-900 rounded-lg p-4 mb-4">
                      <div className="flex items-center gap-2 mb-2 text-gray-400">
                        <Terminal className="w-4 h-4" />
                        <span className="text-sm">Terminal</span>
                      </div>
                      <code className="text-green-400 font-mono text-sm">{step.code}</code>
                    </div>
                  )}

                  <div className="flex items-center gap-4">
                    <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                      <Play className="w-4 h-4" />
                      Try It
                    </button>
                    <button className="flex items-center gap-2 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800">
                      <Code className="w-4 h-4" />
                      View Code
                    </button>
                  </div>
                </div>
              );
            })()
          ) : (
            <div className="card flex items-center justify-center h-96">
              <div className="text-center">
                <Book className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">Select a tutorial to get started</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default InteractiveDocs;
