"""Verify admin endpoints include university_name."""
import asyncio
import httpx

BASE = "http://localhost:5050"


async def main():
    async with httpx.AsyncClient(base_url=BASE, timeout=30) as client:
        resp = await client.post(
            "/api/auth/token",
            data={"username": "zwj", "password": "zwj12138"},
        )
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Admin scores
        resp = await client.get(
            "/api/zhiyuan/admin/scores",
            params={"province": "河南", "page": 1, "size": 5},
            headers=headers,
        )
        data = resp.json()
        print("=== Admin Scores (province=河南) ===")
        print(f"Total: {data['total']}, Items: {len(data['items'])}")
        for item in data["items"][:3]:
            print(f"  university_name={item.get('university_name','?')}, university_id={item.get('university_id')}, min_score={item.get('min_score')}")

        # Admin majors
        resp = await client.get(
            "/api/zhiyuan/admin/majors",
            params={"keyword": "计算机", "page": 1, "size": 5},
            headers=headers,
        )
        data = resp.json()
        print("\n=== Admin Majors (keyword=计算机) ===")
        print(f"Total: {data['total']}, Items: {len(data['items'])}")
        for item in data["items"][:3]:
            print(f"  name={item.get('name','?')}, university_name={item.get('university_name','?')}, university_id={item.get('university_id')}")

        # User-facing scores
        resp = await client.get(
            "/api/zhiyuan/scores",
            params={"province": "河南", "year": 2024},
            headers=headers,
        )
        data = resp.json()
        print("\n=== User Scores (province=河南, year=2024) ===")
        for item in data.get("data", [])[:3]:
            print(f"  university_name={item.get('university_name','?')}, major_name={item.get('major_name','?')}, min_score={item.get('min_score')}")

        print("\n=== DONE ===")


if __name__ == "__main__":
    asyncio.run(main())
