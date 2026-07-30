"""智愿 - 数据导入脚本（种子数据）

用法：
    cd backend && python scripts/import_zhiyuan_data.py

导入内容：
    - 30所院校（985/211/双一流/普通）
    - 每校3-5个专业
    - 河南/山东/湖北 三省近3年录取分数
    - 一分一段表（部分分数段）
    - 省份填报规则
    - 招生计划
"""

from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parents[1]
for import_path in (APP_ROOT, APP_ROOT / "package"):
    import_path_str = str(import_path)
    if import_path_str not in sys.path:
        sys.path.insert(0, import_path_str)

from dotenv import load_dotenv

load_dotenv(APP_ROOT.parent / ".env")

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from yuxi.repositories.zhiyuan_models import (
    Base,
    University,
    Major,
    AdmissionScore,
    ScoreRank,
    ProvinceRule,
    EnrollmentPlan,
)


# ========== 种子数据 ==========

UNIVERSITIES = [
    # 985
    {"name": "清华大学", "province": "北京", "city": "北京", "level": "985", "type": "综合", "nature": "公办", "master_points": 55, "doctor_points": 40, "key_disciplines": "计算机科学与技术,电子科学与技术,机械工程"},
    {"name": "北京大学", "province": "北京", "city": "北京", "level": "985", "type": "综合", "nature": "公办", "master_points": 53, "doctor_points": 38, "key_disciplines": "数学,物理学,中国语言文学"},
    {"name": "浙江大学", "province": "浙江", "city": "杭州", "level": "985", "type": "综合", "nature": "公办", "master_points": 50, "doctor_points": 35, "key_disciplines": "计算机科学与技术,光学工程,控制科学与工程"},
    {"name": "上海交通大学", "province": "上海", "city": "上海", "level": "985", "type": "理工", "nature": "公办", "master_points": 48, "doctor_points": 33, "key_disciplines": "机械工程,船舶与海洋工程,电子信息"},
    {"name": "复旦大学", "province": "上海", "city": "上海", "level": "985", "type": "综合", "nature": "公办", "master_points": 45, "doctor_points": 30, "key_disciplines": "数学,物理学,基础医学"},
    {"name": "南京大学", "province": "江苏", "city": "南京", "level": "985", "type": "综合", "nature": "公办", "master_points": 42, "doctor_points": 28, "key_disciplines": "天文学,地质学,物理学"},
    {"name": "中国科学技术大学", "province": "安徽", "city": "合肥", "level": "985", "type": "理工", "nature": "公办", "master_points": 38, "doctor_points": 25, "key_disciplines": "物理学,化学,数学"},
    {"name": "哈尔滨工业大学", "province": "黑龙江", "city": "哈尔滨", "level": "985", "type": "理工", "nature": "公办", "master_points": 40, "doctor_points": 26, "key_disciplines": "机械工程,材料科学,航天"},
    {"name": "西安交通大学", "province": "陕西", "city": "西安", "level": "985", "type": "综合", "nature": "公办", "master_points": 42, "doctor_points": 27, "key_disciplines": "电气工程,动力工程,管理科学"},
    {"name": "武汉大学", "province": "湖北", "city": "武汉", "level": "985", "type": "综合", "nature": "公办", "master_points": 46, "doctor_points": 30, "key_disciplines": "测绘科学,水利工程,法学"},
    # 211
    {"name": "武汉理工大学", "province": "湖北", "city": "武汉", "level": "211", "type": "理工", "nature": "公办", "master_points": 30, "doctor_points": 15, "key_disciplines": "材料科学,船舶与海洋工程"},
    {"name": "华中师范大学", "province": "湖北", "city": "武汉", "level": "211", "type": "师范", "nature": "公办", "master_points": 28, "doctor_points": 12, "key_disciplines": "教育学,中国语言文学"},
    {"name": "中南财经政法大学", "province": "湖北", "city": "武汉", "level": "211", "type": "财经", "nature": "公办", "master_points": 20, "doctor_points": 8, "key_disciplines": "应用经济学,法学"},
    {"name": "南京理工大学", "province": "江苏", "city": "南京", "level": "211", "type": "理工", "nature": "公办", "master_points": 25, "doctor_points": 12, "key_disciplines": "兵器科学,光学工程"},
    {"name": "郑州大学", "province": "河南", "city": "郑州", "level": "211", "type": "综合", "nature": "公办", "master_points": 35, "doctor_points": 18, "key_disciplines": "化学,材料科学,临床医学"},
    {"name": "河南大学", "province": "河南", "city": "开封", "level": "双一流", "type": "综合", "nature": "公办", "master_points": 25, "doctor_points": 10, "key_disciplines": "生物学,地理学"},
    {"name": "山东大学", "province": "山东", "city": "济南", "level": "985", "type": "综合", "nature": "公办", "master_points": 44, "doctor_points": 28, "key_disciplines": "数学,材料科学,临床医学"},
    {"name": "中国海洋大学", "province": "山东", "city": "青岛", "level": "985", "type": "综合", "nature": "公办", "master_points": 22, "doctor_points": 12, "key_disciplines": "海洋科学,水产"},
    # 普通本科
    {"name": "湖北工业大学", "province": "湖北", "city": "武汉", "level": "普通", "type": "理工", "nature": "公办", "master_points": 12, "doctor_points": 2, "key_disciplines": "轻工技术"},
    {"name": "武汉科技大学", "province": "湖北", "city": "武汉", "level": "普通", "type": "理工", "nature": "公办", "master_points": 10, "doctor_points": 3, "key_disciplines": "材料科学,冶金工程"},
    {"name": "河南科技大学", "province": "河南", "city": "洛阳", "level": "普通", "type": "理工", "nature": "公办", "master_points": 8, "doctor_points": 1, "key_disciplines": "机械工程"},
    {"name": "河南工业大学", "province": "河南", "city": "郑州", "level": "普通", "type": "理工", "nature": "公办", "master_points": 7, "doctor_points": 1, "key_disciplines": "食品科学"},
    {"name": "山东科技大学", "province": "山东", "city": "青岛", "level": "普通", "type": "理工", "nature": "公办", "master_points": 9, "doctor_points": 2, "key_disciplines": "矿业工程,安全科学"},
    {"name": "济南大学", "province": "山东", "city": "济南", "level": "普通", "type": "综合", "nature": "公办", "master_points": 10, "doctor_points": 2, "key_disciplines": "材料科学,化学"},
]

MAJORS_TEMPLATE = [
    {"name": "计算机科学与技术", "code": "080901", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 95.2, "avg_salary": 12500, "career_directions": "软件开发,算法工程师,数据工程师,人工智能"},
    {"name": "软件工程", "code": "080902", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 96.1, "avg_salary": 13000, "career_directions": "软件开发,测试工程师,项目经理,架构师"},
    {"name": "电子信息工程", "code": "080701", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 93.5, "avg_salary": 11000, "career_directions": "硬件工程师,嵌入式开发,通信工程师"},
    {"name": "机械工程", "code": "080201", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 91.8, "avg_salary": 9500, "career_directions": "机械设计,制造工程师,自动化工程师"},
    {"name": "临床医学", "code": "100201K", "degree": "医学学士", "duration": "5年", "subject_category": "医学", "subject_requirement": "物理+化学", "employment_rate": 94.0, "avg_salary": 8500, "career_directions": "临床医生,医学研究,公共卫生"},
    {"name": "金融学", "code": "020301K", "degree": "经济学学士", "duration": "4年", "subject_category": "经济学", "subject_requirement": "", "employment_rate": 89.5, "avg_salary": 10000, "career_directions": "银行,证券,基金,风控"},
    {"name": "法学", "code": "030101K", "degree": "法学学士", "duration": "4年", "subject_category": "法学", "subject_requirement": "", "employment_rate": 85.3, "avg_salary": 8000, "career_directions": "律师,法官,法务,公务员"},
    {"name": "汉语言文学", "code": "050101", "degree": "文学学士", "duration": "4年", "subject_category": "文学", "subject_requirement": "", "employment_rate": 87.2, "avg_salary": 7000, "career_directions": "教师,编辑,文案策划,公务员"},
    {"name": "数学与应用数学", "code": "070101", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "物理", "employment_rate": 92.0, "avg_salary": 11500, "career_directions": "数据分析,精算师,教师,科研"},
    {"name": "土木工程", "code": "081001", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 88.0, "avg_salary": 8500, "career_directions": "结构设计,施工管理,工程造价"},
]

# 各省录取分数基准（用于生成模拟数据）
PROVINCE_SCORES = {
    "河南": {"理科_base": 600, "文科_base": 580, "subject_types": ["理科", "文科"]},
    "山东": {"综合改革_base": 590, "subject_types": ["综合改革"]},
    "湖北": {"物理类_base": 585, "历史类_base": 570, "subject_types": ["物理类", "历史类"]},
}

PROVINCE_RULES = [
    {"province": "河南", "year": 2025, "mode": "平行志愿", "batch_count": 2, "max_per_batch": 6, "subject_mode": "传统文理", "description": "本科一批、本科二批各可填6个院校志愿，每个院校可填5个专业", "tips": "注意院校梯度，建议冲2稳2保2"},
    {"province": "山东", "year": 2025, "mode": "平行志愿", "batch_count": 1, "max_per_batch": 96, "subject_mode": "3+3", "description": "普通类常规批可填96个专业+院校志愿", "tips": "96个志愿按分数优先投档，建议前30个冲、中40个稳、后26个保"},
    {"province": "湖北", "year": 2025, "mode": "平行志愿", "batch_count": 1, "max_per_batch": 45, "subject_mode": "3+1+2", "description": "本科批可填45个院校专业组志愿", "tips": "注意选科要求，物理类和历史类分开填报"},
]


async def seed_data():
    """导入种子数据"""
    db_url = os.getenv("POSTGRES_URL")
    if not db_url:
        print("错误：未配置 POSTGRES_URL，请检查 .env")
        return

    engine = create_async_engine(db_url, echo=False)

    try:
        await _seed_with_engine(engine)
    finally:
        # 无论导入成功、跳过还是异常，都确保连接池被释放，避免泄漏
        await engine.dispose()


async def _seed_with_engine(engine) -> None:
    """在给定引擎上执行建表与种子导入。

    从 seed_data 拆分出来，使 engine.dispose() 能由 seed_data 的 try/finally 统一兜底，
    避免早返回分支各自 dispose、异常分支漏 dispose 的问题。
    """
    # 建表
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✓ 表结构创建完成")

    session_factory = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        # 检查是否已有数据
        count = await session.execute(select(func.count(University.id)))
        if count.scalar() > 0:
            print("⚠ 已有数据，跳过导入（如需重新导入请先清空表）")
            return

        # 1. 导入院校
        uni_map = {}  # name -> id
        for uni_data in UNIVERSITIES:
            uni = University(**uni_data)
            session.add(uni)
            await session.flush()
            uni_map[uni_data["name"]] = uni.id
        print(f"✓ 导入 {len(UNIVERSITIES)} 所院校")

        # 2. 导入专业（每校取3-5个）
        import random
        random.seed(42)
        major_map = {}  # (uni_id, major_name) -> id
        for uni_name, uni_id in uni_map.items():
            # 根据院校类型选专业
            num_majors = random.randint(3, 5)
            selected = random.sample(MAJORS_TEMPLATE, min(num_majors, len(MAJORS_TEMPLATE)))
            for m in selected:
                major = Major(
                    university_id=uni_id,
                    name=m["name"],
                    code=m["code"],
                    degree=m["degree"],
                    duration=m["duration"],
                    subject_category=m["subject_category"],
                    subject_requirement=m["subject_requirement"],
                    employment_rate=m["employment_rate"],
                    avg_salary=m["avg_salary"],
                    career_directions=m["career_directions"],
                    is_key=random.random() < 0.2,
                )
                session.add(major)
                await session.flush()
                major_map[(uni_id, m["name"])] = major.id
        print(f"✓ 导入 {len(major_map)} 个专业")

        # 3. 导入录取分数（近3年）
        score_count = 0
        for uni_name, uni_id in uni_map.items():
            uni_info = next(u for u in UNIVERSITIES if u["name"] == uni_name)
            level = uni_info["level"]

            # 根据层次设定基准分
            level_offset = {"985": 80, "211": 40, "双一流": 30, "普通": 0}
            base_offset = level_offset.get(level, 0)

            for province, config in PROVINCE_SCORES.items():
                for subject_type in config["subject_types"]:
                    base_key = f"{subject_type}_base"
                    base_score = config.get(base_key, 580)

                    for year in [2023, 2024, 2025]:
                        # 模拟分数波动
                        fluctuation = random.randint(-8, 8)
                        min_score = base_score + base_offset + fluctuation
                        min_rank = max(100, int((750 - min_score) * random.uniform(80, 120)))

                        score = AdmissionScore(
                            university_id=uni_id,
                            major_id=0,
                            province=province,
                            year=year,
                            subject_type=subject_type,
                            batch="本科一批" if level in ("985", "211") else "本科二批",
                            min_score=min_score,
                            max_score=min_score + random.randint(15, 40),
                            avg_score=min_score + random.randint(5, 15),
                            min_rank=min_rank,
                            plan_count=random.randint(5, 50),
                        )
                        session.add(score)
                        score_count += 1
        print(f"✓ 导入 {score_count} 条录取分数")

        # 4. 导入一分一段表（部分分数段）
        rank_count = 0
        for province, config in PROVINCE_SCORES.items():
            for subject_type in config["subject_types"]:
                for year in [2024, 2025]:
                    rank = 0
                    for score_val in range(700, 399, -1):
                        segment = random.randint(50, 500) if score_val > 500 else random.randint(200, 1500)
                        rank += segment
                        sr = ScoreRank(
                            province=province,
                            year=year,
                            subject_type=subject_type,
                            score=score_val,
                            rank=rank,
                            segment_count=segment,
                        )
                        session.add(sr)
                        rank_count += 1
        print(f"✓ 导入 {rank_count} 条一分一段数据")

        # 5. 导入省份规则
        for rule_data in PROVINCE_RULES:
            session.add(ProvinceRule(**rule_data))
        print(f"✓ 导入 {len(PROVINCE_RULES)} 条省份规则")

        # 6. 导入招生计划（部分）
        plan_count = 0
        for uni_name, uni_id in list(uni_map.items())[:10]:
            for province in ["河南", "山东", "湖北"]:
                for year in [2024, 2025]:
                    plan = EnrollmentPlan(
                        university_id=uni_id,
                        major_id=0,
                        province=province,
                        year=year,
                        subject_type="",
                        batch="本科一批",
                        plan_count=random.randint(10, 100),
                        duration="4年",
                        tuition="5000-6000元/年",
                        remark="",
                    )
                    session.add(plan)
                    plan_count += 1
        print(f"✓ 导入 {plan_count} 条招生计划")

        await session.commit()
        print("\n✅ 全部数据导入完成！")


if __name__ == "__main__":
    asyncio.run(seed_data())
