import { useState } from 'react';
import { AlertTriangle, CheckCircle, XCircle, HelpCircle } from 'lucide-react';
import type { UIFormField } from '../types/agent';

interface HitlRequest {
  id: string;
  type: 'confirmation' | 'selection' | 'form' | 'review';
  title: string;
  description?: string;
  agent: string;
  options?: string[];
  fields?: UIFormField[];
  oldValue?: string;
  newValue?: string;
  context?: Record<string, unknown>;
}

interface HitlModalProps {
  request: HitlRequest | null;
  onResolve: (requestId: string, response: { approved?: boolean; value?: string; values?: Record<string, unknown> }) => void;
  onDismiss: () => void;
}

function ConfirmationView({ request, onResolve }: { request: HitlRequest; onResolve: (approved: boolean) => void }) {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
        <HelpCircle className="w-5 h-5 text-yellow-600 dark:text-yellow-400 flex-shrink-0" />
        <p className="text-sm text-gray-700 dark:text-gray-300">{request.description || 'Confirm this action?'}</p>
      </div>
      {request.context && (
        <div className="text-xs font-mono bg-gray-50 dark:bg-gray-800 p-2 rounded max-h-24 overflow-y-auto">
          {JSON.stringify(request.context, null, 2)}
        </div>
      )}
      <div className="flex gap-2 justify-end">
        <button onClick={() => onResolve(false)} className="px-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
          <XCircle className="w-4 h-4 inline mr-1" />Reject
        </button>
        <button onClick={() => onResolve(true)} className="px-4 py-2 text-sm rounded-lg bg-green-500 text-white hover:bg-green-600 transition-colors">
          <CheckCircle className="w-4 h-4 inline mr-1" />Approve
        </button>
      </div>
    </div>
  );
}

function SelectionView({ request, onResolve }: { request: HitlRequest; onResolve: (value: string) => void }) {
  const [selected, setSelected] = useState('');
  return (
    <div className="space-y-4">
      {request.description && <p className="text-sm text-gray-600 dark:text-gray-400">{request.description}</p>}
      <div className="space-y-1">
        {(request.options || []).map((opt) => (
          <button
            key={opt}
            onClick={() => setSelected(opt)}
            className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
              selected === opt
                ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 ring-1 ring-purple-300'
                : 'bg-gray-50 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
            }`}
          >
            {opt}
          </button>
        ))}
      </div>
      <div className="flex gap-2 justify-end">
        <button
          onClick={() => selected && onResolve(selected)}
          disabled={!selected}
          className="px-4 py-2 text-sm rounded-lg bg-purple-500 text-white hover:bg-purple-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          Confirm
        </button>
      </div>
    </div>
  );
}

function FormView({ request, onResolve }: { request: HitlRequest; onResolve: (values: Record<string, unknown>) => void }) {
  const [values, setValues] = useState<Record<string, unknown>>(() => {
    const initial: Record<string, unknown> = {};
    for (const f of request.fields || []) {
      if (f.type === 'boolean') initial[f.name] = false;
      else if (f.type === 'number') initial[f.name] = 0;
      else initial[f.name] = '';
    }
    return initial;
  });

  return (
    <div className="space-y-4">
      {request.description && <p className="text-sm text-gray-600 dark:text-gray-400">{request.description}</p>}
      <div className="space-y-3">
        {(request.fields || []).map((field) => (
          <div key={field.name}>
            <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
              {field.label}{field.required && <span className="text-red-500 ml-0.5">*</span>}
            </label>
            {field.type === 'select' ? (
              <select
                value={String(values[field.name] || '')}
                onChange={(e) => setValues({ ...values, [field.name]: e.target.value })}
                className="w-full px-3 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
              >
                <option value="">Select...</option>
                {(field.options || []).map((opt) => (
                  <option key={opt} value={opt}>{opt}</option>
                ))}
              </select>
            ) : field.type === 'boolean' ? (
              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                <input
                  type="checkbox"
                  checked={Boolean(values[field.name])}
                  onChange={(e) => setValues({ ...values, [field.name]: e.target.checked })}
                  className="rounded border-gray-300 text-purple-500 focus:ring-purple-500"
                />
                {field.label}
              </label>
            ) : field.type === 'textarea' ? (
              <textarea
                value={String(values[field.name] || '')}
                onChange={(e) => setValues({ ...values, [field.name]: e.target.value })}
                placeholder={field.placeholder}
                rows={3}
                className="w-full px-3 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
              />
            ) : (
              <input
                type={field.type === 'number' ? 'number' : 'text'}
                value={String(values[field.name] || '')}
                onChange={(e) => setValues({ ...values, [field.name]: field.type === 'number' ? Number(e.target.value) : e.target.value })}
                placeholder={field.placeholder}
                className="w-full px-3 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
              />
            )}
          </div>
        ))}
      </div>
      <div className="flex gap-2 justify-end">
        <button onClick={() => onResolve(values)} className="px-4 py-2 text-sm rounded-lg bg-purple-500 text-white hover:bg-purple-600 transition-colors">
          Submit
        </button>
      </div>
    </div>
  );
}

function ReviewView({ request, onResolve }: { request: HitlRequest; onResolve: (approved: boolean) => void }) {
  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-600 dark:text-gray-400">{request.description || 'Review the changes below:'}</p>
      <div className="grid grid-cols-2 gap-3">
        <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
          <p className="text-[10px] font-medium text-red-500 mb-1">Before</p>
          <pre className="text-xs text-red-600 dark:text-red-400 whitespace-pre-wrap font-mono">{request.oldValue}</pre>
        </div>
        <div className="p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
          <p className="text-[10px] font-medium text-green-500 mb-1">After</p>
          <pre className="text-xs text-green-600 dark:text-green-400 whitespace-pre-wrap font-mono">{request.newValue}</pre>
        </div>
      </div>
      <div className="flex gap-2 justify-end">
        <button onClick={() => onResolve(false)} className="px-4 py-2 text-sm rounded-lg border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
          <XCircle className="w-4 h-4 inline mr-1" />Reject
        </button>
        <button onClick={() => onResolve(true)} className="px-4 py-2 text-sm rounded-lg bg-green-500 text-white hover:bg-green-600 transition-colors">
          <CheckCircle className="w-4 h-4 inline mr-1" />Approve
        </button>
      </div>
    </div>
  );
}

export default function HitlModal({ request, onResolve, onDismiss }: HitlModalProps) {
  if (!request) return null;

  const typeIcons = {
    confirmation: HelpCircle,
    selection: HelpCircle,
    form: AlertTriangle,
    review: AlertTriangle,
  };
  const TypeIcon = typeIcons[request.type];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700 w-full max-w-lg mx-4 overflow-hidden">
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50">
          <div className="flex items-center gap-2">
            <TypeIcon className="w-5 h-5 text-purple-500" />
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white">{request.title}</h3>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-mono bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 px-1.5 py-0.5 rounded">{request.agent}</span>
            <span className="text-[10px] text-gray-400 capitalize">{request.type}</span>
            <button onClick={onDismiss} className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors">
              <XCircle className="w-4 h-4 text-gray-400" />
            </button>
          </div>
        </div>
        <div className="p-4">
          {request.type === 'confirmation' && <ConfirmationView request={request} onResolve={(a) => onResolve(request.id, { approved: a })} />}
          {request.type === 'selection' && <SelectionView request={request} onResolve={(v) => onResolve(request.id, { value: v })} />}
          {request.type === 'form' && <FormView request={request} onResolve={(v) => onResolve(request.id, { values: v })} />}
          {request.type === 'review' && <ReviewView request={request} onResolve={(a) => onResolve(request.id, { approved: a })} />}
        </div>
      </div>
    </div>
  );
}
