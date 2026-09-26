# NL2SQL Analytics Engine

Ask a business question in plain English → get a validated MySQL query,
executed safely, with results printed as a table.

```
"Which 3 customers have spent the most overall?"
        │
        ▼
  [Gemini + schema context]  ──►  generates SQL
        │
        ▼
  [Safety validator]  ──►  blocks anything that isn't a clean SELECT
        │
        ▼
  [MySQL]  ──►  executes, returns rows
        │
        ▼
  Table printed to console
```

## Why this project

Most "SQL projects" are a sales dashboard with a few `GROUP BY` queries.
This one is closer to what a data/AI analytics company actually
builds internally: a conversational layer over a real relational
schema, with the safety and validation work that makes it usable in
practice rather than a toy demo.

## Setup

```bash
pip install -r requirements.txt
mysql -u root -p < schema.sql
cp .env.example .env   # fill in GEMINI_API_KEY and DB_PASSWORD
python app.py
```

Get a free Gemini API key at https://aistudio.google.com/app/apikey

## Try these questions

- "How many orders has each customer placed?"
- "What is the total revenue by product category?"
- "List the top 5 best-selling products by quantity."
- "Which customers signed up in 2024 but never placed an order?"
- "What's the average order value for delivered orders?"
- "Show monthly revenue trend for 2024."


**Schema-aware prompting.** The model is never asked to guess table or
column names — the exact schema is injected into every prompt, which is
the difference between an LLM that hallucinates a `total_amount` column
that doesn't exist and one that writes a query that actually runs.

**Validation before execution, not instead of it.** The model output is
treated as untrusted input: it's stripped of markdown, checked that it
starts with `SELECT`, and scanned for write/DDL keywords and statement
stacking before it ever reaches the database. This is the same instinct
behind the hallucination-detection work in HalluXAI — don't trust a
generative model's output at face value, verify it structurally.

**Read-only by design.** In a production version, the DB user this
connects as would only have `SELECT` grants at the MySQL level too —
defense in depth, not just app-level filtering.




