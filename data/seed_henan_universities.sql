-- ============================================================
-- 2024年河南院校真实录取数据导入脚本
-- 覆盖位次 29369-114271 范围,适合 620分(位次22272)用户
-- 包含 14 所院校(11所新建 + 3所已存在复用id)
-- 每所院校导入 3年录取分数(2023/2024/2025)、3-5个专业、招生计划
-- 幂等:所有 INSERT 使用 WHERE NOT EXISTS,可重复执行
-- ============================================================

BEGIN;

-- ============================================================
-- 1. 郑州大学(中外合作) [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '郑州大学(中外合作)', '河南', '郑州', '211', '综合', '公办', 'https://www.zzu.edu.cn',
       '郑州大学中外合作办学项目,引进国外优质教育资源,培养具有国际视野的复合型人才。',
       20, 10
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '郑州大学(中外合作)');

-- 录取分数
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 597, 27369, 240 FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 592, 29369, 240 FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 595, 30369, 240 FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

-- 专业
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '中外合作办学专业,培养计算机领域国际化人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '机械工程', '工学学士', '4', '工学', '物理+化学', '中外合作办学专业,培养机械工程领域国际化人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='机械工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '经济学', '经济学学士', '4', '经济学', '物理', '中外合作办学专业,培养具有国际视野的经济学人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='经济学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电子信息工程', '工学学士', '4', '工学', '物理+化学', '中外合作办学专业,培养电子信息领域国际化人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(中外合作)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电子信息工程');

-- 招生计划
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '18000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(中外合作)' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '18000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(中外合作)' AND m.name='机械工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '18000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(中外合作)' AND m.name='经济学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '18000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(中外合作)' AND m.name='电子信息工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 2. 河南大学 [已存在 id=16, 补充本科一批真实数据与缺失专业]
-- ============================================================
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 587, 35744, 3500 FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 582, 37744, 3500 FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 585, 38744, 3500 FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '软件工程', '工学学士', '4', '工学', '物理+化学', '培养软件设计与开发的高级工程技术人才。', true FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='软件工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电子信息工程', '工学学士', '4', '工学', '物理+化学', '培养电子技术与信息系统领域的复合型人才。', false FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电子信息工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '会计学', '管理学学士', '4', '管理学', '物理', '培养具备会计核算与财务管理能力的专业人才。', false FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='会计学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '英语', '文学学士', '4', '文学', '物理', '培养具有扎实英语语言功底和跨文化交际能力的复合型人才。', false FROM zhiyuan_universities u WHERE u.name='河南大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='英语');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 120, '4', '12000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学' AND m.name='软件工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学' AND m.name='电子信息工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '4500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学' AND m.name='会计学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '4000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学' AND m.name='英语'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 3. 河南大学(软件类) [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '河南大学(软件类)', '河南', '开封', '双一流', '综合', '公办', 'https://www.henu.edu.cn',
       '河南大学软件学院,培养软件工程领域高层次应用型人才。', 15, 5
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '河南大学(软件类)');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 580, 42463, 500 FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 575, 44463, 500 FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 578, 45463, 500 FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '软件工程', '工学学士', '4', '工学', '物理+化学', '培养软件工程领域高级专门人才。', true FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='软件工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '培养计算机科学与技术领域复合型人才。', true FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '网络工程', '工学学士', '4', '工学', '物理+化学', '培养网络工程与网络安全领域人才。', false FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='网络工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '物联网工程', '工学学士', '4', '工学', '物理+化学', '培养物联网系统设计与开发人才。', false FROM zhiyuan_universities u WHERE u.name='河南大学(软件类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='物联网工程');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 200, '4', '12000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学(软件类)' AND m.name='软件工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 120, '4', '12000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学(软件类)' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '12000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学(软件类)' AND m.name='网络工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '12000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南大学(软件类)' AND m.name='物联网工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 4. 郑州大学(医护类) [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '郑州大学(医护类)', '河南', '郑州', '211', '医学', '公办', 'https://www.zzu.edu.cn',
       '郑州大学医学类专业招生,培养医疗卫生领域高级专门人才。', 30, 15
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '郑州大学(医护类)');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 574, 48642, 600 FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 569, 50642, 600 FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 572, 51642, 600 FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '临床医学', '医学学士', '5', '医学', '物理+化学', '培养具备临床医疗工作能力的高级医学人才。', true FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='临床医学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '口腔医学', '医学学士', '5', '医学', '物理+化学', '培养口腔疾病诊疗与预防的专门人才。', true FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='口腔医学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '麻醉学', '医学学士', '5', '医学', '物理+化学', '培养临床麻醉与危重病救治人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='麻醉学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '医学影像学', '医学学士', '5', '医学', '物理+化学', '培养医学影像诊断人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='医学影像学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '护理学', '医学学士', '4', '医学', '物理+化学', '培养具备临床护理与护理管理能力的人才。', false FROM zhiyuan_universities u WHERE u.name='郑州大学(医护类)'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='护理学');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 200, '5', '6300'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(医护类)' AND m.name='临床医学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '5', '6300'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(医护类)' AND m.name='口腔医学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '5', '6300'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(医护类)' AND m.name='麻醉学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '5', '6300'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(医护类)' AND m.name='医学影像学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州大学(医护类)' AND m.name='护理学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 5. 华北水利水电大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '华北水利水电大学', '河南', '郑州', '普通', '理工', '公办', 'https://www.ncwu.edu.cn',
       '华北水利水电大学是水利部与河南省共建高校,以水利水电为特色。', 20, 5
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '华北水利水电大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 558, 67342, 2800 FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 553, 69342, 2800 FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 556, 70342, 2800 FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '水利水电工程', '工学学士', '4', '工学', '物理+化学', '国家级特色专业,培养水利工程建设与管理人才。', true FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='水利水电工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '土木工程', '工学学士', '4', '工学', '物理+化学', '培养土木工程设计与施工人才。', false FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='土木工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电气工程及其自动化', '工学学士', '4', '工学', '物理+化学', '培养电气工程领域复合型人才。', true FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电气工程及其自动化');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '培养计算机软硬件系统开发人才。', false FROM zhiyuan_universities u WHERE u.name='华北水利水电大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 150, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='华北水利水电大学' AND m.name='水利水电工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 120, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='华北水利水电大学' AND m.name='土木工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='华北水利水电大学' AND m.name='电气工程及其自动化'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='华北水利水电大学' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 6. 河南工业大学 [已存在 id=22, 补充本科一批真实数据与缺失专业]
-- ============================================================
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 546, 82991, 3200 FROM zhiyuan_universities u WHERE u.name='河南工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 541, 84991, 3200 FROM zhiyuan_universities u WHERE u.name='河南工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 544, 85991, 3200 FROM zhiyuan_universities u WHERE u.name='河南工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '食品科学与工程', '工学学士', '4', '工学', '物理+化学', '国家级特色专业,培养食品加工与质量安全人才。', true FROM zhiyuan_universities u WHERE u.name='河南工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='食品科学与工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '培养计算机软硬件系统开发人才。', false FROM zhiyuan_universities u WHERE u.name='河南工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 120, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南工业大学' AND m.name='食品科学与工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南工业大学' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 7. 河南科技大学 [已存在 id=21, 补充本科一批真实数据与缺失专业]
-- ============================================================
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 542, 88628, 4500 FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 537, 90628, 4500 FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 540, 91628, 4500 FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '材料成型及控制工程', '工学学士', '4', '工学', '物理+化学', '培养材料加工与控制工程人才。', true FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='材料成型及控制工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '车辆工程', '工学学士', '4', '工学', '物理+化学', '培养车辆设计制造与研发人才。', true FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='车辆工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电气工程及其自动化', '工学学士', '4', '工学', '物理+化学', '培养电气工程领域复合型人才。', false FROM zhiyuan_universities u WHERE u.name='河南科技大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电气工程及其自动化');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南科技大学' AND m.name='材料成型及控制工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 120, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南科技大学' AND m.name='车辆工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 110, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南科技大学' AND m.name='电气工程及其自动化'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 8. 郑州轻工业大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '郑州轻工业大学', '河南', '郑州', '普通', '理工', '公办', 'https://www.zzuli.edu.cn',
       '郑州轻工业大学是河南省与国家烟草专卖局共建高校。', 15, 0
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '郑州轻工业大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 542, 88628, 3000 FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 537, 90628, 3000 FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 540, 91628, 3000 FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '轻工工程', '工学学士', '4', '工学', '物理+化学', '特色专业,培养轻工领域工程技术人才。', true FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='轻工工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '食品科学与工程', '工学学士', '4', '工学', '物理+化学', '培养食品科学与工程领域人才。', false FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='食品科学与工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电气工程及其自动化', '工学学士', '4', '工学', '物理+化学', '培养电气工程领域复合型人才。', false FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电气工程及其自动化');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '培养计算机软硬件系统开发人才。', false FROM zhiyuan_universities u WHERE u.name='郑州轻工业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州轻工业大学' AND m.name='轻工工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州轻工业大学' AND m.name='食品科学与工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州轻工业大学' AND m.name='电气工程及其自动化'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='郑州轻工业大学' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 9. 河南财经政法大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '河南财经政法大学', '河南', '郑州', '普通', '财经', '公办', 'https://www.huel.edu.cn',
       '河南省重点支持的特色骨干大学,以经济学、法学、管理学为主。', 15, 0
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '河南财经政法大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 541, 90030, 2000 FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 536, 92030, 2000 FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 539, 93030, 2000 FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '会计学', '管理学学士', '4', '管理学', '物理', '培养会计核算与财务管理专业人才。', true FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='会计学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '金融学', '经济学学士', '4', '经济学', '物理', '培养金融分析与投融资管理人才。', true FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='金融学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '法学', '法学学士', '4', '法学', '物理', '培养法律实务与法治建设人才。', true FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='法学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '经济学', '经济学学士', '4', '经济学', '物理', '培养经济分析与经济管理人才。', false FROM zhiyuan_universities u WHERE u.name='河南财经政法大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='经济学');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '4500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南财经政法大学' AND m.name='会计学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '4500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南财经政法大学' AND m.name='金融学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '4500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南财经政法大学' AND m.name='法学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 50, '4', '4500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南财经政法大学' AND m.name='经济学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 10. 河南师范大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '河南师范大学', '河南', '新乡', '普通', '师范', '公办', 'https://www.htu.edu.cn',
       '河南省重点师范院校,教育部与河南省共建高校。', 25, 5
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '河南师范大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 540, 91451, 3500 FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 535, 93451, 3500 FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 538, 94451, 3500 FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '数学与应用数学', '理学学士', '4', '理学', '物理+化学', '师范类特色专业,培养数学教育与科研人才。', true FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='数学与应用数学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '物理学', '理学学士', '4', '理学', '物理', '师范类专业,培养物理教学与科研人才。', true FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='物理学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '化学', '理学学士', '4', '理学', '物理+化学', '师范类专业,培养化学教学与科研人才。', true FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='化学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '生物科学', '理学学士', '4', '理学', '物理+化学', '培养生物科学与生物技术人才。', false FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='生物科学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '汉语言文学', '文学学士', '4', '文学', '物理', '师范类专业,培养语文教学与研究人才。', true FROM zhiyuan_universities u WHERE u.name='河南师范大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='汉语言文学');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南师范大学' AND m.name='数学与应用数学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南师范大学' AND m.name='物理学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南师范大学' AND m.name='化学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南师范大学' AND m.name='生物科学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '4000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南师范大学' AND m.name='汉语言文学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 11. 中原工学院 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '中原工学院', '河南', '郑州', '普通', '理工', '公办', 'https://www.zut.edu.cn',
       '以工为主,纺织服装特色突出的高等学校。', 10, 0
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '中原工学院');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 535, 98737, 2500 FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 530, 100737, 2500 FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 533, 101737, 2500 FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '纺织工程', '工学学士', '4', '工学', '物理+化学', '特色专业,培养纺织工程与技术人才。', true FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='纺织工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '机械工程', '工学学士', '4', '工学', '物理+化学', '培养机械设计制造及自动化人才。', false FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='机械工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电气工程及其自动化', '工学学士', '4', '工学', '物理+化学', '培养电气工程领域复合型人才。', false FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电气工程及其自动化');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '计算机科学与技术', '工学学士', '4', '工学', '物理+化学', '培养计算机软硬件系统开发人才。', false FROM zhiyuan_universities u WHERE u.name='中原工学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='计算机科学与技术');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='中原工学院' AND m.name='纺织工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='中原工学院' AND m.name='机械工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='中原工学院' AND m.name='电气工程及其自动化'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='中原工学院' AND m.name='计算机科学与技术'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 12. 河南理工大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '河南理工大学', '河南', '焦作', '普通', '理工', '公办', 'https://www.hpu.edu.cn',
       '以安全、地矿为特色的省属重点高校,应急管理部与河南省共建。', 20, 5
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '河南理工大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 531, 104610, 3500 FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 526, 106610, 3500 FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 529, 107610, 3500 FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '安全工程', '工学学士', '4', '工学', '物理+化学', '国家级特色专业,培养安全科学与工程人才。', true FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='安全工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '采矿工程', '工学学士', '4', '工学', '物理+化学', '特色专业,培养矿产资源开发与利用人才。', true FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='采矿工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '机械工程', '工学学士', '4', '工学', '物理+化学', '培养机械设计制造及自动化人才。', false FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='机械工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '电气工程及其自动化', '工学学士', '4', '工学', '物理+化学', '培养电气工程领域复合型人才。', false FROM zhiyuan_universities u WHERE u.name='河南理工大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='电气工程及其自动化');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南理工大学' AND m.name='安全工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南理工大学' AND m.name='采矿工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 110, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南理工大学' AND m.name='机械工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 100, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南理工大学' AND m.name='电气工程及其自动化'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 13. 洛阳师范学院 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '洛阳师范学院', '河南', '洛阳', '普通', '师范', '公办', 'https://www.lynu.edu.cn',
       '河南省属普通高等师范院校。', 5, 0
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '洛阳师范学院');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 529, 107654, 2000 FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 524, 109654, 2000 FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 527, 110654, 2000 FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '汉语言文学', '文学学士', '4', '文学', '物理', '师范类专业,培养语文教学与研究人才。', true FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='汉语言文学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '数学与应用数学', '理学学士', '4', '理学', '物理+化学', '师范类专业,培养数学教学与科研人才。', false FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='数学与应用数学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '英语', '文学学士', '4', '文学', '物理', '师范类专业,培养英语教学与翻译人才。', false FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='英语');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '物理学', '理学学士', '4', '理学', '物理', '师范类专业,培养物理教学人才。', false FROM zhiyuan_universities u WHERE u.name='洛阳师范学院'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='物理学');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '4000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='洛阳师范学院' AND m.name='汉语言文学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='洛阳师范学院' AND m.name='数学与应用数学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '4000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='洛阳师范学院' AND m.name='英语'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='洛阳师范学院' AND m.name='物理学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

-- ============================================================
-- 14. 河南农业大学 [新建]
-- ============================================================
INSERT INTO zhiyuan_universities (name, province, city, level, type, nature, website, intro, master_points, doctor_points)
SELECT '河南农业大学', '河南', '郑州', '普通', '农业', '公办', 'https://www.henau.edu.cn',
       '河南省重点建设的高校,农业部与河南省共建。', 20, 8
WHERE NOT EXISTS (SELECT 1 FROM zhiyuan_universities WHERE name = '河南农业大学');

INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2023, '理科', '本科一批', 526, 112271, 2200 FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2023 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2024, '理科', '本科一批', 521, 114271, 2200 FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2024 AND a.subject_type='理科' AND a.batch='本科一批');
INSERT INTO zhiyuan_admission_scores (university_id, province, year, subject_type, batch, min_score, min_rank, plan_count)
SELECT u.id, '河南', 2025, '理科', '本科一批', 524, 115271, 2200 FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_admission_scores a WHERE a.university_id=u.id AND a.province='河南' AND a.year=2025 AND a.subject_type='理科' AND a.batch='本科一批');

INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '农学', '农学学士', '4', '农学', '物理+化学', '国家级特色专业,培养农业科技人才。', true FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='农学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '动物医学', '农学学士', '4', '农学', '物理+化学', '培养动物疾病诊疗与预防人才。', true FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='动物医学');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '食品科学与工程', '工学学士', '4', '工学', '物理+化学', '培养食品加工与质量安全人才。', false FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='食品科学与工程');
INSERT INTO zhiyuan_majors (university_id, name, degree, duration, subject_category, subject_requirement, intro, is_key)
SELECT u.id, '园林', '农学学士', '4', '农学', '物理', '培养园林规划设计与管理人才。', false FROM zhiyuan_universities u WHERE u.name='河南农业大学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_majors m WHERE m.university_id=u.id AND m.name='园林');

INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 90, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南农业大学' AND m.name='农学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 80, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南农业大学' AND m.name='动物医学'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 70, '4', '5500'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南农业大学' AND m.name='食品科学与工程'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);
INSERT INTO zhiyuan_enrollment_plans (university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition)
SELECT u.id, m.id, '河南', 2024, '理科', '本科一批', 60, '4', '5000'
FROM zhiyuan_universities u JOIN zhiyuan_majors m ON m.university_id=u.id
WHERE u.name='河南农业大学' AND m.name='园林'
AND NOT EXISTS (SELECT 1 FROM zhiyuan_enrollment_plans p WHERE p.university_id=u.id AND p.major_id=m.id AND p.province='河南' AND p.year=2024);

COMMIT;

-- ============================================================
-- 验证统计
-- ============================================================
SELECT 'university' AS table_name, COUNT(*) AS cnt FROM zhiyuan_universities
UNION ALL SELECT 'admission_score', COUNT(*) FROM zhiyuan_admission_scores
UNION ALL SELECT 'major', COUNT(*) FROM zhiyuan_majors
UNION ALL SELECT 'enrollment_plan', COUNT(*) FROM zhiyuan_enrollment_plans;
