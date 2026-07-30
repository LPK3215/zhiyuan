"""智愿 - 高考志愿填报数据模型（7张表）"""

from sqlalchemy import (
    Boolean,
    Column,
    Float,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import declarative_base

# 自包含元数据：保持与单测的按路径加载解耦（不触发 yuxi/__init__ 重型依赖链）。
# 表的创建由 server/utils/lifespan.py 在启动时一并 create_all，
# 因此 docker compose up 后无需依赖种子脚本即可建表。
Base = declarative_base()


class University(Base):
    """院校表"""

    __tablename__ = "zhiyuan_universities"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False, index=True)
    province = Column(String(50), nullable=False)
    city = Column(String(50), default="")
    level = Column(String(50), default="")  # 985/211/双一流/普通
    type = Column(String(50), default="")  # 综合/理工/师范/医药...
    nature = Column(String(20), default="公办")  # 公办/民办
    website = Column(String(300), default="")
    intro = Column(Text, default="")
    master_points = Column(Integer, default=0)  # 硕士点数量
    doctor_points = Column(Integer, default=0)  # 博士点数量
    key_disciplines = Column(Text, default="")  # 国家重点学科（逗号分隔）

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "province": self.province,
            "city": self.city,
            "level": self.level,
            "type": self.type,
            "nature": self.nature,
            "website": self.website,
            "intro": self.intro,
            "master_points": self.master_points,
            "doctor_points": self.doctor_points,
            "key_disciplines": self.key_disciplines,
        }


class College(Base):
    """学院/院系表"""

    __tablename__ = "zhiyuan_colleges"

    id = Column(Integer, primary_key=True, autoincrement=True)
    university_id = Column(Integer, nullable=False, index=True)
    name = Column(String(200), nullable=False)
    intro = Column(Text, default="")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "university_id": self.university_id,
            "name": self.name,
            "intro": self.intro,
        }


class Major(Base):
    """专业表"""

    __tablename__ = "zhiyuan_majors"

    id = Column(Integer, primary_key=True, autoincrement=True)
    university_id = Column(Integer, nullable=False, index=True)
    college_id = Column(Integer, default=0)
    name = Column(String(200), nullable=False, index=True)
    code = Column(String(20), default="")  # 专业代码
    degree = Column(String(50), default="")  # 学士/硕士
    duration = Column(String(20), default="4年")  # 学制
    subject_category = Column(String(100), default="")  # 学科门类
    is_key = Column(Boolean, default=False)  # 是否国家重点
    subject_requirement = Column(String(200), default="")  # 选科要求（如"物理+化学"）
    intro = Column(Text, default="")
    employment_rate = Column(Float, default=0.0)  # 就业率
    avg_salary = Column(Float, default=0.0)  # 平均薪资（元/月）
    career_directions = Column(Text, default="")  # 就业方向（逗号分隔）

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "university_id": self.university_id,
            "college_id": self.college_id,
            "name": self.name,
            "code": self.code,
            "degree": self.degree,
            "duration": self.duration,
            "subject_category": self.subject_category,
            "is_key": self.is_key,
            "subject_requirement": self.subject_requirement,
            "intro": self.intro,
            "employment_rate": self.employment_rate,
            "avg_salary": self.avg_salary,
            "career_directions": self.career_directions,
        }


class PlanScoreMixin:
    """招生计划与录取分数线共享的列定义。

    此前 EnrollmentPlan 与 AdmissionScore 各自重复声明了
    university_id/major_id/province/year/subject_type/batch/plan_count 七列，
    抽取为 Mixin 消除重复，保证两表字段语义一致、便于统一维护。
    """

    university_id = Column(Integer, nullable=False, index=True)
    major_id = Column(Integer, default=0, index=True)  # 0表示院校整体
    province = Column(String(50), nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)
    subject_type = Column(String(50), default="")  # 理科/文科/物理类/历史类/综合改革
    batch = Column(String(50), default="本科一批")  # 批次
    plan_count = Column(Integer, default=0)  # 招生人数


class AdmissionScore(PlanScoreMixin, Base):
    """历年录取分数线"""

    __tablename__ = "zhiyuan_admission_scores"

    id = Column(Integer, primary_key=True, autoincrement=True)
    min_score = Column(Integer, default=0)
    max_score = Column(Integer, default=0)
    avg_score = Column(Integer, default=0)
    min_rank = Column(Integer, default=0)  # 最低位次

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "university_id": self.university_id,
            "major_id": self.major_id,
            "province": self.province,
            "year": self.year,
            "subject_type": self.subject_type,
            "batch": self.batch,
            "min_score": self.min_score,
            "max_score": self.max_score,
            "avg_score": self.avg_score,
            "min_rank": self.min_rank,
            "plan_count": self.plan_count,
        }


class ScoreRank(Base):
    """一分一段表"""

    __tablename__ = "zhiyuan_score_ranks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    province = Column(String(50), nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)
    subject_type = Column(String(50), default="", index=True)
    score = Column(Integer, nullable=False, index=True)
    rank = Column(Integer, nullable=False)  # 累计人数（即位次）
    segment_count = Column(Integer, default=0)  # 本段人数

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "province": self.province,
            "year": self.year,
            "subject_type": self.subject_type,
            "score": self.score,
            "rank": self.rank,
            "segment_count": self.segment_count,
        }


class ProvinceRule(Base):
    """省份填报规则"""

    __tablename__ = "zhiyuan_province_rules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    province = Column(String(50), nullable=False, unique=True)
    year = Column(Integer, nullable=False)
    mode = Column(String(50), default="")  # 平行志愿/顺序志愿
    batch_count = Column(Integer, default=0)  # 可填志愿数
    max_per_batch = Column(Integer, default=0)  # 每批次最多填几个
    subject_mode = Column(String(50), default="")  # 3+1+2 / 3+3 / 传统文理
    description = Column(Text, default="")  # 规则详细说明
    tips = Column(Text, default="")  # 填报注意事项

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "province": self.province,
            "year": self.year,
            "mode": self.mode,
            "batch_count": self.batch_count,
            "max_per_batch": self.max_per_batch,
            "subject_mode": self.subject_mode,
            "description": self.description,
            "tips": self.tips,
        }


class EnrollmentPlan(PlanScoreMixin, Base):
    """招生计划表"""

    __tablename__ = "zhiyuan_enrollment_plans"

    id = Column(Integer, primary_key=True, autoincrement=True)
    duration = Column(String(20), default="4年")
    tuition = Column(String(50), default="")  # 学费
    remark = Column(Text, default="")  # 备注（如定向、民族班等）

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "university_id": self.university_id,
            "major_id": self.major_id,
            "province": self.province,
            "year": self.year,
            "subject_type": self.subject_type,
            "batch": self.batch,
            "plan_count": self.plan_count,
            "duration": self.duration,
            "tuition": self.tuition,
            "remark": self.remark,
        }
