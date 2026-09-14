# Agent

Text-to-SQL agent that answers questions about the `analytics` marts. It reasons only over **metadata** (dbt model/column descriptions from `manifest.json`) and gets facts by **executing SQL** against Postgres — no table rows are ever loaded into the prompt.

## How it works

`SemanticAgent` ([`semantic_agent.py`](semantic_agent.py)):

1. `load_schema_from_manifest()` — reads `elt/transformations/target/manifest.json` and builds a text description of every mart model (name, description, columns) as schema context.
2. `generate_sql(question)` — sends that schema context + the question to Claude, asking for a PostgreSQL query back.
3. `execute_sql(sql)` — runs the generated query against the database and returns the rows.
4. `answer_question(question)` — wraps the three steps above and returns `{question, generated_sql, answer, error, correct}`.

## Files

- [`semantic_agent.py`](semantic_agent.py) — the agent class.
- [`questions/ask_questions.ipynb`](questions/ask_questions.ipynb) — runs the challenge questions (Q1–Q12) through the agent, one cell per question.
- [`questions/questions_results.md`](questions/questions_results.md) — final results table: question, generated SQL, answer, correct?, iterations needed, notes.
- [`questions/iteration_log.md`](questions/iteration_log.md) — working log for questions that needed more than one pass (wrong/ambiguous first attempt, how it was diagnosed and fixed).

## Setup

**Model:** Anthropic Claude (`claude-sonnet-5`), via the `anthropic` Python SDK. Any LLM provider would work here (the prompt only needs schema metadata + question in, SQL out).

Requires the dbt project to have been built at least once (`dbt run` in `elt/transformations`), since the agent reads its `target/manifest.json`.

Environment variables (see [`.env.example`](../.env.example)):

```
DATABASE_URL=postgresql://user:password@localhost:5432/loadsmart_db
ANTHROPIC_API_KEY=sk-...
```

## Usage

```python
from semantic_agent import SemanticAgent

agent = SemanticAgent()
result = agent.answer_question("Which shipper had the highest total book price?")
```

Or open [`questions/ask_questions.ipynb`](questions/ask_questions.ipynb) to run the full question set interactively.
