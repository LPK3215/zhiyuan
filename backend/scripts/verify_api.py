"""End-to-end API verification for zhiyuan endpoints."""
import asyncio
import json
import httpx

BASE = "http://localhost:5050"


async def main():
    async with httpx.AsyncClient(base_url=BASE, timeout=30) as client:
        # 1. Login
        resp = await client.post(
            "/api/auth/token",
            data={"username": "zwj", "password": "zwj12138"},
        )
        resp.raise_for_status()
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f"[OK] Login successful, token={token[:30]}...")

        # 2. Universities search (keyword=河南)
        resp = await client.get(
            "/api/zhiyuan/universities",
            params={"keyword": "河南", "limit": 5},
            headers=headers,
        )
        data = resp.json()
        items = data.get("data", [])
        print(f"\n=== 1. Universities (keyword=河南) ===")
        print(f"  Status: {resp.status_code}, Count: {len(items)}")
        for u in items[:3]:
            print(f"  - {u['name']} ({u.get('level','')}, {u.get('province','')})")

        # 3. Scores (province=河南, year=2024)
        resp = await client.get(
            "/api/zhiyuan/scores",
            params={"province": "河南", "year": 2024},
            headers=headers,
        )
        data = resp.json()
        items = data.get("data", [])
        print(f"\n=== 2. Scores (province=河南, year=2024) ===")
        print(f"  Status: {resp.status_code}, Count: {len(items)}")
        for s in items[:3]:
            print(f"  - {s.get('university_name','?')} | {s.get('major_name','?')} | min_score={s.get('min_score','?')}")

        # 4. Rank (year=0 → auto-latest)
        resp = await client.get(
            "/api/zhiyuan/rank",
            params={"score": 600, "province": "河南", "year": 0, "subject_type": "理科"},
            headers=headers,
        )
        print(f"\n=== 3. Rank (score=600, province=河南, year=0 auto) ===")
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json().get("data", {})
            print(f"  Year resolved to: {data.get('year')}")
            print(f"  Score: {data.get('score')}, Rank: {data.get('rank')}")
            print(f"  Province: {data.get('province')}, Batch: {data.get('batch')}")
        else:
            print(f"  Response: {resp.text[:200]}")

        # 5. Rank (year=2024)
        resp = await client.get(
            "/api/zhiyuan/rank",
            params={"score": 600, "province": "河南", "year": 2024, "subject_type": "理科"},
            headers=headers,
        )
        print(f"\n=== 4. Rank (score=600, province=河南, year=2024) ===")
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json().get("data", {})
            print(f"  Year: {data.get('year')}, Score: {data.get('score')}, Rank: {data.get('rank')}")
        else:
            print(f"  Response: {resp.text[:200]}")

        # 6. Rank (year=2025)
        resp = await client.get(
            "/api/zhiyuan/rank",
            params={"score": 600, "province": "河南", "year": 2025, "subject_type": "理科"},
            headers=headers,
        )
        print(f"\n=== 5. Rank (score=600, province=河南, year=2025) ===")
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json().get("data", {})
            print(f"  Year: {data.get('year')}, Score: {data.get('score')}, Rank: {data.get('rank')}")
        else:
            print(f"  Response: {resp.text[:200]}")

        # 7. Graph query (using an entity that exists in the seed data)
        resp = await client.get(
            "/api/zhiyuan/graph",
            params={"start_entity": "武汉大学", "depth": 2},
            headers=headers,
        )
        print(f"\n=== 6. Graph (start_entity=武汉大学) ===")
        print(f"  Status: {resp.status_code}")
        data = resp.json()
        if isinstance(data.get("data"), list):
            print(f"  Results: {len(data['data'])} rows")
            for row in data["data"][:3]:
                print(f"  - {row}")
        else:
            print(f"  Message: {data.get('message')}")
            print(f"  Data: {str(data.get('data'))[:200]}")

        # 8. Admin universities LIKE injection test (keyword=%)
        resp = await client.get(
            "/api/zhiyuan/admin/universities",
            params={"keyword": "%", "page": 1, "size": 5},
            headers=headers,
        )
        print(f"\n=== 7. Admin Universities LIKE injection (keyword=%) ===")
        print(f"  Status: {resp.status_code}")
        data = resp.json()
        print(f"  Total: {data.get('total')} (should be 0 if escaped correctly)")

        # 9. Admin universities (keyword=河南)
        resp = await client.get(
            "/api/zhiyuan/admin/universities",
            params={"keyword": "河南", "page": 1, "size": 5},
            headers=headers,
        )
        print(f"\n=== 8. Admin Universities (keyword=河南) ===")
        data = resp.json()
        print(f"  Total: {data.get('total')}, Items: {len(data.get('items', []))}")

        # 10. Admin plans (province=河南)
        resp = await client.get(
            "/api/zhiyuan/admin/plans",
            params={"province": "河南", "page": 1, "size": 5},
            headers=headers,
        )
        print(f"\n=== 9. Admin Plans (province=河南) ===")
        data = resp.json()
        print(f"  Total: {data.get('total')}, Items: {len(data.get('items', []))}")
        for p in data.get("items", [])[:3]:
            print(f"  - {p.get('university_name','?')} | year={p.get('year')} | plan_count={p.get('plan_count')}")

        # 11. Generate plan (full flow: rank lookup + recommendation)
        resp = await client.post(
            "/api/zhiyuan/plan",
            json={
                "score": 600,
                "rank": 25000,
                "province": "河南",
                "subject_type": "理科",
                "subject_combination": "物理+化学+生物",
            },
            headers=headers,
        )
        print(f"\n=== 10. Generate Plan (score=600, rank=25000, province=河南) ===")
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json().get("data", {})
            summary = data.get("summary", {})
            print(f"  Summary: total={summary.get('total')}, rush={summary.get('rush_count')}, stable={summary.get('stable_count')}, safe={summary.get('safe_count')}")
            for category in ("rush", "stable", "safe"):
                items = data.get(category, [])
                print(f"  {category} ({len(items)} items):")
                for item in items[:2]:
                    majors_str = ", ".join(m.get("major_name", "?") for m in item.get("majors", [])[:2])
                    print(f"    - {item.get('university_name','?')} ({item.get('level','')}) avg_rank={item.get('avg_rank','?')} majors=[{majors_str}]")
        else:
            print(f"  Response: {resp.text[:300]}")

        # 12. Recommend
        resp = await client.post(
            "/api/zhiyuan/recommend",
            json={"rank": 25000, "province": "河南", "subject_type": "理科", "strategy": "all"},
            headers=headers,
        )
        print(f"\n=== 11. Recommend (rank=25000, province=河南) ===")
        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json().get("data", {})
            for cat in ("rush", "stable", "safe"):
                print(f"  {cat}: {len(data.get(cat, []))} items")

        print("\n=== ALL API TESTS COMPLETED ===")


if __name__ == "__main__":
    asyncio.run(main())
