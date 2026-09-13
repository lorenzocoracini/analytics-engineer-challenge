import json
import os
from sqlalchemy import create_engine, text
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(PROJECT_ROOT, "elt/transformations/target/manifest.json")

MODEL= "claude-sonnet-5"
API_KEY = os.getenv("ANTHROPIC_API_KEY") 

class SemanticAgent:
    """Simple agent to answer questions using dbt semantic layer."""
    
    def __init__(self):
        self.engine = self._connect_database()
        self.client = Anthropic(api_key=API_KEY)
        self.model = MODEL
        self.manifest_path = MANIFEST
        self.schema_context = self.load_schema_from_manifest()
    
    def _connect_database(self):
        database_url = os.getenv("DATABASE_URL")
        if not database_url:
            raise ValueError("DATABASE_URL not set in environment variables")
        return create_engine(database_url)

    def load_schema_from_manifest(self):
        """Extract schema metadata from dbt manifest.json"""
        with open(self.manifest_path) as f:
            manifest = json.load(f)
        
        schema_text = "# Available Models and Columns\n\n"
        for node_id, node in manifest.get("nodes", {}).items():
            if "model" in node_id and "marts" in node_id:
                schema_text += f"## {node['name']}\n"
                schema_text += f"Full name: analytics.{node['name']}\n"
                schema_text += f"Description: {node.get('description', 'N/A')}\n\n"
                schema_text += "Columns:\n"
                
                for col_name, col_info in node.get("columns", {}).items():
                    col_desc = col_info.get("description", "N/A")
                    schema_text += f"- `{col_name}` ({col_info.get('data_type', 'unknown')}): {col_desc}\n"
                
                schema_text += "\n"
        
        self.schema_context = schema_text
        return schema_text
    
    def generate_sql(self, question: str):
        prompt = f"""You are a SQL expert. Using ONLY this schema:
        {self.schema_context}
        IMPORTANT:
            - Use full table names: analytics.fact_loads, analytics.dim_shipper, etc
            - Do NOT use table aliases from raw data
            - Reference ONLY the tables listed above
        Answer this question by generating PostgreSQL SQL:
        {question}
        Respond with ONLY the SQL query, no explanation."""

        message = self.client.messages.create(
            model=self.model,
            max_tokens=500,
            messages=[{"role": "user", "content": prompt}]
        )
        
        sql = None
        for block in message.content:
            if block.type == "text":
                sql = block.text
                break
        
        if not sql:
            raise ValueError("No SQL generated from Claude")
        
        if sql.startswith("```"):
            sql = sql.split("```")[1]
            if sql.startswith("sql"):
                sql = sql[3:]
        
        return sql.strip()
        
    def execute_sql(self, sql: str):
        try:
            with self.engine.connect() as conn:
                result = conn.execute(text(sql))
                rows = result.fetchall()
                columns = result.keys()
                return {
                    "success": True,
                    "data": [dict(zip(columns, row)) for row in rows],
                    "error": None
                }
        except Exception as e:
            return {"success": False, "data": None, "error": str(e)}
    
    def answer_question(self, question: str):
        sql = self.generate_sql(question)
        result = self.execute_sql(sql)
        
        return {
            "question": question,
            "generated_sql": sql,
            "answer": result["data"] if result["success"] else None,
            "error": result["error"],
            "correct": result["success"]
        }