"""
NL2SQL Analytics Engine
------------------------
Turns a plain-English question into a MySQL query, validates it for safety,
executes it read-only, and prints the results.

Usage:
    python app.py

Requires a .env file (see .env.example) with:
    GEMINI_API_KEY=...
    DB_HOST=localhost
    DB_USER=root
    DB_PASSWORD=...
    DB_NAME=nl2sql_demo
"""

import os
import re
import sys

from google import genai
import mysql.connector
from dotenv import load_dotenv
from tabulate import tabulate

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "nl2sql_demo")

if not GEMINI_API_KEY:
    sys.exit("Missing GEMINI_API_KEY. Copy .env.example to .env and fill it in.")

client = genai.Client(api_key=GEMINI_API_KEY)
MODEL_NAME = "gemini-2.5-flash"

# ---------------------------------------------------------------
# 1. Schema context — this is what makes the LLM "schema-aware"
#    instead of hallucinating table/column names.
# ---------------------------------------------------------------

SCHEMA_CONTEXT = """
Tables:
categories(category_id, category_name)
customers(customer_id, name, email, city, signup_date)
products(product_id, product_name, category_id, price)
orders(order_id, customer_id, order_date, status)   -- status: placed, shipped, delivered, cancelled
order_items(order_item_id, order_id, product_id, quantity, unit_price)

Relationships:
products.category_id -> categories.category_id
orders.customer_id -> customers.customer_id
order_items.order_id -> orders.order_id
order_items.product_id -> products.product_id
"""

PROMPT_TEMPLATE = """You are a MySQL expert. Given the schema below, write a single
MySQL SELECT query that answers the user's question.

Rules:
- Output ONLY the raw SQL query. No explanation, no markdown, no code fences.
- Only ever write a SELECT statement. Never write INSERT, UPDATE, DELETE, DROP,
  ALTER, TRUNCATE, CREATE, GRANT, or REVOKE.
- Only use tables/columns that exist in the schema below.
- Use JOINs instead of subqueries where a join is simpler.
- If the question is ambiguous, make the most reasonable assumption.

Schema:
{schema}

Question: {question}

SQL:"""

# ---------------------------------------------------------------
# 2. Safety layer — never trust LLM output blindly.
#    This is the piece that matters most in the interview: an LLM
#    can hallucinate or be prompt-injected, so the query is
#    validated before it ever touches the database.
# ---------------------------------------------------------------

FORBIDDEN_KEYWORDS = [
    "insert", "update", "delete", "drop", "alter", "truncate",
    "create", "grant", "revoke", "replace", "call", "exec",
    "execute", "--", "/*", "*/", ";",
]


def clean_sql(raw_text: str) -> str:
    """Strip markdown fences / stray text the model might add."""
    text = raw_text.strip()
    text = re.sub(r"^```(sql)?", "", text, flags=re.IGNORECASE).strip()
    text = re.sub(r"```$", "", text).strip()
    return text


def is_safe_select(query: str) -> bool:
    q = query.strip().lower()
    if not q.startswith("select"):
        return False
    if any(word in q for word in FORBIDDEN_KEYWORDS):
        return False
    # single statement only
    if q.count("select") > 3:  # allow a couple of subqueries, not stacked statements
        return False
    return True


def generate_sql(question: str) -> str:
    prompt = PROMPT_TEMPLATE.format(schema=SCHEMA_CONTEXT, question=question)
    response = client.models.generate_content(model=MODEL_NAME, contents=prompt)
    return clean_sql(response.text)


def run_query(query: str):
    conn = mysql.connector.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DB_NAME
    )
    try:
        cursor = conn.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        return columns, rows
    finally:
        conn.close()


def ask(question: str):
    print(f"\nQuestion: {question}")
    sql = generate_sql(question)
    print(f"Generated SQL:\n  {sql}")

    if not is_safe_select(sql):
        print("Blocked: generated query failed safety validation (not a plain SELECT).")
        return

    try:
        columns, rows = run_query(sql)
    except mysql.connector.Error as e:
        print(f"MySQL error: {e}")
        return

    if not rows:
        print("No results.")
        return

    print(tabulate(rows, headers=columns, tablefmt="psql"))


def main():
    print("NL2SQL Analytics Engine — type a question in plain English (or 'exit')")
    while True:
        question = input("\n> ").strip()
        if question.lower() in ("exit", "quit"):
            break
        if question:
            ask(question)


if __name__ == "__main__":
    main()
