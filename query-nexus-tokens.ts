import Database from 'better-sqlite3';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname);
const DB_PATH = join(ROOT, '.runtime', 'gentle-vanguard.db');

console.log('Opening Nexus DB:', DB_PATH);

const db = new Database(DB_PATH, { readonly: true });

// Check if token_transactions table exists
const tableCheck = db.prepare(`SELECT name FROM sqlite_master WHERE type='table' AND name='token_transactions'`).get();
if (!tableCheck) {
    console.log('Table token_transactions not found. Checking available tables:');
    const tables = db.prepare(`SELECT name FROM sqlite_master WHERE type='table'`).all();
    console.table(tables);
    db.close();
    process.exit(1);
}

// Top sessions by input tokens desde la tabla token_transactions
console.log('\n=== TOP 15 SESSIONS BY INPUT TOKENS (Nexus) ===');
const topSessions = db.prepare(`
    SELECT 
        session_id,
        SUM(input_tokens) as total_input,
        SUM(output_tokens) as total_output,
        SUM(reasoning_tokens) as total_reasoning,
        SUM(cache_read_tokens) as total_cache_read,
        SUM(cache_write_tokens) as total_cache_write,
        SUM(cost) as total_cost,
        COUNT(*) as transaction_count,
        MAX(CASE WHEN agent = 'orchestrator' THEN 1 ELSE 0 END) as has_orchestrator,
        MAX(CASE WHEN agent = 'subagent' THEN 1 ELSE 0 END) as has_subagent
    FROM token_transactions 
    GROUP BY session_id
    HAVING total_input > 100000
    ORDER BY total_input DESC 
    LIMIT 15
`).all();
console.table(topSessions);

// Total stats
console.log('\n=== OVERALL NEXUS TOKEN STATISTICS ===');
const totals = db.prepare(`
    SELECT 
        COUNT(DISTINCT session_id) as total_sessions,
        SUM(input_tokens) as total_input,
        SUM(output_tokens) as total_output,
        SUM(reasoning_tokens) as total_reasoning,
        SUM(cache_read_tokens) as total_cache_read,
        SUM(cost) as total_cost,
        COUNT(*) as total_transactions
    FROM token_transactions
`).get();
console.table([totals]);

// Agent breakdown
console.log('\n=== TOKEN CONSUMPTION BY AGENT TYPE ===');
const byAgent = db.prepare(`
    SELECT 
        agent,
        COUNT(*) as transactions,
        SUM(input_tokens) as input_tokens,
        SUM(output_tokens) as output_tokens,
        ROUND(100.0 * SUM(input_tokens) / (SELECT SUM(input_tokens) FROM token_transactions), 2) as pct_input
    FROM token_transactions
    GROUP BY agent
    ORDER BY input_tokens DESC
`).all();
console.table(byAgent);

db.close();
console.log('\nDone!');
