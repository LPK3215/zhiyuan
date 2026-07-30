"""智愿 - Neo4j 知识图谱种子数据

用法：
    cd backend && python scripts/seed_zhiyuan_graph.py

构建关系：
    院校 -[开设]-> 专业
    专业 -[属于]-> 学科门类
    专业 -[对应职业]-> 职业
    专业 -[前置学科]-> 基础学科
    院校 -[位于]-> 城市
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
for import_path in (APP_ROOT, APP_ROOT / "package"):
    import_path_str = str(import_path)
    if import_path_str not in sys.path:
        sys.path.insert(0, import_path_str)

from dotenv import load_dotenv

load_dotenv(APP_ROOT.parent / ".env")

import os

# ========== 图谱数据定义 ==========

# 院校节点
UNIVERSITIES = [
    "清华大学", "北京大学", "浙江大学", "上海交通大学", "复旦大学",
    "南京大学", "中国科学技术大学", "哈尔滨工业大学", "西安交通大学", "武汉大学",
    "武汉理工大学", "华中师范大学", "中南财经政法大学", "郑州大学", "山东大学",
]

# 专业节点
MAJORS = [
    "计算机科学与技术", "软件工程", "电子信息工程", "机械工程",
    "临床医学", "金融学", "法学", "汉语言文学", "数学与应用数学", "土木工程",
    "人工智能", "数据科学与大数据技术", "自动化", "材料科学与工程",
]

# 学科门类
DISCIPLINES = ["工学", "理学", "医学", "经济学", "法学", "文学"]

# 职业
CAREERS = [
    "软件工程师", "算法工程师", "数据分析师", "产品经理",
    "硬件工程师", "通信工程师", "临床医生", "金融分析师",
    "律师", "教师", "科研工作者", "结构工程师",
    "人工智能工程师", "大数据工程师", "自动化工程师", "材料工程师",
]

# 基础学科（前置知识）
BASE_SUBJECTS = ["高等数学", "线性代数", "概率论", "大学物理", "程序设计基础", "离散数学"]

# 关系定义
UNI_OPENS_MAJOR = {
    "清华大学": ["计算机科学与技术", "软件工程", "电子信息工程", "机械工程", "人工智能", "自动化"],
    "北京大学": ["计算机科学与技术", "数学与应用数学", "法学", "金融学", "汉语言文学"],
    "浙江大学": ["计算机科学与技术", "软件工程", "机械工程", "土木工程", "数据科学与大数据技术"],
    "上海交通大学": ["电子信息工程", "机械工程", "计算机科学与技术", "自动化", "材料科学与工程"],
    "复旦大学": ["数学与应用数学", "临床医学", "金融学", "法学", "汉语言文学"],
    "南京大学": ["计算机科学与技术", "数学与应用数学", "人工智能", "数据科学与大数据技术"],
    "中国科学技术大学": ["数学与应用数学", "计算机科学与技术", "人工智能"],
    "哈尔滨工业大学": ["机械工程", "自动化", "计算机科学与技术", "材料科学与工程"],
    "西安交通大学": ["机械工程", "电子信息工程", "金融学", "自动化"],
    "武汉大学": ["法学", "计算机科学与技术", "土木工程", "金融学"],
    "武汉理工大学": ["材料科学与工程", "机械工程", "土木工程", "自动化"],
    "华中师范大学": ["汉语言文学", "数学与应用数学", "计算机科学与技术"],
    "中南财经政法大学": ["金融学", "法学"],
    "郑州大学": ["临床医学", "材料科学与工程", "法学", "计算机科学与技术"],
    "山东大学": ["数学与应用数学", "临床医学", "材料科学与工程", "机械工程"],
}

MAJOR_BELONGS_DISCIPLINE = {
    "计算机科学与技术": "工学", "软件工程": "工学", "电子信息工程": "工学",
    "机械工程": "工学", "土木工程": "工学", "自动化": "工学",
    "材料科学与工程": "工学", "人工智能": "工学", "数据科学与大数据技术": "工学",
    "临床医学": "医学", "金融学": "经济学", "法学": "法学",
    "汉语言文学": "文学", "数学与应用数学": "理学",
}

MAJOR_TO_CAREER = {
    "计算机科学与技术": ["软件工程师", "算法工程师", "人工智能工程师"],
    "软件工程": ["软件工程师", "产品经理"],
    "电子信息工程": ["硬件工程师", "通信工程师"],
    "机械工程": ["结构工程师", "自动化工程师"],
    "临床医学": ["临床医生", "科研工作者"],
    "金融学": ["金融分析师"],
    "法学": ["律师"],
    "汉语言文学": ["教师"],
    "数学与应用数学": ["数据分析师", "科研工作者", "教师"],
    "土木工程": ["结构工程师"],
    "人工智能": ["人工智能工程师", "算法工程师"],
    "数据科学与大数据技术": ["大数据工程师", "数据分析师"],
    "自动化": ["自动化工程师"],
    "材料科学与工程": ["材料工程师", "科研工作者"],
}

MAJOR_PREREQUISITE = {
    "计算机科学与技术": ["高等数学", "程序设计基础", "离散数学"],
    "软件工程": ["程序设计基础", "离散数学"],
    "电子信息工程": ["高等数学", "大学物理", "线性代数"],
    "机械工程": ["高等数学", "大学物理"],
    "人工智能": ["高等数学", "线性代数", "概率论", "程序设计基础"],
    "数据科学与大数据技术": ["高等数学", "线性代数", "概率论"],
    "数学与应用数学": ["高等数学", "线性代数"],
    "自动化": ["高等数学", "大学物理", "线性代数"],
}

UNI_LOCATED_CITY = {
    "清华大学": "北京", "北京大学": "北京", "浙江大学": "杭州",
    "上海交通大学": "上海", "复旦大学": "上海", "南京大学": "南京",
    "中国科学技术大学": "合肥", "哈尔滨工业大学": "哈尔滨",
    "西安交通大学": "西安", "武汉大学": "武汉", "武汉理工大学": "武汉",
    "华中师范大学": "武汉", "中南财经政法大学": "武汉",
    "郑州大学": "郑州", "山东大学": "济南",
}


async def seed_graph():
    """向Neo4j写入图谱数据"""
    neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    neo4j_user = os.getenv("NEO4J_USERNAME", "neo4j")
    neo4j_pass = os.getenv("NEO4J_PASSWORD", "0123456789")

    try:
        from neo4j import AsyncGraphDatabase
    except ImportError:
        print("错误：需要安装 neo4j 驱动 (pip install neo4j)")
        return

    driver = AsyncGraphDatabase.driver(neo4j_uri, auth=(neo4j_user, neo4j_pass))

    async with driver.session() as session:
        # 清空旧的智愿数据
        await session.run("MATCH (n) WHERE n.source = 'zhiyuan' DETACH DELETE n")
        print("✓ 清理旧数据")

        # 创建院校节点
        for name in UNIVERSITIES:
            city = UNI_LOCATED_CITY.get(name, "")
            await session.run(
                "CREATE (n:University {name: $name, city: $city, source: 'zhiyuan'})",
                name=name, city=city,
            )
        print(f"✓ 创建 {len(UNIVERSITIES)} 个院校节点")

        # 创建专业节点
        for name in MAJORS:
            await session.run(
                "CREATE (n:Major {name: $name, source: 'zhiyuan'})",
                name=name,
            )
        print(f"✓ 创建 {len(MAJORS)} 个专业节点")

        # 创建学科门类节点
        for name in DISCIPLINES:
            await session.run(
                "CREATE (n:Discipline {name: $name, source: 'zhiyuan'})",
                name=name,
            )

        # 创建职业节点
        for name in CAREERS:
            await session.run(
                "CREATE (n:Career {name: $name, source: 'zhiyuan'})",
                name=name,
            )

        # 创建基础学科节点
        for name in BASE_SUBJECTS:
            await session.run(
                "CREATE (n:Subject {name: $name, source: 'zhiyuan'})",
                name=name,
            )
        print(f"✓ 创建学科/职业/基础学科节点")

        # 创建关系：院校 -[开设]-> 专业
        rel_count = 0
        for uni, majors in UNI_OPENS_MAJOR.items():
            for major in majors:
                await session.run(
                    "MATCH (u:University {name: $uni}), (m:Major {name: $major}) "
                    "CREATE (u)-[:开设]->(m)",
                    uni=uni, major=major,
                )
                rel_count += 1
        print(f"✓ 创建 {rel_count} 条 开设 关系")

        # 专业 -[属于]-> 学科门类
        for major, disc in MAJOR_BELONGS_DISCIPLINE.items():
            await session.run(
                "MATCH (m:Major {name: $major}), (d:Discipline {name: $disc}) "
                "CREATE (m)-[:属于]->(d)",
                major=major, disc=disc,
            )

        # 专业 -[对应职业]-> 职业
        for major, careers in MAJOR_TO_CAREER.items():
            for career in careers:
                await session.run(
                    "MATCH (m:Major {name: $major}), (c:Career {name: $career}) "
                    "CREATE (m)-[:对应职业]->(c)",
                    major=major, career=career,
                )

        # 专业 -[前置学科]-> 基础学科
        for major, subjects in MAJOR_PREREQUISITE.items():
            for subj in subjects:
                await session.run(
                    "MATCH (m:Major {name: $major}), (s:Subject {name: $subj}) "
                    "CREATE (m)-[:前置学科]->(s)",
                    major=major, subj=subj,
                )

        # 院校 -[位于]-> 城市（用属性表示，不单独建城市节点也行）
        print("✓ 创建 属于/对应职业/前置学科 关系")

        # 统计
        result = await session.run(
            "MATCH (n) WHERE n.source = 'zhiyuan' RETURN count(n) AS nodes"
        )
        record = await result.single()
        node_count = record["nodes"] if record else 0

        result = await session.run(
            "MATCH ()-[r]->() WHERE type(r) IN ['开设','属于','对应职业','前置学科'] RETURN count(r) AS rels"
        )
        record = await result.single()
        rel_total = record["rels"] if record else 0

        print(f"\n✅ 图谱导入完成！节点: {node_count}, 关系: {rel_total}")

    await driver.close()


if __name__ == "__main__":
    asyncio.run(seed_graph())
