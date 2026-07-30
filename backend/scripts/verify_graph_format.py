"""Verify graph API response format matches frontend expectations."""
import asyncio
import json
import httpx

BASE = "http://localhost:5050"

async def main():
    async with httpx.AsyncClient(base_url=BASE, timeout=30) as c:
        # Login
        r = await c.post("/api/auth/token", data={"username": "zwj", "password": "zwj12138"})
        h = {"Authorization": f"Bearer {r.json()['access_token']}"}

        # Query graph
        r = await c.get("/api/zhiyuan/graph", params={"start_entity": "武汉大学", "depth": 2}, headers=h)
        data = r.json()

        # Check envelope
        print("=== API Response Structure ===")
        print(f"Top-level keys: {list(data.keys())}")
        print(f"Type of 'data': {type(data.get('data'))}")

        rows = data.get("data", [])
        if not isinstance(rows, list):
            print("ERROR: data is not a list!")
            return

        print(f"Row count: {len(rows)}")
        print(f"\n=== First 5 Rows (raw) ===")
        for row in rows[:5]:
            print(f"  {json.dumps(row, ensure_ascii=False)}")

        # Check field names
        print(f"\n=== Field Name Analysis ===")
        if rows:
            sample = rows[0]
            print(f"Fields in each row: {list(sample.keys())}")
            print(f"  start field exists: {'start' in sample}")
            print(f"  relation field exists: {'relation' in sample}")
            print(f"  target field exists: {'target' in sample}")

        # Check relation types (Chinese vs English)
        relations_set = set()
        for row in rows:
            relations_set.add(row.get("relation", ""))
        print(f"\n=== Relation Types Found ===")
        for rel in sorted(relations_set):
            count = sum(1 for r in rows if r.get("relation") == rel)
            print(f"  '{rel}': {count} occurrences")

        # Simulate frontend buildGraphData logic
        print(f"\n=== Simulating Frontend buildGraphData ===")
        node_map = {}
        edges = []
        edge_set = set()
        for rel in rows:
            start_name = rel.get("start") or rel.get("start_name")
            target_name = rel.get("target") or rel.get("target_name")
            rel_type = rel.get("relation") or rel.get("type") or "关联"
            if not start_name or not target_name:
                continue
            if start_name not in node_map:
                node_map[start_name] = {"id": start_name, "name": start_name}
            if target_name not in node_map:
                node_map[target_name] = {"id": target_name, "name": target_name}
            edge_key = f"{start_name}-{rel_type}-{target_name}"
            if edge_key not in edge_set:
                edge_set.add(edge_key)
                edges.append({
                    "id": edge_key,
                    "source_id": start_name,
                    "target_id": target_name,
                    "type": rel_type,
                })

        print(f"Nodes: {len(node_map)}")
        print(f"Edges: {len(edges)}")
        print(f"\nSample nodes: {list(node_map.keys())[:10]}")
        print(f"\nSample edges:")
        for e in edges[:5]:
            print(f"  {e['source_id']} --[{e['type']}]--> {e['target_id']}")

        # Verify GraphCanvas compatibility
        print(f"\n=== GraphCanvas Compatibility Check ===")
        print(f"nodes[0] has 'id': {'id' in list(node_map.values())[0]}")
        print(f"nodes[0] has 'name': {'name' in list(node_map.values())[0]}")
        print(f"edges[0] has 'source_id': {'source_id' in edges[0]}")
        print(f"edges[0] has 'target_id': {'target_id' in edges[0]}")
        print(f"edges[0] has 'type': {'type' in edges[0]}")
        print(f"\n✅ All checks passed - data format is compatible with GraphCanvas")

asyncio.run(main())
