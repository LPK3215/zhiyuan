<template>
  <div class="zhiyuan-admin">
    <div class="page-header">
      <h2>智愿数据管理</h2>
      <p class="subtitle">管理院校、专业、录取分数、志愿规则与招生计划数据</p>
    </div>

    <!-- 数据看板 -->
    <div class="dashboard" v-if="dashStats">
      <div class="dash-card" v-for="item in dashItems" :key="item.label">
        <div class="dash-icon" :style="{ background: item.color }">
          <component :is="item.icon" :size="20" />
        </div>
        <div class="dash-info">
          <span class="dash-number">{{ item.value }}</span>
          <span class="dash-label">{{ item.label }}</span>
        </div>
      </div>
    </div>

    <!-- 数据健康度 -->
    <div class="health-panel" v-if="healthData">
      <div class="health-header">
        <h3 class="health-title">数据完整度</h3>
        <div class="health-score-wrapper">
          <div
            class="health-score-bar"
            :style="{
              width: healthData.health_score + '%',
              background: healthScoreColor,
            }"
          ></div>
          <span class="health-score-text" :style="{ color: healthScoreColor }">
            {{ healthData.health_score }}/100
          </span>
        </div>
      </div>
      <div class="health-issues" v-if="healthItems.length > 0">
        <div class="health-issue" v-for="issue in healthItems" :key="issue.key">
          <span class="issue-label">{{ issue.label }}</span>
          <a-tag color="orange">{{ issue.value }} 所</a-tag>
        </div>
      </div>
      <a-alert
        v-else
        type="success"
        message="数据完整度良好"
        description="所有院校均具备完整的学科、分数、计划等关键数据"
        show-icon
        style="margin-top: 12px"
      />
    </div>

    <a-tabs v-model:activeKey="activeTab" type="card" @change="onTabChange">
      <!-- ========== 院校管理 ========== -->
      <a-tab-pane key="university" tab="院校管理">
        <div class="filter-bar">
          <a-input-search
            v-model:value="uniState.keyword"
            placeholder="搜索院校名称"
            style="width: 260px"
            allow-clear
            @search="onUniSearch"
          />
          <a-button type="primary" @click="openUniModal(null)">新增院校</a-button>
        </div>
        <a-table
          :dataSource="uniState.list"
          :columns="uniColumns"
          :loading="uniState.loading"
          rowKey="id"
          :pagination="false"
          size="small"
          :scroll="{ x: 1100 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-button type="link" size="small" @click="openUniModal(record)">编辑</a-button>
              <a-popconfirm
                title="确认删除该院校？"
                ok-text="删除"
                cancel-text="取消"
                @confirm="deleteUniversity(record)"
              >
                <a-button type="link" size="small" danger>删除</a-button>
              </a-popconfirm>
            </template>
          </template>
        </a-table>
        <div class="pagination-bar">
          <a-pagination
            v-model:current="uniState.page"
            v-model:pageSize="uniState.size"
            :total="uniState.total"
            show-size-changer
            :show-total="(t) => `共 ${t} 条`"
            @change="loadUniversities"
          />
        </div>
      </a-tab-pane>

      <!-- ========== 专业管理 ========== -->
      <a-tab-pane key="major" tab="专业管理">
        <div class="filter-bar">
          <a-input-number
            v-model:value="majorState.universityId"
            placeholder="院校ID"
            :min="0"
            style="width: 140px"
          />
          <a-input-search
            v-model:value="majorState.keyword"
            placeholder="搜索专业名称"
            style="width: 240px"
            allow-clear
            @search="onMajorSearch"
          />
          <a-button type="primary" @click="openMajorModal(null)">新增专业</a-button>
          <a-button :loading="importState.importing && importState.type === 'major'" @click="openImportDialog('major')">
            批量导入
          </a-button>
        </div>
        <a-table
          :dataSource="majorState.list"
          :columns="majorColumns"
          :loading="majorState.loading"
          rowKey="id"
          :pagination="false"
          size="small"
          :scroll="{ x: 1100 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'is_key'">
              <a-tag :color="record.is_key ? 'green' : 'default'">
                {{ record.is_key ? '重点' : '普通' }}
              </a-tag>
            </template>
            <template v-if="column.key === 'action'">
              <a-button type="link" size="small" @click="openMajorModal(record)">编辑</a-button>
              <a-popconfirm
                title="确认删除该专业？"
                ok-text="删除"
                cancel-text="取消"
                @confirm="deleteMajor(record)"
              >
                <a-button type="link" size="small" danger>删除</a-button>
              </a-popconfirm>
            </template>
          </template>
        </a-table>
        <div class="pagination-bar">
          <a-pagination
            v-model:current="majorState.page"
            v-model:pageSize="majorState.size"
            :total="majorState.total"
            show-size-changer
            :show-total="(t) => `共 ${t} 条`"
            @change="loadMajors"
          />
        </div>
      </a-tab-pane>

      <!-- ========== 分数管理 ========== -->
      <a-tab-pane key="score" tab="分数管理">
        <div class="filter-bar">
          <a-input-number
            v-model:value="scoreState.universityId"
            placeholder="院校ID"
            :min="0"
            style="width: 140px"
          />
          <a-select
            v-model:value="scoreState.province"
            placeholder="省份"
            style="width: 140px"
            allow-clear
            show-search
          >
            <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
          </a-select>
          <a-input-number
            v-model:value="scoreState.year"
            placeholder="年份"
            :min="0"
            style="width: 120px"
          />
          <a-button type="primary" @click="onScoreSearch">查询</a-button>
          <a-button type="primary" @click="openScoreModal(null)">新增分数</a-button>
          <a-button :loading="importState.importing && importState.type === 'score'" @click="openImportDialog('score')">
            批量导入
          </a-button>
        </div>
        <a-table
          :dataSource="scoreState.list"
          :columns="scoreColumns"
          :loading="scoreState.loading"
          rowKey="id"
          :pagination="false"
          size="small"
          :scroll="{ x: 1100 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-button type="link" size="small" @click="openScoreModal(record)">编辑</a-button>
              <a-popconfirm
                title="确认删除该分数记录？"
                ok-text="删除"
                cancel-text="取消"
                @confirm="deleteScore(record)"
              >
                <a-button type="link" size="small" danger>删除</a-button>
              </a-popconfirm>
            </template>
          </template>
        </a-table>
        <div class="pagination-bar">
          <a-pagination
            v-model:current="scoreState.page"
            v-model:pageSize="scoreState.size"
            :total="scoreState.total"
            show-size-changer
            :show-total="(t) => `共 ${t} 条`"
            @change="loadScores"
          />
        </div>
      </a-tab-pane>

      <!-- ========== 规则管理 ========== -->
      <a-tab-pane key="rule" tab="规则管理">
        <div class="filter-bar">
          <span class="hint-text">规则按 upsert 写入（同 province+year 自动更新）</span>
          <a-button type="primary" @click="openRuleModal(null)">新增 / 更新规则</a-button>
        </div>
        <a-table
          :dataSource="rulePagedList"
          :columns="ruleColumns"
          :loading="ruleState.loading"
          rowKey="id"
          :pagination="false"
          size="small"
          :scroll="{ x: 900 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-button type="link" size="small" @click="openRuleModal(record)">编辑</a-button>
              <a-popconfirm
                title="确认删除该规则？"
                ok-text="删除"
                cancel-text="取消"
                @confirm="deleteRule(record)"
              >
                <a-button type="link" size="small" danger>删除</a-button>
              </a-popconfirm>
            </template>
          </template>
        </a-table>
        <div class="pagination-bar">
          <a-pagination
            v-model:current="ruleState.page"
            :pageSize="ruleState.size"
            :total="ruleState.list.length"
            :show-total="(t) => `共 ${t} 条`"
            show-size-changer
            @change="(p, s) => { ruleState.page = p; ruleState.size = s }"
          />
        </div>
      </a-tab-pane>

      <!-- ========== 计划管理 ========== -->
      <a-tab-pane key="plan" tab="计划管理">
        <div class="filter-bar">
          <a-input-number
            v-model:value="planState.universityId"
            placeholder="院校ID"
            :min="0"
            style="width: 140px"
          />
          <a-select
            v-model:value="planState.province"
            placeholder="省份"
            style="width: 140px"
            allow-clear
            show-search
          >
            <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
          </a-select>
          <a-input-number
            v-model:value="planState.year"
            placeholder="年份"
            :min="0"
            style="width: 120px"
          />
          <a-button type="primary" @click="onPlanSearch">查询</a-button>
          <a-button type="primary" @click="openPlanModal(null)">新增计划</a-button>
        </div>
        <a-table
          :dataSource="planState.list"
          :columns="planColumns"
          :loading="planState.loading"
          rowKey="id"
          :pagination="false"
          size="small"
          :scroll="{ x: 1100 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-button type="link" size="small" @click="openPlanModal(record)">编辑</a-button>
              <a-popconfirm
                title="确认删除该计划？"
                ok-text="删除"
                cancel-text="取消"
                @confirm="deletePlan(record)"
              >
                <a-button type="link" size="small" danger>删除</a-button>
              </a-popconfirm>
            </template>
          </template>
        </a-table>
        <div class="pagination-bar">
          <a-pagination
            v-model:current="planState.page"
            v-model:pageSize="planState.size"
            :total="planState.total"
            :show-total="(t) => `共 ${t} 条`"
            show-size-changer
            @change="loadPlans"
          />
        </div>
      </a-tab-pane>
    </a-tabs>

    <!-- 隐藏的文件上传输入（用于 Excel/CSV 导入） -->
    <input
      ref="importFileInput"
      type="file"
      accept=".xlsx,.xls,.csv"
      style="display: none"
      @change="onImportFileChange"
    />

    <!-- ========== 院校表单 Modal ========== -->
    <a-modal
      v-model:open="uniState.modalVisible"
      :title="uniState.editing ? '编辑院校' : '新增院校'"
      width="760px"
      :confirm-loading="uniState.submitting"
      :mask-closable="false"
      @ok="submitUniversity"
      @cancel="uniState.modalVisible = false"
    >
      <a-form :model="uniState.form" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="名称" required>
              <a-input v-model:value="uniState.form.name" placeholder="院校名称" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="层次">
              <a-select v-model:value="uniState.form.level" placeholder="层次" allow-clear>
                <a-select-option v-for="lv in universityLevels" :key="lv.value" :value="lv.value">
                  {{ lv.label }}
                </a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="类型">
              <a-select v-model:value="uniState.form.type" placeholder="类型" allow-clear>
                <a-select-option v-for="t in universityTypes" :key="t" :value="t">{{ t }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="省份">
              <a-select v-model:value="uniState.form.province" placeholder="省份" allow-clear show-search>
                <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="城市">
              <a-input v-model:value="uniState.form.city" placeholder="城市" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="性质">
              <a-select v-model:value="uniState.form.nature" placeholder="性质" allow-clear>
                <a-select-option value="公办">公办</a-select-option>
                <a-select-option value="民办">民办</a-select-option>
                <a-select-option value="中外合作">中外合作</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="网站">
              <a-input v-model:value="uniState.form.website" placeholder="https://" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="硕士点">
              <a-input-number v-model:value="uniState.form.master_points" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="博士点">
              <a-input-number v-model:value="uniState.form.doctor_points" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="重点学科">
              <a-input v-model:value="uniState.form.key_disciplines" placeholder="多个用逗号分隔" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="简介">
              <a-textarea v-model:value="uniState.form.intro" :rows="3" placeholder="院校简介" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- ========== 专业表单 Modal ========== -->
    <a-modal
      v-model:open="majorState.modalVisible"
      :title="majorState.editing ? '编辑专业' : '新增专业'"
      width="760px"
      :confirm-loading="majorState.submitting"
      :mask-closable="false"
      @ok="submitMajor"
      @cancel="majorState.modalVisible = false"
    >
      <a-form :model="majorState.form" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="所属院校" required>
              <a-select
                v-model:value="majorState.form.university_id"
                placeholder="搜索选择院校"
                show-search
                :filter-option="filterUniversityOption"
                :options="universityOptions"
                :loading="universityOptionsLoading"
                style="width: 100%"
              />
            </a-form-item>
          </a-col>
          <a-col :span="10">
            <a-form-item label="专业名称" required>
              <a-input v-model:value="majorState.form.name" placeholder="专业名称" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="专业代码">
              <a-input v-model:value="majorState.form.code" placeholder="如 0809" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="学位类型">
              <a-input v-model:value="majorState.form.degree" placeholder="如 工学学士" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="学制">
              <a-input v-model:value="majorState.form.duration" placeholder="如 4年" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="学科门类">
              <a-input v-model:value="majorState.form.subject_category" placeholder="如 工学" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="选科要求">
              <a-input v-model:value="majorState.form.subject_requirement" placeholder="如 物理+化学" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="就业率(%)">
              <a-input-number v-model:value="majorState.form.employment_rate" :min="0" :max="100" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="平均薪资">
              <a-input-number v-model:value="majorState.form.avg_salary" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="是否重点">
              <a-switch v-model:checked="majorState.form.is_key" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="就业方向">
              <a-input v-model:value="majorState.form.career_directions" placeholder="多个用逗号分隔" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="专业简介">
              <a-textarea v-model:value="majorState.form.intro" :rows="3" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- ========== 分数表单 Modal ========== -->
    <a-modal
      v-model:open="scoreState.modalVisible"
      :title="scoreState.editing ? '编辑分数' : '新增分数'"
      width="720px"
      :confirm-loading="scoreState.submitting"
      :mask-closable="false"
      @ok="submitScore"
      @cancel="scoreState.modalVisible = false"
    >
      <a-form :model="scoreState.form" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="院校" required>
              <a-select
                v-model:value="scoreState.form.university_id"
                placeholder="搜索选择院校"
                show-search
                :filter-option="filterUniversityOption"
                :options="universityOptions"
                :loading="universityOptionsLoading"
                style="width: 100%"
                @change="onScoreUniversityChange"
              />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="专业（0=院校整体线）">
              <a-select
                v-model:value="scoreState.form.major_id"
                placeholder="选择专业（可选）"
                allow-clear
                :options="scoreMajorOptions"
                style="width: 100%"
              />
            </a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="省份" required>
              <a-select v-model:value="scoreState.form.province" placeholder="省份" allow-clear show-search>
                <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="年份" required>
              <a-input-number v-model:value="scoreState.form.year" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="科类">
              <a-select v-model:value="scoreState.form.subject_type" placeholder="科类" allow-clear show-search>
                <a-select-option v-for="s in subjectTypes" :key="s" :value="s">{{ s }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="批次">
              <a-input v-model:value="scoreState.form.batch" placeholder="如 本科一批" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="计划数">
              <a-input-number v-model:value="scoreState.form.plan_count" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="最低分">
              <a-input-number v-model:value="scoreState.form.min_score" :min="0" :max="750" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="最高分">
              <a-input-number v-model:value="scoreState.form.max_score" :min="0" :max="750" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="平均分">
              <a-input-number v-model:value="scoreState.form.avg_score" :min="0" :max="750" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="最低位次">
              <a-input-number v-model:value="scoreState.form.min_rank" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- ========== 规则表单 Modal ========== -->
    <a-modal
      v-model:open="ruleState.modalVisible"
      :title="ruleState.editing ? '编辑规则' : '新增 / 更新规则'"
      width="640px"
      :confirm-loading="ruleState.submitting"
      :mask-closable="false"
      @ok="submitRule"
      @cancel="ruleState.modalVisible = false"
    >
      <a-alert
        message="同 province + year 的规则会被自动更新（upsert）"
        type="info"
        show-icon
        style="margin-bottom: 12px"
      />
      <a-form :model="ruleState.form" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="省份" required>
              <a-select v-model:value="ruleState.form.province" placeholder="省份" allow-clear show-search>
                <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="年份" required>
              <a-input-number v-model:value="ruleState.form.year" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="模式">
              <a-input v-model:value="ruleState.form.mode" placeholder="如 新高考" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="批次数量">
              <a-input-number v-model:value="ruleState.form.batch_count" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="每批上限">
              <a-input-number v-model:value="ruleState.form.max_per_batch" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="科类模式">
              <a-input v-model:value="ruleState.form.subject_mode" placeholder="如 物理类/历史类" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="描述">
              <a-textarea v-model:value="ruleState.form.description" :rows="2" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="提示">
              <a-textarea v-model:value="ruleState.form.tips" :rows="2" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>

    <!-- ========== 计划表单 Modal ========== -->
    <a-modal
      v-model:open="planState.modalVisible"
      :title="planState.editing ? '编辑计划' : '新增计划'"
      width="720px"
      :confirm-loading="planState.submitting"
      :mask-closable="false"
      @ok="submitPlan"
      @cancel="planState.modalVisible = false"
    >
      <a-form :model="planState.form" layout="vertical">
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="院校" required>
              <a-select
                v-model:value="planState.form.university_id"
                placeholder="搜索选择院校"
                show-search
                :filter-option="filterUniversityOption"
                :options="universityOptions"
                :loading="universityOptionsLoading"
                style="width: 100%"
                @change="onPlanUniversityChange"
              />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="专业（0=院校整体线）">
              <a-select
                v-model:value="planState.form.major_id"
                placeholder="选择专业（可选）"
                allow-clear
                :options="planMajorOptions"
                style="width: 100%"
              />
            </a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="省份" required>
              <a-select v-model:value="planState.form.province" placeholder="省份" allow-clear show-search>
                <a-select-option v-for="p in provinces" :key="p" :value="p">{{ p }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="年份" required>
              <a-input-number v-model:value="planState.form.year" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="科类">
              <a-select v-model:value="planState.form.subject_type" placeholder="科类" allow-clear show-search>
                <a-select-option v-for="s in subjectTypes" :key="s" :value="s">{{ s }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="批次">
              <a-input v-model:value="planState.form.batch" placeholder="如 本科一批" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="计划数">
              <a-input-number v-model:value="planState.form.plan_count" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="学制">
              <a-input v-model:value="planState.form.duration" placeholder="如 4年" />
            </a-form-item>
          </a-col>
          <a-col :span="6">
            <a-form-item label="学费">
              <a-input v-model:value="planState.form.tuition" placeholder="如 5000元/年" />
            </a-form-item>
          </a-col>
          <a-col :span="24">
            <a-form-item label="备注">
              <a-textarea v-model:value="planState.form.remark" :rows="2" />
            </a-form-item>
          </a-col>
        </a-row>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { zhiyuanApi } from '@/apis/zhiyuan_api'
import {
  Building2,
  BookOpen,
  TrendingUp,
  BarChart3,
  ClipboardList,
  MapPin,
} from 'lucide-vue-next'
import {
  PROVINCES,
  SUBJECT_TYPES,
  UNIVERSITY_LEVELS,
  UNIVERSITY_TYPES,
} from '@/constants/zhiyuanOptions'

const provinces = PROVINCES
const subjectTypes = SUBJECT_TYPES
const universityLevels = UNIVERSITY_LEVELS
const universityTypes = UNIVERSITY_TYPES

const activeTab = ref('university')

// ========== 数据看板 ==========
const dashStats = ref(null)
const dashItems = computed(() => {
  if (!dashStats.value) return []
  return [
    { label: '院校', value: dashStats.value.universities || 0, icon: Building2, color: 'linear-gradient(135deg, #035064, #0a8499)' },
    { label: '专业', value: dashStats.value.majors || 0, icon: BookOpen, color: 'linear-gradient(135deg, #2563eb, #1d4ed8)' },
    { label: '录取分数', value: dashStats.value.admission_scores || 0, icon: TrendingUp, color: 'linear-gradient(135deg, #059669, #10b981)' },
    { label: '位次数据', value: dashStats.value.score_ranks || 0, icon: BarChart3, color: 'linear-gradient(135deg, #7c3aed, #6d28d9)' },
    { label: '招生计划', value: dashStats.value.enrollment_plans || 0, icon: ClipboardList, color: 'linear-gradient(135deg, #ea580c, #f97316)' },
    { label: '覆盖省份', value: dashStats.value.provinces_covered || 0, icon: MapPin, color: 'linear-gradient(135deg, #dc2626, #ef4444)' },
  ]
})

// ========== 数据健康度 ==========
const healthData = ref(null)
const healthScoreColor = computed(() => {
  if (!healthData.value) return 'var(--gray-500)'
  const s = healthData.value.health_score
  if (s >= 85) return '#10b981'
  if (s >= 60) return '#f59e0b'
  return '#ef4444'
})
const healthItems = computed(() => {
  if (!healthData.value || !healthData.value.issues) return []
  const labels = {
    no_disciplines: '缺失重点学科',
    no_master: '缺失硕士点',
    no_doctor: '缺失博士点',
    no_website: '缺失官网链接',
    no_majors: '无专业数据',
    no_scores: '无录取分数',
    no_plans: '无招生计划',
  }
  return Object.entries(healthData.value.issues)
    .filter(([k]) => k !== 'empty_data')
    .map(([k, v]) => ({ key: k, label: labels[k] || k, value: v }))
})

// ========== 院校/专业下拉选项（用于专业/分数/计划表单的级联选择） ==========
const universityOptions = ref([])  // [{ label: '清华大学', value: 1 }, ...]
const scoreMajorOptions = ref([])  // 分数表单中当前院校的专业列表
const planMajorOptions = ref([])   // 计划表单中当前院校的专业列表
const _majorOptionsCache = {}      // 缓存：universityId -> [{label, value}]

// 院校下拉过滤函数
const filterUniversityOption = (input, option) => {
  const label = option?.label || ''
  return String(label).toLowerCase().includes(input.toLowerCase())
}

const universityOptionsLoading = ref(false)

async function loadUniversityOptions() {
  // 如果已经加载过且非空，不重复加载
  if (universityOptions.value.length > 0) return
  universityOptionsLoading.value = true
  try {
    const res = await zhiyuanApi.adminListUniversities({ page: 1, size: 500 })
    const items = res?.items || []
    universityOptions.value = items.map(u => ({ label: u.name, value: u.id }))
  } catch (e) {
    console.error('加载院校选项失败:', e?.message || e)
  } finally {
    universityOptionsLoading.value = false
  }
}

async function loadMajorOptionsForSelect(universityId, targetRef) {
  if (!universityId) {
    targetRef.value = []
    return
  }
  // 命中缓存
  if (_majorOptionsCache[universityId]) {
    targetRef.value = _majorOptionsCache[universityId]
    return
  }
  try {
    const res = await zhiyuanApi.adminListMajors({ university_id: universityId, page: 1, size: 200 })
    const opts = (res?.items || []).map(m => ({ label: m.name, value: m.id }))
    _majorOptionsCache[universityId] = opts
    targetRef.value = opts
  } catch (e) {
    console.error('加载专业选项失败', e)
    targetRef.value = []
  }
}

function onScoreUniversityChange(universityId) {
  scoreState.form.major_id = 0
  loadMajorOptionsForSelect(universityId, scoreMajorOptions)
}

function onPlanUniversityChange(universityId) {
  planState.form.major_id = 0
  loadMajorOptionsForSelect(universityId, planMajorOptions)
}

// ========== 表格列定义 ==========
const uniColumns = [
  { title: '名称', dataIndex: 'name', key: 'name', width: 200, ellipsis: true },
  { title: '省份', dataIndex: 'province', key: 'province', width: 80 },
  { title: '城市', dataIndex: 'city', key: 'city', width: 80 },
  { title: '层次', dataIndex: 'level', key: 'level', width: 90 },
  { title: '类型', dataIndex: 'type', key: 'type', width: 80 },
  { title: '性质', dataIndex: 'nature', key: 'nature', width: 80 },
  { title: '硕士点', dataIndex: 'master_points', key: 'master_points', width: 80, align: 'right' },
  { title: '博士点', dataIndex: 'doctor_points', key: 'doctor_points', width: 80, align: 'right' },
  { title: '操作', key: 'action', fixed: 'right', width: 130 },
]

const majorColumns = [
  { title: '名称', dataIndex: 'name', key: 'name', width: 180, ellipsis: true },
  { title: '院校', dataIndex: 'university_name', key: 'university_name', width: 150, ellipsis: true },
  { title: '院校ID', dataIndex: 'university_id', key: 'university_id', width: 90, align: 'right' },
  { title: '代码', dataIndex: 'code', key: 'code', width: 90 },
  { title: '学制', dataIndex: 'duration', key: 'duration', width: 80 },
  { title: '选科要求', dataIndex: 'subject_requirement', key: 'subject_requirement', width: 140, ellipsis: true },
  { title: '就业率', dataIndex: 'employment_rate', key: 'employment_rate', width: 90, align: 'right' },
  { title: '重点', key: 'is_key', width: 80 },
  { title: '操作', key: 'action', fixed: 'right', width: 130 },
]

const scoreColumns = [
  { title: '院校', dataIndex: 'university_name', key: 'university_name', width: 150, ellipsis: true },
  { title: '院校ID', dataIndex: 'university_id', key: 'university_id', width: 90, align: 'right' },
  { title: '省份', dataIndex: 'province', key: 'province', width: 80 },
  { title: '年份', dataIndex: 'year', key: 'year', width: 80, align: 'right' },
  { title: '科类', dataIndex: 'subject_type', key: 'subject_type', width: 100 },
  { title: '批次', dataIndex: 'batch', key: 'batch', width: 110 },
  { title: '最低分', dataIndex: 'min_score', key: 'min_score', width: 80, align: 'right' },
  { title: '最低位次', dataIndex: 'min_rank', key: 'min_rank', width: 100, align: 'right' },
  { title: '计划数', dataIndex: 'plan_count', key: 'plan_count', width: 80, align: 'right' },
  { title: '操作', key: 'action', fixed: 'right', width: 130 },
]

const ruleColumns = [
  { title: '省份', dataIndex: 'province', key: 'province', width: 100 },
  { title: '年份', dataIndex: 'year', key: 'year', width: 80, align: 'right' },
  { title: '模式', dataIndex: 'mode', key: 'mode', width: 120 },
  { title: '批次数量', dataIndex: 'batch_count', key: 'batch_count', width: 90, align: 'right' },
  { title: '每批上限', dataIndex: 'max_per_batch', key: 'max_per_batch', width: 90, align: 'right' },
  { title: '科类模式', dataIndex: 'subject_mode', key: 'subject_mode', width: 130, ellipsis: true },
  { title: '操作', key: 'action', fixed: 'right', width: 130 },
]

const planColumns = [
  { title: '院校', dataIndex: 'university_name', key: 'university_name', width: 150, ellipsis: true },
  { title: '院校ID', dataIndex: 'university_id', key: 'university_id', width: 90, align: 'right' },
  { title: '省份', dataIndex: 'province', key: 'province', width: 80 },
  { title: '年份', dataIndex: 'year', key: 'year', width: 80, align: 'right' },
  { title: '科类', dataIndex: 'subject_type', key: 'subject_type', width: 100 },
  { title: '批次', dataIndex: 'batch', key: 'batch', width: 110 },
  { title: '计划数', dataIndex: 'plan_count', key: 'plan_count', width: 80, align: 'right' },
  { title: '学制', dataIndex: 'duration', key: 'duration', width: 80 },
  { title: '学费', dataIndex: 'tuition', key: 'tuition', width: 90, align: 'right' },
  { title: '操作', key: 'action', fixed: 'right', width: 130 },
]

// ========== 默认表单 ==========
function defaultUniForm() {
  return {
    name: '', province: undefined, city: '', level: undefined, type: undefined,
    nature: undefined, website: '', intro: '', master_points: 0, doctor_points: 0,
    key_disciplines: '',
  }
}
function defaultMajorForm() {
  return {
    university_id: undefined, name: '', code: '', degree: '', duration: '',
    subject_category: '', subject_requirement: '', intro: '',
    employment_rate: undefined, avg_salary: undefined, career_directions: '',
    is_key: false,
  }
}
function defaultScoreForm() {
  return {
    university_id: undefined, major_id: 0, province: undefined, year: undefined,
    subject_type: undefined, batch: '', min_score: undefined, max_score: undefined,
    avg_score: undefined, min_rank: undefined, plan_count: undefined,
  }
}
function defaultRuleForm() {
  return {
    province: undefined, year: undefined, mode: '', batch_count: undefined,
    max_per_batch: undefined, subject_mode: '', description: '', tips: '',
  }
}
function defaultPlanForm() {
  return {
    university_id: undefined, major_id: 0, province: undefined, year: undefined,
    subject_type: undefined, batch: '', plan_count: undefined, duration: '',
    tuition: undefined, remark: '',
  }
}

// ========== 院校管理 ==========
const uniState = reactive({
  loading: false,
  list: [],
  total: 0,
  page: 1,
  size: 20,
  keyword: '',
  modalVisible: false,
  editing: null,
  form: defaultUniForm(),
  submitting: false,
})

async function loadUniversities() {
  uniState.loading = true
  try {
    const res = await zhiyuanApi.adminListUniversities({
      page: uniState.page,
      size: uniState.size,
      keyword: uniState.keyword,
    })
    uniState.list = res?.items || []
    uniState.total = res?.total || 0
  } catch (e) {
    message.error('加载院校失败：' + (e.message || '未知错误'))
  } finally {
    uniState.loading = false
  }
}

function onUniSearch() {
  uniState.page = 1
  loadUniversities()
}

function openUniModal(record) {
  uniState.editing = record || null
  uniState.form = record ? { ...defaultUniForm(), ...record } : defaultUniForm()
  uniState.modalVisible = true
}

async function submitUniversity() {
  if (!uniState.form.name || !uniState.form.name.trim()) {
    message.warning('请填写院校名称')
    return
  }
  uniState.submitting = true
  try {
    if (uniState.editing) {
      await zhiyuanApi.adminUpdateUniversity(uniState.editing.id, uniState.form)
      message.success('更新成功')
    } else {
      await zhiyuanApi.adminCreateUniversity(uniState.form)
      message.success('新增成功')
    }
    uniState.modalVisible = false
    loadUniversities()
    // 院校变更后清除下拉选项缓存，下次打开表单时重新加载
    universityOptions.value = []
  } catch (e) {
    message.error('保存失败：' + (e.message || '未知错误'))
  } finally {
    uniState.submitting = false
  }
}

async function deleteUniversity(record) {
  try {
    await zhiyuanApi.adminDeleteUniversity(record.id)
    message.success('删除成功')
    loadUniversities()
    // 院校删除后清除下拉选项缓存
    universityOptions.value = []
  } catch (e) {
    message.error('删除失败：' + (e.message || '未知错误'))
  }
}

// ========== 专业管理 ==========
const majorState = reactive({
  loading: false,
  list: [],
  total: 0,
  page: 1,
  size: 20,
  universityId: undefined,
  keyword: '',
  modalVisible: false,
  editing: null,
  form: defaultMajorForm(),
  submitting: false,
})

async function loadMajors() {
  majorState.loading = true
  try {
    const res = await zhiyuanApi.adminListMajors({
      university_id: majorState.universityId,
      keyword: majorState.keyword,
      page: majorState.page,
      size: majorState.size,
    })
    majorState.list = res?.items || []
    majorState.total = res?.total || 0
  } catch (e) {
    message.error('加载专业失败：' + (e.message || '未知错误'))
  } finally {
    majorState.loading = false
  }
}

function onMajorSearch() {
  majorState.page = 1
  loadMajors()
}

function openMajorModal(record) {
  majorState.editing = record || null
  majorState.form = record ? { ...defaultMajorForm(), ...record } : defaultMajorForm()
  majorState.modalVisible = true
  // 兜底：确保院校选项已加载（防止初始化时失败导致下拉框为空）
  loadUniversityOptions()
}

async function submitMajor() {
  if (!majorState.form.university_id || majorState.form.university_id <= 0) {
    message.warning('请选择所属院校')
    return
  }
  if (!majorState.form.name || !majorState.form.name.trim()) {
    message.warning('请填写专业名称')
    return
  }
  majorState.submitting = true
  try {
    if (majorState.editing) {
      await zhiyuanApi.adminUpdateMajor(majorState.editing.id, majorState.form)
      message.success('更新成功')
    } else {
      await zhiyuanApi.adminCreateMajor(majorState.form)
      message.success('新增成功')
    }
    majorState.modalVisible = false
    loadMajors()
    // 专业变更后清除该院校的专业缓存
    if (majorState.form.university_id) {
      delete _majorOptionsCache[majorState.form.university_id]
    }
  } catch (e) {
    message.error('保存失败：' + (e.message || '未知错误'))
  } finally {
    majorState.submitting = false
  }
}

async function deleteMajor(record) {
  try {
    await zhiyuanApi.adminDeleteMajor(record.id)
    message.success('删除成功')
    loadMajors()
    // 专业删除后清除该院校的专业缓存
    if (record.university_id) {
      delete _majorOptionsCache[record.university_id]
    }
  } catch (e) {
    message.error('删除失败：' + (e.message || '未知错误'))
  }
}

// ========== 分数管理 ==========
const scoreState = reactive({
  loading: false,
  list: [],
  total: 0,
  page: 1,
  size: 50,
  universityId: undefined,
  province: undefined,
  year: undefined,
  modalVisible: false,
  editing: null,
  form: defaultScoreForm(),
  submitting: false,
})

async function loadScores() {
  scoreState.loading = true
  try {
    const res = await zhiyuanApi.adminListScores({
      university_id: scoreState.universityId,
      province: scoreState.province,
      year: scoreState.year,
      page: scoreState.page,
      size: scoreState.size,
    })
    scoreState.list = res?.items || []
    scoreState.total = res?.total || 0
  } catch (e) {
    message.error('加载分数失败：' + (e.message || '未知错误'))
  } finally {
    scoreState.loading = false
  }
}

function onScoreSearch() {
  scoreState.page = 1
  loadScores()
}

function openScoreModal(record) {
  scoreState.editing = record || null
  scoreState.form = record ? { ...defaultScoreForm(), ...record } : defaultScoreForm()
  scoreState.modalVisible = true
  // 兜底：确保院校选项已加载（防止初始化时失败导致下拉框为空）
  loadUniversityOptions()
  // 编辑时预加载该院校的专业列表
  if (scoreState.form.university_id) {
    loadMajorOptionsForSelect(scoreState.form.university_id, scoreMajorOptions)
  } else {
    scoreMajorOptions.value = []
  }
}

async function submitScore() {
  if (!scoreState.form.university_id) {
    message.warning('请选择院校')
    return
  }
  if (!scoreState.form.province) {
    message.warning('请选择省份')
    return
  }
  if (!scoreState.form.year) {
    message.warning('请填写年份')
    return
  }
  scoreState.submitting = true
  try {
    if (scoreState.editing) {
      await zhiyuanApi.adminUpdateScore(scoreState.editing.id, scoreState.form)
      message.success('更新成功')
    } else {
      await zhiyuanApi.adminCreateScore(scoreState.form)
      message.success('新增成功')
    }
    scoreState.modalVisible = false
    loadScores()
  } catch (e) {
    message.error('保存失败：' + (e.message || '未知错误'))
  } finally {
    scoreState.submitting = false
  }
}

async function deleteScore(record) {
  try {
    await zhiyuanApi.adminDeleteScore(record.id)
    message.success('删除成功')
    loadScores()
  } catch (e) {
    message.error('删除失败：' + (e.message || '未知错误'))
  }
}

// ========== 规则管理 ==========
const ruleState = reactive({
  loading: false,
  list: [],
  page: 1,
  size: 20,
  modalVisible: false,
  editing: null,
  form: defaultRuleForm(),
  submitting: false,
})

const rulePagedList = computed(() => {
  const start = (ruleState.page - 1) * ruleState.size
  return ruleState.list.slice(start, start + ruleState.size)
})

async function loadRules() {
  ruleState.loading = true
  try {
    const res = await zhiyuanApi.adminListRules()
    const data = Array.isArray(res) ? res : (res?.items || res?.data || [])
    ruleState.list = data
    ruleState.page = 1
  } catch (e) {
    message.error('加载规则失败：' + (e.message || '未知错误'))
  } finally {
    ruleState.loading = false
  }
}

function openRuleModal(record) {
  ruleState.editing = record || null
  ruleState.form = record ? { ...defaultRuleForm(), ...record } : defaultRuleForm()
  ruleState.modalVisible = true
}

async function submitRule() {
  if (!ruleState.form.province) {
    message.warning('请选择省份')
    return
  }
  if (!ruleState.form.year) {
    message.warning('请填写年份')
    return
  }
  ruleState.submitting = true
  try {
    await zhiyuanApi.adminUpsertRule(ruleState.form)
    message.success(ruleState.editing ? '更新成功' : '保存成功')
    ruleState.modalVisible = false
    loadRules()
  } catch (e) {
    message.error('保存失败：' + (e.message || '未知错误'))
  } finally {
    ruleState.submitting = false
  }
}

async function deleteRule(record) {
  try {
    await zhiyuanApi.adminDeleteRule(record.province, record.year)
    message.success('删除成功')
    loadRules()
  } catch (e) {
    message.error('删除失败：' + (e.message || '未知错误'))
  }
}

// ========== 计划管理 ==========
const planState = reactive({
  loading: false,
  list: [],
  total: 0,
  page: 1,
  size: 20,
  universityId: undefined,
  province: undefined,
  year: undefined,
  modalVisible: false,
  editing: null,
  form: defaultPlanForm(),
  submitting: false,
})

async function loadPlans() {
  planState.loading = true
  try {
    const res = await zhiyuanApi.adminListPlans({
      university_id: planState.universityId,
      province: planState.province,
      year: planState.year,
      page: planState.page,
      size: planState.size,
    })
    planState.list = res?.items || []
    planState.total = res?.total || 0
  } catch (e) {
    message.error('加载计划失败：' + (e.message || '未知错误'))
  } finally {
    planState.loading = false
  }
}

function onPlanSearch() {
  planState.page = 1
  loadPlans()
}

function openPlanModal(record) {
  planState.editing = record || null
  planState.form = record ? { ...defaultPlanForm(), ...record } : defaultPlanForm()
  planState.modalVisible = true
  // 兜底：确保院校选项已加载（防止初始化时失败导致下拉框为空）
  loadUniversityOptions()
  // 编辑时预加载该院校的专业列表
  if (planState.form.university_id) {
    loadMajorOptionsForSelect(planState.form.university_id, planMajorOptions)
  } else {
    planMajorOptions.value = []
  }
}

async function submitPlan() {
  if (!planState.form.university_id) {
    message.warning('请选择院校')
    return
  }
  if (!planState.form.province) {
    message.warning('请选择省份')
    return
  }
  if (!planState.form.year) {
    message.warning('请填写年份')
    return
  }
  planState.submitting = true
  try {
    if (planState.editing) {
      await zhiyuanApi.adminUpdatePlan(planState.editing.id, planState.form)
      message.success('更新成功')
    } else {
      await zhiyuanApi.adminCreatePlan(planState.form)
      message.success('新增成功')
    }
    planState.modalVisible = false
    loadPlans()
  } catch (e) {
    message.error('保存失败：' + (e.message || '未知错误'))
  } finally {
    planState.submitting = false
  }
}

async function deletePlan(record) {
  try {
    await zhiyuanApi.adminDeletePlan(record.id)
    message.success('删除成功')
    loadPlans()
  } catch (e) {
    message.error('删除失败：' + (e.message || '未知错误'))
  }
}

// ========== Excel/CSV 文件导入 ==========
const importState = reactive({
  visible: false,
  importing: false,
  type: '',  // 'score' | 'major'
  file: null,
})

const importFileInput = ref(null)

function openImportDialog(type) {
  importState.type = type
  importState.file = null
  importState.importing = false
  if (importFileInput.value) {
    importFileInput.value.value = ''
  }
  importFileInput.value?.click()
}

function onImportFileChange(e) {
  const file = e.target.files?.[0]
  if (!file) return
  importState.file = file
  handleImport()
}

async function handleImport() {
  if (!importState.file) {
    message.warning('请先选择文件')
    return
  }
  // 文件导入端点尚未实现，引导用户使用批量 JSON 导入
  message.warning('文件导入功能尚未上线，请使用批量导入（JSON 格式）')
  importState.importing = false
}

// ========== 初始化 ==========
const loadedTabs = new Set(['university'])

function onTabChange(key) {
  if (loadedTabs.has(key)) return
  loadedTabs.add(key)
  if (key === 'major') loadMajors()
  else if (key === 'score') loadScores()
  else if (key === 'rule') loadRules()
  else if (key === 'plan') loadPlans()
}

async function loadDashStats() {
  try {
    const res = await zhiyuanApi.getPublicStats()
    dashStats.value = res || null
  } catch (e) {
    console.error('加载统计数据失败:', e?.message || e)
  }
}

async function loadHealthData() {
  try {
    const res = await zhiyuanApi.getDataHealth()
    healthData.value = res || null
  } catch (e) {
    console.error('加载健康度失败:', e?.message || e)
  }
}

onMounted(() => {
  loadUniversities()
  loadUniversityOptions()
  loadDashStats()
  loadHealthData()
})
</script>

<style lang="less" scoped>
.zhiyuan-admin {
  padding: 24px;
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;

  h2 {
    margin: 0 0 4px;
    font-size: 22px;
  }

  .subtitle {
    color: var(--gray-600);
    font-size: 14px;
    margin: 0;
  }
}

.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
  align-items: center;

  .hint-text {
    color: var(--gray-500);
    font-size: 13px;
    margin-right: auto;
  }
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

// ========== 数据看板 ==========
.dashboard {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
  margin-bottom: 24px;
}

.dash-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: var(--gray-0);
  border: 1px solid var(--gray-150);
  border-radius: 10px;
  transition:
    box-shadow 0.2s ease,
    transform 0.15s ease;

  &:hover {
    box-shadow: 0 6px 18px var(--shadow-2);
    transform: translateY(-2px);
  }
}

.dash-icon {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  flex-shrink: 0;
}

.dash-info {
  display: flex;
  flex-direction: column;
  line-height: 1.2;

  .dash-number {
    font-size: 20px;
    font-weight: 700;
    color: var(--gray-1000);
  }

  .dash-label {
    font-size: 12px;
    color: var(--gray-600);
    margin-top: 2px;
  }
}

// ========== 数据健康度 ==========
.health-panel {
  background: var(--gray-0);
  border: 1px solid var(--gray-150);
  border-radius: 10px;
  padding: 16px 20px;
  margin-bottom: 24px;
}

.health-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.health-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: var(--gray-800);
}

.health-score-wrapper {
  position: relative;
  flex: 1;
  max-width: 360px;
  height: 24px;
  background: var(--gray-100);
  border-radius: 12px;
  overflow: hidden;
}

.health-score-bar {
  height: 100%;
  border-radius: 12px;
  transition: width 0.4s ease;
}

.health-score-text {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 12px;
  font-weight: 700;
  z-index: 1;
}

.health-issues {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}

.health-issue {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: var(--gray-10);
  border-radius: 6px;

  .issue-label {
    font-size: 12px;
    color: var(--gray-700);
  }
}
</style>
