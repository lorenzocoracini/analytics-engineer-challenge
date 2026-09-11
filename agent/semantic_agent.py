import json
import os
import psycopg2
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

# LLM Config
LLM_PROVIDER = os.getenv("LLM_PROVIDER")
LLM_API_KEY = os.getenv("LLM_API_KEY")
LLM_MODEL = os.getenv("LLM_MODEL")

# Get the project root directory
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "elt/transformations/target/manifest.json")

# Database Config
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_SCHEMA = os.getenv("DB_SCHEMA", "analytics")


class SemanticAgent:
    def __init__(self):
        self.client = Anthropic(api_key=LLM_API_KEY)
        self.provider = LLM_PROVIDER
        self.model = LLM_MODEL
        self.manifest = self._load_manifest()
        self.schema_context = self._build_schema_context()
        
    def _load_manifest(self):
        with open(MANIFEST_PATH) as f:
            return json.load(f)
    
    def _build_schema_context(self):
        context = "# Available Tables\n\n"
        
        for node_key, node in self.manifest['nodes'].items():
            if node.get('resource_type') != 'model':
                continue
            
            if node['name'] not in ['dim_location', 'dim_lane']:
                continue
            
            table_name = node['name']
            full_table = f"{DB_SCHEMA}.{table_name}"
            
            context += f"\n## {table_name}\n"
            context += f"Table: {full_table}\n"
            context += f"Description: {node.get('description', 'N/A')}\n\n"
            context += "Columns:\n"
            
            for col_name, col_info in node.get('columns', {}).items():
                col_desc = col_info.get('description', 'N/A')
                context += f"- {col_name}: {col_desc}\n"
            
            context += "\n"
        
        return context
    
    def _build_system_prompt(self):
        return f"""You are an expert SQL analyst. You have access to these tables:
        {self.schema_context}
        Generate ONLY valid PostgreSQL SQL using schema: {DB_SCHEMA}.table_name
        Return ONLY the SQL query, no explanations."""
    
    def query(self, question):
        print(f"\nQuestion: {question}")
        
        response = self.client.messages.create(
            model=self.model,
            max_tokens=500,
            system=self._build_system_prompt(),
            messages=[{"role": "user", "content": question}]
        )
        
        sql = response.content[0].text.strip()
        
        if sql.startswith("```"):
            sql = sql.split("```")[1]
            if sql.startswith("sql"):
                sql = sql[3:]
        sql = sql.strip()
        
        print(f"SQL: {sql}")
        
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                port=DB_PORT,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            cur = conn.cursor()
            cur.execute(sql)
            
            rows = cur.fetchall()
            columns = [desc[0] for desc in cur.description]
            
            result = {
                "question": question,
                "sql": sql,
                "columns": columns,
                "rows": rows,
                "row_count": len(rows)
            }
            
            print(f"Result ({len(rows)} rows):")
            if len(rows) == 0:
                print("(No results)")
            elif len(rows) == 1 and len(columns) == 1:
                print(f"{columns[0]}: {rows[0][0]}")
            else:
                print(f"Columns: {', '.join(columns)}")
                for row in rows[:10]:
                    print(f"  {row}")
                if len(rows) > 10:
                    print(f"  ... and {len(rows) - 10} more rows")
            
            cur.close()
            conn.close()
            
            return result
            
        except Exception as e:
            print(f"Error: {e}")
            return {
                "question": question,
                "sql": sql,
                "error": str(e)
            }
    
    def test_questions(self):
        questions = [
            "How many unique locations are in the dataset?",
            "Which states have the most cities?",
            "How many unique lanes are there?",
            "What's the average mileage per lane?",
            "Which lane has the longest distance?",
        ]
        
        results = []
        for question in questions:
            result = self.query(question)
            results.append(result)
            print("-" * 80)
        
        return results


if __name__ == "__main__":    
    agent = SemanticAgent()
    agent.test_questions()