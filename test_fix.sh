#!/bin/bash
TOKEN=$(curl -s -X POST "http://localhost:5050/api/auth/token" -d "username=zwj&password=zwj12138" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
H="Authorization: Bearer $TOKEN"

echo "=== recommend (物理, rank=6000) ==="
curl -s -X POST "http://localhost:5050/api/zhiyuan/recommend" -H "$H" -H "Content-Type: application/json" -d '{"rank":6000,"province":"河南","subject_type":"物理"}' | python3 -c "
import sys,json
d=json.load(sys.stdin)
data=d.get('data',{})
print('rush:',len(data.get('rush',[])),'stable:',len(data.get('stable',[])),'safe:',len(data.get('safe',[])))
for cat in ['rush','stable','safe']:
    for r in data.get(cat,[])[:2]:
        print(f'  {cat}: {r.get(\"university_name\")} ratio={r.get(\"ratio\")}')
"

echo ""
echo "=== plan (物理, rank=6000) ==="
curl -s -X POST "http://localhost:5050/api/zhiyuan/plan" -H "$H" -H "Content-Type: application/json" -d '{"score":680,"rank":6000,"province":"河南","subject_type":"物理","subject_combination":"物理+化学+生物"}' | python3 -c "
import sys,json
d=json.load(sys.stdin)
data=d.get('data',{})
s=data.get('summary',{})
print('summary:',s)
for cat in ['rush','stable','safe']:
    items=data.get(cat,[])
    print(f'{cat}: {len(items)} items')
    if items:
        print(f'  first: {json.dumps(items[0],ensure_ascii=False)[:200]}')
"

echo ""
echo "=== rank (score=680, 河南, 物理, 2024) ==="
curl -s "http://localhost:5050/api/zhiyuan/rank?score=680&province=%E6%B2%B3%E5%8D%97&year=2024&subject_type=%E7%89%A9%E7%90%86" -H "$H" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(json.dumps(d,ensure_ascii=False)[:300])
"

echo ""
echo "=== scores (河南, 物理, 2024) ==="
curl -s "http://localhost:5050/api/zhiyuan/scores?province=%E6%B2%B3%E5%8D%97&year=2024&subject_type=%E7%89%A9%E7%90%86" -H "$H" | python3 -c "
import sys,json
d=json.load(sys.stdin)
data=d.get('data',[])
print('count:',len(data))
if data: print('first:',json.dumps(data[0],ensure_ascii=False)[:200])
"
