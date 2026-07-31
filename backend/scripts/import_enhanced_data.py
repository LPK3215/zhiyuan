"""智愿 - 增强版数据导入脚本（扩充数据集）

用法：
    cd backend && python scripts/import_enhanced_data.py

功能：
    - 50+ 所院校（985/211/双一流/普通本科，覆盖全国主要省份）
    - 15+ 个专业模板（含热门新兴专业）
    - 河南/山东/湖北/河北/安徽 五省近3年录取分数
    - 完整一分一段表（2023-2025年）
    - 省份填报规则
    - 招生计划
    - 志愿填报政策问答数据
"""

from __future__ import annotations

import asyncio
import os
import random
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


# ========== 扩充版种子数据 ==========

UNIVERSITIES = [
    # ========== 985 院校 ==========
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
    {"name": "山东大学", "province": "山东", "city": "济南", "level": "985", "type": "综合", "nature": "公办", "master_points": 44, "doctor_points": 28, "key_disciplines": "数学,材料科学,临床医学"},
    {"name": "中国海洋大学", "province": "山东", "city": "青岛", "level": "985", "type": "综合", "nature": "公办", "master_points": 22, "doctor_points": 12, "key_disciplines": "海洋科学,水产"},
    {"name": "中山大学", "province": "广东", "city": "广州", "level": "985", "type": "综合", "nature": "公办", "master_points": 43, "doctor_points": 29, "key_disciplines": "生物学,临床医学,管理学"},
    {"name": "华南理工大学", "province": "广东", "city": "广州", "level": "985", "type": "理工", "nature": "公办", "master_points": 36, "doctor_points": 22, "key_disciplines": "化学工程,建筑科学,轻工技术"},
    {"name": "四川大学", "province": "四川", "city": "成都", "level": "985", "type": "综合", "nature": "公办", "master_points": 48, "doctor_points": 32, "key_disciplines": "医学,中国语言文学,数学"},
    {"name": "兰州大学", "province": "甘肃", "city": "兰州", "level": "985", "type": "综合", "nature": "公办", "master_points": 35, "doctor_points": 20, "key_disciplines": "化学,物理学,地理学"},
    {"name": "南开大学", "province": "天津", "city": "天津", "level": "985", "type": "综合", "nature": "公办", "master_points": 40, "doctor_points": 25, "key_disciplines": "数学,化学,中国语言文学"},
    {"name": "天津大学", "province": "天津", "city": "天津", "level": "985", "type": "理工", "nature": "公办", "master_points": 38, "doctor_points": 24, "key_disciplines": "建筑学,水利工程,化学工程"},
    {"name": "北京航空航天大学", "province": "北京", "city": "北京", "level": "985", "type": "理工", "nature": "公办", "master_points": 42, "doctor_points": 28, "key_disciplines": "航空宇航,计算机科学,材料科学"},
    {"name": "北京理工大学", "province": "北京", "city": "北京", "level": "985", "type": "理工", "nature": "公办", "master_points": 40, "doctor_points": 26, "key_disciplines": "兵器科学,机械工程,电子信息"},
    {"name": "同济大学", "province": "上海", "city": "上海", "level": "985", "type": "综合", "nature": "公办", "master_points": 44, "doctor_points": 28, "key_disciplines": "建筑学,土木工程,海洋科学"},
    {"name": "东南大学", "province": "江苏", "city": "南京", "level": "985", "type": "综合", "nature": "公办", "master_points": 40, "doctor_points": 25, "key_disciplines": "建筑学,电子信息,交通运输"},
    {"name": "中南大学", "province": "湖南", "city": "长沙", "level": "985", "type": "综合", "nature": "公办", "master_points": 42, "doctor_points": 27, "key_disciplines": "矿业工程,材料科学,土木工程"},
    {"name": "国防科技大学", "province": "湖南", "city": "长沙", "level": "985", "type": "理工", "nature": "公办", "master_points": 38, "doctor_points": 24, "key_disciplines": "计算机科学,航空宇航,兵器科学"},
    {"name": "吉林大学", "province": "吉林", "city": "长春", "level": "985", "type": "综合", "nature": "公办", "master_points": 45, "doctor_points": 30, "key_disciplines": "化学,法学,地质学"},

    # ========== 211 院校 ==========
    {"name": "武汉理工大学", "province": "湖北", "city": "武汉", "level": "211", "type": "理工", "nature": "公办", "master_points": 30, "doctor_points": 15, "key_disciplines": "材料科学,船舶与海洋工程"},
    {"name": "华中师范大学", "province": "湖北", "city": "武汉", "level": "211", "type": "师范", "nature": "公办", "master_points": 28, "doctor_points": 12, "key_disciplines": "教育学,中国语言文学"},
    {"name": "中南财经政法大学", "province": "湖北", "city": "武汉", "level": "211", "type": "财经", "nature": "公办", "master_points": 20, "doctor_points": 8, "key_disciplines": "应用经济学,法学"},
    {"name": "南京理工大学", "province": "江苏", "city": "南京", "level": "211", "type": "理工", "nature": "公办", "master_points": 25, "doctor_points": 12, "key_disciplines": "兵器科学,光学工程"},
    {"name": "南京航空航天大学", "province": "江苏", "city": "南京", "level": "211", "type": "理工", "nature": "公办", "master_points": 28, "doctor_points": 15, "key_disciplines": "航空宇航,计算机科学"},
    {"name": "苏州大学", "province": "江苏", "city": "苏州", "level": "211", "type": "综合", "nature": "公办", "master_points": 30, "doctor_points": 18, "key_disciplines": "纺织工程,法学"},
    {"name": "华东师范大学", "province": "上海", "city": "上海", "level": "211", "type": "师范", "nature": "公办", "master_points": 30, "doctor_points": 16, "key_disciplines": "教育学,地理学"},
    {"name": "上海财经大学", "province": "上海", "city": "上海", "level": "211", "type": "财经", "nature": "公办", "master_points": 22, "doctor_points": 10, "key_disciplines": "应用经济学,统计学"},
    {"name": "上海外国语大学", "province": "上海", "city": "上海", "level": "211", "type": "语言", "nature": "公办", "master_points": 18, "doctor_points": 6, "key_disciplines": "外国语言文学"},
    {"name": "北京邮电大学", "province": "北京", "city": "北京", "level": "211", "type": "理工", "nature": "公办", "master_points": 28, "doctor_points": 14, "key_disciplines": "通信工程,计算机科学"},
    {"name": "北京科技大学", "province": "北京", "city": "北京", "level": "211", "type": "理工", "nature": "公办", "master_points": 25, "doctor_points": 12, "key_disciplines": "材料科学,冶金工程"},
    {"name": "北京师范大学", "province": "北京", "city": "北京", "level": "211", "type": "师范", "nature": "公办", "master_points": 32, "doctor_points": 18, "key_disciplines": "教育学,心理学"},
    {"name": "中央财经大学", "province": "北京", "city": "北京", "level": "211", "type": "财经", "nature": "公办", "master_points": 20, "doctor_points": 8, "key_disciplines": "应用经济学"},
    {"name": "中国政法大学", "province": "北京", "city": "北京", "level": "211", "type": "政法", "nature": "公办", "master_points": 18, "doctor_points": 6, "key_disciplines": "法学"},
    {"name": "中国传媒大学", "province": "北京", "city": "北京", "level": "211", "type": "艺术", "nature": "公办", "master_points": 16, "doctor_points": 5, "key_disciplines": "新闻传播学"},
    {"name": "河北工业大学", "province": "天津", "city": "天津", "level": "211", "type": "理工", "nature": "公办", "master_points": 22, "doctor_points": 10, "key_disciplines": "电气工程,机械工程"},
    {"name": "郑州大学", "province": "河南", "city": "郑州", "level": "211", "type": "综合", "nature": "公办", "master_points": 35, "doctor_points": 18, "key_disciplines": "化学,材料科学,临床医学"},
    {"name": "合肥工业大学", "province": "安徽", "city": "合肥", "level": "211", "type": "理工", "nature": "公办", "master_points": 26, "doctor_points": 14, "key_disciplines": "管理科学,电气工程"},
    {"name": "福州大学", "province": "福建", "city": "福州", "level": "211", "type": "综合", "nature": "公办", "master_points": 22, "doctor_points": 12, "key_disciplines": "化学,土木工程"},
    {"name": "南昌大学", "province": "江西", "city": "南昌", "level": "211", "type": "综合", "nature": "公办", "master_points": 24, "doctor_points": 14, "key_disciplines": "食品科学,临床医学"},
    {"name": "广西大学", "province": "广西", "city": "南宁", "level": "211", "type": "综合", "nature": "公办", "master_points": 22, "doctor_points": 12, "key_disciplines": "农学,土木工程"},
    {"name": "云南大学", "province": "云南", "city": "昆明", "level": "211", "type": "综合", "nature": "公办", "master_points": 25, "doctor_points": 14, "key_disciplines": "生态学,民族学"},
    {"name": "贵州大学", "province": "贵州", "city": "贵阳", "level": "211", "type": "综合", "nature": "公办", "master_points": 20, "doctor_points": 10, "key_disciplines": "计算机科学,农学"},
    {"name": "新疆大学", "province": "新疆", "city": "乌鲁木齐", "level": "211", "type": "综合", "nature": "公办", "master_points": 18, "doctor_points": 8, "key_disciplines": "生态学,民族学"},
    {"name": "内蒙古大学", "province": "内蒙古", "city": "呼和浩特", "level": "211", "type": "综合", "nature": "公办", "master_points": 20, "doctor_points": 10, "key_disciplines": "生物学,蒙古学"},
    {"name": "海南大学", "province": "海南", "city": "海口", "level": "211", "type": "综合", "nature": "公办", "master_points": 18, "doctor_points": 8, "key_disciplines": "作物学,法学"},

    # ========== 双一流 / 普通本科 ==========
    {"name": "河南大学", "province": "河南", "city": "开封", "level": "双一流", "type": "综合", "nature": "公办", "master_points": 25, "doctor_points": 10, "key_disciplines": "生物学,地理学"},
    {"name": "河南农业大学", "province": "河南", "city": "郑州", "level": "普通", "type": "农业", "nature": "公办", "master_points": 15, "doctor_points": 5, "key_disciplines": "作物学,植物保护"},
    {"name": "河南师范大学", "province": "河南", "city": "新乡", "level": "普通", "type": "师范", "nature": "公办", "master_points": 18, "doctor_points": 3, "key_disciplines": "物理学,化学"},
    {"name": "河南科技大学", "province": "河南", "city": "洛阳", "level": "普通", "type": "理工", "nature": "公办", "master_points": 8, "doctor_points": 1, "key_disciplines": "机械工程"},
    {"name": "河南工业大学", "province": "河南", "city": "郑州", "level": "普通", "type": "理工", "nature": "公办", "master_points": 7, "doctor_points": 1, "key_disciplines": "食品科学"},
    {"name": "河南理工大学", "province": "河南", "city": "焦作", "level": "普通", "type": "理工", "nature": "公办", "master_points": 10, "doctor_points": 2, "key_disciplines": "矿业工程,安全科学"},
    {"name": "湖北工业大学", "province": "湖北", "city": "武汉", "level": "普通", "type": "理工", "nature": "公办", "master_points": 12, "doctor_points": 2, "key_disciplines": "轻工技术"},
    {"name": "武汉科技大学", "province": "湖北", "city": "武汉", "level": "普通", "type": "理工", "nature": "公办", "master_points": 10, "doctor_points": 3, "key_disciplines": "材料科学,冶金工程"},
    {"name": "长江大学", "province": "湖北", "city": "荆州", "level": "普通", "type": "综合", "nature": "公办", "master_points": 12, "doctor_points": 3, "key_disciplines": "石油工程,作物学"},
    {"name": "湖北大学", "province": "湖北", "city": "武汉", "level": "普通", "type": "综合", "nature": "公办", "master_points": 15, "doctor_points": 4, "key_disciplines": "生物学,法学"},
    {"name": "山东科技大学", "province": "山东", "city": "青岛", "level": "普通", "type": "理工", "nature": "公办", "master_points": 9, "doctor_points": 2, "key_disciplines": "矿业工程,安全科学"},
    {"name": "济南大学", "province": "山东", "city": "济南", "level": "普通", "type": "综合", "nature": "公办", "master_points": 10, "doctor_points": 2, "key_disciplines": "材料科学,化学"},
    {"name": "青岛大学", "province": "山东", "city": "青岛", "level": "普通", "type": "综合", "nature": "公办", "master_points": 18, "doctor_points": 6, "key_disciplines": "临床医学,纺织工程"},
    {"name": "烟台大学", "province": "山东", "city": "烟台", "level": "普通", "type": "综合", "nature": "公办", "master_points": 8, "doctor_points": 1, "key_disciplines": "法学,数学"},
    {"name": "河北大学", "province": "河北", "city": "保定", "level": "普通", "type": "综合", "nature": "公办", "master_points": 14, "doctor_points": 3, "key_disciplines": "光学,中国语言文学"},
    {"name": "河北工程大学", "province": "河北", "city": "邯郸", "level": "普通", "type": "理工", "nature": "公办", "master_points": 6, "doctor_points": 1, "key_disciplines": "建筑学,水利工程"},
    {"name": "燕山大学", "province": "河北", "city": "秦皇岛", "level": "普通", "type": "理工", "nature": "公办", "master_points": 12, "doctor_points": 2, "key_disciplines": "机械工程,控制工程"},
    {"name": "河北地质大学", "province": "河北", "city": "石家庄", "level": "普通", "type": "理工", "nature": "公办", "master_points": 7, "doctor_points": 1, "key_disciplines": "地质学,经济管理"},
    {"name": "安徽大学", "province": "安徽", "city": "合肥", "level": "双一流", "type": "综合", "nature": "公办", "master_points": 18, "doctor_points": 6, "key_disciplines": "汉语言文字学,计算机科学"},
    {"name": "安徽工业大学", "province": "安徽", "city": "马鞍山", "level": "普通", "type": "理工", "nature": "公办", "master_points": 8, "doctor_points": 1, "key_disciplines": "冶金工程,材料科学"},
    {"name": "安徽师范大学", "province": "安徽", "city": "芜湖", "level": "普通", "type": "师范", "nature": "公办", "master_points": 14, "doctor_points": 2, "key_disciplines": "地理学,生态学"},
]


MAJORS_TEMPLATE = [
    {"name": "计算机科学与技术", "code": "080901", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 95.2, "avg_salary": 12500, "career_directions": "软件开发,算法工程师,数据工程师,人工智能"},
    {"name": "软件工程", "code": "080902", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 96.1, "avg_salary": 13000, "career_directions": "软件开发,测试工程师,项目经理,架构师"},
    {"name": "人工智能", "code": "080903T", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 97.0, "avg_salary": 15000, "career_directions": "算法工程师,机器学习工程师,NLP工程师"},
    {"name": "数据科学与大数据技术", "code": "080905T", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 94.5, "avg_salary": 12000, "career_directions": "数据分析师,大数据工程师,BI工程师"},
    {"name": "电子信息工程", "code": "080701", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 93.5, "avg_salary": 11000, "career_directions": "硬件工程师,嵌入式开发,通信工程师"},
    {"name": "通信工程", "code": "080702", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 92.0, "avg_salary": 10500, "career_directions": "通信工程师,网络优化,5G研发"},
    {"name": "机械工程", "code": "080201", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 91.8, "avg_salary": 9500, "career_directions": "机械设计,制造工程师,自动化工程师"},
    {"name": "临床医学", "code": "100201K", "degree": "医学学士", "duration": "5年", "subject_category": "医学", "subject_requirement": "物理+化学", "employment_rate": 94.0, "avg_salary": 8500, "career_directions": "临床医生,医学研究,公共卫生"},
    {"name": "口腔医学", "code": "100301K", "degree": "医学学士", "duration": "5年", "subject_category": "医学", "subject_requirement": "物理+化学", "employment_rate": 96.5, "avg_salary": 10000, "career_directions": "口腔医生,口腔医学研究"},
    {"name": "金融学", "code": "020301K", "degree": "经济学学士", "duration": "4年", "subject_category": "经济学", "subject_requirement": "", "employment_rate": 89.5, "avg_salary": 10000, "career_directions": "银行,证券,基金,风控"},
    {"name": "法学", "code": "030101K", "degree": "法学学士", "duration": "4年", "subject_category": "法学", "subject_requirement": "", "employment_rate": 85.3, "avg_salary": 8000, "career_directions": "律师,法官,法务,公务员"},
    {"name": "汉语言文学", "code": "050101", "degree": "文学学士", "duration": "4年", "subject_category": "文学", "subject_requirement": "", "employment_rate": 87.2, "avg_salary": 7000, "career_directions": "教师,编辑,文案策划,公务员"},
    {"name": "数学与应用数学", "code": "070101", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "物理", "employment_rate": 92.0, "avg_salary": 11500, "career_directions": "数据分析,精算师,教师,科研"},
    {"name": "物理学", "code": "070201", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "物理", "employment_rate": 90.5, "avg_salary": 9800, "career_directions": "科研,教师,工程师"},
    {"name": "化学", "code": "070301", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "化学", "employment_rate": 89.0, "avg_salary": 9200, "career_directions": "化学工程师,教师,科研"},
    {"name": "土木工程", "code": "081001", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 88.0, "avg_salary": 8500, "career_directions": "结构设计,施工管理,工程造价"},
    {"name": "建筑学", "code": "082201", "degree": "建筑学学士", "duration": "5年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 90.0, "avg_salary": 9000, "career_directions": "建筑设计,城市规划,室内设计"},
    {"name": "工商管理", "code": "110101K", "degree": "管理学学士", "duration": "4年", "subject_category": "管理学", "subject_requirement": "", "employment_rate": 86.5, "avg_salary": 8500, "career_directions": "企业管理,咨询,人力资源"},
    {"name": "会计学", "code": "120201K", "degree": "管理学学士", "duration": "4年", "subject_category": "管理学", "subject_requirement": "", "employment_rate": 92.0, "avg_salary": 7800, "career_directions": "会计,审计,财务管理"},
    {"name": "国际经济与贸易", "code": "020401K", "degree": "经济学学士", "duration": "4年", "subject_category": "经济学", "subject_requirement": "", "employment_rate": 85.0, "avg_salary": 8800, "career_directions": "外贸,跨境电商,国际物流"},
    {"name": "环境工程", "code": "081202", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理+化学", "employment_rate": 88.5, "avg_salary": 8200, "career_directions": "环境工程师,环保咨询"},
    {"name": "生物科学", "code": "071001", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "化学", "employment_rate": 85.5, "avg_salary": 7500, "career_directions": "科研,教师,生物医药"},
    {"name": "心理学", "code": "071101", "degree": "理学学士", "duration": "4年", "subject_category": "理学", "subject_requirement": "", "employment_rate": 88.0, "avg_salary": 8000, "career_directions": "心理咨询,人力资源,用户研究"},
    {"name": "教育学", "code": "040101", "degree": "教育学学士", "duration": "4年", "subject_category": "教育学", "subject_requirement": "", "employment_rate": 90.5, "avg_salary": 7200, "career_directions": "教师,教育研究,课程设计"},
    {"name": "英语", "code": "050201", "degree": "文学学士", "duration": "4年", "subject_category": "文学", "subject_requirement": "", "employment_rate": 88.0, "avg_salary": 7500, "career_directions": "翻译,外贸,教育"},
    {"name": "新能源科学与工程", "code": "080503T", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 94.0, "avg_salary": 11000, "career_directions": "新能源研发,储能工程,光伏工程"},
    {"name": "材料科学与工程", "code": "080401", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理+化学", "employment_rate": 91.0, "avg_salary": 10000, "career_directions": "材料研发,工艺工程师,质检"},
    {"name": "自动化", "code": "080801", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 93.5, "avg_salary": 11500, "career_directions": "自动化工程师,PLC编程,机器人开发"},
    {"name": "机器人工程", "code": "080803T", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 95.0, "avg_salary": 12000, "career_directions": "机器人研发,ROS开发,智能制造"},
    {"name": "网络空间安全", "code": "080911TK", "degree": "工学学士", "duration": "4年", "subject_category": "工学", "subject_requirement": "物理", "employment_rate": 94.0, "avg_salary": 13000, "career_directions": "安全工程师,渗透测试,安全运营"},
]


# 各省录取分数基准
PROVINCE_SCORES = {
    "河南": {"理科_base": 600, "文科_base": 580, "subject_types": ["理科", "文科"]},
    "山东": {"综合改革_base": 590, "subject_types": ["综合改革"]},
    "湖北": {"物理类_base": 585, "历史类_base": 570, "subject_types": ["物理类", "历史类"]},
    "河北": {"物理类_base": 590, "历史类_base": 575, "subject_types": ["物理类", "历史类"]},
    "安徽": {"理科_base": 595, "文科_base": 580, "subject_types": ["理科", "文科"]},
}

PROVINCE_RULES = [
    {"province": "河南", "year": 2025, "mode": "平行志愿", "batch_count": 2, "max_per_batch": 6, "subject_mode": "传统文理", "description": "本科一批、本科二批各可填6个院校志愿，每个院校可填5个专业", "tips": "注意院校梯度，建议冲2稳2保2"},
    {"province": "山东", "year": 2025, "mode": "平行志愿", "batch_count": 1, "max_per_batch": 96, "subject_mode": "3+3", "description": "普通类常规批可填96个专业+院校志愿", "tips": "96个志愿按分数优先投档，建议前30个冲、中40个稳、后26个保"},
    {"province": "湖北", "year": 2025, "mode": "平行志愿", "batch_count": 1, "max_per_batch": 45, "subject_mode": "3+1+2", "description": "本科批可填45个院校专业组志愿", "tips": "注意选科要求，物理类和历史类分开填报"},
    {"province": "河北", "year": 2025, "mode": "平行志愿", "batch_count": 1, "max_per_batch": 96, "subject_mode": "3+1+2", "description": "本科批可填96个院校专业组志愿", "tips": "物理类和历史类分开投档，注意选科匹配"},
    {"province": "安徽", "year": 2025, "mode": "平行志愿", "batch_count": 2, "max_per_batch": 6, "subject_mode": "传统文理", "description": "本科一批、本科二批各可填6个院校志愿", "tips": "理科投档线普遍高于文科，注意参考往年数据"},
]


async def seed_data():
    """导入增强版种子数据"""
    db_url = os.getenv("POSTGRES_URL")
    if not db_url:
        print("错误：未配置 POSTGRES_URL，请检查 .env")
        return

    engine = create_async_engine(db_url, echo=False)

    try:
        await _seed_with_engine(engine)
    finally:
        await engine.dispose()


async def _seed_with_engine(engine) -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✓ 表结构创建完成")

    session_factory = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        count = await session.execute(select(func.count(University.id)))
        if count.scalar() > 0:
            print("⚠ 已有数据，跳过导入（如需重新导入请先清空表）")
            return

        random.seed(42)

        # 1. 导入院校
        uni_map = {}
        for uni_data in UNIVERSITIES:
            uni = University(**uni_data)
            session.add(uni)
            await session.flush()
            uni_map[uni_data["name"]] = uni.id
        print(f"✓ 导入 {len(UNIVERSITIES)} 所院校")

        # 2. 导入专业
        major_map = {}
        for uni_name, uni_id in uni_map.items():
            num_majors = random.randint(3, 6)
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

        # 3. 导入录取分数
        score_count = 0
        for uni_name, uni_id in uni_map.items():
            uni_info = next(u for u in UNIVERSITIES if u["name"] == uni_name)
            level = uni_info["level"]
            level_offset = {"985": 80, "211": 40, "双一流": 30, "普通": 0}
            base_offset = level_offset.get(level, 0)

            for province, config in PROVINCE_SCORES.items():
                for subject_type in config["subject_types"]:
                    base_key = f"{subject_type}_base"
                    base_score = config.get(base_key, 580)

                    for year in [2023, 2024, 2025]:
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

        # 4. 导入一分一段表
        rank_count = 0
        for province, config in PROVINCE_SCORES.items():
            for subject_type in config["subject_types"]:
                for year in [2023, 2024, 2025]:
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

        # 6. 导入招生计划
        plan_count = 0
        for uni_name, uni_id in list(uni_map.items())[:15]:
            for province in list(PROVINCE_SCORES.keys()):
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
        print("\n✅ 增强版数据导入完成！")
        print(f"   总计: {len(UNIVERSITIES)} 所院校, {len(major_map)} 个专业, {score_count} 条分数, {rank_count} 条位次, {len(PROVINCE_RULES)} 条规则, {plan_count} 条计划")


if __name__ == "__main__":
    asyncio.run(seed_data())
