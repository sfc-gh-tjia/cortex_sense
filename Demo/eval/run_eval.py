"""
Eval runner: sends all questions to both agents and captures results.
Usage: python demo/eval/run_eval.py
"""
import json
import time
from pathlib import Path
from snowflake.connector import connect

DB = "DB_ONTOLOGY_CONTROL_PLANE"
SCHEMA = "SAP_PRODUCTION"
BASELINE = f"{DB}.{SCHEMA}.BASELINE_SUPPLY_CHAIN_AGENT"
SENSE = f"{DB}.{SCHEMA}.SENSE_SUPPLY_CHAIN_AGENT"


def invoke(conn, agent_fqn, question):
    cur = conn.cursor()
    req = json.dumps({"messages": [{"role": "user", "content": [{"type": "text", "text": question}]}]})
    sql = f"SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN('{agent_fqn}', $${req}$$) AS response"
        result = cur.fetchone()[0]
        elapsed = round(time.time() - start, 1)
        parsed = json.loads(result) if isinstance(result, str) else result
        text = ""
        if isinstance(parsed, dict):
            for msg in parsed.get("messages", []):
                if msg.get("role") == "assistant":
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        text = "\n".join(c.get("text", "") for c in content if c.get("type") == "text")
                    else:
                        text = str(content)
        return {"text": text or str(parsed), "elapsed": elapsed}
    except Exception as e:
        return {"text": f"ERROR: {e}", "elapsed": 0}


def main():
    questions_path = Path(__file__).parent / "questions.json"
    with open(questions_path) as f:
        data = json.load(f)

    conn = connect(connection_name="default")
    results = []

    for q in data["eval_questions"]:
        print(f"\n[{q['id']}] {q['question'][:70]}...")
        print("  Baseline...", end=" ", flush=True)
        bl = invoke(conn, BASELINE, q["question"])
        print(f"{bl['elapsed']}s")
        print("  Sense...", end=" ", flush=True)
        se = invoke(conn, SENSE, q["question"])
        print(f"{se['elapsed']}s")

        results.append({
            "id": q["id"],
            "tier": q["tier"],
            "question": q["question"],
            "expected": q["expected"],
            "baseline_response": bl["text"][:2000],
            "baseline_time": bl["elapsed"],
            "sense_response": se["text"][:2000],
            "sense_time": se["elapsed"],
        })

    output_path = Path(__file__).parent / f"eval_results_{int(time.time())}.json"
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved to {output_path}")

    # Summary
    print("\n=== SUMMARY ===")
    for tier in ["A", "B", "C", "D", "E", "X"]:
        tier_qs = [r for r in results if r["tier"] == tier]
        if tier_qs:
            print(f"Tier {tier}: {len(tier_qs)} questions")


if __name__ == "__main__":
    main()
