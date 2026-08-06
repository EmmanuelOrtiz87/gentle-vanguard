## Identifying Loops in Systems

### Step 1: Define the Problem

Boundary the system: what's in, what's out. Identify the behavior-over-time graph (BOT).

### Step 2: List Key Variables

Stock variables (accumulations): users, revenue, quality, morale Flow variables (rates):
acquisition, churn, spending, hiring

### Step 3: Map Causal Connections

Draw arrows. Mark polarity:

- **(+)** Same direction: A increases → B increases; A decreases → B decreases
- **(−)** Opposite direction: A increases → B decreases

Track each pair: "If X goes up, does Y go up or down?"

### Step 4: Identify Loop Polarity

Walk the chain. Count minus signs:

- **Even** number of (−) signs → Reinforcing loop (R)
- **Odd** number of (−) signs → Balancing loop (B)

Label each loop with its function: R-Addiction, B-Correction, etc.

### Heuristics

- R loops: "more leads to more" or "less leads to less"
- B loops: "too much triggers correction back toward goal"
- If it oscillates, there's a B loop with a delay
- If it grows or collapses, an R loop is dominant
