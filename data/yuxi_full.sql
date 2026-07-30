--
-- PostgreSQL database dump
--

\restrict iFcdOYD8NSEZWwLLrpTy7AqsPmLcunTtTPkYRLMmvkwiKT5Mir7BLJny4O754zf

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_envs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_envs (
    id integer NOT NULL,
    uid character varying NOT NULL,
    env json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: agent_envs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_envs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_envs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_envs_id_seq OWNED BY public.agent_envs.id;


--
-- Name: agent_run_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_run_requests (
    id integer NOT NULL,
    request_id character varying(64) NOT NULL,
    uid character varying(64) NOT NULL,
    agent_slug character varying(64) NOT NULL,
    conversation_thread_id character varying(64) NOT NULL,
    source character varying(32) NOT NULL,
    queue_policy character varying(16) NOT NULL,
    status character varying(32) NOT NULL,
    input_message_id integer NOT NULL,
    dispatched_run_id character varying(64),
    input_payload json NOT NULL,
    error_message text,
    created_at timestamp without time zone NOT NULL,
    dispatched_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: COLUMN agent_run_requests.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.id IS 'Primary key';


--
-- Name: COLUMN agent_run_requests.request_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.request_id IS '幂等请求 ID';


--
-- Name: COLUMN agent_run_requests.uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.uid IS 'UID';


--
-- Name: COLUMN agent_run_requests.agent_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.agent_slug IS 'Agent slug';


--
-- Name: COLUMN agent_run_requests.conversation_thread_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.conversation_thread_id IS 'Conversation thread ID';


--
-- Name: COLUMN agent_run_requests.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.source IS '请求来源: chat/agent_call/eval';


--
-- Name: COLUMN agent_run_requests.queue_policy; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.queue_policy IS '排队策略: enqueue/reject/steer';


--
-- Name: COLUMN agent_run_requests.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.status IS '请求状态: queued/dispatched/cancelled/rejected/failed';


--
-- Name: COLUMN agent_run_requests.input_message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.input_message_id IS '关联输入消息 ID';


--
-- Name: COLUMN agent_run_requests.dispatched_run_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.dispatched_run_id IS '已派发的 AgentRun ID';


--
-- Name: COLUMN agent_run_requests.input_payload; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.input_payload IS '原始输入载荷快照';


--
-- Name: COLUMN agent_run_requests.error_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.error_message IS 'rejected/failed 时的错误信息';


--
-- Name: COLUMN agent_run_requests.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.created_at IS '创建时间';


--
-- Name: COLUMN agent_run_requests.dispatched_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.dispatched_at IS '派发时间';


--
-- Name: COLUMN agent_run_requests.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_run_requests.updated_at IS '更新时间';


--
-- Name: agent_run_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_run_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_run_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_run_requests_id_seq OWNED BY public.agent_run_requests.id;


--
-- Name: agent_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_runs (
    id character varying(64) NOT NULL,
    conversation_thread_id character varying(64) NOT NULL,
    agent_slug character varying(64) NOT NULL,
    uid character varying(64) NOT NULL,
    status character varying(32) NOT NULL,
    request_id character varying(64) NOT NULL,
    conversation_id integer,
    created_by_run_id character varying(64),
    subagent_thread_relation_id integer,
    run_type character varying(32) NOT NULL,
    input_message_id integer,
    output_message_id integer,
    last_event_id character varying(64),
    input_payload json NOT NULL,
    error_type character varying(64),
    error_message text,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN agent_runs.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.id IS 'Run ID (UUID)';


--
-- Name: COLUMN agent_runs.conversation_thread_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.conversation_thread_id IS 'Conversation thread ID snapshot';


--
-- Name: COLUMN agent_runs.agent_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.agent_slug IS 'Agent slug';


--
-- Name: COLUMN agent_runs.uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.uid IS 'UID';


--
-- Name: COLUMN agent_runs.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.status IS 'Run status: pending/running/completed/failed/cancel_requested/cancelled/interrupted';


--
-- Name: COLUMN agent_runs.request_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.request_id IS 'Idempotency request ID';


--
-- Name: COLUMN agent_runs.conversation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.conversation_id IS 'Conversation ID';


--
-- Name: COLUMN agent_runs.created_by_run_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.created_by_run_id IS 'Run that created this run';


--
-- Name: COLUMN agent_runs.subagent_thread_relation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.subagent_thread_relation_id IS 'Subagent thread relation record ID';


--
-- Name: COLUMN agent_runs.run_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.run_type IS 'Run type: chat/resume/subagent';


--
-- Name: COLUMN agent_runs.input_message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.input_message_id IS 'Input message ID';


--
-- Name: COLUMN agent_runs.output_message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.output_message_id IS 'Output message ID';


--
-- Name: COLUMN agent_runs.last_event_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.last_event_id IS 'Last Redis stream event ID';


--
-- Name: COLUMN agent_runs.input_payload; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.input_payload IS 'Original input payload';


--
-- Name: COLUMN agent_runs.error_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.error_type IS 'Error type';


--
-- Name: COLUMN agent_runs.error_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.error_message IS 'Error message';


--
-- Name: COLUMN agent_runs.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.started_at IS 'Start time';


--
-- Name: COLUMN agent_runs.finished_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.finished_at IS 'Finish time';


--
-- Name: COLUMN agent_runs.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.created_at IS 'Creation time';


--
-- Name: COLUMN agent_runs.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agent_runs.updated_at IS 'Update time';


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id integer NOT NULL,
    slug character varying(80) NOT NULL,
    backend_id character varying(64) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    icon character varying(255),
    pics json NOT NULL,
    config_json json NOT NULL,
    share_config json NOT NULL,
    is_default boolean NOT NULL,
    is_subagent boolean NOT NULL,
    created_by character varying(64),
    updated_by character varying(64),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    key_hash character varying(64) NOT NULL,
    key_prefix character varying(16) NOT NULL,
    name character varying(100) NOT NULL,
    user_id integer NOT NULL,
    department_id integer,
    expires_at timestamp without time zone,
    is_enabled boolean NOT NULL,
    last_used_at timestamp without time zone,
    created_by character varying(64) NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: checkpoint_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_blobs (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    channel text NOT NULL,
    version text NOT NULL,
    type text NOT NULL,
    blob bytea
);


--
-- Name: checkpoint_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_migrations (
    v integer NOT NULL
);


--
-- Name: checkpoint_writes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoint_writes (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    checkpoint_id text NOT NULL,
    task_id text NOT NULL,
    idx integer NOT NULL,
    channel text NOT NULL,
    type text,
    blob bytea NOT NULL,
    task_path text DEFAULT ''::text NOT NULL
);


--
-- Name: checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkpoints (
    thread_id text NOT NULL,
    checkpoint_ns text DEFAULT ''::text NOT NULL,
    checkpoint_id text NOT NULL,
    parent_checkpoint_id text,
    type text,
    checkpoint jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: cli_auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cli_auth_sessions (
    id integer NOT NULL,
    device_code_hash character varying(64) NOT NULL,
    user_code character varying(16) NOT NULL,
    status character varying(32) NOT NULL,
    key_name character varying(100) NOT NULL,
    approved_user_id integer,
    api_key_id integer,
    created_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    approved_at timestamp without time zone,
    consumed_at timestamp without time zone
);


--
-- Name: cli_auth_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cli_auth_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cli_auth_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cli_auth_sessions_id_seq OWNED BY public.cli_auth_sessions.id;


--
-- Name: config_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.config_options (
    id integer NOT NULL,
    key character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    params json NOT NULL,
    value json NOT NULL,
    created_by character varying(100),
    updated_by character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: config_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.config_options_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.config_options_id_seq OWNED BY public.config_options.id;


--
-- Name: conversation_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_stats (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    message_count integer,
    total_tokens integer,
    model_used character varying(100),
    user_feedback json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN conversation_stats.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.id IS 'Primary key';


--
-- Name: COLUMN conversation_stats.conversation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.conversation_id IS 'Conversation ID';


--
-- Name: COLUMN conversation_stats.message_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.message_count IS 'Total message count';


--
-- Name: COLUMN conversation_stats.total_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.total_tokens IS 'Total tokens used';


--
-- Name: COLUMN conversation_stats.model_used; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.model_used IS 'Model used';


--
-- Name: COLUMN conversation_stats.user_feedback; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.user_feedback IS 'User feedback';


--
-- Name: COLUMN conversation_stats.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.created_at IS 'Creation time';


--
-- Name: COLUMN conversation_stats.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversation_stats.updated_at IS 'Update time';


--
-- Name: conversation_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_stats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_stats_id_seq OWNED BY public.conversation_stats.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id integer NOT NULL,
    thread_id character varying(64) NOT NULL,
    uid character varying(64) NOT NULL,
    agent_id character varying(64) NOT NULL,
    title character varying(255),
    status character varying(20),
    is_pinned boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    extra_metadata json
);


--
-- Name: COLUMN conversations.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.id IS 'Primary key';


--
-- Name: COLUMN conversations.thread_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.thread_id IS 'Thread ID (UUID)';


--
-- Name: COLUMN conversations.uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.uid IS 'UID';


--
-- Name: COLUMN conversations.agent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.agent_id IS 'Agent slug (legacy column name: agent_id)';


--
-- Name: COLUMN conversations.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.title IS 'Conversation title';


--
-- Name: COLUMN conversations.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.status IS 'Status: active/archived/deleted';


--
-- Name: COLUMN conversations.is_pinned; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.is_pinned IS 'Is pinned to top';


--
-- Name: COLUMN conversations.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.created_at IS 'Creation time';


--
-- Name: COLUMN conversations.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.updated_at IS 'Update time';


--
-- Name: COLUMN conversations.extra_metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.conversations.extra_metadata IS 'Additional metadata';


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: evaluation_dataset_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluation_dataset_items (
    id integer NOT NULL,
    item_id character varying(64) NOT NULL,
    dataset_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    item_index integer NOT NULL,
    query_text text NOT NULL,
    gold_chunk_ids jsonb,
    gold_answer text,
    created_at timestamp with time zone
);


--
-- Name: evaluation_dataset_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evaluation_dataset_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evaluation_dataset_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evaluation_dataset_items_id_seq OWNED BY public.evaluation_dataset_items.id;


--
-- Name: evaluation_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluation_datasets (
    id integer NOT NULL,
    dataset_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    item_count integer,
    has_gold_chunks boolean,
    has_gold_answers boolean,
    build_metadata jsonb,
    created_by character varying(64),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: evaluation_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evaluation_datasets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evaluation_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evaluation_datasets_id_seq OWNED BY public.evaluation_datasets.id;


--
-- Name: evaluation_run_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluation_run_items (
    id integer NOT NULL,
    run_id character varying(64) NOT NULL,
    dataset_item_id character varying(64),
    item_index integer NOT NULL,
    query_text text NOT NULL,
    gold_chunk_ids jsonb,
    gold_answer text,
    generated_answer text,
    retrieved_chunks jsonb,
    metrics jsonb,
    created_at timestamp with time zone
);


--
-- Name: evaluation_run_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evaluation_run_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evaluation_run_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evaluation_run_items_id_seq OWNED BY public.evaluation_run_items.id;


--
-- Name: evaluation_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluation_runs (
    id integer NOT NULL,
    run_id character varying(64) NOT NULL,
    name character varying(255) NOT NULL,
    kb_id character varying(80) NOT NULL,
    dataset_id character varying(64),
    status character varying(32),
    retrieval_config jsonb,
    metrics jsonb,
    overall_score double precision,
    total_items integer,
    completed_items integer,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_by character varying(64)
);


--
-- Name: evaluation_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evaluation_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evaluation_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evaluation_runs_id_seq OWNED BY public.evaluation_runs.id;


--
-- Name: knowledge_bases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_bases (
    id integer NOT NULL,
    kb_id character varying(80) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    kb_type character varying(32) NOT NULL,
    embedding_model_spec character varying(512),
    llm_model_spec character varying(512),
    query_params jsonb,
    additional_params jsonb,
    share_config jsonb,
    mindmap jsonb,
    mindmap_file_ids jsonb,
    mindmap_metadata jsonb,
    sample_questions jsonb,
    created_by character varying(64),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: knowledge_bases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_bases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_bases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_bases_id_seq OWNED BY public.knowledge_bases.id;


--
-- Name: knowledge_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_chunks (
    id integer NOT NULL,
    chunk_id character varying(128) NOT NULL,
    file_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    chunk_index integer NOT NULL,
    content text NOT NULL,
    start_char_pos integer,
    end_char_pos integer,
    start_token_pos integer,
    end_token_pos integer,
    graph_structure_indexed boolean DEFAULT false NOT NULL,
    graph_indexed boolean,
    graph_extraction_details jsonb DEFAULT jsonb_build_object('status', 'pending', 'attempt_count', 0) NOT NULL,
    ent_ids jsonb,
    tags jsonb,
    extraction_result jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: knowledge_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_chunks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_chunks_id_seq OWNED BY public.knowledge_chunks.id;


--
-- Name: knowledge_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_files (
    id integer NOT NULL,
    file_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    parent_id character varying(64),
    filename character varying(512) NOT NULL,
    original_filename character varying(512),
    file_type character varying(64),
    path character varying(1024),
    minio_url character varying(1024),
    markdown_file character varying(1024),
    status character varying(32),
    content_hash character varying(128),
    file_size bigint,
    chunk_count integer,
    token_count bigint,
    content_type character varying(64),
    processing_params jsonb,
    is_folder boolean,
    error_message text,
    created_by character varying(64),
    updated_by character varying(64),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: knowledge_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_files_id_seq OWNED BY public.knowledge_files.id;


--
-- Name: knowledge_graph_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_graph_entities (
    id integer NOT NULL,
    entity_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    normalized_name character varying(512) NOT NULL,
    label character varying(128) NOT NULL,
    name character varying(512) NOT NULL,
    attributes jsonb,
    vector_status character varying(16) DEFAULT 'pending'::character varying NOT NULL,
    vector_attempt_count integer DEFAULT 0 NOT NULL,
    vector_last_error text,
    vector_next_retry_at timestamp with time zone,
    vector_locked_until timestamp with time zone,
    vector_lock_token character varying(32),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: knowledge_graph_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_graph_entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_graph_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_graph_entities_id_seq OWNED BY public.knowledge_graph_entities.id;


--
-- Name: knowledge_graph_entity_mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_graph_entity_mentions (
    id integer NOT NULL,
    entity_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    file_id character varying(64) NOT NULL,
    chunk_id character varying(128) NOT NULL,
    created_at timestamp with time zone
);


--
-- Name: knowledge_graph_entity_mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_graph_entity_mentions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_graph_entity_mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_graph_entity_mentions_id_seq OWNED BY public.knowledge_graph_entity_mentions.id;


--
-- Name: knowledge_graph_triple_mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_graph_triple_mentions (
    id integer NOT NULL,
    triple_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    file_id character varying(64) NOT NULL,
    chunk_id character varying(128) NOT NULL,
    text text,
    extractor_type character varying(128),
    created_at timestamp with time zone
);


--
-- Name: knowledge_graph_triple_mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_graph_triple_mentions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_graph_triple_mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_graph_triple_mentions_id_seq OWNED BY public.knowledge_graph_triple_mentions.id;


--
-- Name: knowledge_graph_triples; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_graph_triples (
    id integer NOT NULL,
    triple_id character varying(64) NOT NULL,
    kb_id character varying(80) NOT NULL,
    source_entity_id character varying(64) NOT NULL,
    target_entity_id character varying(64) NOT NULL,
    relation_type character varying(256) NOT NULL,
    content text NOT NULL,
    vector_status character varying(16) DEFAULT 'pending'::character varying NOT NULL,
    vector_attempt_count integer DEFAULT 0 NOT NULL,
    vector_last_error text,
    vector_next_retry_at timestamp with time zone,
    vector_locked_until timestamp with time zone,
    vector_lock_token character varying(32),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: knowledge_graph_triples_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_graph_triples_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_graph_triples_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_graph_triples_id_seq OWNED BY public.knowledge_graph_triples.id;


--
-- Name: mcp_servers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_servers (
    id integer NOT NULL,
    slug character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(500),
    transport character varying(20) NOT NULL,
    url character varying(500),
    command character varying(500),
    args json,
    env json,
    headers json,
    timeout integer,
    sse_read_timeout integer,
    tags json,
    icon character varying(50),
    enabled integer NOT NULL,
    disabled_tools json,
    created_by character varying(100) NOT NULL,
    updated_by character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN mcp_servers.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.slug IS '稳定标识';


--
-- Name: COLUMN mcp_servers.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.name IS '展示名称';


--
-- Name: COLUMN mcp_servers.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.description IS '描述';


--
-- Name: COLUMN mcp_servers.transport; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.transport IS '传输类型：sse/streamable_http/stdio';


--
-- Name: COLUMN mcp_servers.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.url IS '服务器 URL（sse/streamable_http）';


--
-- Name: COLUMN mcp_servers.command; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.command IS '命令（stdio）';


--
-- Name: COLUMN mcp_servers.args; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.args IS '命令参数数组（stdio）';


--
-- Name: COLUMN mcp_servers.env; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.env IS '环境变量（stdio）';


--
-- Name: COLUMN mcp_servers.headers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.headers IS 'HTTP 请求头';


--
-- Name: COLUMN mcp_servers.timeout; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.timeout IS 'HTTP 超时时间（秒）';


--
-- Name: COLUMN mcp_servers.sse_read_timeout; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.sse_read_timeout IS 'SSE 读取超时（秒）';


--
-- Name: COLUMN mcp_servers.tags; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.tags IS '标签数组';


--
-- Name: COLUMN mcp_servers.icon; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.icon IS '图标（emoji）';


--
-- Name: COLUMN mcp_servers.enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.enabled IS '是否启用：1=是，0=否';


--
-- Name: COLUMN mcp_servers.disabled_tools; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.disabled_tools IS '禁用的工具名称列表';


--
-- Name: COLUMN mcp_servers.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.created_by IS '创建人用户名';


--
-- Name: COLUMN mcp_servers.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.updated_by IS '修改人用户名';


--
-- Name: COLUMN mcp_servers.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.created_at IS '创建时间';


--
-- Name: COLUMN mcp_servers.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mcp_servers.updated_at IS '更新时间';


--
-- Name: mcp_servers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mcp_servers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mcp_servers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mcp_servers_id_seq OWNED BY public.mcp_servers.id;


--
-- Name: message_feedbacks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_feedbacks (
    id integer NOT NULL,
    message_id integer NOT NULL,
    uid character varying(64) NOT NULL,
    rating character varying(10) NOT NULL,
    reason text,
    created_at timestamp without time zone
);


--
-- Name: COLUMN message_feedbacks.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.id IS 'Primary key';


--
-- Name: COLUMN message_feedbacks.message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.message_id IS 'Message ID being rated';


--
-- Name: COLUMN message_feedbacks.uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.uid IS 'UID who provided feedback';


--
-- Name: COLUMN message_feedbacks.rating; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.rating IS 'Feedback rating: like or dislike';


--
-- Name: COLUMN message_feedbacks.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.reason IS 'Optional reason for dislike feedback';


--
-- Name: COLUMN message_feedbacks.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.message_feedbacks.created_at IS 'Feedback creation time';


--
-- Name: message_feedbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_feedbacks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_feedbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_feedbacks_id_seq OWNED BY public.message_feedbacks.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    role character varying(20) NOT NULL,
    content text NOT NULL,
    message_type character varying(30),
    created_at timestamp without time zone,
    token_count integer,
    extra_metadata json,
    image_content text,
    run_id character varying(64),
    request_id character varying(64),
    delivery_status character varying(32) NOT NULL
);


--
-- Name: COLUMN messages.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.id IS 'Primary key';


--
-- Name: COLUMN messages.conversation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.conversation_id IS 'Conversation ID';


--
-- Name: COLUMN messages.role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.role IS 'Message role: user/assistant/system/tool';


--
-- Name: COLUMN messages.content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.content IS 'Message content';


--
-- Name: COLUMN messages.message_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.message_type IS 'Message type: text/tool_call/tool_result';


--
-- Name: COLUMN messages.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.created_at IS 'Creation time';


--
-- Name: COLUMN messages.token_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.token_count IS 'Token count (optional)';


--
-- Name: COLUMN messages.extra_metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.extra_metadata IS 'Additional metadata (complete message dump)';


--
-- Name: COLUMN messages.image_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.image_content IS 'Base64 encoded image content for multimodal messages';


--
-- Name: COLUMN messages.run_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.run_id IS 'Agent run ID';


--
-- Name: COLUMN messages.request_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.request_id IS 'Request ID for idempotency';


--
-- Name: COLUMN messages.delivery_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.delivery_status IS 'Message status';


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: model_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_providers (
    id integer NOT NULL,
    provider_id character varying(100) NOT NULL,
    display_name character varying(100) NOT NULL,
    provider_type character varying(32) NOT NULL,
    default_protocol character varying(64),
    base_url character varying(500) NOT NULL,
    embedding_base_url character varying(500),
    rerank_base_url character varying(500),
    models_endpoint character varying(200),
    embedding_models_endpoint character varying(200),
    rerank_models_endpoint character varying(200),
    api_key_env character varying(128),
    api_key character varying(500),
    capabilities json NOT NULL,
    enabled_models json NOT NULL,
    headers_json json,
    extra_json json,
    is_enabled boolean NOT NULL,
    is_builtin boolean NOT NULL,
    created_by character varying(100),
    updated_by character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN model_providers.provider_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.provider_id IS '供应商稳定标识';


--
-- Name: COLUMN model_providers.display_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.display_name IS '展示名称';


--
-- Name: COLUMN model_providers.provider_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.provider_type IS '供应商适配类型，默认 openai';


--
-- Name: COLUMN model_providers.default_protocol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.default_protocol IS '默认协议，如 openai_compatible';


--
-- Name: COLUMN model_providers.base_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.base_url IS 'API 基础 URL';


--
-- Name: COLUMN model_providers.embedding_base_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.embedding_base_url IS 'Embedding 模型请求基础 URL';


--
-- Name: COLUMN model_providers.rerank_base_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.rerank_base_url IS 'Rerank 模型请求基础 URL';


--
-- Name: COLUMN model_providers.models_endpoint; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.models_endpoint IS '聊天/通用模型列表端点';


--
-- Name: COLUMN model_providers.embedding_models_endpoint; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.embedding_models_endpoint IS 'Embedding 模型列表端点';


--
-- Name: COLUMN model_providers.rerank_models_endpoint; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.rerank_models_endpoint IS 'Rerank 模型列表端点';


--
-- Name: COLUMN model_providers.api_key_env; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.api_key_env IS 'API Key 环境变量名';


--
-- Name: COLUMN model_providers.api_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.api_key IS '直接配置的 API Key';


--
-- Name: COLUMN model_providers.capabilities; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.capabilities IS '支持能力：chat/embedding/rerank';


--
-- Name: COLUMN model_providers.enabled_models; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.enabled_models IS '已启用模型配置对象';


--
-- Name: COLUMN model_providers.headers_json; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.headers_json IS '额外请求头';


--
-- Name: COLUMN model_providers.extra_json; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.extra_json IS '扩展配置';


--
-- Name: COLUMN model_providers.is_enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.is_enabled IS '供应商是否启用';


--
-- Name: COLUMN model_providers.is_builtin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.is_builtin IS '是否内置';


--
-- Name: COLUMN model_providers.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.created_at IS '创建时间';


--
-- Name: COLUMN model_providers.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.model_providers.updated_at IS '更新时间';


--
-- Name: model_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.model_providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: model_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.model_providers_id_seq OWNED BY public.model_providers.id;


--
-- Name: operation_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operation_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    operation character varying NOT NULL,
    details text,
    ip_address character varying,
    "timestamp" timestamp without time zone
);


--
-- Name: operation_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operation_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operation_logs_id_seq OWNED BY public.operation_logs.id;


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    id integer NOT NULL,
    slug character varying(128) NOT NULL,
    name character varying(128) NOT NULL,
    description text NOT NULL,
    source_type character varying(32) NOT NULL,
    tool_dependencies json NOT NULL,
    mcp_dependencies json NOT NULL,
    skill_dependencies json NOT NULL,
    dir_path character varying(512) NOT NULL,
    version character varying(64),
    content_hash character varying(128),
    share_config json NOT NULL,
    enabled boolean NOT NULL,
    created_by character varying(64),
    updated_by character varying(64),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN skills.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.slug IS '技能唯一标识（目录名）';


--
-- Name: COLUMN skills.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.name IS '技能名称（来自 SKILL.md frontmatter.name）';


--
-- Name: COLUMN skills.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.description IS '技能描述（来自 SKILL.md frontmatter.description）';


--
-- Name: COLUMN skills.source_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.source_type IS '来源: builtin/upload/remote';


--
-- Name: COLUMN skills.tool_dependencies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.tool_dependencies IS '依赖的内置工具名列表';


--
-- Name: COLUMN skills.mcp_dependencies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.mcp_dependencies IS '依赖的 MCP 服务名列表';


--
-- Name: COLUMN skills.skill_dependencies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.skill_dependencies IS '依赖的其他 skill slug 列表';


--
-- Name: COLUMN skills.dir_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.dir_path IS '技能目录路径（相对 save_dir）';


--
-- Name: COLUMN skills.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.version IS '技能版本（内置 skill 使用语义化版本）';


--
-- Name: COLUMN skills.content_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.content_hash IS '技能目录内容哈希（内置 skill 安装时计算）';


--
-- Name: COLUMN skills.share_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.share_config IS '共享权限配置';


--
-- Name: COLUMN skills.enabled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.skills.enabled IS '是否启用';


--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.skills_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: subagent_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subagent_threads (
    id integer NOT NULL,
    uid character varying(64) NOT NULL,
    parent_conversation_id integer NOT NULL,
    child_conversation_id integer NOT NULL,
    child_thread_id character varying(64) NOT NULL,
    subagent_slug character varying(64) NOT NULL,
    created_by_run_id character varying(64) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN subagent_threads.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.id IS 'Primary key';


--
-- Name: COLUMN subagent_threads.uid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.uid IS 'UID';


--
-- Name: COLUMN subagent_threads.parent_conversation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.parent_conversation_id IS 'Parent conversation ID';


--
-- Name: COLUMN subagent_threads.child_conversation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.child_conversation_id IS 'Child conversation ID';


--
-- Name: COLUMN subagent_threads.child_thread_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.child_thread_id IS 'Child thread ID';


--
-- Name: COLUMN subagent_threads.subagent_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.subagent_slug IS 'Subagent slug';


--
-- Name: COLUMN subagent_threads.created_by_run_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.created_by_run_id IS 'Run that created this subagent thread';


--
-- Name: COLUMN subagent_threads.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.created_at IS 'Creation time';


--
-- Name: COLUMN subagent_threads.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subagent_threads.updated_at IS 'Update time';


--
-- Name: subagent_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subagent_threads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subagent_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subagent_threads_id_seq OWNED BY public.subagent_threads.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id character varying(32) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(64) NOT NULL,
    status character varying(32) NOT NULL,
    progress double precision NOT NULL,
    message text NOT NULL,
    payload json,
    result json,
    error text,
    cancel_requested integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: tool_calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_calls (
    id integer NOT NULL,
    message_id integer NOT NULL,
    langgraph_tool_call_id character varying(100),
    tool_name character varying(100) NOT NULL,
    tool_input json,
    tool_output text,
    status character varying(20),
    error_message text,
    created_at timestamp without time zone
);


--
-- Name: COLUMN tool_calls.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.id IS 'Primary key';


--
-- Name: COLUMN tool_calls.message_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.message_id IS 'Message ID';


--
-- Name: COLUMN tool_calls.langgraph_tool_call_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.langgraph_tool_call_id IS 'LangGraph tool_call_id';


--
-- Name: COLUMN tool_calls.tool_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.tool_name IS 'Tool name';


--
-- Name: COLUMN tool_calls.tool_input; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.tool_input IS 'Tool input parameters';


--
-- Name: COLUMN tool_calls.tool_output; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.tool_output IS 'Tool execution result';


--
-- Name: COLUMN tool_calls.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.status IS 'Status: pending/success/error';


--
-- Name: COLUMN tool_calls.error_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.error_message IS 'Error message if failed';


--
-- Name: COLUMN tool_calls.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tool_calls.created_at IS 'Creation time';


--
-- Name: tool_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tool_calls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tool_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tool_calls_id_seq OWNED BY public.tool_calls.id;


--
-- Name: user_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_config (
    id integer NOT NULL,
    uid character varying NOT NULL,
    enable_memory boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_config_id_seq OWNED BY public.user_config.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying NOT NULL,
    uid character varying NOT NULL,
    phone_number character varying,
    avatar character varying,
    password_hash character varying NOT NULL,
    role character varying NOT NULL,
    department_id integer,
    created_at timestamp without time zone,
    last_login timestamp without time zone,
    login_failed_count integer NOT NULL,
    last_failed_login timestamp without time zone,
    login_locked_until timestamp without time zone,
    is_deleted integer NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: zhiyuan_admission_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_admission_scores (
    id integer NOT NULL,
    university_id integer NOT NULL,
    major_id integer,
    province character varying(50) NOT NULL,
    year integer NOT NULL,
    subject_type character varying(50),
    batch character varying(50),
    min_score integer,
    max_score integer,
    avg_score integer,
    min_rank integer,
    plan_count integer
);


--
-- Name: zhiyuan_admission_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_admission_scores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_admission_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_admission_scores_id_seq OWNED BY public.zhiyuan_admission_scores.id;


--
-- Name: zhiyuan_colleges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_colleges (
    id integer NOT NULL,
    university_id integer NOT NULL,
    name character varying(200) NOT NULL,
    intro text
);


--
-- Name: zhiyuan_colleges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_colleges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_colleges_id_seq OWNED BY public.zhiyuan_colleges.id;


--
-- Name: zhiyuan_enrollment_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_enrollment_plans (
    id integer NOT NULL,
    university_id integer NOT NULL,
    major_id integer,
    province character varying(50) NOT NULL,
    year integer NOT NULL,
    subject_type character varying(50),
    batch character varying(50),
    plan_count integer,
    duration character varying(20),
    tuition character varying(50),
    remark text
);


--
-- Name: zhiyuan_enrollment_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_enrollment_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_enrollment_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_enrollment_plans_id_seq OWNED BY public.zhiyuan_enrollment_plans.id;


--
-- Name: zhiyuan_majors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_majors (
    id integer NOT NULL,
    university_id integer NOT NULL,
    college_id integer,
    name character varying(200) NOT NULL,
    code character varying(20),
    degree character varying(50),
    duration character varying(20),
    subject_category character varying(100),
    is_key boolean,
    subject_requirement character varying(200),
    intro text,
    employment_rate double precision,
    avg_salary double precision,
    career_directions text
);


--
-- Name: zhiyuan_majors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_majors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_majors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_majors_id_seq OWNED BY public.zhiyuan_majors.id;


--
-- Name: zhiyuan_province_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_province_rules (
    id integer NOT NULL,
    province character varying(50) NOT NULL,
    year integer NOT NULL,
    mode character varying(50),
    batch_count integer,
    max_per_batch integer,
    subject_mode character varying(50),
    description text,
    tips text
);


--
-- Name: zhiyuan_province_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_province_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_province_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_province_rules_id_seq OWNED BY public.zhiyuan_province_rules.id;


--
-- Name: zhiyuan_score_ranks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_score_ranks (
    id integer NOT NULL,
    province character varying(50) NOT NULL,
    year integer NOT NULL,
    subject_type character varying(50),
    score integer NOT NULL,
    rank integer NOT NULL,
    segment_count integer
);


--
-- Name: zhiyuan_score_ranks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_score_ranks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_score_ranks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_score_ranks_id_seq OWNED BY public.zhiyuan_score_ranks.id;


--
-- Name: zhiyuan_universities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zhiyuan_universities (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    province character varying(50) NOT NULL,
    city character varying(50),
    level character varying(50),
    type character varying(50),
    nature character varying(20),
    website character varying(300),
    intro text,
    master_points integer,
    doctor_points integer,
    key_disciplines text
);


--
-- Name: zhiyuan_universities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zhiyuan_universities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zhiyuan_universities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zhiyuan_universities_id_seq OWNED BY public.zhiyuan_universities.id;


--
-- Name: agent_envs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_envs ALTER COLUMN id SET DEFAULT nextval('public.agent_envs_id_seq'::regclass);


--
-- Name: agent_run_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_requests ALTER COLUMN id SET DEFAULT nextval('public.agent_run_requests_id_seq'::regclass);


--
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: cli_auth_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cli_auth_sessions ALTER COLUMN id SET DEFAULT nextval('public.cli_auth_sessions_id_seq'::regclass);


--
-- Name: config_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_options ALTER COLUMN id SET DEFAULT nextval('public.config_options_id_seq'::regclass);


--
-- Name: conversation_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_stats ALTER COLUMN id SET DEFAULT nextval('public.conversation_stats_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: evaluation_dataset_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items ALTER COLUMN id SET DEFAULT nextval('public.evaluation_dataset_items_id_seq'::regclass);


--
-- Name: evaluation_datasets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_datasets ALTER COLUMN id SET DEFAULT nextval('public.evaluation_datasets_id_seq'::regclass);


--
-- Name: evaluation_run_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_run_items ALTER COLUMN id SET DEFAULT nextval('public.evaluation_run_items_id_seq'::regclass);


--
-- Name: evaluation_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_runs ALTER COLUMN id SET DEFAULT nextval('public.evaluation_runs_id_seq'::regclass);


--
-- Name: knowledge_bases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_bases ALTER COLUMN id SET DEFAULT nextval('public.knowledge_bases_id_seq'::regclass);


--
-- Name: knowledge_chunks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks ALTER COLUMN id SET DEFAULT nextval('public.knowledge_chunks_id_seq'::regclass);


--
-- Name: knowledge_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_files ALTER COLUMN id SET DEFAULT nextval('public.knowledge_files_id_seq'::regclass);


--
-- Name: knowledge_graph_entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entities ALTER COLUMN id SET DEFAULT nextval('public.knowledge_graph_entities_id_seq'::regclass);


--
-- Name: knowledge_graph_entity_mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions ALTER COLUMN id SET DEFAULT nextval('public.knowledge_graph_entity_mentions_id_seq'::regclass);


--
-- Name: knowledge_graph_triple_mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions ALTER COLUMN id SET DEFAULT nextval('public.knowledge_graph_triple_mentions_id_seq'::regclass);


--
-- Name: knowledge_graph_triples id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples ALTER COLUMN id SET DEFAULT nextval('public.knowledge_graph_triples_id_seq'::regclass);


--
-- Name: mcp_servers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_servers ALTER COLUMN id SET DEFAULT nextval('public.mcp_servers_id_seq'::regclass);


--
-- Name: message_feedbacks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_feedbacks ALTER COLUMN id SET DEFAULT nextval('public.message_feedbacks_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: model_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_providers ALTER COLUMN id SET DEFAULT nextval('public.model_providers_id_seq'::regclass);


--
-- Name: operation_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_logs ALTER COLUMN id SET DEFAULT nextval('public.operation_logs_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: subagent_threads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subagent_threads ALTER COLUMN id SET DEFAULT nextval('public.subagent_threads_id_seq'::regclass);


--
-- Name: tool_calls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls ALTER COLUMN id SET DEFAULT nextval('public.tool_calls_id_seq'::regclass);


--
-- Name: user_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_config ALTER COLUMN id SET DEFAULT nextval('public.user_config_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: zhiyuan_admission_scores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_admission_scores ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_admission_scores_id_seq'::regclass);


--
-- Name: zhiyuan_colleges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_colleges ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_colleges_id_seq'::regclass);


--
-- Name: zhiyuan_enrollment_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_enrollment_plans ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_enrollment_plans_id_seq'::regclass);


--
-- Name: zhiyuan_majors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_majors ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_majors_id_seq'::regclass);


--
-- Name: zhiyuan_province_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_province_rules ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_province_rules_id_seq'::regclass);


--
-- Name: zhiyuan_score_ranks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_score_ranks ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_score_ranks_id_seq'::regclass);


--
-- Name: zhiyuan_universities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_universities ALTER COLUMN id SET DEFAULT nextval('public.zhiyuan_universities_id_seq'::regclass);


--
-- Data for Name: agent_envs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_envs (id, uid, env, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: agent_run_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_run_requests (id, request_id, uid, agent_slug, conversation_thread_id, source, queue_policy, status, input_message_id, dispatched_run_id, input_payload, error_message, created_at, dispatched_at, updated_at) FROM stdin;
1	test-001	zwj	default-chatbot	8fbe4c48-9f1d-447e-af81-88e00c62a996	chat	enqueue	dispatched	1	d5839b90-6e66-4bf6-8106-e213b9319569	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	2026-07-30 04:04:20.181689	2026-07-30 04:04:20.216501	2026-07-30 04:04:20.216501
2	15626640-6654-4e59-a4c6-6168bfef0be1	zwj	default-chatbot	8ac076a6-6722-4241-80c8-338bbada9bf2	chat	enqueue	dispatched	3	73c1c05e-0960-4fc5-8ab6-9d91f7e2db0f	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	2026-07-30 05:02:55.558197	2026-07-30 05:02:55.585767	2026-07-30 05:02:55.585767
3	4dbec0ca-811b-41b8-a37b-1b6065c6d980	zwj	default-chatbot	44c2844b-29d9-49b9-b869-445dc3a2df4d	chat	enqueue	dispatched	5	af732f4f-8c50-46e5-887d-4b3b81a0d397	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	2026-07-30 05:07:35.70803	2026-07-30 05:07:35.715632	2026-07-30 05:07:35.715632
\.


--
-- Data for Name: agent_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_runs (id, conversation_thread_id, agent_slug, uid, status, request_id, conversation_id, created_by_run_id, subagent_thread_relation_id, run_type, input_message_id, output_message_id, last_event_id, input_payload, error_type, error_message, started_at, finished_at, created_at, updated_at) FROM stdin;
d5839b90-6e66-4bf6-8106-e213b9319569	8fbe4c48-9f1d-447e-af81-88e00c62a996	default-chatbot	zwj	completed	test-001	1	\N	\N	chat	1	2	\N	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	\N	2026-07-30 04:04:20.355147	2026-07-30 04:04:24.98096	2026-07-30 04:04:20.202376	2026-07-30 04:04:24.98096
73c1c05e-0960-4fc5-8ab6-9d91f7e2db0f	8ac076a6-6722-4241-80c8-338bbada9bf2	default-chatbot	zwj	completed	15626640-6654-4e59-a4c6-6168bfef0be1	2	\N	\N	chat	3	4	\N	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	\N	2026-07-30 05:02:55.837343	2026-07-30 05:03:04.239881	2026-07-30 05:02:55.564937	2026-07-30 05:03:04.239881
af732f4f-8c50-46e5-887d-4b3b81a0d397	44c2844b-29d9-49b9-b869-445dc3a2df4d	default-chatbot	zwj	completed	4dbec0ca-811b-41b8-a37b-1b6065c6d980	3	\N	\N	chat	5	6	\N	{"model_spec": "siliconflow-cn:Pro/MiniMaxAI/MiniMax-M2.5", "tool_approval_mode": "default"}	\N	\N	2026-07-30 05:07:36.193708	2026-07-30 05:07:38.903105	2026-07-30 05:07:35.713088	2026-07-30 05:07:38.903105
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agents (id, slug, backend_id, name, description, icon, pics, config_json, share_config, is_default, is_subagent, created_by, updated_by, created_at, updated_at) FROM stdin;
1	default-chatbot	ChatbotAgent	智能助手	基础的对话机器人，可以回答问题，可在配置中启用需要的工具。	\N	[]	{"context": {}}	{"access_level": "global", "department_ids": [], "user_uids": []}	t	f	\N	\N	2026-07-29 16:01:14.985236	2026-07-29 16:01:14.98524
2	general-purpose	SubAgentBackend	通用任务	面向没有专用角色约束的一般任务，使用默认运行配置独立完成分析、整理、写作或文件处理。	\N	[]	{"context": {}}	{"access_level": "global", "department_ids": [], "user_uids": []}	f	t	\N	\N	2026-07-29 16:01:14.994958	2026-07-29 16:01:14.994961
3	web-search	SubAgentBackend	网页检索	围绕检索目标持续搜索网页，返回带引用来源的摘要资料。	\N	[]	{"context": {"system_prompt": "你是「网页检索」子智能体，专注于面向目标的网页信息检索。\\n\\n你的职责：围绕调用方给定的检索目标，使用网页搜索工具持续检索，直到收集到足以回答目标的信息。\\n\\n工作方式：\\n1. 拆解目标，确定需要检索的关键问题与检索词。\\n2. 多轮调用搜索工具：依据上一轮结果调整检索词、补充遗漏角度、交叉验证关键事实，直到信息充分或确认无法获取更多有效信息。\\n3. 优先采信权威、时效性强且彼此印证的来源；对存在冲突的信息要说明分歧。\\n\\n输出要求：\\n- 返回一份结构化的摘要资料，按主题或要点组织。\\n- 每条关键结论后使用 <cite source=\\"$URL\\" type=\\"url\\">$INDEX</cite> 标注引用来源，$INDEX 从 1 开始递增。\\n- 引用不单独成行，直接跟在结论后面。\\n- 在结尾汇总「参考来源」列表，逐条列出标题与 URL。\\n- 不要编造来源或链接；无法验证的信息要明确标注。"}}	{"access_level": "global", "department_ids": [], "user_uids": []}	f	t	\N	\N	2026-07-29 16:01:14.998688	2026-07-29 16:01:14.998692
4	research-explorer	SubAgentBackend	调研探索员	围绕单个子问题多轮检索网页与知识库，交叉验证后返回带引用的结构化发现。	\N	[]	{"context": {"system_prompt": "你是「调研探索员」子智能体。\\n专注于围绕调用方给定的**单个子问题**收集充分、可追溯的证据。\\n\\n你的职责：围绕该子问题持续检索网页与知识库，直到收集到足以回答它的信息。\\n\\n工作方式：\\n1. 拆解子问题，确定需要检索的关键点与检索词。\\n2. 多轮调用检索工具：依据上一轮结果调整检索词、补充遗漏角度、交叉验证关键事实，直到信息充分或确认无法获取更多有效信息。\\n3. 优先采信权威、时效性强且彼此印证的来源；对存在冲突的信息要说明分歧。\\n\\n输出要求：\\n- 返回一份围绕该子问题、按要点组织的结构化发现，不要展开成完整报告。\\n- 每条关键结论后使用 <cite source=\\"$URL\\" type=\\"url\\">$INDEX</cite> 标注引用来源，$INDEX 从 1 开始递增。\\n- 引用紧跟结论后、不单独成行。\\n- 结尾汇总「参考来源」列表，逐条列出标题与 URL。\\n- 不要编造来源或链接；无法验证的信息要明确标注证据缺口。"}}	{"access_level": "global", "department_ids": [], "user_uids": []}	f	t	\N	\N	2026-07-29 16:01:15.002231	2026-07-29 16:01:15.002235
5	fact-verifier	SubAgentBackend	事实核查员	对给定论断做对抗式核验，逐条给出支持/存疑/反驳判定、依据来源与置信度，并标注冲突。	\N	[]	{"context": {"system_prompt": "你是「事实核查员」子智能体，专注于对调用方给定的论断做对抗式核验。\\n\\n你的职责：对每一条论断独立查证，默认持怀疑态度——证据不足时倾向判定「存疑」，而不是默认相信。\\n\\n工作方式：\\n1. 逐条拆出待核验的论断（事实、数字、因果、时间等）。\\n2. 主动检索权威、独立的来源交叉比对；优先寻找能反驳该论断的证据。\\n3. 对来源之间的冲突如实呈现，不强行调和。\\n\\n输出要求：\\n- 对每条论断给出：判定（支持 / 存疑 / 反驳）+ 简要依据 + 依据来源 + 置信度（高/中/低）。\\n- 关键依据后使用 <cite source=\\"$URL\\" type=\\"url\\">$INDEX</cite> 标注来源，$INDEX 从 1 开始递增。\\n- 明确标注无法查证或来源相互冲突的论断。\\n- 不要编造来源或链接。"}}	{"access_level": "global", "department_ids": [], "user_uids": []}	f	t	\N	\N	2026-07-29 16:01:15.005383	2026-07-29 16:01:15.005385
6	deep-research	ChatbotAgent	深度研究	面向多来源、需事实核查的深度研究任务：规划拆解、并行调度调研子智能体、核验并综合成带引用的结构化报告。	\N	[]	{"context": {"system_prompt": "你是「深度研究」智能体，负责一项深度研究任务的整体把控与子智能体调度。\\n\\n你的核心定位是编排者，而不是亲自完成所有检索：把繁重、可独立、可并行的调研与核验工作派发给子智能体，自己专注于规划、调度与最终综合。\\n\\n工作方式：\\n1. 接到研究任务后，先读取 `deep-research` 技能（read_file 其 SKILL.md）获取完整方法论，并严格据此执行。\\n2. 问题不明确时先澄清范围，再用待办拆解出可独立调研的子问题。\\n3. 优先用 `task` 工具把子问题并行派发给调研子智能体；仅在澄清范围或补少量零散事实时自己直接检索。\\n4. 对关键结论与相互冲突的发现派发核查子智能体核验，未通过的结论不写入正文或明确降级标注。\\n5. 证据充分后由你统一综合为结构化、带引用的报告，不要简单拼接子智能体返回的原文。\\n\\n始终全程跟踪进度，最终交付一份可直接使用、围绕论证组织、来源可追溯的报告。", "subagents": ["research-explorer", "fact-verifier"], "skills": ["deep-research"]}}	{"access_level": "global", "department_ids": [], "user_uids": []}	f	f	\N	\N	2026-07-29 16:01:15.008627	2026-07-29 16:01:15.008637
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.api_keys (id, key_hash, key_prefix, name, user_id, department_id, expires_at, is_enabled, last_used_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: checkpoint_blobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_blobs (thread_id, checkpoint_ns, channel, version, type, blob) FROM stdin;
\.


--
-- Data for Name: checkpoint_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_migrations (v) FROM stdin;
0
1
2
3
4
5
6
7
8
9
\.


--
-- Data for Name: checkpoint_writes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoint_writes (thread_id, checkpoint_ns, checkpoint_id, task_id, idx, channel, type, blob, task_path) FROM stdin;
\.


--
-- Data for Name: checkpoints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.checkpoints (thread_id, checkpoint_ns, checkpoint_id, parent_checkpoint_id, type, checkpoint, metadata) FROM stdin;
\.


--
-- Data for Name: cli_auth_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cli_auth_sessions (id, device_code_hash, user_code, status, key_name, approved_user_id, api_key_id, created_at, expires_at, approved_at, consumed_at) FROM stdin;
\.


--
-- Data for Name: config_options; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.config_options (id, key, name, description, params, value, created_by, updated_by, created_at, updated_at) FROM stdin;
1	mineru_ocr_host_opts	MinerU 服务	配置自托管 MinerU 服务地址。	{"fields": [{"key": "server_url", "label": "服务地址", "type": "url", "environment": "MINERU_API_URI", "placeholder": "http://mineru-api:30001", "help": "留空时读取 MINERU_API_URI。"}]}	{}	system	system	2026-07-29 16:01:00.922446	2026-07-29 16:01:00.922451
2	mineru_official_api_opts	MinerU Official	配置 MinerU 官方云服务凭证。	{"fields": [{"key": "api_key", "label": "API Key", "type": "password", "environment": "MINERU_API_KEY", "sensitive": true, "help": "留空时读取 MINERU_API_KEY，建议优先使用环境变量。"}]}	{}	system	system	2026-07-29 16:01:00.922452	2026-07-29 16:01:00.922452
3	pp_structure_v3_ocr_host_opts	PP-Structure-V3 服务	配置自托管 PaddleX 服务地址。	{"fields": [{"key": "server_url", "label": "服务地址", "type": "url", "environment": "PADDLEX_URI", "placeholder": "http://paddlex:8080", "help": "留空时读取 PADDLEX_URI。"}]}	{}	system	system	2026-07-29 16:01:00.922453	2026-07-29 16:01:00.922453
4	paddleocr_api_opts	PaddleOCR API	PaddleOCR-VL 和 PP-OCRv6 共用此配置。	{"fields": [{"key": "api_url", "label": "API 地址", "type": "url", "environment": "PADDLEOCR_API_URL", "placeholder": "https://paddleocr.aistudio-app.com/api/v2/ocr/jobs", "help": "留空时读取 PADDLEOCR_API_URL。"}, {"key": "api_token", "label": "Access Token", "type": "password", "environment": "PADDLEOCR_API_TOKEN", "sensitive": true, "help": "留空时读取 PADDLEOCR_API_TOKEN，建议优先使用环境变量。"}]}	{}	system	system	2026-07-29 16:01:00.922454	2026-07-29 16:01:00.922454
\.


--
-- Data for Name: conversation_stats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversation_stats (id, conversation_id, message_count, total_tokens, model_used, user_feedback, created_at, updated_at) FROM stdin;
1	1	2	0	\N	\N	2026-07-30 04:04:05.158831	2026-07-30 04:04:24.973217
2	2	2	0	\N	\N	2026-07-30 05:02:54.646378	2026-07-30 05:03:04.228655
3	3	2	0	\N	\N	2026-07-30 05:07:35.32223	2026-07-30 05:07:38.894464
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversations (id, thread_id, uid, agent_id, title, status, is_pinned, created_at, updated_at, extra_metadata) FROM stdin;
1	8fbe4c48-9f1d-447e-af81-88e00c62a996	zwj	default-chatbot	测试对话-已更新	active	t	2026-07-30 04:04:05.144236	2026-07-30 04:05:11.194882	{"backend_id": "ChatbotAgent", "attachments": []}
2	8ac076a6-6722-4241-80c8-338bbada9bf2	zwj	default-chatbot	自我介绍	active	f	2026-07-30 05:02:54.640652	2026-07-30 05:03:04.203062	{"tool_approval_mode": "default", "backend_id": "ChatbotAgent", "attachments": []}
3	44c2844b-29d9-49b9-b869-445dc3a2df4d	zwj	default-chatbot	自我介绍	active	f	2026-07-30 05:07:35.320598	2026-07-30 05:07:39.824291	{"tool_approval_mode": "default", "backend_id": "ChatbotAgent", "attachments": []}
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, description, created_at) FROM stdin;
1	研发部	负责产品研发与技术平台建设	2026-07-29 17:40:19.654595
2	产品部	负责产品规划、需求分析与项目推进	2026-07-29 17:40:19.6546
3	运营部	负责业务运营、用户支持与内容维护	2026-07-29 17:40:19.654602
\.


--
-- Data for Name: evaluation_dataset_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evaluation_dataset_items (id, item_id, dataset_id, kb_id, item_index, query_text, gold_chunk_ids, gold_answer, created_at) FROM stdin;
\.


--
-- Data for Name: evaluation_datasets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evaluation_datasets (id, dataset_id, kb_id, name, description, item_count, has_gold_chunks, has_gold_answers, build_metadata, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: evaluation_run_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evaluation_run_items (id, run_id, dataset_item_id, item_index, query_text, gold_chunk_ids, gold_answer, generated_answer, retrieved_chunks, metrics, created_at) FROM stdin;
\.


--
-- Data for Name: evaluation_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evaluation_runs (id, run_id, name, kb_id, dataset_id, status, retrieval_config, metrics, overall_score, total_items, completed_items, started_at, completed_at, created_by) FROM stdin;
\.


--
-- Data for Name: knowledge_bases; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_bases (id, kb_id, name, description, kb_type, embedding_model_spec, llm_model_spec, query_params, additional_params, share_config, mindmap, mindmap_file_ids, mindmap_metadata, sample_questions, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: knowledge_chunks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_chunks (id, chunk_id, file_id, kb_id, chunk_index, content, start_char_pos, end_char_pos, start_token_pos, end_token_pos, graph_structure_indexed, graph_indexed, graph_extraction_details, ent_ids, tags, extraction_result, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: knowledge_files; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_files (id, file_id, kb_id, parent_id, filename, original_filename, file_type, path, minio_url, markdown_file, status, content_hash, file_size, chunk_count, token_count, content_type, processing_params, is_folder, error_message, created_by, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: knowledge_graph_entities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_graph_entities (id, entity_id, kb_id, normalized_name, label, name, attributes, vector_status, vector_attempt_count, vector_last_error, vector_next_retry_at, vector_locked_until, vector_lock_token, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: knowledge_graph_entity_mentions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_graph_entity_mentions (id, entity_id, kb_id, file_id, chunk_id, created_at) FROM stdin;
\.


--
-- Data for Name: knowledge_graph_triple_mentions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_graph_triple_mentions (id, triple_id, kb_id, file_id, chunk_id, text, extractor_type, created_at) FROM stdin;
\.


--
-- Data for Name: knowledge_graph_triples; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.knowledge_graph_triples (id, triple_id, kb_id, source_entity_id, target_entity_id, relation_type, content, vector_status, vector_attempt_count, vector_last_error, vector_next_retry_at, vector_locked_until, vector_lock_token, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mcp_servers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mcp_servers (id, slug, name, description, transport, url, command, args, env, headers, timeout, sse_read_timeout, tags, icon, enabled, disabled_tools, created_by, updated_by, created_at, updated_at) FROM stdin;
1	mcp-server-chart	mcp-server-chart	图表生成工具，支持生成各类图表（柱状图、折线图、饼图等）	stdio	\N	npx	["-y", "@antv/mcp-server-chart"]	null	null	\N	\N	["内置", "图表"]	📊	0	\N	system	system	2026-07-29 16:01:00.082191	2026-07-29 16:01:00.082197
\.


--
-- Data for Name: message_feedbacks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.message_feedbacks (id, message_id, uid, rating, reason, created_at) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.messages (id, conversation_id, role, content, message_type, created_at, token_count, extra_metadata, image_content, run_id, request_id, delivery_status) FROM stdin;
2	1	assistant	\n\n你好！我是“智愿”——专业的高考志愿填报AI顾问，可以帮你查分数位次、推荐院校、检索政策和生成志愿方案。有什么高考志愿方面的问题，随时可以问我！	text	2026-07-30 04:04:24.9322	\N	{"content": [{"type": "text", "text": "\\n\\n你好！我是“智愿”——专业的高考志愿填报AI顾问，可以帮你查分数位次、推荐院校、检索政策和生成志愿方案。有什么高考志愿方面的问题，随时可以问我！", "index": 0}], "additional_kwargs": {}, "response_metadata": {"model_provider": "openai", "finish_reason": "stop", "model_name": "Pro/MiniMaxAI/MiniMax-M2.5", "output_version": "v1"}, "type": "ai", "name": null, "id": "lc_run--019fb131-d67e-7073-bb44-aade71ddd143", "tool_calls": [], "invalid_tool_calls": [], "usage_metadata": {"input_tokens": 806631, "output_tokens": 2523, "total_tokens": 809154, "input_token_details": {"cache_read": 0}, "output_token_details": {"reasoning": 30}}}	\N	d5839b90-6e66-4bf6-8106-e213b9319569	test-001	complete
1	1	user	你好，请用一句话介绍你自己	text	2026-07-30 04:04:20.129371	\N	{"request_id": "test-001", "source": "chat", "raw_message": {"content": "你好，请用一句话介绍你自己", "additional_kwargs": {}, "response_metadata": {}, "type": "human", "name": null, "id": null}}	\N	d5839b90-6e66-4bf6-8106-e213b9319569	test-001	complete
4	2	assistant	\n\n你好！我是**智愿**——专业的高考志愿填报AI顾问。\n\n我的核心能力包括：\n\n- **查分数、算位次**：根据你的高考分数，查询对应的全省排名\n- **推荐院校**：基于你的位次，推荐冲/稳/保三档院校\n- **检索政策**：查询各省份招生政策和院校招生章程\n- **生成志愿方案**：综合你的情况，生成完整的志愿填报方案\n\n工作原则：\n\n1. 所有数据都以官方查询结果为准，不编造信息\n2. 推荐时给出位次对比和录取概率\n3. 政策类问题会通过知识库检索确认\n4. 回答简洁实用，像经验丰富的填报老师\n\n如果你有高考志愿相关的问题，比如想知道分数能上什么大学、某个专业就业情况如何、某院校历年录取位次怎样等，欢迎随时问我！	text	2026-07-30 05:03:04.187057	\N	{"content": [{"type": "text", "text": "\\n\\n你好！我是**智愿**——专业的高考志愿填报AI顾问。\\n\\n我的核心能力包括：\\n\\n- **查分数、算位次**：根据你的高考分数，查询对应的全省排名\\n- **推荐院校**：基于你的位次，推荐冲/稳/保三档院校\\n- **检索政策**：查询各省份招生政策和院校招生章程\\n- **生成志愿方案**：综合你的情况，生成完整的志愿填报方案\\n\\n工作原则：\\n\\n1. 所有数据都以官方查询结果为准，不编造信息\\n2. 推荐时给出位次对比和录取概率\\n3. 政策类问题会通过知识库检索确认\\n4. 回答简洁实用，像经验丰富的填报老师\\n\\n如果你有高考志愿相关的问题，比如想知道分数能上什么大学、某个专业就业情况如何、某院校历年录取位次怎样等，欢迎随时问我！", "index": 0}], "additional_kwargs": {}, "response_metadata": {"model_provider": "openai", "finish_reason": "stop", "model_name": "Pro/MiniMaxAI/MiniMax-M2.5", "output_version": "v1"}, "type": "ai", "name": null, "id": "lc_run--019fb167-7c74-7383-b545-34b54366c276", "tool_calls": [], "invalid_tool_calls": [], "usage_metadata": {"input_tokens": 2419980, "output_tokens": 22541, "total_tokens": 2442521, "input_token_details": {"cache_read": 0}, "output_token_details": {"reasoning": 34}}}	\N	73c1c05e-0960-4fc5-8ab6-9d91f7e2db0f	15626640-6654-4e59-a4c6-6168bfef0be1	complete
3	2	user	你好，请简单介绍一下自己	text	2026-07-30 05:02:55.55597	\N	{"request_id": "15626640-6654-4e59-a4c6-6168bfef0be1", "source": "chat", "raw_message": {"content": "你好，请简单介绍一下自己", "additional_kwargs": {}, "response_metadata": {}, "type": "human", "name": null, "id": null}, "tool_approval_mode": "default"}	\N	73c1c05e-0960-4fc5-8ab6-9d91f7e2db0f	15626640-6654-4e59-a4c6-6168bfef0be1	complete
6	3	assistant	\n\n你好！我是智愿，专注于高考志愿填报，可以帮你**查分数位次、推荐院校、解读招生政策**，根据你的分数和位次生成冲稳保的志愿方案。	text	2026-07-30 05:07:38.883191	\N	{"content": [{"type": "text", "text": "\\n\\n你好！我是智愿，专注于高考志愿填报，可以帮你**查分数位次、推荐院校、解读招生政策**，根据你的分数和位次生成冲稳保的志愿方案。", "index": 0}], "additional_kwargs": {}, "response_metadata": {"model_provider": "openai", "finish_reason": "stop", "model_name": "Pro/MiniMaxAI/MiniMax-M2.5", "output_version": "v1"}, "type": "ai", "name": null, "id": "lc_run--019fb16b-bf02-7cb0-89b2-a92d18c5d305", "tool_calls": [], "invalid_tool_calls": [], "usage_metadata": {"input_tokens": 833514, "output_tokens": 2667, "total_tokens": 836181, "input_token_details": {"cache_read": 11392}, "output_token_details": {"reasoning": 31}}}	\N	af732f4f-8c50-46e5-887d-4b3b81a0d397	4dbec0ca-811b-41b8-a37b-1b6065c6d980	complete
5	3	user	你好，请用一句话介绍你能帮我做什么	text	2026-07-30 05:07:35.706091	\N	{"request_id": "4dbec0ca-811b-41b8-a37b-1b6065c6d980", "source": "chat", "raw_message": {"content": "你好，请用一句话介绍你能帮我做什么", "additional_kwargs": {}, "response_metadata": {}, "type": "human", "name": null, "id": null}, "tool_approval_mode": "default"}	\N	af732f4f-8c50-46e5-887d-4b3b81a0d397	4dbec0ca-811b-41b8-a37b-1b6065c6d980	complete
\.


--
-- Data for Name: model_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.model_providers (id, provider_id, display_name, provider_type, default_protocol, base_url, embedding_base_url, rerank_base_url, models_endpoint, embedding_models_endpoint, rerank_models_endpoint, api_key_env, api_key, capabilities, enabled_models, headers_json, extra_json, is_enabled, is_builtin, created_by, updated_by, created_at, updated_at) FROM stdin;
1	openai	OpenAI	openai	\N	https://api.openai.com/v1	\N	\N	https://api.openai.com/v1/models	\N	\N	OPENAI_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.020245	2026-07-29 16:01:15.020251
2	deepseek	DeepSeek	openai	\N	https://api.deepseek.com	\N	\N	https://api.deepseek.com/models	\N	\N	DEEPSEEK_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.024668	2026-07-29 16:01:15.024671
3	alibaba-cn	DashScope	openai	\N	https://dashscope.aliyuncs.com/compatible-mode/v1	https://dashscope.aliyuncs.com/compatible-mode/v1/embeddings	https://dashscope.aliyuncs.com/compatible-api/v1/reranks	https://dashscope.aliyuncs.com/compatible-mode/v1/models	\N	\N	DASHSCOPE_API_KEY	\N	["chat", "embedding", "rerank"]	[{"id": "text-embedding-v4", "type": "embedding", "display_name": "text-embedding-v4", "dimension": 1024, "source": "remote", "extra": {}}, {"id": "qwen3-rerank", "type": "rerank", "display_name": "qwen3-rerank", "source": "remote", "extra": {}}]	{}	{}	f	t	system	system	2026-07-29 16:01:15.025647	2026-07-29 16:01:15.025649
4	alibaba	DashScope (International)	openai	\N	https://dashscope-intl.aliyuncs.com/compatible-mode/v1	\N	\N	https://dashscope-intl.aliyuncs.com/compatible-mode/v1/models	\N	\N	DASHSCOPE_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.02661	2026-07-29 16:01:15.026612
5	alibaba-coding-plan-cn	Aliyun Coding Plan	openai	\N	https://coding.dashscope.aliyuncs.com/v1	\N	\N	https://coding.dashscope.aliyuncs.com/v1/models	\N	\N	DASHSCOPE_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.027989	2026-07-29 16:01:15.027991
6	alibaba-coding-plan	Aliyun Coding Plan (International)	openai	\N	https://coding-intl.dashscope.aliyuncs.com/v1	\N	\N	https://coding-intl.dashscope.aliyuncs.com/v1/models	\N	\N	DASHSCOPE_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.028939	2026-07-29 16:01:15.028941
7	zhipuai	Zhipu (BigModel)	openai	\N	https://open.bigmodel.cn/api/paas/v4	\N	\N	https://open.bigmodel.cn/api/paas/v4/models	\N	\N	ZHIPUAI_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.029894	2026-07-29 16:01:15.029897
8	zhipuai-coding-plan	Zhipu Coding Plan (BigModel)	openai	\N	https://open.bigmodel.cn/api/coding/paas/v4	\N	\N	https://open.bigmodel.cn/api/coding/paas/v4/models	\N	\N	ZHIPUAI_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.030899	2026-07-29 16:01:15.030902
9	zai	Zhipu (Z.AI)	openai	\N	https://api.z.ai/api/paas/v4	\N	\N	https://api.z.ai/api/paas/v4/models	\N	\N	ZAI_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.03186	2026-07-29 16:01:15.031863
10	zai-coding-plan	Zhipu Coding Plan (Z.AI)	openai	\N	https://api.z.ai/api/coding/paas/v4	\N	\N	https://api.z.ai/api/coding/paas/v4/models	\N	\N	ZAI_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.032769	2026-07-29 16:01:15.032771
11	xiaomi-token-plan-cn	XiaomiMiMo Token Plan	openai	\N	https://token-plan-cn.xiaomimimo.com/v1	\N	\N	https://token-plan-cn.xiaomimimo.com/v1/models	\N	\N	XIAOMI_MIMO_TOKEN_PLAN_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.033654	2026-07-29 16:01:15.033656
12	xiaomi	XiaomiMiMo	openai	\N	https://api.xiaomimimo.com/v1	\N	\N	https://api.xiaomimimo.com/v1/models	\N	\N	XIAOMI_MIMO_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.034476	2026-07-29 16:01:15.034478
13	kimi-for-coding	Kimi Code	openai	\N	https://api.kimi.com/coding/v1	\N	\N	https://api.kimi.com/coding/v1/models	\N	\N	KIMI_CODE_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.035456	2026-07-29 16:01:15.035459
14	moonshotai-cn	Moonshot	openai	\N	https://api.moonshot.cn/v1	\N	\N	https://api.moonshot.cn/v1/models	\N	\N	MOONSHOT_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.036294	2026-07-29 16:01:15.036296
15	moonshotai	Moonshot (International)	openai	\N	https://api.moonshot.ai/v1	\N	\N	https://api.moonshot.ai/v1/models	\N	\N	MOONSHOT_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.037117	2026-07-29 16:01:15.03712
16	minimax-cn	MiniMax	openai	\N	https://api.minimaxi.com/v1	\N	\N	https://api.minimaxi.com/v1/models	\N	\N	MINIMAX_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.037966	2026-07-29 16:01:15.037969
17	minimax	MiniMax (International)	openai	\N	https://api.minimax.io/v1	\N	\N	https://api.minimax.io/v1/models	\N	\N	MINIMAX_API_KEY	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.038796	2026-07-29 16:01:15.038798
18	openrouter	OpenRouter	openai	\N	https://openrouter.ai/api/v1	https://openrouter.ai/api/v1/embeddings	\N	https://openrouter.ai/api/v1/models	https://openrouter.ai/api/v1/embeddings/models	\N	OPENROUTER_API_KEY	\N	["chat", "embedding"]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.039666	2026-07-29 16:01:15.039668
19	modelscope	ModelScope	openai	\N	https://api-inference.modelscope.cn/v1	\N	\N	https://api-inference.modelscope.cn/v1/models	\N	\N	MODELSCOPE_ACCESS_TOKEN	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.040498	2026-07-29 16:01:15.0405
20	opencode	OpenCode	openai	\N	https://opencode.ai/zen/v1	\N	\N	https://opencode.ai/zen/v1/models	\N	\N	\N	\N	[]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.041282	2026-07-29 16:01:15.041285
21	siliconflow-cn	SiliconFlow	openai	\N	https://api.siliconflow.cn/v1	https://api.siliconflow.cn/v1/embeddings	https://api.siliconflow.cn/v1/rerank	https://api.siliconflow.cn/v1/models?sub_type=chat	https://api.siliconflow.cn/v1/models?sub_type=embedding	https://api.siliconflow.cn/v1/models?sub_type=reranker	SILICONFLOW_API_KEY	\N	["chat", "embedding", "rerank"]	[{"id": "deepseek-ai/DeepSeek-V4-Flash", "type": "chat", "display_name": "deepseek-ai/DeepSeek-V4-Flash", "source": "remote", "extra": {}}, {"id": "Pro/MiniMaxAI/MiniMax-M2.5", "type": "chat", "display_name": "Pro/MiniMaxAI/MiniMax-M2.5", "source": "remote", "extra": {}}, {"id": "zai-org/GLM-5.2", "type": "chat", "display_name": "zai-org/GLM-5.2", "source": "remote", "extra": {}}, {"id": "Pro/BAAI/bge-m3", "type": "embedding", "display_name": "Pro/BAAI/bge-m3", "dimension": 1024, "batch_size": 40, "source": "remote", "extra": {}}, {"id": "BAAI/bge-m3", "type": "embedding", "display_name": "BAAI/bge-m3", "dimension": 1024, "batch_size": 40, "source": "remote", "extra": {}}, {"id": "Qwen/Qwen3-Embedding-0.6B", "type": "embedding", "display_name": "Qwen/Qwen3-Embedding-0.6B", "dimension": 1024, "batch_size": 40, "source": "remote", "extra": {}}, {"id": "Pro/BAAI/bge-reranker-v2-m3", "type": "rerank", "display_name": "Pro/BAAI/bge-reranker-v2-m3", "source": "remote", "extra": {}}, {"id": "BAAI/bge-reranker-v2-m3", "type": "rerank", "display_name": "BAAI/bge-reranker-v2-m3", "source": "remote", "extra": {}}]	{}	{}	t	t	system	system	2026-07-29 16:01:15.042172	2026-07-29 16:01:15.042174
22	siliconflow	SiliconFlow (International)	openai	\N	https://api.siliconflow.com/v1	https://api.siliconflow.com/v1/embeddings	https://api.siliconflow.com/v1/rerank	https://api.siliconflow.com/v1/models?sub_type=chat	https://api.siliconflow.com/v1/models?sub_type=embedding	https://api.siliconflow.com/v1/models?sub_type=reranker	SILICONFLOW_GLOBAL_API_KEY	\N	["chat", "embedding", "rerank"]	[]	{}	{}	f	t	system	system	2026-07-29 16:01:15.043075	2026-07-29 16:01:15.043077
\.


--
-- Data for Name: operation_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operation_logs (id, user_id, operation, details, ip_address, "timestamp") FROM stdin;
1	1	登录	\N	\N	2026-07-29 17:42:11.192765
2	1	登录	\N	\N	2026-07-30 03:49:34.530535
3	1	登录	\N	\N	2026-07-30 03:54:39.537951
4	1	登录	\N	\N	2026-07-30 03:55:40.829648
5	1	登录	\N	\N	2026-07-30 03:56:59.165532
6	1	登录	\N	\N	2026-07-30 03:57:52.898524
7	1	登录	\N	\N	2026-07-30 03:59:35.097106
8	1	登录	\N	\N	2026-07-30 04:02:28.763263
9	1	登录失败	密码错误，失败次数: 1	\N	2026-07-30 04:12:05.546464
10	1	登录失败	密码错误，失败次数: 2	\N	2026-07-30 04:13:27.013469
11	1	登录	\N	\N	2026-07-30 04:14:32.506123
12	1	登录	\N	\N	2026-07-30 04:23:24.089661
13	1	登录	\N	\N	2026-07-30 04:23:25.930591
14	1	登录	\N	\N	2026-07-30 04:24:03.336072
15	1	登录	\N	\N	2026-07-30 04:27:31.295443
16	1	登录	\N	\N	2026-07-30 04:29:51.591633
17	1	登录	\N	\N	2026-07-30 04:31:05.481396
18	1	登录	\N	\N	2026-07-30 04:32:43.945869
19	1	登录	\N	\N	2026-07-30 04:33:54.345814
20	1	登录	\N	\N	2026-07-30 04:38:26.846264
21	1	登录	\N	\N	2026-07-30 04:39:01.320938
22	1	登录	\N	\N	2026-07-30 04:43:08.934664
23	1	登录	\N	\N	2026-07-30 04:46:02.930176
24	1	登录	\N	\N	2026-07-30 04:48:07.311674
25	1	登录	\N	\N	2026-07-30 04:49:43.711751
26	1	登录	\N	\N	2026-07-30 04:55:17.287788
27	1	登录	\N	\N	2026-07-30 04:59:26.692697
28	1	登录	\N	\N	2026-07-30 05:00:31.761336
29	1	登录	\N	\N	2026-07-30 05:01:11.14126
30	1	登录	\N	\N	2026-07-30 05:33:13.534979
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.skills (id, slug, name, description, source_type, tool_dependencies, mcp_dependencies, skill_dependencies, dir_path, version, content_hash, share_config, enabled, created_by, updated_by, created_at, updated_at) FROM stdin;
3	deep-research	deep-research	深度研究编排方法论：澄清范围、拆解规划、并行调度子智能体调研、对抗式核验、综合成带引用的结构化报告。	builtin	["tavily_search"]	[]	["html-preview"]	skills/deep-research	2026.06.05	7ab6ad9f2b68af05e693f453816b81e9d4320bd36cd9f2c764da9415ca359205	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:01:00.653614	2026-07-30 05:24:50.763064
4	knowledge-base	knowledge-base	使用 Yuxi 知识库进行检索、打开文档、文档内定位和查看思维导图。	builtin	["list_kbs", "query_kb", "find_kb_document", "open_kb_document", "get_mindmap", "search_file", "download_kb_file"]	[]	[]	skills/knowledge-base	2026.06.24	f7a9275adc8b32fd11b87a4fe1d5555f909149605ec2437dd1232aa9a9d3d1bb	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:01:00.701328	2026-07-30 05:24:50.829211
5	mysql-reporter	mysql reporter	基于 MySQL 数据库生成查询报表和可视化图表，适合分析业务指标、统计趋势，并用 Charts MCP 展示结果。	builtin	[]	["mcp-server-chart"]	[]	skills/mysql-reporter	2026.06.05	a910e4def3d3add7663234bc473e56027a6fea33c74a2a9cac406dee1f2787e9	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:01:00.91204	2026-07-30 05:24:51.246433
6	zhiyuan	zhiyuan	高考志愿填报智能顾问：查分数位次、推荐院校、检索政策、生成冲稳保志愿方案。	builtin	["query_admission_scores", "get_score_rank", "get_university_detail", "get_province_plan", "get_employment_data", "query_graph", "recommend_schools", "calculate_probability", "check_subject_requirement", "compare_majors", "rank_trend_analysis", "generate_application_plan", "export_plan"]	[]	[]	skills/zhiyuan	2026.07.30	4f38828bf62a33cae880a410c83d88c6492e40e23b851edaeee87ac5c41def98	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:05:44.624597	2026-07-30 05:24:51.323777
1	image-gen	image-gen	在 Agent 沙盒中生成图片并保存到 outputs，默认支持 Qwen-Image，也可接入其它图片生成接口。	builtin	["present_artifacts"]	[]	[]	skills/image-gen	2026.06.02	64a7c7a6224a493b9ca2232dbe30c82540d34eef723e1babf6f6d8a6c8d8087c	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:01:00.529763	2026-07-30 05:24:50.602255
2	html-preview	html-preview	使用 Markdown `html:preview` 围栏输出轻量静态 HTML/CSS 可视化，适合数值对比、流程、时间线、层级关系和关键指标。	builtin	[]	[]	[]	skills/html-preview	2026.07.23	2ee9462295cbaa88fc26b0f50cdd444480951788159203d84186a0254443bf2e	{"access_level": "global", "department_ids": [], "user_uids": []}	t	system	system	2026-07-29 16:01:00.596924	2026-07-30 05:24:50.685542
\.


--
-- Data for Name: subagent_threads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subagent_threads (id, uid, parent_conversation_id, child_conversation_id, child_thread_id, subagent_slug, created_by_run_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tasks (id, name, type, status, progress, message, payload, result, error, cancel_requested, created_at, updated_at, started_at, completed_at) FROM stdin;
620fdc9845da42ca9d2e4d58129bef53	知识库文档处理 (测试知识库)	knowledge_ingest	success	100	任务已完成	{"kb_id": "kb_ccgiybwxdo", "items": ["http://localhost:9000/knowledgebases/kb_ccgiybwxdo/upload/test_doc_1785384380037.txt"], "params": {"content_type": "file", "auto_index": true, "content_hashes": {"http://localhost:9000/knowledgebases/kb_ccgiybwxdo/upload/test_doc_1785384380037.txt": "f65f2e8d80b033e42d37db175f68587c3f05aebccf6e7dafd74bb4b8e42a8ed3"}, "chunk_preset_id": "general"}, "content_type": "file"}	{"kb_id": "kb_ccgiybwxdo", "item_type": "文件", "submitted": 1, "failed": 0, "items": [{"file_id": "file_17694f", "kb_id": "kb_ccgiybwxdo", "parent_id": null, "filename": "test_doc.txt", "file_type": "txt", "path": "http://localhost:9000/knowledgebases/kb_ccgiybwxdo/upload/test_doc_1785384380037.txt", "markdown_file": "http://localhost:9000/knowledgebases/kb_ccgiybwxdo/parsed/file_17694f.md", "status": "indexed", "content_hash": "f65f2e8d80b033e42d37db175f68587c3f05aebccf6e7dafd74bb4b8e42a8ed3", "size": 656, "chunk_count": 1, "token_count": 181, "content_type": null, "processing_params": {"content_type": "file", "chunk_preset_id": "general", "chunk_parser_config": {}, "chunk_engine_version": "ragflow_like_v1"}, "is_folder": false, "error": null, "created_by": "zwj", "updated_by": "zwj", "created_at": "2026-07-29T20:06:38.590762Z", "updated_at": "2026-07-29T20:06:41.067373Z", "original_filename": null, "minio_url": null}]}	\N	0	2026-07-30 04:06:38.548443	2026-07-30 04:06:41.085295	2026-07-30 04:06:38.561515	2026-07-30 04:06:41.085275
\.


--
-- Data for Name: tool_calls; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tool_calls (id, message_id, langgraph_tool_call_id, tool_name, tool_input, tool_output, status, error_message, created_at) FROM stdin;
\.


--
-- Data for Name: user_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_config (id, uid, enable_memory, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, uid, phone_number, avatar, password_hash, role, department_id, created_at, last_login, login_failed_count, last_failed_login, login_locked_until, is_deleted, deleted_at) FROM stdin;
2	研发部管理员1	dev_admin_1	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$sydFrSQ2+nwoCPnZkFClCw$Oc/DR1/SKsbDrLejfFijzLxc4Afjdbn3NvUOKizrThM	admin	1	2026-07-29 17:40:20.420515	\N	0	\N	\N	0	\N
3	研发部管理员2	dev_admin_2	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$3WyMwzM4cZLK+0q+YLnyLA$j4FIdsTX809MMc+lJZs2mrtfwtezhovx7PvqOBG8rF8	admin	1	2026-07-29 17:40:20.420515	\N	0	\N	\N	0	\N
4	研发部用户1	dev_user_01	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$klV+VGxvCgf4kePFIDr5sA$b0y/52ZLxh+E5nWyNOYwejy++ZNEMcnYD0fneLKJQd0	user	1	2026-07-29 17:40:20.420516	\N	0	\N	\N	0	\N
5	研发部用户2	dev_user_02	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$XnM1Q1a2cTmMhHsfQhpAJQ$6DETbaQF9TI1ucaYQAxqbY+ZVpqbg0uK+cKCNRS30YE	user	1	2026-07-29 17:40:20.420517	\N	0	\N	\N	0	\N
6	研发部用户3	dev_user_03	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$ZhSacUQWgmo+yqEfyVgEig$lDY2M048n3rvBRzrd01u+pY3HqPUAHSTYcHctjj0O5I	user	1	2026-07-29 17:40:20.420517	\N	0	\N	\N	0	\N
7	研发部用户4	dev_user_04	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$hKy32b/1EZhpHX2AXg3z8w$hHeCZNj/MCAXppPzx/6mRlXjPF+jwBGDZjrK1NynYeM	user	1	2026-07-29 17:40:20.420518	\N	0	\N	\N	0	\N
8	研发部用户5	dev_user_05	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$PHwDIXU7b+XtxNiGQUsFoA$fANsgrdBYcZ7yDf5B02+DUM754FFciUgS69LkJju42M	user	1	2026-07-29 17:40:20.420518	\N	0	\N	\N	0	\N
9	产品部管理员1	prod_admin_1	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$bNAG8yFMIo0g8QLxlSu+JQ$FbV2tc3kNtv/AWRrmHVVjgqvhuYUmF6CmW74ICo8Kdw	admin	2	2026-07-29 17:40:20.420519	\N	0	\N	\N	0	\N
10	产品部管理员2	prod_admin_2	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$KRanpv5X0arLPQRRwJd5JA$oWo3TX22EZfAVBvagrpkGiosZIUkkfCGi5j+kLVC0SI	admin	2	2026-07-29 17:40:20.420519	\N	0	\N	\N	0	\N
11	产品部用户1	prod_user_01	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$b12UYsijFtaxVY0mutmpiA$n4XHOz1NLOXz8Y331Xv2NVOA8ibXIjw+V9fG534Mbj8	user	2	2026-07-29 17:40:20.42052	\N	0	\N	\N	0	\N
12	产品部用户2	prod_user_02	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$pzI2BCmMkS0Des/4orrlOg$+ljj/xHmfeCEVyOL5p7MtPRmhGoI4OQR8LuUVUWy/U8	user	2	2026-07-29 17:40:20.420521	\N	0	\N	\N	0	\N
13	产品部用户3	prod_user_03	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$uJGS6ZN9Yvr9UgyZvExA7Q$Dg3C1oIo2ufrHtlKTzGmwZsU+W++PPSFgSx8qb4owys	user	2	2026-07-29 17:40:20.420521	\N	0	\N	\N	0	\N
14	产品部用户4	prod_user_04	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$TvFDwxXwcw8tBKf0SzsgAg$yuc4QMclLtdFzbh4/nqfXilGCyKnh4F+7hyfmScbI4k	user	2	2026-07-29 17:40:20.420522	\N	0	\N	\N	0	\N
15	产品部用户5	prod_user_05	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$ctych4L41/Pc+tQm0kruHg$VsYXCwAw58pG3T+BGq5OAR2mGJnJ1OSSYWRQhuYTgl8	user	2	2026-07-29 17:40:20.420522	\N	0	\N	\N	0	\N
16	运营部管理员1	ops_admin_1	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$BatwlTHEs4yCwS6NY9q64w$2zTgkSYdhtiKoDVSN6v6UqVawe+ayohqunhrDOJfm9k	admin	3	2026-07-29 17:40:20.420523	\N	0	\N	\N	0	\N
17	运营部管理员2	ops_admin_2	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$stkbOKORTTphx5UHiS1G+Q$RWoJ0uRyc3FgXGYjf4yLdRvEUqHDiVGo2BYr3zsYo4Y	admin	3	2026-07-29 17:40:20.420523	\N	0	\N	\N	0	\N
18	运营部用户1	ops_user_01	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$CFm3XTzzV0o5x4GicQCUMg$iknmyZQxOo3cTAOzAhNTbMwUs8BNzqDh9XP1iPCxSIM	user	3	2026-07-29 17:40:20.420524	\N	0	\N	\N	0	\N
19	运营部用户2	ops_user_02	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$3RbclBEQ/Zi8iCf/8FiW4Q$y+q9hXL+TVJy9RFVG/sQBuIaqXGaTw3D7yP6xLXWNeY	user	3	2026-07-29 17:40:20.420524	\N	0	\N	\N	0	\N
20	运营部用户3	ops_user_03	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$HQN+S9c5MH/btMH+3usRPQ$aP2MLO8QUn6yJK34kWAVRiLEFnejvi68nDKAlhzxE4g	user	3	2026-07-29 17:40:20.420525	\N	0	\N	\N	0	\N
21	运营部用户4	ops_user_04	\N	\N	$argon2id$v=19$m=65536,t=3,p=4$bBmFGG91rHeFh2CPmJmHuA$Q5ZT8E6uojQn+3SrxRRMjV0cKpg4E7+zU/PlNkLcKiM	user	3	2026-07-29 17:40:20.420525	\N	0	\N	\N	0	\N
1	张文杰	zwj	15251638888	\N	$argon2id$v=19$m=65536,t=3,p=4$OzUtVxCJPpRLucRz4X0Ygg$nx0lWLDIpsIyWGqfy3w9ldYtvS2jwH1cSF/yGeVdze8	superadmin	1	2026-07-29 17:40:20.42051	2026-07-30 05:33:13.505326	0	\N	\N	0	\N
\.


--
-- Data for Name: zhiyuan_admission_scores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_admission_scores (id, university_id, major_id, province, year, subject_type, batch, min_score, max_score, avg_score, min_rank, plan_count) FROM stdin;
1	1	0	河南	2023	理科	本科一批	675	707	680	6151	10
2	1	0	河南	2024	理科	本科一批	679	709	691	6152	18
3	1	0	河南	2025	理科	本科一批	684	704	695	7662	5
4	1	0	河南	2023	文科	本科一批	664	704	676	7792	23
5	1	0	河南	2024	文科	本科一批	665	703	678	9168	47
6	1	0	河南	2025	文科	本科一批	667	691	675	7153	8
7	1	0	山东	2023	综合改革	本科一批	663	679	668	9562	42
8	1	0	山东	2024	综合改革	本科一批	677	708	684	7308	8
9	1	0	山东	2025	综合改革	本科一批	678	698	684	5990	43
10	1	0	湖北	2023	物理类	本科一批	659	681	670	9737	12
11	1	0	湖北	2024	物理类	本科一批	664	680	678	8871	10
12	1	0	湖北	2025	物理类	本科一批	670	703	683	8503	25
13	1	0	湖北	2023	历史类	本科一批	650	687	660	8817	20
14	1	0	湖北	2024	历史类	本科一批	650	686	665	9583	24
15	1	0	湖北	2025	历史类	本科一批	656	695	662	8708	5
16	2	0	河南	2023	理科	本科一批	686	719	692	6710	9
17	2	0	河南	2024	理科	本科一批	678	697	688	7216	9
18	2	0	河南	2025	理科	本科一批	679	699	691	6729	39
19	2	0	河南	2023	文科	本科一批	661	701	676	9297	38
20	2	0	河南	2024	文科	本科一批	652	684	661	10458	47
21	2	0	河南	2025	文科	本科一批	655	674	664	11167	12
22	2	0	山东	2023	综合改革	本科一批	665	684	674	9324	23
23	2	0	山东	2024	综合改革	本科一批	668	689	683	8913	45
24	2	0	山东	2025	综合改革	本科一批	670	693	675	8017	10
25	2	0	湖北	2023	物理类	本科一批	670	686	675	9053	26
26	2	0	湖北	2024	物理类	本科一批	661	684	668	9388	33
27	2	0	湖北	2025	物理类	本科一批	670	688	676	8194	49
28	2	0	湖北	2023	历史类	本科一批	646	672	660	10589	40
29	2	0	湖北	2024	历史类	本科一批	646	662	655	10107	28
30	2	0	湖北	2025	历史类	本科一批	643	664	658	12407	20
31	3	0	河南	2023	理科	本科一批	675	707	686	7061	44
32	3	0	河南	2024	理科	本科一批	676	698	683	8660	16
33	3	0	河南	2025	理科	本科一批	685	723	695	5264	31
34	3	0	河南	2023	文科	本科一批	659	699	665	8251	29
35	3	0	河南	2024	文科	本科一批	653	675	661	11091	34
36	3	0	河南	2025	文科	本科一批	663	703	671	8022	19
37	3	0	山东	2023	综合改革	本科一批	662	689	672	9363	22
38	3	0	山东	2024	综合改革	本科一批	664	687	674	10206	46
39	3	0	山东	2025	综合改革	本科一批	678	710	688	6911	6
40	3	0	湖北	2023	物理类	本科一批	660	683	667	10357	42
41	3	0	湖北	2024	物理类	本科一批	665	699	676	6930	27
42	3	0	湖北	2025	物理类	本科一批	667	698	673	8088	29
43	3	0	湖北	2023	历史类	本科一批	648	685	659	9199	5
44	3	0	湖北	2024	历史类	本科一批	658	690	673	10766	47
45	3	0	湖北	2025	历史类	本科一批	648	665	663	9646	26
46	4	0	河南	2023	理科	本科一批	682	700	691	7244	37
47	4	0	河南	2024	理科	本科一批	681	706	692	7360	49
48	4	0	河南	2025	理科	本科一批	681	702	692	7050	47
49	4	0	河南	2023	文科	本科一批	664	684	678	9209	41
50	4	0	河南	2024	文科	本科一批	661	676	670	8565	23
51	4	0	河南	2025	文科	本科一批	658	691	672	8941	46
52	4	0	山东	2023	综合改革	本科一批	672	701	687	7690	18
53	4	0	山东	2024	综合改革	本科一批	678	718	685	7122	47
54	4	0	山东	2025	综合改革	本科一批	664	700	679	7856	44
55	4	0	湖北	2023	物理类	本科一批	667	706	675	6950	48
56	4	0	湖北	2024	物理类	本科一批	666	687	673	7474	6
57	4	0	湖北	2025	物理类	本科一批	658	688	672	8261	9
58	4	0	湖北	2023	历史类	本科一批	656	691	670	9078	17
59	4	0	湖北	2024	历史类	本科一批	654	676	661	9578	46
60	4	0	湖北	2025	历史类	本科一批	642	681	648	12496	32
61	5	0	河南	2023	理科	本科一批	679	716	692	6179	34
62	5	0	河南	2024	理科	本科一批	673	691	685	7876	13
63	5	0	河南	2025	理科	本科一批	686	718	700	6828	25
64	5	0	河南	2023	文科	本科一批	666	704	679	8778	32
65	5	0	河南	2024	文科	本科一批	666	704	678	9734	33
66	5	0	河南	2025	文科	本科一批	660	695	669	9906	38
67	5	0	山东	2023	综合改革	本科一批	677	700	689	7670	9
68	5	0	山东	2024	综合改革	本科一批	671	696	681	7060	39
69	5	0	山东	2025	综合改革	本科一批	664	686	675	7356	49
70	5	0	湖北	2023	物理类	本科一批	661	678	672	9634	31
71	5	0	湖北	2024	物理类	本科一批	667	695	672	8441	18
72	5	0	湖北	2025	物理类	本科一批	670	709	684	7646	49
73	5	0	湖北	2023	历史类	本科一批	642	681	656	12341	29
74	5	0	湖北	2024	历史类	本科一批	657	683	666	7461	29
75	5	0	湖北	2025	历史类	本科一批	655	693	668	9645	43
76	6	0	河南	2023	理科	本科一批	679	702	690	7066	36
77	6	0	河南	2024	理科	本科一批	672	708	687	7453	30
78	6	0	河南	2025	理科	本科一批	677	696	691	8294	39
79	6	0	河南	2023	文科	本科一批	652	685	666	11395	47
80	6	0	河南	2024	文科	本科一批	652	680	659	8169	34
81	6	0	河南	2025	文科	本科一批	657	684	667	7627	18
82	6	0	山东	2023	综合改革	本科一批	676	715	687	6887	22
83	6	0	山东	2024	综合改革	本科一批	675	692	687	6756	6
84	6	0	山东	2025	综合改革	本科一批	663	689	671	10439	46
85	6	0	湖北	2023	物理类	本科一批	659	694	664	10123	6
86	6	0	湖北	2024	物理类	本科一批	664	679	678	7565	14
87	6	0	湖北	2025	物理类	本科一批	664	700	670	7314	41
88	6	0	湖北	2023	历史类	本科一批	648	671	658	10057	15
89	6	0	湖北	2024	历史类	本科一批	645	665	654	11666	11
90	6	0	湖北	2025	历史类	本科一批	642	675	657	12652	29
91	7	0	河南	2023	理科	本科一批	684	705	690	7765	42
92	7	0	河南	2024	理科	本科一批	679	718	688	5969	48
93	7	0	河南	2025	理科	本科一批	675	708	680	8388	27
94	7	0	河南	2023	文科	本科一批	665	682	678	9049	46
95	7	0	河南	2024	文科	本科一批	662	690	674	7084	11
96	7	0	河南	2025	文科	本科一批	665	700	677	10066	50
97	7	0	山东	2023	综合改革	本科一批	666	704	679	8183	46
98	7	0	山东	2024	综合改革	本科一批	670	702	682	8370	34
99	7	0	山东	2025	综合改革	本科一批	675	708	684	8477	25
100	7	0	湖北	2023	物理类	本科一批	664	681	673	9737	33
101	7	0	湖北	2024	物理类	本科一批	664	697	678	9461	47
102	7	0	湖北	2025	物理类	本科一批	669	699	679	7569	16
103	7	0	湖北	2023	历史类	本科一批	657	697	666	8229	26
104	7	0	湖北	2024	历史类	本科一批	650	687	659	11521	40
105	7	0	湖北	2025	历史类	本科一批	642	663	648	10871	20
106	8	0	河南	2023	理科	本科一批	685	724	693	6470	49
107	8	0	河南	2024	理科	本科一批	687	717	699	6667	6
108	8	0	河南	2025	理科	本科一批	674	701	682	6974	24
109	8	0	河南	2023	文科	本科一批	663	694	673	8606	32
110	8	0	河南	2024	文科	本科一批	662	691	671	8278	24
111	8	0	河南	2025	文科	本科一批	660	698	668	8029	25
112	8	0	山东	2023	综合改革	本科一批	665	704	672	9325	17
113	8	0	山东	2024	综合改革	本科一批	668	691	682	8982	38
114	8	0	山东	2025	综合改革	本科一批	671	692	680	9418	19
115	8	0	湖北	2023	物理类	本科一批	668	683	681	7148	13
116	8	0	湖北	2024	物理类	本科一批	665	681	678	6954	23
117	8	0	湖北	2025	物理类	本科一批	661	700	673	9390	11
118	8	0	湖北	2023	历史类	本科一批	642	672	654	11119	33
119	8	0	湖北	2024	历史类	本科一批	652	668	661	8562	35
120	8	0	湖北	2025	历史类	本科一批	645	672	657	11852	9
121	9	0	河南	2023	理科	本科一批	673	713	687	6627	24
122	9	0	河南	2024	理科	本科一批	674	692	687	9101	31
123	9	0	河南	2025	理科	本科一批	679	706	691	7882	33
124	9	0	河南	2023	文科	本科一批	661	689	670	10182	41
125	9	0	河南	2024	文科	本科一批	653	691	659	10125	18
126	9	0	河南	2025	文科	本科一批	658	675	665	8333	20
127	9	0	山东	2023	综合改革	本科一批	667	687	672	8472	31
128	9	0	山东	2024	综合改革	本科一批	676	706	685	7960	7
129	9	0	山东	2025	综合改革	本科一批	669	693	681	7413	9
130	9	0	湖北	2023	物理类	本科一批	664	704	679	10058	42
131	9	0	湖北	2024	物理类	本科一批	663	695	671	8439	46
132	9	0	湖北	2025	物理类	本科一批	661	680	667	10353	8
133	9	0	湖北	2023	历史类	本科一批	647	681	661	11505	23
134	9	0	湖北	2024	历史类	本科一批	656	693	665	7987	49
135	9	0	湖北	2025	历史类	本科一批	654	685	667	11299	36
136	10	0	河南	2023	理科	本科一批	686	702	697	5325	25
137	10	0	河南	2024	理科	本科一批	680	702	695	5672	41
138	10	0	河南	2025	理科	本科一批	672	708	681	9358	41
139	10	0	河南	2023	文科	本科一批	653	673	665	10720	38
140	10	0	河南	2024	文科	本科一批	666	686	680	9798	32
141	10	0	河南	2025	文科	本科一批	667	697	677	9857	31
142	10	0	山东	2023	综合改革	本科一批	672	690	679	7241	26
143	10	0	山东	2024	综合改革	本科一批	675	699	690	8081	30
144	10	0	山东	2025	综合改革	本科一批	663	688	672	8542	25
145	10	0	湖北	2023	物理类	本科一批	660	687	673	10692	5
146	10	0	湖北	2024	物理类	本科一批	671	692	684	7625	28
147	10	0	湖北	2025	物理类	本科一批	672	711	677	8191	18
148	10	0	湖北	2023	历史类	本科一批	650	674	662	10196	49
149	10	0	湖北	2024	历史类	本科一批	657	692	671	7891	20
150	10	0	湖北	2025	历史类	本科一批	647	662	660	9520	31
151	11	0	河南	2023	理科	本科一批	634	652	646	10322	12
152	11	0	河南	2024	理科	本科一批	636	673	645	11392	37
153	11	0	河南	2025	理科	本科一批	640	670	652	10628	20
154	11	0	河南	2023	文科	本科一批	626	653	634	12654	43
155	11	0	河南	2024	文科	本科一批	628	647	634	13401	22
156	11	0	河南	2025	文科	本科一批	625	665	638	11699	22
157	11	0	山东	2023	综合改革	本科一批	622	646	636	11688	42
158	11	0	山东	2024	综合改革	本科一批	637	666	650	12950	35
159	11	0	山东	2025	综合改革	本科一批	633	672	646	10915	29
160	11	0	湖北	2023	物理类	本科一批	631	652	639	13960	41
161	11	0	湖北	2024	物理类	本科一批	629	668	640	10810	7
162	11	0	湖北	2025	物理类	本科一批	627	664	638	13503	29
163	11	0	湖北	2023	历史类	本科一批	606	622	613	14373	37
164	11	0	湖北	2024	历史类	本科一批	612	641	618	15840	38
165	11	0	湖北	2025	历史类	本科一批	616	635	627	10802	46
166	12	0	河南	2023	理科	本科一批	636	676	645	9461	26
167	12	0	河南	2024	理科	本科一批	644	669	659	11235	39
168	12	0	河南	2025	理科	本科一批	644	679	656	12525	39
169	12	0	河南	2023	文科	本科一批	613	635	628	14343	48
170	12	0	河南	2024	文科	本科一批	621	659	627	15466	32
171	12	0	河南	2025	文科	本科一批	615	652	621	14905	33
172	12	0	山东	2023	综合改革	本科一批	627	642	632	13254	25
173	12	0	山东	2024	综合改革	本科一批	623	649	634	11650	14
174	12	0	山东	2025	综合改革	本科一批	629	662	644	12250	16
175	12	0	湖北	2023	物理类	本科一批	622	656	633	11136	44
176	12	0	湖北	2024	物理类	本科一批	624	657	631	12588	19
177	12	0	湖北	2025	物理类	本科一批	631	660	640	12556	47
178	12	0	湖北	2023	历史类	本科一批	602	631	611	17161	48
179	12	0	湖北	2024	历史类	本科一批	607	633	621	11862	24
180	12	0	湖北	2025	历史类	本科一批	615	644	624	14527	17
181	13	0	河南	2023	理科	本科一批	644	662	652	12098	29
182	13	0	河南	2024	理科	本科一批	643	680	652	11020	6
183	13	0	河南	2025	理科	本科一批	644	677	659	9643	8
184	13	0	河南	2023	文科	本科一批	627	651	635	13937	43
185	13	0	河南	2024	文科	本科一批	623	644	637	11272	21
186	13	0	河南	2025	文科	本科一批	616	651	631	14087	7
187	13	0	山东	2023	综合改革	本科一批	631	647	645	13273	28
188	13	0	山东	2024	综合改革	本科一批	626	650	636	10367	31
189	13	0	山东	2025	综合改革	本科一批	627	667	640	10827	28
190	13	0	湖北	2023	物理类	本科一批	633	656	640	11708	21
191	13	0	湖北	2024	物理类	本科一批	632	656	642	14006	12
192	13	0	湖北	2025	物理类	本科一批	631	650	639	14103	48
193	13	0	湖北	2023	历史类	本科一批	614	654	627	16141	28
194	13	0	湖北	2024	历史类	本科一批	604	619	613	16297	39
195	13	0	湖北	2025	历史类	本科一批	605	641	620	14237	21
196	14	0	河南	2023	理科	本科一批	644	670	650	11967	48
197	14	0	河南	2024	理科	本科一批	639	673	652	10973	25
198	14	0	河南	2025	理科	本科一批	639	674	651	11755	49
199	14	0	河南	2023	文科	本科一批	621	639	628	13670	7
200	14	0	河南	2024	文科	本科一批	613	643	619	12627	11
201	14	0	河南	2025	文科	本科一批	619	638	630	15129	34
202	14	0	山东	2023	综合改革	本科一批	633	671	646	12497	31
203	14	0	山东	2024	综合改革	本科一批	626	661	632	14311	36
204	14	0	山东	2025	综合改革	本科一批	635	658	640	13519	49
205	14	0	湖北	2023	物理类	本科一批	628	657	636	10820	28
206	14	0	湖北	2024	物理类	本科一批	620	646	633	15500	46
207	14	0	湖北	2025	物理类	本科一批	628	651	636	10055	12
208	14	0	湖北	2023	历史类	本科一批	616	637	631	11211	45
209	14	0	湖北	2024	历史类	本科一批	602	627	610	12139	13
210	14	0	湖北	2025	历史类	本科一批	608	647	621	11749	18
211	15	0	河南	2023	理科	本科一批	638	660	648	12602	14
212	15	0	河南	2024	理科	本科一批	632	651	639	10748	39
213	15	0	河南	2025	理科	本科一批	640	658	655	12313	6
214	15	0	河南	2023	文科	本科一批	616	656	624	10799	42
215	15	0	河南	2024	文科	本科一批	622	645	627	10320	13
216	15	0	河南	2025	文科	本科一批	625	663	631	12630	35
217	15	0	山东	2023	综合改革	本科一批	636	667	650	12667	11
218	15	0	山东	2024	综合改革	本科一批	636	670	641	11417	47
219	15	0	山东	2025	综合改革	本科一批	638	673	643	10311	8
220	15	0	湖北	2023	物理类	本科一批	632	660	647	13439	11
221	15	0	湖北	2024	物理类	本科一批	632	661	638	12802	10
222	15	0	湖北	2025	物理类	本科一批	627	644	634	12832	22
223	15	0	湖北	2023	历史类	本科一批	612	646	625	13142	23
224	15	0	湖北	2024	历史类	本科一批	616	644	622	13429	49
225	15	0	湖北	2025	历史类	本科一批	605	640	618	16546	18
226	16	0	河南	2023	理科	本科二批	635	657	646	11277	26
227	16	0	河南	2024	理科	本科二批	636	674	642	10938	25
228	16	0	河南	2025	理科	本科二批	635	658	645	10637	14
229	16	0	河南	2023	文科	本科二批	617	634	623	10997	32
230	16	0	河南	2024	文科	本科二批	605	631	612	15918	40
231	16	0	河南	2025	文科	本科二批	603	635	616	15208	26
232	16	0	山东	2023	综合改革	本科二批	615	651	626	13018	8
233	16	0	山东	2024	综合改革	本科二批	621	647	627	13418	41
234	16	0	山东	2025	综合改革	本科二批	628	664	640	10798	19
235	16	0	湖北	2023	物理类	本科二批	610	642	620	13160	12
236	16	0	湖北	2024	物理类	本科二批	615	655	626	13900	40
237	16	0	湖北	2025	物理类	本科二批	607	643	616	14923	6
238	16	0	湖北	2023	历史类	本科二批	597	636	606	13912	26
239	16	0	湖北	2024	历史类	本科二批	603	622	617	11795	47
240	16	0	湖北	2025	历史类	本科二批	604	642	619	12086	6
241	17	0	河南	2023	理科	本科一批	674	695	685	8348	31
242	17	0	河南	2024	理科	本科一批	686	712	695	5992	25
243	17	0	河南	2025	理科	本科一批	674	693	681	8765	44
244	17	0	河南	2023	文科	本科一批	653	676	665	10374	47
245	17	0	河南	2024	文科	本科一批	665	694	676	8451	22
246	17	0	河南	2025	文科	本科一批	658	676	668	10138	32
247	17	0	山东	2023	综合改革	本科一批	665	701	679	7763	36
248	17	0	山东	2024	综合改革	本科一批	678	694	686	7681	30
249	17	0	山东	2025	综合改革	本科一批	663	687	671	6986	13
250	17	0	湖北	2023	物理类	本科一批	665	683	670	7784	36
251	17	0	湖北	2024	物理类	本科一批	670	697	683	6962	50
252	17	0	湖北	2025	物理类	本科一批	664	700	674	8600	9
253	17	0	湖北	2023	历史类	本科一批	654	670	665	10989	6
254	17	0	湖北	2024	历史类	本科一批	656	681	670	10983	32
255	17	0	湖北	2025	历史类	本科一批	654	682	663	10404	12
256	18	0	河南	2023	理科	本科一批	684	709	691	5335	44
257	18	0	河南	2024	理科	本科一批	686	712	692	7249	32
258	18	0	河南	2025	理科	本科一批	675	708	686	6729	38
259	18	0	河南	2023	文科	本科一批	654	678	664	9199	19
260	18	0	河南	2024	文科	本科一批	662	679	675	9782	45
261	18	0	河南	2025	文科	本科一批	655	676	665	9616	27
262	18	0	山东	2023	综合改革	本科一批	666	685	675	7513	17
263	18	0	山东	2024	综合改革	本科一批	667	706	682	8639	9
264	18	0	山东	2025	综合改革	本科一批	667	702	679	9798	34
265	18	0	湖北	2023	物理类	本科一批	671	704	686	8472	45
266	18	0	湖北	2024	物理类	本科一批	667	702	677	9509	14
267	18	0	湖北	2025	物理类	本科一批	671	700	686	6535	24
268	18	0	湖北	2023	历史类	本科一批	650	676	663	10365	9
269	18	0	湖北	2024	历史类	本科一批	651	667	656	9748	28
270	18	0	湖北	2025	历史类	本科一批	651	668	665	8223	43
271	19	0	河南	2023	理科	本科二批	608	641	621	13543	7
272	19	0	河南	2024	理科	本科二批	606	639	621	16756	17
273	19	0	河南	2025	理科	本科二批	602	633	609	15421	8
274	19	0	河南	2023	文科	本科二批	586	611	592	13798	37
275	19	0	河南	2024	文科	本科二批	577	614	589	14110	33
276	19	0	河南	2025	文科	本科二批	588	608	598	16347	28
277	19	0	山东	2023	综合改革	本科二批	591	630	601	15183	48
278	19	0	山东	2024	综合改革	本科二批	583	618	593	18632	9
279	19	0	山东	2025	综合改革	本科二批	592	628	603	13237	23
280	19	0	湖北	2023	物理类	本科二批	585	621	599	17976	14
281	19	0	湖北	2024	物理类	本科二批	587	623	594	13571	27
282	19	0	湖北	2025	物理类	本科二批	586	623	601	19468	30
283	19	0	湖北	2023	历史类	本科二批	566	583	575	19099	40
284	19	0	湖北	2024	历史类	本科二批	574	599	581	18610	47
285	19	0	湖北	2025	历史类	本科二批	578	614	589	14402	37
286	20	0	河南	2023	理科	本科二批	603	627	610	11867	18
287	20	0	河南	2024	理科	本科二批	602	632	610	17450	19
288	20	0	河南	2025	理科	本科二批	596	620	602	13274	37
289	20	0	河南	2023	文科	本科二批	588	613	602	13204	13
290	20	0	河南	2024	文科	本科二批	584	604	598	14304	15
291	20	0	河南	2025	文科	本科二批	586	612	601	13406	20
292	20	0	山东	2023	综合改革	本科二批	596	635	608	16081	19
293	20	0	山东	2024	综合改革	本科二批	589	629	601	14872	17
294	20	0	山东	2025	综合改革	本科二批	593	626	605	16819	34
295	20	0	湖北	2023	物理类	本科二批	586	617	599	18224	31
296	20	0	湖北	2024	物理类	本科二批	582	622	596	18929	13
297	20	0	湖北	2025	物理类	本科二批	585	615	595	13544	40
298	20	0	湖北	2023	历史类	本科二批	565	596	571	20064	23
299	20	0	湖北	2024	历史类	本科二批	564	587	576	20557	37
300	20	0	湖北	2025	历史类	本科二批	566	583	574	20836	33
301	21	0	河南	2023	理科	本科二批	603	631	608	17231	30
302	21	0	河南	2024	理科	本科二批	608	635	614	13484	28
303	21	0	河南	2025	理科	本科二批	599	617	614	12250	26
304	21	0	河南	2023	文科	本科二批	576	600	588	14877	49
305	21	0	河南	2024	文科	本科二批	576	606	588	19201	44
306	21	0	河南	2025	文科	本科二批	572	587	581	20689	18
307	21	0	山东	2023	综合改革	本科二批	586	624	600	16720	38
308	21	0	山东	2024	综合改革	本科二批	595	619	603	13089	24
309	21	0	山东	2025	综合改革	本科二批	585	613	600	13515	44
310	21	0	湖北	2023	物理类	本科二批	591	621	605	13119	39
311	21	0	湖北	2024	物理类	本科二批	577	610	585	18213	50
312	21	0	湖北	2025	物理类	本科二批	581	596	595	15488	27
313	21	0	湖北	2023	历史类	本科二批	569	589	584	18611	47
314	21	0	湖北	2024	历史类	本科二批	564	590	570	18774	38
315	21	0	湖北	2025	历史类	本科二批	578	609	591	19170	6
316	22	0	河南	2023	理科	本科二批	604	620	619	16780	29
317	22	0	河南	2024	理科	本科二批	603	618	613	13251	9
318	22	0	河南	2025	理科	本科二批	603	639	618	13177	11
319	22	0	河南	2023	文科	本科二批	582	608	595	14336	26
320	22	0	河南	2024	文科	本科二批	577	613	589	19586	49
321	22	0	河南	2025	文科	本科二批	587	627	594	17158	9
322	22	0	山东	2023	综合改革	本科二批	596	617	601	12547	17
323	22	0	山东	2024	综合改革	本科二批	583	607	596	15468	30
324	22	0	山东	2025	综合改革	本科二批	597	636	612	13790	17
325	22	0	湖北	2023	物理类	本科二批	586	625	591	15461	46
326	22	0	湖北	2024	物理类	本科二批	587	627	597	14821	32
327	22	0	湖北	2025	物理类	本科二批	589	616	599	17666	16
328	22	0	湖北	2023	历史类	本科二批	577	603	590	18629	22
329	22	0	湖北	2024	历史类	本科二批	564	581	575	20289	43
330	22	0	湖北	2025	历史类	本科二批	567	592	573	18632	10
331	23	0	河南	2023	理科	本科二批	602	626	614	15752	43
332	23	0	河南	2024	理科	本科二批	605	634	615	12566	33
333	23	0	河南	2025	理科	本科二批	593	619	607	17124	32
334	23	0	河南	2023	文科	本科二批	580	620	585	17948	9
335	23	0	河南	2024	文科	本科二批	584	624	599	15692	15
336	23	0	河南	2025	文科	本科二批	572	606	587	15256	33
337	23	0	山东	2023	综合改革	本科二批	583	605	598	14203	28
338	23	0	山东	2024	综合改革	本科二批	593	626	598	14964	43
339	23	0	山东	2025	综合改革	本科二批	586	612	596	17574	33
340	23	0	湖北	2023	物理类	本科二批	579	610	589	17605	30
341	23	0	湖北	2024	物理类	本科二批	587	609	593	17275	6
342	23	0	湖北	2025	物理类	本科二批	582	609	595	16793	12
343	23	0	湖北	2023	历史类	本科二批	570	607	582	19979	18
344	23	0	湖北	2024	历史类	本科二批	571	601	579	19288	12
345	23	0	湖北	2025	历史类	本科二批	566	595	573	20996	50
346	24	0	河南	2023	理科	本科二批	606	646	621	17264	25
347	24	0	河南	2024	理科	本科二批	603	635	616	15932	23
348	24	0	河南	2025	理科	本科二批	601	638	616	16994	16
349	24	0	河南	2023	文科	本科二批	583	601	591	16758	13
350	24	0	河南	2024	文科	本科二批	579	594	589	19086	40
351	24	0	河南	2025	文科	本科二批	583	615	590	16482	44
352	24	0	山东	2023	综合改革	本科二批	584	611	596	13716	38
353	24	0	山东	2024	综合改革	本科二批	595	628	601	17168	13
354	24	0	山东	2025	综合改革	本科二批	592	621	604	16699	48
355	24	0	湖北	2023	物理类	本科二批	593	632	606	14723	45
356	24	0	湖北	2024	物理类	本科二批	582	601	593	18599	37
357	24	0	湖北	2025	物理类	本科二批	578	609	585	19479	24
358	24	0	湖北	2023	历史类	本科二批	567	604	575	15825	27
359	24	0	湖北	2024	历史类	本科二批	578	595	587	19917	17
360	24	0	湖北	2025	历史类	本科二批	570	594	584	15301	39
\.


--
-- Data for Name: zhiyuan_colleges; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_colleges (id, university_id, name, intro) FROM stdin;
\.


--
-- Data for Name: zhiyuan_enrollment_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_enrollment_plans (id, university_id, major_id, province, year, subject_type, batch, plan_count, duration, tuition, remark) FROM stdin;
1	1	0	河南	2024		本科一批	31	4年	5000-6000元/年	
2	1	0	河南	2025		本科一批	73	4年	5000-6000元/年	
3	1	0	山东	2024		本科一批	27	4年	5000-6000元/年	
4	1	0	山东	2025		本科一批	62	4年	5000-6000元/年	
5	1	0	湖北	2024		本科一批	23	4年	5000-6000元/年	
6	1	0	湖北	2025		本科一批	42	4年	5000-6000元/年	
7	2	0	河南	2024		本科一批	88	4年	5000-6000元/年	
8	2	0	河南	2025		本科一批	35	4年	5000-6000元/年	
9	2	0	山东	2024		本科一批	34	4年	5000-6000元/年	
10	2	0	山东	2025		本科一批	25	4年	5000-6000元/年	
11	2	0	湖北	2024		本科一批	60	4年	5000-6000元/年	
12	2	0	湖北	2025		本科一批	37	4年	5000-6000元/年	
13	3	0	河南	2024		本科一批	68	4年	5000-6000元/年	
14	3	0	河南	2025		本科一批	34	4年	5000-6000元/年	
15	3	0	山东	2024		本科一批	53	4年	5000-6000元/年	
16	3	0	山东	2025		本科一批	23	4年	5000-6000元/年	
17	3	0	湖北	2024		本科一批	63	4年	5000-6000元/年	
18	3	0	湖北	2025		本科一批	15	4年	5000-6000元/年	
19	4	0	河南	2024		本科一批	91	4年	5000-6000元/年	
20	4	0	河南	2025		本科一批	96	4年	5000-6000元/年	
21	4	0	山东	2024		本科一批	85	4年	5000-6000元/年	
22	4	0	山东	2025		本科一批	25	4年	5000-6000元/年	
23	4	0	湖北	2024		本科一批	67	4年	5000-6000元/年	
24	4	0	湖北	2025		本科一批	68	4年	5000-6000元/年	
25	5	0	河南	2024		本科一批	94	4年	5000-6000元/年	
26	5	0	河南	2025		本科一批	85	4年	5000-6000元/年	
27	5	0	山东	2024		本科一批	74	4年	5000-6000元/年	
28	5	0	山东	2025		本科一批	27	4年	5000-6000元/年	
29	5	0	湖北	2024		本科一批	73	4年	5000-6000元/年	
30	5	0	湖北	2025		本科一批	10	4年	5000-6000元/年	
31	6	0	河南	2024		本科一批	77	4年	5000-6000元/年	
32	6	0	河南	2025		本科一批	16	4年	5000-6000元/年	
33	6	0	山东	2024		本科一批	80	4年	5000-6000元/年	
34	6	0	山东	2025		本科一批	65	4年	5000-6000元/年	
35	6	0	湖北	2024		本科一批	84	4年	5000-6000元/年	
36	6	0	湖北	2025		本科一批	71	4年	5000-6000元/年	
37	7	0	河南	2024		本科一批	75	4年	5000-6000元/年	
38	7	0	河南	2025		本科一批	32	4年	5000-6000元/年	
39	7	0	山东	2024		本科一批	98	4年	5000-6000元/年	
40	7	0	山东	2025		本科一批	84	4年	5000-6000元/年	
41	7	0	湖北	2024		本科一批	32	4年	5000-6000元/年	
42	7	0	湖北	2025		本科一批	26	4年	5000-6000元/年	
43	8	0	河南	2024		本科一批	23	4年	5000-6000元/年	
44	8	0	河南	2025		本科一批	59	4年	5000-6000元/年	
45	8	0	山东	2024		本科一批	94	4年	5000-6000元/年	
46	8	0	山东	2025		本科一批	86	4年	5000-6000元/年	
47	8	0	湖北	2024		本科一批	87	4年	5000-6000元/年	
48	8	0	湖北	2025		本科一批	51	4年	5000-6000元/年	
49	9	0	河南	2024		本科一批	74	4年	5000-6000元/年	
50	9	0	河南	2025		本科一批	59	4年	5000-6000元/年	
51	9	0	山东	2024		本科一批	63	4年	5000-6000元/年	
52	9	0	山东	2025		本科一批	87	4年	5000-6000元/年	
53	9	0	湖北	2024		本科一批	98	4年	5000-6000元/年	
54	9	0	湖北	2025		本科一批	41	4年	5000-6000元/年	
55	10	0	河南	2024		本科一批	45	4年	5000-6000元/年	
56	10	0	河南	2025		本科一批	60	4年	5000-6000元/年	
57	10	0	山东	2024		本科一批	53	4年	5000-6000元/年	
58	10	0	山东	2025		本科一批	47	4年	5000-6000元/年	
59	10	0	湖北	2024		本科一批	67	4年	5000-6000元/年	
60	10	0	湖北	2025		本科一批	27	4年	5000-6000元/年	
\.


--
-- Data for Name: zhiyuan_majors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_majors (id, university_id, college_id, name, code, degree, duration, subject_category, is_key, subject_requirement, intro, employment_rate, avg_salary, career_directions) FROM stdin;
1	1	0	软件工程	080902	工学学士	4年	工学	t	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
2	1	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
3	1	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
4	1	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
5	1	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
6	2	0	计算机科学与技术	080901	工学学士	4年	工学	f	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
7	2	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
8	2	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
9	3	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
10	3	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
11	3	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
12	3	0	汉语言文学	050101	文学学士	4年	文学	t			87.2	7000	教师,编辑,文案策划,公务员
13	3	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
14	4	0	电子信息工程	080701	工学学士	4年	工学	t	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
15	4	0	机械工程	080201	工学学士	4年	工学	t	物理		91.8	9500	机械设计,制造工程师,自动化工程师
16	4	0	金融学	020301K	经济学学士	4年	经济学	f			89.5	10000	银行,证券,基金,风控
17	4	0	计算机科学与技术	080901	工学学士	4年	工学	f	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
18	5	0	汉语言文学	050101	文学学士	4年	文学	f			87.2	7000	教师,编辑,文案策划,公务员
19	5	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
20	5	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
21	6	0	土木工程	081001	工学学士	4年	工学	t	物理		88	8500	结构设计,施工管理,工程造价
22	6	0	金融学	020301K	经济学学士	4年	经济学	f			89.5	10000	银行,证券,基金,风控
23	6	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
24	6	0	数学与应用数学	070101	理学学士	4年	理学	t	物理		92	11500	数据分析,精算师,教师,科研
25	6	0	计算机科学与技术	080901	工学学士	4年	工学	f	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
26	7	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
27	7	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
28	7	0	汉语言文学	050101	文学学士	4年	文学	f			87.2	7000	教师,编辑,文案策划,公务员
29	8	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
30	8	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
31	8	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
32	9	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
33	9	0	机械工程	080201	工学学士	4年	工学	t	物理		91.8	9500	机械设计,制造工程师,自动化工程师
34	9	0	金融学	020301K	经济学学士	4年	经济学	f			89.5	10000	银行,证券,基金,风控
35	9	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
36	10	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
37	10	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
38	10	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
39	10	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
40	11	0	汉语言文学	050101	文学学士	4年	文学	f			87.2	7000	教师,编辑,文案策划,公务员
41	11	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
42	11	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
43	11	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
44	11	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
45	12	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
46	12	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
47	12	0	汉语言文学	050101	文学学士	4年	文学	t			87.2	7000	教师,编辑,文案策划,公务员
48	12	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
49	13	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
50	13	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
51	13	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
52	13	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
53	13	0	临床医学	100201K	医学学士	5年	医学	t	物理+化学		94	8500	临床医生,医学研究,公共卫生
54	14	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
55	14	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
56	14	0	临床医学	100201K	医学学士	5年	医学	t	物理+化学		94	8500	临床医生,医学研究,公共卫生
57	14	0	法学	030101K	法学学士	4年	法学	t			85.3	8000	律师,法官,法务,公务员
58	14	0	金融学	020301K	经济学学士	4年	经济学	f			89.5	10000	银行,证券,基金,风控
59	15	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
60	15	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
61	15	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
62	15	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
63	15	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
64	16	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
65	16	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
66	16	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
67	17	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
68	17	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
69	17	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
70	17	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
71	18	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
72	18	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
73	18	0	土木工程	081001	工学学士	4年	工学	t	物理		88	8500	结构设计,施工管理,工程造价
74	19	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
75	19	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
76	19	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
77	19	0	临床医学	100201K	医学学士	5年	医学	f	物理+化学		94	8500	临床医生,医学研究,公共卫生
78	19	0	金融学	020301K	经济学学士	4年	经济学	f			89.5	10000	银行,证券,基金,风控
79	20	0	汉语言文学	050101	文学学士	4年	文学	f			87.2	7000	教师,编辑,文案策划,公务员
80	20	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
81	20	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
82	20	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
83	20	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
84	21	0	计算机科学与技术	080901	工学学士	4年	工学	t	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
85	21	0	机械工程	080201	工学学士	4年	工学	f	物理		91.8	9500	机械设计,制造工程师,自动化工程师
86	21	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
87	21	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
88	21	0	电子信息工程	080701	工学学士	4年	工学	t	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
89	22	0	土木工程	081001	工学学士	4年	工学	f	物理		88	8500	结构设计,施工管理,工程造价
90	22	0	汉语言文学	050101	文学学士	4年	文学	t			87.2	7000	教师,编辑,文案策划,公务员
91	22	0	机械工程	080201	工学学士	4年	工学	t	物理		91.8	9500	机械设计,制造工程师,自动化工程师
92	22	0	法学	030101K	法学学士	4年	法学	f			85.3	8000	律师,法官,法务,公务员
93	22	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
94	23	0	计算机科学与技术	080901	工学学士	4年	工学	f	物理		95.2	12500	软件开发,算法工程师,数据工程师,人工智能
95	23	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
96	23	0	土木工程	081001	工学学士	4年	工学	t	物理		88	8500	结构设计,施工管理,工程造价
97	23	0	机械工程	080201	工学学士	4年	工学	t	物理		91.8	9500	机械设计,制造工程师,自动化工程师
98	24	0	汉语言文学	050101	文学学士	4年	文学	f			87.2	7000	教师,编辑,文案策划,公务员
99	24	0	电子信息工程	080701	工学学士	4年	工学	f	物理		93.5	11000	硬件工程师,嵌入式开发,通信工程师
100	24	0	法学	030101K	法学学士	4年	法学	t			85.3	8000	律师,法官,法务,公务员
101	24	0	软件工程	080902	工学学士	4年	工学	f	物理		96.1	13000	软件开发,测试工程师,项目经理,架构师
102	24	0	数学与应用数学	070101	理学学士	4年	理学	f	物理		92	11500	数据分析,精算师,教师,科研
\.


--
-- Data for Name: zhiyuan_province_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_province_rules (id, province, year, mode, batch_count, max_per_batch, subject_mode, description, tips) FROM stdin;
1	河南	2025	平行志愿	2	6	传统文理	本科一批、本科二批各可填6个院校志愿，每个院校可填5个专业	注意院校梯度，建议冲2稳2保2
2	山东	2025	平行志愿	1	96	3+3	普通类常规批可填96个专业+院校志愿	96个志愿按分数优先投档，建议前30个冲、中40个稳、后26个保
3	湖北	2025	平行志愿	1	45	3+1+2	本科批可填45个院校专业组志愿	注意选科要求，物理类和历史类分开填报
\.


--
-- Data for Name: zhiyuan_score_ranks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_score_ranks (id, province, year, subject_type, score, rank, segment_count) FROM stdin;
1	河南	2024	理科	700	97	97
2	河南	2024	理科	699	404	307
3	河南	2024	理科	698	782	378
4	河南	2024	理科	697	918	136
5	河南	2024	理科	696	1271	353
6	河南	2024	理科	695	1618	347
7	河南	2024	理科	694	1746	128
8	河南	2024	理科	693	1883	137
9	河南	2024	理科	692	2270	387
10	河南	2024	理科	691	2639	369
11	河南	2024	理科	690	3057	418
12	河南	2024	理科	689	3416	359
13	河南	2024	理科	688	3638	222
14	河南	2024	理科	687	4119	481
15	河南	2024	理科	686	4457	338
16	河南	2024	理科	685	4528	71
17	河南	2024	理科	684	5000	472
18	河南	2024	理科	683	5492	492
19	河南	2024	理科	682	5556	64
20	河南	2024	理科	681	5647	91
21	河南	2024	理科	680	5720	73
22	河南	2024	理科	679	6098	378
23	河南	2024	理科	678	6542	444
24	河南	2024	理科	677	6887	345
25	河南	2024	理科	676	7072	185
26	河南	2024	理科	675	7455	383
27	河南	2024	理科	674	7612	157
28	河南	2024	理科	673	8054	442
29	河南	2024	理科	672	8396	342
30	河南	2024	理科	671	8659	263
31	河南	2024	理科	670	9025	366
32	河南	2024	理科	669	9402	377
33	河南	2024	理科	668	9467	65
34	河南	2024	理科	667	9771	304
35	河南	2024	理科	666	10142	371
36	河南	2024	理科	665	10471	329
37	河南	2024	理科	664	10669	198
38	河南	2024	理科	663	11047	378
39	河南	2024	理科	662	11251	204
40	河南	2024	理科	661	11548	297
41	河南	2024	理科	660	11723	175
42	河南	2024	理科	659	12185	462
43	河南	2024	理科	658	12648	463
44	河南	2024	理科	657	13048	400
45	河南	2024	理科	656	13305	257
46	河南	2024	理科	655	13507	202
47	河南	2024	理科	654	13789	282
48	河南	2024	理科	653	13876	87
49	河南	2024	理科	652	14278	402
50	河南	2024	理科	651	14358	80
51	河南	2024	理科	650	14488	130
52	河南	2024	理科	649	14763	275
53	河南	2024	理科	648	15025	262
54	河南	2024	理科	647	15322	297
55	河南	2024	理科	646	15609	287
56	河南	2024	理科	645	15763	154
57	河南	2024	理科	644	15987	224
58	河南	2024	理科	643	16347	360
59	河南	2024	理科	642	16470	123
60	河南	2024	理科	641	16680	210
61	河南	2024	理科	640	17171	491
62	河南	2024	理科	639	17588	417
63	河南	2024	理科	638	17801	213
64	河南	2024	理科	637	18226	425
65	河南	2024	理科	636	18716	490
66	河南	2024	理科	635	18942	226
67	河南	2024	理科	634	19196	254
68	河南	2024	理科	633	19312	116
69	河南	2024	理科	632	19751	439
70	河南	2024	理科	631	19990	239
71	河南	2024	理科	630	20303	313
72	河南	2024	理科	629	20640	337
73	河南	2024	理科	628	20744	104
74	河南	2024	理科	627	20957	213
75	河南	2024	理科	626	21130	173
76	河南	2024	理科	625	21418	288
77	河南	2024	理科	624	21530	112
78	河南	2024	理科	623	21716	186
79	河南	2024	理科	622	21996	280
80	河南	2024	理科	621	22172	176
81	河南	2024	理科	620	22294	122
82	河南	2024	理科	619	22393	99
83	河南	2024	理科	618	22468	75
84	河南	2024	理科	617	22666	198
85	河南	2024	理科	616	22912	246
86	河南	2024	理科	615	23404	492
87	河南	2024	理科	614	23769	365
88	河南	2024	理科	613	24033	264
89	河南	2024	理科	612	24210	177
90	河南	2024	理科	611	24703	493
91	河南	2024	理科	610	24834	131
92	河南	2024	理科	609	25300	466
93	河南	2024	理科	608	25517	217
94	河南	2024	理科	607	25862	345
95	河南	2024	理科	606	26281	419
96	河南	2024	理科	605	26491	210
97	河南	2024	理科	604	26638	147
98	河南	2024	理科	603	27078	440
99	河南	2024	理科	602	27209	131
100	河南	2024	理科	601	27514	305
101	河南	2024	理科	600	27827	313
102	河南	2024	理科	599	28116	289
103	河南	2024	理科	598	28421	305
104	河南	2024	理科	597	28921	500
105	河南	2024	理科	596	29128	207
106	河南	2024	理科	595	29432	304
107	河南	2024	理科	594	29493	61
108	河南	2024	理科	593	29589	96
109	河南	2024	理科	592	29840	251
110	河南	2024	理科	591	30148	308
111	河南	2024	理科	590	30432	284
112	河南	2024	理科	589	30605	173
113	河南	2024	理科	588	30765	160
114	河南	2024	理科	587	31113	348
115	河南	2024	理科	586	31343	230
116	河南	2024	理科	585	31417	74
117	河南	2024	理科	584	31492	75
118	河南	2024	理科	583	31686	194
119	河南	2024	理科	582	31989	303
120	河南	2024	理科	581	32344	355
121	河南	2024	理科	580	32825	481
122	河南	2024	理科	579	33209	384
123	河南	2024	理科	578	33603	394
124	河南	2024	理科	577	33893	290
125	河南	2024	理科	576	34089	196
126	河南	2024	理科	575	34413	324
127	河南	2024	理科	574	34467	54
128	河南	2024	理科	573	34950	483
129	河南	2024	理科	572	35055	105
130	河南	2024	理科	571	35325	270
131	河南	2024	理科	570	35443	118
132	河南	2024	理科	569	35628	185
133	河南	2024	理科	568	36050	422
134	河南	2024	理科	567	36287	237
135	河南	2024	理科	566	36728	441
136	河南	2024	理科	565	36984	256
137	河南	2024	理科	564	37221	237
138	河南	2024	理科	563	37294	73
139	河南	2024	理科	562	37549	255
140	河南	2024	理科	561	37625	76
141	河南	2024	理科	560	37966	341
142	河南	2024	理科	559	38303	337
143	河南	2024	理科	558	38452	149
144	河南	2024	理科	557	38687	235
145	河南	2024	理科	556	39020	333
146	河南	2024	理科	555	39217	197
147	河南	2024	理科	554	39304	87
148	河南	2024	理科	553	39551	247
149	河南	2024	理科	552	39859	308
150	河南	2024	理科	551	40139	280
151	河南	2024	理科	550	40580	441
152	河南	2024	理科	549	40911	331
153	河南	2024	理科	548	41104	193
154	河南	2024	理科	547	41576	472
155	河南	2024	理科	546	41945	369
156	河南	2024	理科	545	42343	398
157	河南	2024	理科	544	42705	362
158	河南	2024	理科	543	42815	110
159	河南	2024	理科	542	42930	115
160	河南	2024	理科	541	43029	99
161	河南	2024	理科	540	43280	251
162	河南	2024	理科	539	43521	241
163	河南	2024	理科	538	43977	456
164	河南	2024	理科	537	44200	223
165	河南	2024	理科	536	44535	335
166	河南	2024	理科	535	44772	237
167	河南	2024	理科	534	45208	436
168	河南	2024	理科	533	45331	123
169	河南	2024	理科	532	45482	151
170	河南	2024	理科	531	45840	358
171	河南	2024	理科	530	46150	310
172	河南	2024	理科	529	46405	255
173	河南	2024	理科	528	46711	306
174	河南	2024	理科	527	46781	70
175	河南	2024	理科	526	46854	73
176	河南	2024	理科	525	46923	69
177	河南	2024	理科	524	47043	120
178	河南	2024	理科	523	47458	415
179	河南	2024	理科	522	47678	220
180	河南	2024	理科	521	48139	461
181	河南	2024	理科	520	48431	292
182	河南	2024	理科	519	48746	315
183	河南	2024	理科	518	49029	283
184	河南	2024	理科	517	49155	126
185	河南	2024	理科	516	49515	360
186	河南	2024	理科	515	49828	313
187	河南	2024	理科	514	49949	121
188	河南	2024	理科	513	50166	217
189	河南	2024	理科	512	50529	363
190	河南	2024	理科	511	50742	213
191	河南	2024	理科	510	50875	133
192	河南	2024	理科	509	51126	251
193	河南	2024	理科	508	51491	365
194	河南	2024	理科	507	51919	428
195	河南	2024	理科	506	52400	481
196	河南	2024	理科	505	52603	203
197	河南	2024	理科	504	52956	353
198	河南	2024	理科	503	53178	222
199	河南	2024	理科	502	53487	309
200	河南	2024	理科	501	53961	474
201	河南	2024	理科	500	55204	1243
202	河南	2024	理科	499	56494	1290
203	河南	2024	理科	498	57697	1203
204	河南	2024	理科	497	59049	1352
205	河南	2024	理科	496	59862	813
206	河南	2024	理科	495	61034	1172
207	河南	2024	理科	494	61268	234
208	河南	2024	理科	493	62222	954
209	河南	2024	理科	492	63100	878
210	河南	2024	理科	491	63524	424
211	河南	2024	理科	490	64577	1053
212	河南	2024	理科	489	65972	1395
213	河南	2024	理科	488	66802	830
214	河南	2024	理科	487	68290	1488
215	河南	2024	理科	486	68544	254
216	河南	2024	理科	485	69966	1422
217	河南	2024	理科	484	71137	1171
218	河南	2024	理科	483	71880	743
219	河南	2024	理科	482	73264	1384
220	河南	2024	理科	481	74646	1382
221	河南	2024	理科	480	75312	666
222	河南	2024	理科	479	75617	305
223	河南	2024	理科	478	77012	1395
224	河南	2024	理科	477	78195	1183
225	河南	2024	理科	476	78744	549
226	河南	2024	理科	475	80017	1273
227	河南	2024	理科	474	81505	1488
228	河南	2024	理科	473	82974	1469
229	河南	2024	理科	472	83952	978
230	河南	2024	理科	471	84454	502
231	河南	2024	理科	470	85150	696
232	河南	2024	理科	469	85414	264
233	河南	2024	理科	468	86786	1372
234	河南	2024	理科	467	87211	425
235	河南	2024	理科	466	87801	590
236	河南	2024	理科	465	88039	238
237	河南	2024	理科	464	89142	1103
238	河南	2024	理科	463	89984	842
239	河南	2024	理科	462	91041	1057
240	河南	2024	理科	461	91551	510
241	河南	2024	理科	460	92596	1045
242	河南	2024	理科	459	93213	617
243	河南	2024	理科	458	94253	1040
244	河南	2024	理科	457	95480	1227
245	河南	2024	理科	456	96932	1452
246	河南	2024	理科	455	98097	1165
247	河南	2024	理科	454	98424	327
248	河南	2024	理科	453	98906	482
249	河南	2024	理科	452	100168	1262
250	河南	2024	理科	451	100792	624
251	河南	2024	理科	450	102140	1348
252	河南	2024	理科	449	103005	865
253	河南	2024	理科	448	104184	1179
254	河南	2024	理科	447	105460	1276
255	河南	2024	理科	446	106431	971
256	河南	2024	理科	445	107273	842
257	河南	2024	理科	444	107827	554
258	河南	2024	理科	443	108968	1141
259	河南	2024	理科	442	110259	1291
260	河南	2024	理科	441	111160	901
261	河南	2024	理科	440	112478	1318
262	河南	2024	理科	439	113403	925
263	河南	2024	理科	438	114144	741
264	河南	2024	理科	437	115593	1449
265	河南	2024	理科	436	116784	1191
266	河南	2024	理科	435	117377	593
267	河南	2024	理科	434	118081	704
268	河南	2024	理科	433	118852	771
269	河南	2024	理科	432	120194	1342
270	河南	2024	理科	431	121005	811
271	河南	2024	理科	430	121665	660
272	河南	2024	理科	429	122474	809
273	河南	2024	理科	428	123265	791
274	河南	2024	理科	427	123889	624
275	河南	2024	理科	426	125090	1201
276	河南	2024	理科	425	125939	849
277	河南	2024	理科	424	127121	1182
278	河南	2024	理科	423	128035	914
279	河南	2024	理科	422	129382	1347
280	河南	2024	理科	421	130142	760
281	河南	2024	理科	420	130931	789
282	河南	2024	理科	419	131380	449
283	河南	2024	理科	418	132754	1374
284	河南	2024	理科	417	134066	1312
285	河南	2024	理科	416	135043	977
286	河南	2024	理科	415	136051	1008
287	河南	2024	理科	414	136957	906
288	河南	2024	理科	413	137456	499
289	河南	2024	理科	412	138250	794
290	河南	2024	理科	411	138536	286
291	河南	2024	理科	410	139325	789
292	河南	2024	理科	409	139686	361
293	河南	2024	理科	408	140595	909
294	河南	2024	理科	407	141700	1105
295	河南	2024	理科	406	142425	725
296	河南	2024	理科	405	143606	1181
297	河南	2024	理科	404	144244	638
298	河南	2024	理科	403	144857	613
299	河南	2024	理科	402	146160	1303
300	河南	2024	理科	401	146915	755
301	河南	2024	理科	400	148266	1351
302	河南	2025	理科	700	406	406
303	河南	2025	理科	699	595	189
304	河南	2025	理科	698	715	120
305	河南	2025	理科	697	820	105
306	河南	2025	理科	696	1185	365
307	河南	2025	理科	695	1614	429
308	河南	2025	理科	694	1964	350
309	河南	2025	理科	693	2136	172
310	河南	2025	理科	692	2310	174
311	河南	2025	理科	691	2385	75
312	河南	2025	理科	690	2777	392
313	河南	2025	理科	689	3098	321
314	河南	2025	理科	688	3263	165
315	河南	2025	理科	687	3639	376
316	河南	2025	理科	686	3808	169
317	河南	2025	理科	685	3884	76
318	河南	2025	理科	684	3985	101
319	河南	2025	理科	683	4246	261
320	河南	2025	理科	682	4465	219
321	河南	2025	理科	681	4882	417
322	河南	2025	理科	680	5173	291
323	河南	2025	理科	679	5274	101
324	河南	2025	理科	678	5672	398
325	河南	2025	理科	677	6116	444
326	河南	2025	理科	676	6236	120
327	河南	2025	理科	675	6288	52
328	河南	2025	理科	674	6619	331
329	河南	2025	理科	673	6749	130
330	河南	2025	理科	672	7007	258
331	河南	2025	理科	671	7391	384
332	河南	2025	理科	670	7891	500
333	河南	2025	理科	669	8390	499
334	河南	2025	理科	668	8683	293
335	河南	2025	理科	667	8977	294
336	河南	2025	理科	666	9360	383
337	河南	2025	理科	665	9512	152
338	河南	2025	理科	664	9949	437
339	河南	2025	理科	663	10146	197
340	河南	2025	理科	662	10360	214
341	河南	2025	理科	661	10556	196
342	河南	2025	理科	660	10936	380
343	河南	2025	理科	659	11016	80
344	河南	2025	理科	658	11459	443
345	河南	2025	理科	657	11554	95
346	河南	2025	理科	656	11937	383
347	河南	2025	理科	655	12280	343
348	河南	2025	理科	654	12448	168
349	河南	2025	理科	653	12771	323
350	河南	2025	理科	652	13199	428
351	河南	2025	理科	651	13619	420
352	河南	2025	理科	650	14104	485
353	河南	2025	理科	649	14173	69
354	河南	2025	理科	648	14312	139
355	河南	2025	理科	647	14575	263
356	河南	2025	理科	646	15053	478
357	河南	2025	理科	645	15193	140
358	河南	2025	理科	644	15261	68
359	河南	2025	理科	643	15739	478
360	河南	2025	理科	642	15992	253
361	河南	2025	理科	641	16445	453
362	河南	2025	理科	640	16748	303
363	河南	2025	理科	639	16893	145
364	河南	2025	理科	638	17326	433
365	河南	2025	理科	637	17822	496
366	河南	2025	理科	636	18020	198
367	河南	2025	理科	635	18518	498
368	河南	2025	理科	634	18587	69
369	河南	2025	理科	633	18641	54
370	河南	2025	理科	632	18843	202
371	河南	2025	理科	631	19183	340
372	河南	2025	理科	630	19541	358
373	河南	2025	理科	629	19645	104
374	河南	2025	理科	628	19866	221
375	河南	2025	理科	627	20061	195
376	河南	2025	理科	626	20343	282
377	河南	2025	理科	625	20721	378
378	河南	2025	理科	624	21049	328
379	河南	2025	理科	623	21367	318
380	河南	2025	理科	622	21669	302
381	河南	2025	理科	621	21787	118
382	河南	2025	理科	620	22272	485
383	河南	2025	理科	619	22580	308
384	河南	2025	理科	618	22869	289
385	河南	2025	理科	617	23058	189
386	河南	2025	理科	616	23206	148
387	河南	2025	理科	615	23670	464
388	河南	2025	理科	614	23777	107
389	河南	2025	理科	613	23996	219
390	河南	2025	理科	612	24129	133
391	河南	2025	理科	611	24553	424
392	河南	2025	理科	610	24837	284
393	河南	2025	理科	609	25218	381
394	河南	2025	理科	608	25399	181
395	河南	2025	理科	607	25816	417
396	河南	2025	理科	606	25961	145
397	河南	2025	理科	605	26018	57
398	河南	2025	理科	604	26445	427
399	河南	2025	理科	603	26667	222
400	河南	2025	理科	602	27121	454
401	河南	2025	理科	601	27322	201
402	河南	2025	理科	600	27662	340
403	河南	2025	理科	599	28057	395
404	河南	2025	理科	598	28494	437
405	河南	2025	理科	597	28642	148
406	河南	2025	理科	596	28781	139
407	河南	2025	理科	595	29143	362
408	河南	2025	理科	594	29631	488
409	河南	2025	理科	593	30008	377
410	河南	2025	理科	592	30265	257
411	河南	2025	理科	591	30738	473
412	河南	2025	理科	590	31006	268
413	河南	2025	理科	589	31319	313
414	河南	2025	理科	588	31536	217
415	河南	2025	理科	587	31630	94
416	河南	2025	理科	586	31885	255
417	河南	2025	理科	585	32277	392
418	河南	2025	理科	584	32375	98
419	河南	2025	理科	583	32519	144
420	河南	2025	理科	582	32640	121
421	河南	2025	理科	581	32934	294
422	河南	2025	理科	580	33149	215
423	河南	2025	理科	579	33326	177
424	河南	2025	理科	578	33379	53
425	河南	2025	理科	577	33562	183
426	河南	2025	理科	576	33808	246
427	河南	2025	理科	575	33978	170
428	河南	2025	理科	574	34256	278
429	河南	2025	理科	573	34691	435
430	河南	2025	理科	572	34877	186
431	河南	2025	理科	571	35095	218
432	河南	2025	理科	570	35299	204
433	河南	2025	理科	569	35647	348
434	河南	2025	理科	568	36067	420
435	河南	2025	理科	567	36410	343
436	河南	2025	理科	566	36465	55
437	河南	2025	理科	565	36648	183
438	河南	2025	理科	564	37032	384
439	河南	2025	理科	563	37266	234
440	河南	2025	理科	562	37670	404
441	河南	2025	理科	561	37840	170
442	河南	2025	理科	560	37921	81
443	河南	2025	理科	559	38312	391
444	河南	2025	理科	558	38422	110
445	河南	2025	理科	557	38710	288
446	河南	2025	理科	556	38917	207
447	河南	2025	理科	555	39048	131
448	河南	2025	理科	554	39305	257
449	河南	2025	理科	553	39706	401
450	河南	2025	理科	552	40013	307
451	河南	2025	理科	551	40423	410
452	河南	2025	理科	550	40867	444
453	河南	2025	理科	549	41076	209
454	河南	2025	理科	548	41479	403
455	河南	2025	理科	547	41589	110
456	河南	2025	理科	546	41966	377
457	河南	2025	理科	545	42167	201
458	河南	2025	理科	544	42405	238
459	河南	2025	理科	543	42769	364
460	河南	2025	理科	542	42932	163
461	河南	2025	理科	541	43094	162
462	河南	2025	理科	540	43212	118
463	河南	2025	理科	539	43506	294
464	河南	2025	理科	538	43634	128
465	河南	2025	理科	537	43916	282
466	河南	2025	理科	536	44348	432
467	河南	2025	理科	535	44708	360
468	河南	2025	理科	534	44949	241
469	河南	2025	理科	533	45211	262
470	河南	2025	理科	532	45620	409
471	河南	2025	理科	531	45951	331
472	河南	2025	理科	530	46242	291
473	河南	2025	理科	529	46679	437
474	河南	2025	理科	528	47004	325
475	河南	2025	理科	527	47464	460
476	河南	2025	理科	526	47854	390
477	河南	2025	理科	525	48326	472
478	河南	2025	理科	524	48487	161
479	河南	2025	理科	523	48927	440
480	河南	2025	理科	522	49103	176
481	河南	2025	理科	521	49501	398
482	河南	2025	理科	520	49937	436
483	河南	2025	理科	519	50292	355
484	河南	2025	理科	518	50789	497
485	河南	2025	理科	517	51242	453
486	河南	2025	理科	516	51333	91
487	河南	2025	理科	515	51652	319
488	河南	2025	理科	514	51930	278
489	河南	2025	理科	513	52250	320
490	河南	2025	理科	512	52660	410
491	河南	2025	理科	511	52895	235
492	河南	2025	理科	510	52984	89
493	河南	2025	理科	509	53322	338
494	河南	2025	理科	508	53429	107
495	河南	2025	理科	507	53510	81
496	河南	2025	理科	506	53984	474
497	河南	2025	理科	505	54314	330
498	河南	2025	理科	504	54622	308
499	河南	2025	理科	503	54775	153
500	河南	2025	理科	502	55118	343
501	河南	2025	理科	501	55442	324
502	河南	2025	理科	500	55948	506
503	河南	2025	理科	499	56484	536
504	河南	2025	理科	498	57355	871
505	河南	2025	理科	497	58620	1265
506	河南	2025	理科	496	59724	1104
507	河南	2025	理科	495	60162	438
508	河南	2025	理科	494	60782	620
509	河南	2025	理科	493	62176	1394
510	河南	2025	理科	492	63377	1201
511	河南	2025	理科	491	63763	386
512	河南	2025	理科	490	65008	1245
513	河南	2025	理科	489	66120	1112
514	河南	2025	理科	488	66433	313
515	河南	2025	理科	487	67561	1128
516	河南	2025	理科	486	68031	470
517	河南	2025	理科	485	69282	1251
518	河南	2025	理科	484	70332	1050
519	河南	2025	理科	483	71467	1135
520	河南	2025	理科	482	72821	1354
521	河南	2025	理科	481	73139	318
522	河南	2025	理科	480	74483	1344
523	河南	2025	理科	479	75629	1146
524	河南	2025	理科	478	76460	831
525	河南	2025	理科	477	76704	244
526	河南	2025	理科	476	77714	1010
527	河南	2025	理科	475	78435	721
528	河南	2025	理科	474	78641	206
529	河南	2025	理科	473	79287	646
530	河南	2025	理科	472	80671	1384
531	河南	2025	理科	471	81020	349
532	河南	2025	理科	470	81312	292
533	河南	2025	理科	469	82379	1067
534	河南	2025	理科	468	83284	905
535	河南	2025	理科	467	83614	330
536	河南	2025	理科	466	84922	1308
537	河南	2025	理科	465	85245	323
538	河南	2025	理科	464	85586	341
539	河南	2025	理科	463	86752	1166
540	河南	2025	理科	462	87016	264
541	河南	2025	理科	461	87803	787
542	河南	2025	理科	460	88840	1037
543	河南	2025	理科	459	89408	568
544	河南	2025	理科	458	89885	477
545	河南	2025	理科	457	90945	1060
546	河南	2025	理科	456	91911	966
547	河南	2025	理科	455	92894	983
548	河南	2025	理科	454	94012	1118
549	河南	2025	理科	453	94985	973
550	河南	2025	理科	452	95954	969
551	河南	2025	理科	451	96318	364
552	河南	2025	理科	450	97622	1304
553	河南	2025	理科	449	98094	472
554	河南	2025	理科	448	99006	912
555	河南	2025	理科	447	99448	442
556	河南	2025	理科	446	100013	565
557	河南	2025	理科	445	101313	1300
558	河南	2025	理科	444	102317	1004
559	河南	2025	理科	443	103600	1283
560	河南	2025	理科	442	104060	460
561	河南	2025	理科	441	104716	656
562	河南	2025	理科	440	104923	207
563	河南	2025	理科	439	105169	246
564	河南	2025	理科	438	105980	811
565	河南	2025	理科	437	107128	1148
566	河南	2025	理科	436	108443	1315
567	河南	2025	理科	435	109511	1068
568	河南	2025	理科	434	110800	1289
569	河南	2025	理科	433	111776	976
570	河南	2025	理科	432	112446	670
571	河南	2025	理科	431	113152	706
572	河南	2025	理科	430	114295	1143
573	河南	2025	理科	429	115203	908
574	河南	2025	理科	428	115720	517
575	河南	2025	理科	427	116484	764
576	河南	2025	理科	426	117070	586
577	河南	2025	理科	425	117501	431
578	河南	2025	理科	424	117766	265
579	河南	2025	理科	423	118824	1058
580	河南	2025	理科	422	120283	1459
581	河南	2025	理科	421	120515	232
582	河南	2025	理科	420	121207	692
583	河南	2025	理科	419	121829	622
584	河南	2025	理科	418	122166	337
585	河南	2025	理科	417	122572	406
586	河南	2025	理科	416	123988	1416
587	河南	2025	理科	415	124256	268
588	河南	2025	理科	414	125370	1114
589	河南	2025	理科	413	126794	1424
590	河南	2025	理科	412	127093	299
591	河南	2025	理科	411	127794	701
592	河南	2025	理科	410	128084	290
593	河南	2025	理科	409	129107	1023
594	河南	2025	理科	408	130205	1098
595	河南	2025	理科	407	130884	679
596	河南	2025	理科	406	132189	1305
597	河南	2025	理科	405	132833	644
598	河南	2025	理科	404	133148	315
599	河南	2025	理科	403	133634	486
600	河南	2025	理科	402	134865	1231
601	河南	2025	理科	401	135657	792
602	河南	2025	理科	400	136336	679
603	河南	2024	文科	700	467	467
604	河南	2024	文科	699	891	424
605	河南	2024	文科	698	1235	344
606	河南	2024	文科	697	1448	213
607	河南	2024	文科	696	1793	345
608	河南	2024	文科	695	2149	356
609	河南	2024	文科	694	2594	445
610	河南	2024	文科	693	2988	394
611	河南	2024	文科	692	3457	469
612	河南	2024	文科	691	3671	214
613	河南	2024	文科	690	3842	171
614	河南	2024	文科	689	4046	204
615	河南	2024	文科	688	4544	498
616	河南	2024	文科	687	4667	123
617	河南	2024	文科	686	5055	388
618	河南	2024	文科	685	5371	316
619	河南	2024	文科	684	5534	163
620	河南	2024	文科	683	5795	261
621	河南	2024	文科	682	5998	203
622	河南	2024	文科	681	6188	190
623	河南	2024	文科	680	6269	81
624	河南	2024	文科	679	6604	335
625	河南	2024	文科	678	6956	352
626	河南	2024	文科	677	7456	500
627	河南	2024	文科	676	7882	426
628	河南	2024	文科	675	8021	139
629	河南	2024	文科	674	8391	370
630	河南	2024	文科	673	8788	397
631	河南	2024	文科	672	9056	268
632	河南	2024	文科	671	9390	334
633	河南	2024	文科	670	9693	303
634	河南	2024	文科	669	9767	74
635	河南	2024	文科	668	9993	226
636	河南	2024	文科	667	10372	379
637	河南	2024	文科	666	10765	393
638	河南	2024	文科	665	11010	245
639	河南	2024	文科	664	11462	452
640	河南	2024	文科	663	11780	318
641	河南	2024	文科	662	11993	213
642	河南	2024	文科	661	12399	406
643	河南	2024	文科	660	12662	263
644	河南	2024	文科	659	12921	259
645	河南	2024	文科	658	13047	126
646	河南	2024	文科	657	13250	203
647	河南	2024	文科	656	13492	242
648	河南	2024	文科	655	13636	144
649	河南	2024	文科	654	14072	436
650	河南	2024	文科	653	14397	325
651	河南	2024	文科	652	14689	292
652	河南	2024	文科	651	14862	173
653	河南	2024	文科	650	15346	484
654	河南	2024	文科	649	15511	165
655	河南	2024	文科	648	15714	203
656	河南	2024	文科	647	16203	489
657	河南	2024	文科	646	16615	412
658	河南	2024	文科	645	16738	123
659	河南	2024	文科	644	17200	462
660	河南	2024	文科	643	17487	287
661	河南	2024	文科	642	17566	79
662	河南	2024	文科	641	17903	337
663	河南	2024	文科	640	18164	261
664	河南	2024	文科	639	18427	263
665	河南	2024	文科	638	18762	335
666	河南	2024	文科	637	19083	321
667	河南	2024	文科	636	19201	118
668	河南	2024	文科	635	19449	248
669	河南	2024	文科	634	19623	174
670	河南	2024	文科	633	19803	180
671	河南	2024	文科	632	19957	154
672	河南	2024	文科	631	20176	219
673	河南	2024	文科	630	20557	381
674	河南	2024	文科	629	20647	90
675	河南	2024	文科	628	20927	280
676	河南	2024	文科	627	21410	483
677	河南	2024	文科	626	21649	239
678	河南	2024	文科	625	21746	97
679	河南	2024	文科	624	22070	324
680	河南	2024	文科	623	22490	420
681	河南	2024	文科	622	22964	474
682	河南	2024	文科	621	23111	147
683	河南	2024	文科	620	23187	76
684	河南	2024	文科	619	23374	187
685	河南	2024	文科	618	23617	243
686	河南	2024	文科	617	24011	394
687	河南	2024	文科	616	24370	359
688	河南	2024	文科	615	24728	358
689	河南	2024	文科	614	24798	70
690	河南	2024	文科	613	25295	497
691	河南	2024	文科	612	25382	87
692	河南	2024	文科	611	25528	146
693	河南	2024	文科	610	25989	461
694	河南	2024	文科	609	26428	439
695	河南	2024	文科	608	26778	350
696	河南	2024	文科	607	27198	420
697	河南	2024	文科	606	27591	393
698	河南	2024	文科	605	27927	336
699	河南	2024	文科	604	28088	161
700	河南	2024	文科	603	28383	295
701	河南	2024	文科	602	28539	156
702	河南	2024	文科	601	29034	495
703	河南	2024	文科	600	29254	220
704	河南	2024	文科	599	29459	205
705	河南	2024	文科	598	29516	57
706	河南	2024	文科	597	29674	158
707	河南	2024	文科	596	29821	147
708	河南	2024	文科	595	30250	429
709	河南	2024	文科	594	30360	110
710	河南	2024	文科	593	30792	432
711	河南	2024	文科	592	31228	436
712	河南	2024	文科	591	31523	295
713	河南	2024	文科	590	31697	174
714	河南	2024	文科	589	32103	406
715	河南	2024	文科	588	32462	359
716	河南	2024	文科	587	32872	410
717	河南	2024	文科	586	33026	154
718	河南	2024	文科	585	33279	253
719	河南	2024	文科	584	33451	172
720	河南	2024	文科	583	33783	332
721	河南	2024	文科	582	33997	214
722	河南	2024	文科	581	34444	447
723	河南	2024	文科	580	34638	194
724	河南	2024	文科	579	34882	244
725	河南	2024	文科	578	35170	288
726	河南	2024	文科	577	35493	323
727	河南	2024	文科	576	35875	382
728	河南	2024	文科	575	36108	233
729	河南	2024	文科	574	36315	207
730	河南	2024	文科	573	36498	183
731	河南	2024	文科	572	36732	234
732	河南	2024	文科	571	37044	312
733	河南	2024	文科	570	37348	304
734	河南	2024	文科	569	37636	288
735	河南	2024	文科	568	37736	100
736	河南	2024	文科	567	38197	461
737	河南	2024	文科	566	38616	419
738	河南	2024	文科	565	38906	290
739	河南	2024	文科	564	39345	439
740	河南	2024	文科	563	39824	479
741	河南	2024	文科	562	40037	213
742	河南	2024	文科	561	40191	154
743	河南	2024	文科	560	40430	239
744	河南	2024	文科	559	40640	210
745	河南	2024	文科	558	40901	261
746	河南	2024	文科	557	40974	73
747	河南	2024	文科	556	41312	338
748	河南	2024	文科	555	41804	492
749	河南	2024	文科	554	41967	163
750	河南	2024	文科	553	42396	429
751	河南	2024	文科	552	42520	124
752	河南	2024	文科	551	42578	58
753	河南	2024	文科	550	42761	183
754	河南	2024	文科	549	43094	333
755	河南	2024	文科	548	43443	349
756	河南	2024	文科	547	43789	346
757	河南	2024	文科	546	44207	418
758	河南	2024	文科	545	44470	263
759	河南	2024	文科	544	44671	201
760	河南	2024	文科	543	44799	128
761	河南	2024	文科	542	44949	150
762	河南	2024	文科	541	45167	218
763	河南	2024	文科	540	45334	167
764	河南	2024	文科	539	45578	244
765	河南	2024	文科	538	45919	341
766	河南	2024	文科	537	46395	476
767	河南	2024	文科	536	46570	175
768	河南	2024	文科	535	46875	305
769	河南	2024	文科	534	47206	331
770	河南	2024	文科	533	47591	385
771	河南	2024	文科	532	47991	400
772	河南	2024	文科	531	48213	222
773	河南	2024	文科	530	48394	181
774	河南	2024	文科	529	48834	440
775	河南	2024	文科	528	49304	470
776	河南	2024	文科	527	49604	300
777	河南	2024	文科	526	50024	420
778	河南	2024	文科	525	50402	378
779	河南	2024	文科	524	50830	428
780	河南	2024	文科	523	51131	301
781	河南	2024	文科	522	51416	285
782	河南	2024	文科	521	51552	136
783	河南	2024	文科	520	51977	425
784	河南	2024	文科	519	52434	457
785	河南	2024	文科	518	52664	230
786	河南	2024	文科	517	52800	136
787	河南	2024	文科	516	52921	121
788	河南	2024	文科	515	53339	418
789	河南	2024	文科	514	53668	329
790	河南	2024	文科	513	53968	300
791	河南	2024	文科	512	54112	144
792	河南	2024	文科	511	54439	327
793	河南	2024	文科	510	54817	378
794	河南	2024	文科	509	54897	80
795	河南	2024	文科	508	55215	318
796	河南	2024	文科	507	55282	67
797	河南	2024	文科	506	55761	479
798	河南	2024	文科	505	56244	483
799	河南	2024	文科	504	56332	88
800	河南	2024	文科	503	56800	468
801	河南	2024	文科	502	57192	392
802	河南	2024	文科	501	57266	74
803	河南	2024	文科	500	57479	213
804	河南	2024	文科	499	58523	1044
805	河南	2024	文科	498	59004	481
806	河南	2024	文科	497	60495	1491
807	河南	2024	文科	496	61168	673
808	河南	2024	文科	495	61507	339
809	河南	2024	文科	494	62016	509
810	河南	2024	文科	493	62234	218
811	河南	2024	文科	492	62881	647
812	河南	2024	文科	491	64116	1235
813	河南	2024	文科	490	65249	1133
814	河南	2024	文科	489	66213	964
815	河南	2024	文科	488	66536	323
816	河南	2024	文科	487	68001	1465
817	河南	2024	文科	486	69463	1462
818	河南	2024	文科	485	70652	1189
819	河南	2024	文科	484	71851	1199
820	河南	2024	文科	483	72083	232
821	河南	2024	文科	482	72296	213
822	河南	2024	文科	481	73585	1289
823	河南	2024	文科	480	74914	1329
824	河南	2024	文科	479	75956	1042
825	河南	2024	文科	478	76180	224
826	河南	2024	文科	477	76414	234
827	河南	2024	文科	476	77698	1284
828	河南	2024	文科	475	78460	762
829	河南	2024	文科	474	79757	1297
830	河南	2024	文科	473	80544	787
831	河南	2024	文科	472	80779	235
832	河南	2024	文科	471	82007	1228
833	河南	2024	文科	470	83088	1081
834	河南	2024	文科	469	83655	567
835	河南	2024	文科	468	84074	419
836	河南	2024	文科	467	84471	397
837	河南	2024	文科	466	85744	1273
838	河南	2024	文科	465	86248	504
839	河南	2024	文科	464	86941	693
840	河南	2024	文科	463	87534	593
841	河南	2024	文科	462	89003	1469
842	河南	2024	文科	461	90281	1278
843	河南	2024	文科	460	90997	716
844	河南	2024	文科	459	91922	925
845	河南	2024	文科	458	92669	747
846	河南	2024	文科	457	93681	1012
847	河南	2024	文科	456	94042	361
848	河南	2024	文科	455	95006	964
849	河南	2024	文科	454	96037	1031
850	河南	2024	文科	453	97177	1140
851	河南	2024	文科	452	98534	1357
852	河南	2024	文科	451	99232	698
853	河南	2024	文科	450	99894	662
854	河南	2024	文科	449	100708	814
855	河南	2024	文科	448	101073	365
856	河南	2024	文科	447	101337	264
857	河南	2024	文科	446	101728	391
858	河南	2024	文科	445	102758	1030
859	河南	2024	文科	444	103734	976
860	河南	2024	文科	443	104706	972
861	河南	2024	文科	442	106037	1331
862	河南	2024	文科	441	107211	1174
863	河南	2024	文科	440	107525	314
864	河南	2024	文科	439	107744	219
865	河南	2024	文科	438	108294	550
866	河南	2024	文科	437	108663	369
867	河南	2024	文科	436	109886	1223
868	河南	2024	文科	435	110974	1088
869	河南	2024	文科	434	111852	878
870	河南	2024	文科	433	113210	1358
871	河南	2024	文科	432	113605	395
872	河南	2024	文科	431	114886	1281
873	河南	2024	文科	430	115173	287
874	河南	2024	文科	429	115843	670
875	河南	2024	文科	428	116475	632
876	河南	2024	文科	427	117835	1360
877	河南	2024	文科	426	119008	1173
878	河南	2024	文科	425	119763	755
879	河南	2024	文科	424	120058	295
880	河南	2024	文科	423	120410	352
881	河南	2024	文科	422	121184	774
882	河南	2024	文科	421	122496	1312
883	河南	2024	文科	420	123850	1354
884	河南	2024	文科	419	124117	267
885	河南	2024	文科	418	124684	567
886	河南	2024	文科	417	125528	844
887	河南	2024	文科	416	125760	232
888	河南	2024	文科	415	126384	624
889	河南	2024	文科	414	127786	1402
890	河南	2024	文科	413	128281	495
891	河南	2024	文科	412	129296	1015
892	河南	2024	文科	411	129653	357
893	河南	2024	文科	410	130465	812
894	河南	2024	文科	409	130997	532
895	河南	2024	文科	408	132351	1354
896	河南	2024	文科	407	133043	692
897	河南	2024	文科	406	134403	1360
898	河南	2024	文科	405	135399	996
899	河南	2024	文科	404	136706	1307
900	河南	2024	文科	403	137585	879
901	河南	2024	文科	402	138571	986
902	河南	2024	文科	401	139057	486
903	河南	2024	文科	400	139417	360
904	河南	2025	文科	700	306	306
905	河南	2025	文科	699	737	431
906	河南	2025	文科	698	964	227
907	河南	2025	文科	697	1041	77
908	河南	2025	文科	696	1141	100
909	河南	2025	文科	695	1414	273
910	河南	2025	文科	694	1582	168
911	河南	2025	文科	693	2061	479
912	河南	2025	文科	692	2149	88
913	河南	2025	文科	691	2373	224
914	河南	2025	文科	690	2732	359
915	河南	2025	文科	689	3175	443
916	河南	2025	文科	688	3539	364
917	河南	2025	文科	687	3893	354
918	河南	2025	文科	686	4146	253
919	河南	2025	文科	685	4592	446
920	河南	2025	文科	684	4809	217
921	河南	2025	文科	683	4874	65
922	河南	2025	文科	682	5248	374
923	河南	2025	文科	681	5437	189
924	河南	2025	文科	680	5888	451
925	河南	2025	文科	679	6168	280
926	河南	2025	文科	678	6469	301
927	河南	2025	文科	677	6635	166
928	河南	2025	文科	676	6867	232
929	河南	2025	文科	675	7200	333
930	河南	2025	文科	674	7442	242
931	河南	2025	文科	673	7713	271
932	河南	2025	文科	672	7858	145
933	河南	2025	文科	671	8256	398
934	河南	2025	文科	670	8605	349
935	河南	2025	文科	669	8993	388
936	河南	2025	文科	668	9237	244
937	河南	2025	文科	667	9330	93
938	河南	2025	文科	666	9775	445
939	河南	2025	文科	665	10141	366
940	河南	2025	文科	664	10342	201
941	河南	2025	文科	663	10800	458
942	河南	2025	文科	662	10976	176
943	河南	2025	文科	661	11391	415
944	河南	2025	文科	660	11478	87
945	河南	2025	文科	659	11570	92
946	河南	2025	文科	658	11757	187
947	河南	2025	文科	657	11885	128
948	河南	2025	文科	656	12129	244
949	河南	2025	文科	655	12543	414
950	河南	2025	文科	654	12994	451
951	河南	2025	文科	653	13368	374
952	河南	2025	文科	652	13496	128
953	河南	2025	文科	651	13924	428
954	河南	2025	文科	650	14173	249
955	河南	2025	文科	649	14385	212
956	河南	2025	文科	648	14619	234
957	河南	2025	文科	647	14723	104
958	河南	2025	文科	646	14819	96
959	河南	2025	文科	645	14871	52
960	河南	2025	文科	644	15078	207
961	河南	2025	文科	643	15355	277
962	河南	2025	文科	642	15589	234
963	河南	2025	文科	641	16028	439
964	河南	2025	文科	640	16216	188
965	河南	2025	文科	639	16318	102
966	河南	2025	文科	638	16435	117
967	河南	2025	文科	637	16529	94
968	河南	2025	文科	636	16674	145
969	河南	2025	文科	635	16944	270
970	河南	2025	文科	634	17223	279
971	河南	2025	文科	633	17558	335
972	河南	2025	文科	632	17892	334
973	河南	2025	文科	631	18204	312
974	河南	2025	文科	630	18462	258
975	河南	2025	文科	629	18564	102
976	河南	2025	文科	628	18627	63
977	河南	2025	文科	627	18722	95
978	河南	2025	文科	626	18953	231
979	河南	2025	文科	625	19286	333
980	河南	2025	文科	624	19383	97
981	河南	2025	文科	623	19738	355
982	河南	2025	文科	622	20094	356
983	河南	2025	文科	621	20545	451
984	河南	2025	文科	620	20761	216
985	河南	2025	文科	619	21253	492
986	河南	2025	文科	618	21500	247
987	河南	2025	文科	617	21556	56
988	河南	2025	文科	616	21755	199
989	河南	2025	文科	615	22016	261
990	河南	2025	文科	614	22264	248
991	河南	2025	文科	613	22712	448
992	河南	2025	文科	612	22805	93
993	河南	2025	文科	611	23226	421
994	河南	2025	文科	610	23562	336
995	河南	2025	文科	609	23736	174
996	河南	2025	文科	608	24078	342
997	河南	2025	文科	607	24394	316
998	河南	2025	文科	606	24530	136
999	河南	2025	文科	605	24930	400
1000	河南	2025	文科	604	25174	244
1001	河南	2025	文科	603	25310	136
1002	河南	2025	文科	602	25431	121
1003	河南	2025	文科	601	25618	187
1004	河南	2025	文科	600	25822	204
1005	河南	2025	文科	599	26009	187
1006	河南	2025	文科	598	26311	302
1007	河南	2025	文科	597	26435	124
1008	河南	2025	文科	596	26517	82
1009	河南	2025	文科	595	26652	135
1010	河南	2025	文科	594	26924	272
1011	河南	2025	文科	593	27115	191
1012	河南	2025	文科	592	27380	265
1013	河南	2025	文科	591	27583	203
1014	河南	2025	文科	590	27880	297
1015	河南	2025	文科	589	28330	450
1016	河南	2025	文科	588	28419	89
1017	河南	2025	文科	587	28653	234
1018	河南	2025	文科	586	28831	178
1019	河南	2025	文科	585	29007	176
1020	河南	2025	文科	584	29426	419
1021	河南	2025	文科	583	29796	370
1022	河南	2025	文科	582	30099	303
1023	河南	2025	文科	581	30453	354
1024	河南	2025	文科	580	30818	365
1025	河南	2025	文科	579	30968	150
1026	河南	2025	文科	578	31252	284
1027	河南	2025	文科	577	31356	104
1028	河南	2025	文科	576	31475	119
1029	河南	2025	文科	575	31680	205
1030	河南	2025	文科	574	31733	53
1031	河南	2025	文科	573	31985	252
1032	河南	2025	文科	572	32205	220
1033	河南	2025	文科	571	32685	480
1034	河南	2025	文科	570	33052	367
1035	河南	2025	文科	569	33296	244
1036	河南	2025	文科	568	33757	461
1037	河南	2025	文科	567	34248	491
1038	河南	2025	文科	566	34466	218
1039	河南	2025	文科	565	34741	275
1040	河南	2025	文科	564	34962	221
1041	河南	2025	文科	563	35232	270
1042	河南	2025	文科	562	35699	467
1043	河南	2025	文科	561	36170	471
1044	河南	2025	文科	560	36660	490
1045	河南	2025	文科	559	37043	383
1046	河南	2025	文科	558	37397	354
1047	河南	2025	文科	557	37516	119
1048	河南	2025	文科	556	37719	203
1049	河南	2025	文科	555	37933	214
1050	河南	2025	文科	554	38291	358
1051	河南	2025	文科	553	38696	405
1052	河南	2025	文科	552	38848	152
1053	河南	2025	文科	551	39143	295
1054	河南	2025	文科	550	39353	210
1055	河南	2025	文科	549	39493	140
1056	河南	2025	文科	548	39746	253
1057	河南	2025	文科	547	39959	213
1058	河南	2025	文科	546	40158	199
1059	河南	2025	文科	545	40584	426
1060	河南	2025	文科	544	40989	405
1061	河南	2025	文科	543	41363	374
1062	河南	2025	文科	542	41664	301
1063	河南	2025	文科	541	42008	344
1064	河南	2025	文科	540	42458	450
1065	河南	2025	文科	539	42632	174
1066	河南	2025	文科	538	42848	216
1067	河南	2025	文科	537	43090	242
1068	河南	2025	文科	536	43283	193
1069	河南	2025	文科	535	43751	468
1070	河南	2025	文科	534	44203	452
1071	河南	2025	文科	533	44454	251
1072	河南	2025	文科	532	44690	236
1073	河南	2025	文科	531	44798	108
1074	河南	2025	文科	530	45136	338
1075	河南	2025	文科	529	45288	152
1076	河南	2025	文科	528	45641	353
1077	河南	2025	文科	527	45970	329
1078	河南	2025	文科	526	46112	142
1079	河南	2025	文科	525	46511	399
1080	河南	2025	文科	524	46954	443
1081	河南	2025	文科	523	47285	331
1082	河南	2025	文科	522	47348	63
1083	河南	2025	文科	521	47770	422
1084	河南	2025	文科	520	48056	286
1085	河南	2025	文科	519	48468	412
1086	河南	2025	文科	518	48625	157
1087	河南	2025	文科	517	48899	274
1088	河南	2025	文科	516	49357	458
1089	河南	2025	文科	515	49556	199
1090	河南	2025	文科	514	50031	475
1091	河南	2025	文科	513	50435	404
1092	河南	2025	文科	512	50520	85
1093	河南	2025	文科	511	50989	469
1094	河南	2025	文科	510	51473	484
1095	河南	2025	文科	509	51930	457
1096	河南	2025	文科	508	52387	457
1097	河南	2025	文科	507	52646	259
1098	河南	2025	文科	506	53040	394
1099	河南	2025	文科	505	53345	305
1100	河南	2025	文科	504	53466	121
1101	河南	2025	文科	503	53840	374
1102	河南	2025	文科	502	54045	205
1103	河南	2025	文科	501	54218	173
1104	河南	2025	文科	500	54935	717
1105	河南	2025	文科	499	55450	515
1106	河南	2025	文科	498	56516	1066
1107	河南	2025	文科	497	57488	972
1108	河南	2025	文科	496	57839	351
1109	河南	2025	文科	495	58958	1119
1110	河南	2025	文科	494	60382	1424
1111	河南	2025	文科	493	61563	1181
1112	河南	2025	文科	492	62955	1392
1113	河南	2025	文科	491	63975	1020
1114	河南	2025	文科	490	65269	1294
1115	河南	2025	文科	489	66506	1237
1116	河南	2025	文科	488	67562	1056
1117	河南	2025	文科	487	68875	1313
1118	河南	2025	文科	486	69150	275
1119	河南	2025	文科	485	70086	936
1120	河南	2025	文科	484	71385	1299
1121	河南	2025	文科	483	72801	1416
1122	河南	2025	文科	482	73175	374
1123	河南	2025	文科	481	73598	423
1124	河南	2025	文科	480	74306	708
1125	河南	2025	文科	479	75233	927
1126	河南	2025	文科	478	75773	540
1127	河南	2025	文科	477	77227	1454
1128	河南	2025	文科	476	77517	290
1129	河南	2025	文科	475	78870	1353
1130	河南	2025	文科	474	79888	1018
1131	河南	2025	文科	473	80767	879
1132	河南	2025	文科	472	81848	1081
1133	河南	2025	文科	471	82264	416
1134	河南	2025	文科	470	82485	221
1135	河南	2025	文科	469	82886	401
1136	河南	2025	文科	468	83615	729
1137	河南	2025	文科	467	84269	654
1138	河南	2025	文科	466	85514	1245
1139	河南	2025	文科	465	86776	1262
1140	河南	2025	文科	464	88118	1342
1141	河南	2025	文科	463	89506	1388
1142	河南	2025	文科	462	90884	1378
1143	河南	2025	文科	461	91536	652
1144	河南	2025	文科	460	92648	1112
1145	河南	2025	文科	459	93614	966
1146	河南	2025	文科	458	94615	1001
1147	河南	2025	文科	457	95763	1148
1148	河南	2025	文科	456	97168	1405
1149	河南	2025	文科	455	98392	1224
1150	河南	2025	文科	454	98900	508
1151	河南	2025	文科	453	99806	906
1152	河南	2025	文科	452	100056	250
1153	河南	2025	文科	451	101244	1188
1154	河南	2025	文科	450	101658	414
1155	河南	2025	文科	449	102463	805
1156	河南	2025	文科	448	103514	1051
1157	河南	2025	文科	447	103889	375
1158	河南	2025	文科	446	104326	437
1159	河南	2025	文科	445	104816	490
1160	河南	2025	文科	444	105729	913
1161	河南	2025	文科	443	106567	838
1162	河南	2025	文科	442	107469	902
1163	河南	2025	文科	441	108601	1132
1164	河南	2025	文科	440	109224	623
1165	河南	2025	文科	439	110491	1267
1166	河南	2025	文科	438	111680	1189
1167	河南	2025	文科	437	112593	913
1168	河南	2025	文科	436	113768	1175
1169	河南	2025	文科	435	114167	399
1170	河南	2025	文科	434	115264	1097
1171	河南	2025	文科	433	116390	1126
1172	河南	2025	文科	432	117243	853
1173	河南	2025	文科	431	117580	337
1174	河南	2025	文科	430	118394	814
1175	河南	2025	文科	429	118685	291
1176	河南	2025	文科	428	119120	435
1177	河南	2025	文科	427	119366	246
1178	河南	2025	文科	426	120268	902
1179	河南	2025	文科	425	120691	423
1180	河南	2025	文科	424	121227	536
1181	河南	2025	文科	423	121926	699
1182	河南	2025	文科	422	123182	1256
1183	河南	2025	文科	421	123739	557
1184	河南	2025	文科	420	125069	1330
1185	河南	2025	文科	419	125596	527
1186	河南	2025	文科	418	126473	877
1187	河南	2025	文科	417	127819	1346
1188	河南	2025	文科	416	128892	1073
1189	河南	2025	文科	415	130038	1146
1190	河南	2025	文科	414	130712	674
1191	河南	2025	文科	413	131741	1029
1192	河南	2025	文科	412	133230	1489
1193	河南	2025	文科	411	133807	577
1194	河南	2025	文科	410	134388	581
1195	河南	2025	文科	409	135473	1085
1196	河南	2025	文科	408	136483	1010
1197	河南	2025	文科	407	136742	259
1198	河南	2025	文科	406	138199	1457
1199	河南	2025	文科	405	138803	604
1200	河南	2025	文科	404	139923	1120
1201	河南	2025	文科	403	141335	1412
1202	河南	2025	文科	402	142414	1079
1203	河南	2025	文科	401	143410	996
1204	河南	2025	文科	400	143619	209
1205	山东	2024	综合改革	700	410	410
1206	山东	2024	综合改革	699	569	159
1207	山东	2024	综合改革	698	724	155
1208	山东	2024	综合改革	697	916	192
1209	山东	2024	综合改革	696	1351	435
1210	山东	2024	综合改革	695	1761	410
1211	山东	2024	综合改革	694	2225	464
1212	山东	2024	综合改革	693	2682	457
1213	山东	2024	综合改革	692	2764	82
1214	山东	2024	综合改革	691	3109	345
1215	山东	2024	综合改革	690	3211	102
1216	山东	2024	综合改革	689	3670	459
1217	山东	2024	综合改革	688	4166	496
1218	山东	2024	综合改革	687	4490	324
1219	山东	2024	综合改革	686	4635	145
1220	山东	2024	综合改革	685	4872	237
1221	山东	2024	综合改革	684	5088	216
1222	山东	2024	综合改革	683	5238	150
1223	山东	2024	综合改革	682	5522	284
1224	山东	2024	综合改革	681	5630	108
1225	山东	2024	综合改革	680	5814	184
1226	山东	2024	综合改革	679	6207	393
1227	山东	2024	综合改革	678	6698	491
1228	山东	2024	综合改革	677	6998	300
1229	山东	2024	综合改革	676	7318	320
1230	山东	2024	综合改革	675	7695	377
1231	山东	2024	综合改革	674	7905	210
1232	山东	2024	综合改革	673	8260	355
1233	山东	2024	综合改革	672	8508	248
1234	山东	2024	综合改革	671	8870	362
1235	山东	2024	综合改革	670	9120	250
1236	山东	2024	综合改革	669	9470	350
1237	山东	2024	综合改革	668	9578	108
1238	山东	2024	综合改革	667	9806	228
1239	山东	2024	综合改革	666	10036	230
1240	山东	2024	综合改革	665	10518	482
1241	山东	2024	综合改革	664	10802	284
1242	山东	2024	综合改革	663	11168	366
1243	山东	2024	综合改革	662	11306	138
1244	山东	2024	综合改革	661	11772	466
1245	山东	2024	综合改革	660	12166	394
1246	山东	2024	综合改革	659	12577	411
1247	山东	2024	综合改革	658	13036	459
1248	山东	2024	综合改革	657	13238	202
1249	山东	2024	综合改革	656	13602	364
1250	山东	2024	综合改革	655	13954	352
1251	山东	2024	综合改革	654	14047	93
1252	山东	2024	综合改革	653	14441	394
1253	山东	2024	综合改革	652	14559	118
1254	山东	2024	综合改革	651	14769	210
1255	山东	2024	综合改革	650	14879	110
1256	山东	2024	综合改革	649	15051	172
1257	山东	2024	综合改革	648	15257	206
1258	山东	2024	综合改革	647	15366	109
1259	山东	2024	综合改革	646	15509	143
1260	山东	2024	综合改革	645	15750	241
1261	山东	2024	综合改革	644	16155	405
1262	山东	2024	综合改革	643	16277	122
1263	山东	2024	综合改革	642	16588	311
1264	山东	2024	综合改革	641	16836	248
1265	山东	2024	综合改革	640	17100	264
1266	山东	2024	综合改革	639	17455	355
1267	山东	2024	综合改革	638	17575	120
1268	山东	2024	综合改革	637	17919	344
1269	山东	2024	综合改革	636	18165	246
1270	山东	2024	综合改革	635	18431	266
1271	山东	2024	综合改革	634	18576	145
1272	山东	2024	综合改革	633	18875	299
1273	山东	2024	综合改革	632	19250	375
1274	山东	2024	综合改革	631	19575	325
1275	山东	2024	综合改革	630	19980	405
1276	山东	2024	综合改革	629	20360	380
1277	山东	2024	综合改革	628	20498	138
1278	山东	2024	综合改革	627	20832	334
1279	山东	2024	综合改革	626	20967	135
1280	山东	2024	综合改革	625	21267	300
1281	山东	2024	综合改革	624	21464	197
1282	山东	2024	综合改革	623	21585	121
1283	山东	2024	综合改革	622	21730	145
1284	山东	2024	综合改革	621	21941	211
1285	山东	2024	综合改革	620	22422	481
1286	山东	2024	综合改革	619	22702	280
1287	山东	2024	综合改革	618	23069	367
1288	山东	2024	综合改革	617	23146	77
1289	山东	2024	综合改革	616	23639	493
1290	山东	2024	综合改革	615	23872	233
1291	山东	2024	综合改革	614	23926	54
1292	山东	2024	综合改革	613	24224	298
1293	山东	2024	综合改革	612	24343	119
1294	山东	2024	综合改革	611	24492	149
1295	山东	2024	综合改革	610	24959	467
1296	山东	2024	综合改革	609	25205	246
1297	山东	2024	综合改革	608	25542	337
1298	山东	2024	综合改革	607	25850	308
1299	山东	2024	综合改革	606	26234	384
1300	山东	2024	综合改革	605	26537	303
1301	山东	2024	综合改革	604	26796	259
1302	山东	2024	综合改革	603	27196	400
1303	山东	2024	综合改革	602	27497	301
1304	山东	2024	综合改革	601	27759	262
1305	山东	2024	综合改革	600	28172	413
1306	山东	2024	综合改革	599	28652	480
1307	山东	2024	综合改革	598	28929	277
1847	湖北	2024	物理类	660	11234	189
1308	山东	2024	综合改革	597	29229	300
1309	山东	2024	综合改革	596	29364	135
1310	山东	2024	综合改革	595	29456	92
1311	山东	2024	综合改革	594	29795	339
1312	山东	2024	综合改革	593	29860	65
1313	山东	2024	综合改革	592	30317	457
1314	山东	2024	综合改革	591	30756	439
1315	山东	2024	综合改革	590	30918	162
1316	山东	2024	综合改革	589	31117	199
1317	山东	2024	综合改革	588	31183	66
1318	山东	2024	综合改革	587	31373	190
1319	山东	2024	综合改革	586	31538	165
1320	山东	2024	综合改革	585	31863	325
1321	山东	2024	综合改革	584	32060	197
1322	山东	2024	综合改革	583	32196	136
1323	山东	2024	综合改革	582	32645	449
1324	山东	2024	综合改革	581	32929	284
1325	山东	2024	综合改革	580	33268	339
1326	山东	2024	综合改革	579	33698	430
1327	山东	2024	综合改革	578	34143	445
1328	山东	2024	综合改革	577	34585	442
1329	山东	2024	综合改革	576	34888	303
1330	山东	2024	综合改革	575	35219	331
1331	山东	2024	综合改革	574	35530	311
1332	山东	2024	综合改革	573	35637	107
1333	山东	2024	综合改革	572	35980	343
1334	山东	2024	综合改革	571	36088	108
1335	山东	2024	综合改革	570	36275	187
1336	山东	2024	综合改革	569	36721	446
1337	山东	2024	综合改革	568	37049	328
1338	山东	2024	综合改革	567	37520	471
1339	山东	2024	综合改革	566	37757	237
1340	山东	2024	综合改革	565	38084	327
1341	山东	2024	综合改革	564	38555	471
1342	山东	2024	综合改革	563	38992	437
1343	山东	2024	综合改革	562	39063	71
1344	山东	2024	综合改革	561	39502	439
1345	山东	2024	综合改革	560	39920	418
1346	山东	2024	综合改革	559	40195	275
1347	山东	2024	综合改革	558	40524	329
1348	山东	2024	综合改革	557	40685	161
1349	山东	2024	综合改革	556	40952	267
1350	山东	2024	综合改革	555	41054	102
1351	山东	2024	综合改革	554	41480	426
1352	山东	2024	综合改革	553	41954	474
1353	山东	2024	综合改革	552	42338	384
1354	山东	2024	综合改革	551	42772	434
1355	山东	2024	综合改革	550	42948	176
1356	山东	2024	综合改革	549	43150	202
1357	山东	2024	综合改革	548	43647	497
1358	山东	2024	综合改革	547	43713	66
1359	山东	2024	综合改革	546	43993	280
1360	山东	2024	综合改革	545	44177	184
1361	山东	2024	综合改革	544	44405	228
1362	山东	2024	综合改革	543	44896	491
1363	山东	2024	综合改革	542	45364	468
1364	山东	2024	综合改革	541	45458	94
1365	山东	2024	综合改革	540	45732	274
1366	山东	2024	综合改革	539	46225	493
1367	山东	2024	综合改革	538	46335	110
1368	山东	2024	综合改革	537	46782	447
1369	山东	2024	综合改革	536	47247	465
1370	山东	2024	综合改革	535	47418	171
1371	山东	2024	综合改革	534	47575	157
1372	山东	2024	综合改革	533	48040	465
1373	山东	2024	综合改革	532	48467	427
1374	山东	2024	综合改革	531	48818	351
1375	山东	2024	综合改革	530	49220	402
1376	山东	2024	综合改革	529	49449	229
1377	山东	2024	综合改革	528	49939	490
1378	山东	2024	综合改革	527	50352	413
1379	山东	2024	综合改革	526	50714	362
1380	山东	2024	综合改革	525	51087	373
1381	山东	2024	综合改革	524	51356	269
1382	山东	2024	综合改革	523	51490	134
1383	山东	2024	综合改革	522	51855	365
1384	山东	2024	综合改革	521	51976	121
1385	山东	2024	综合改革	520	52427	451
1386	山东	2024	综合改革	519	52582	155
1387	山东	2024	综合改革	518	53048	466
1388	山东	2024	综合改革	517	53203	155
1389	山东	2024	综合改革	516	53665	462
1390	山东	2024	综合改革	515	53745	80
1391	山东	2024	综合改革	514	54086	341
1392	山东	2024	综合改革	513	54315	229
1393	山东	2024	综合改革	512	54637	322
1394	山东	2024	综合改革	511	54830	193
1395	山东	2024	综合改革	510	55185	355
1396	山东	2024	综合改革	509	55510	325
1397	山东	2024	综合改革	508	55646	136
1398	山东	2024	综合改革	507	55861	215
1399	山东	2024	综合改革	506	56271	410
1400	山东	2024	综合改革	505	56470	199
1401	山东	2024	综合改革	504	56668	198
1402	山东	2024	综合改革	503	57011	343
1403	山东	2024	综合改革	502	57197	186
1404	山东	2024	综合改革	501	57686	489
1405	山东	2024	综合改革	500	58939	1253
1406	山东	2024	综合改革	499	59334	395
1407	山东	2024	综合改革	498	59811	477
1408	山东	2024	综合改革	497	60853	1042
1409	山东	2024	综合改革	496	61174	321
1410	山东	2024	综合改革	495	61941	767
1411	山东	2024	综合改革	494	62400	459
1412	山东	2024	综合改革	493	62871	471
1413	山东	2024	综合改革	492	63582	711
1414	山东	2024	综合改革	491	64081	499
1415	山东	2024	综合改革	490	64940	859
1416	山东	2024	综合改革	489	65646	706
1417	山东	2024	综合改革	488	66650	1004
1418	山东	2024	综合改革	487	67852	1202
1419	山东	2024	综合改革	486	68343	491
1420	山东	2024	综合改革	485	69725	1382
1421	山东	2024	综合改革	484	71220	1495
1422	山东	2024	综合改革	483	71970	750
1423	山东	2024	综合改革	482	73455	1485
1424	山东	2024	综合改革	481	74503	1048
1425	山东	2024	综合改革	480	75471	968
1426	山东	2024	综合改革	479	76596	1125
1427	山东	2024	综合改革	478	76950	354
1428	山东	2024	综合改革	477	78447	1497
1429	山东	2024	综合改革	476	78837	390
1430	山东	2024	综合改革	475	79862	1025
1431	山东	2024	综合改革	474	81117	1255
1432	山东	2024	综合改革	473	81886	769
1433	山东	2024	综合改革	472	82841	955
1434	山东	2024	综合改革	471	83972	1131
1435	山东	2024	综合改革	470	85171	1199
1436	山东	2024	综合改革	469	86041	870
1437	山东	2024	综合改革	468	87432	1391
1438	山东	2024	综合改革	467	87637	205
1439	山东	2024	综合改革	466	88027	390
1440	山东	2024	综合改革	465	89165	1138
1441	山东	2024	综合改革	464	90665	1500
1442	山东	2024	综合改革	463	91598	933
1443	山东	2024	综合改革	462	91927	329
1444	山东	2024	综合改革	461	93221	1294
1445	山东	2024	综合改革	460	94235	1014
1446	山东	2024	综合改革	459	94881	646
1447	山东	2024	综合改革	458	95960	1079
1448	山东	2024	综合改革	457	96593	633
1449	山东	2024	综合改革	456	97806	1213
1450	山东	2024	综合改革	455	98555	749
1451	山东	2024	综合改革	454	99416	861
1452	山东	2024	综合改革	453	100196	780
1453	山东	2024	综合改革	452	101087	891
1454	山东	2024	综合改革	451	102407	1320
1455	山东	2024	综合改革	450	103790	1383
1456	山东	2024	综合改革	449	104257	467
1457	山东	2024	综合改革	448	105616	1359
1458	山东	2024	综合改革	447	106809	1193
1459	山东	2024	综合改革	446	107712	903
1460	山东	2024	综合改革	445	108011	299
1461	山东	2024	综合改革	444	108305	294
1462	山东	2024	综合改革	443	108708	403
1463	山东	2024	综合改革	442	110190	1482
1464	山东	2024	综合改革	441	111331	1141
1465	山东	2024	综合改革	440	111564	233
1466	山东	2024	综合改革	439	112018	454
1467	山东	2024	综合改革	438	112541	523
1468	山东	2024	综合改革	437	113644	1103
1469	山东	2024	综合改革	436	114778	1134
1470	山东	2024	综合改革	435	114979	201
1471	山东	2024	综合改革	434	116055	1076
1472	山东	2024	综合改革	433	116669	614
1473	山东	2024	综合改革	432	117139	470
1474	山东	2024	综合改革	431	117957	818
1475	山东	2024	综合改革	430	118482	525
1476	山东	2024	综合改革	429	119243	761
1477	山东	2024	综合改革	428	119634	391
1478	山东	2024	综合改革	427	120572	938
1479	山东	2024	综合改革	426	121284	712
1480	山东	2024	综合改革	425	121652	368
1481	山东	2024	综合改革	424	122613	961
1482	山东	2024	综合改革	423	123151	538
1483	山东	2024	综合改革	422	123457	306
1484	山东	2024	综合改革	421	124468	1011
1485	山东	2024	综合改革	420	125949	1481
1486	山东	2024	综合改革	419	126774	825
1487	山东	2024	综合改革	418	127453	679
1488	山东	2024	综合改革	417	128532	1079
1489	山东	2024	综合改革	416	128918	386
1490	山东	2024	综合改革	415	129312	394
1491	山东	2024	综合改革	414	129514	202
1492	山东	2024	综合改革	413	130151	637
1493	山东	2024	综合改革	412	131327	1176
1494	山东	2024	综合改革	411	131686	359
1495	山东	2024	综合改革	410	132157	471
1496	山东	2024	综合改革	409	133572	1415
1497	山东	2024	综合改革	408	134235	663
1498	山东	2024	综合改革	407	135498	1263
1499	山东	2024	综合改革	406	136609	1111
1500	山东	2024	综合改革	405	136828	219
1501	山东	2024	综合改革	404	137044	216
1502	山东	2024	综合改革	403	137947	903
1503	山东	2024	综合改革	402	138393	446
1504	山东	2024	综合改革	401	139457	1064
1505	山东	2024	综合改革	400	139927	470
1506	山东	2025	综合改革	700	294	294
1507	山东	2025	综合改革	699	380	86
1508	山东	2025	综合改革	698	547	167
1509	山东	2025	综合改革	697	793	246
1510	山东	2025	综合改革	696	888	95
1511	山东	2025	综合改革	695	1312	424
1512	山东	2025	综合改革	694	1774	462
1513	山东	2025	综合改革	693	1876	102
1514	山东	2025	综合改革	692	1978	102
1515	山东	2025	综合改革	691	2188	210
1516	山东	2025	综合改革	690	2426	238
1517	山东	2025	综合改革	689	2629	203
1518	山东	2025	综合改革	688	2749	120
1519	山东	2025	综合改革	687	2994	245
1520	山东	2025	综合改革	686	3440	446
1521	山东	2025	综合改革	685	3906	466
1522	山东	2025	综合改革	684	4341	435
1523	山东	2025	综合改革	683	4838	497
1524	山东	2025	综合改革	682	4956	118
1525	山东	2025	综合改革	681	5334	378
1526	山东	2025	综合改革	680	5730	396
1527	山东	2025	综合改革	679	5853	123
1528	山东	2025	综合改革	678	5938	85
1529	山东	2025	综合改革	677	6259	321
1530	山东	2025	综合改革	676	6597	338
1531	山东	2025	综合改革	675	6651	54
1532	山东	2025	综合改革	674	7013	362
1533	山东	2025	综合改革	673	7395	382
1534	山东	2025	综合改革	672	7529	134
1535	山东	2025	综合改革	671	7804	275
1536	山东	2025	综合改革	670	8033	229
1537	山东	2025	综合改革	669	8452	419
1538	山东	2025	综合改革	668	8611	159
1539	山东	2025	综合改革	667	8982	371
1540	山东	2025	综合改革	666	9415	433
1541	山东	2025	综合改革	665	9542	127
1542	山东	2025	综合改革	664	9802	260
1543	山东	2025	综合改革	663	10167	365
1544	山东	2025	综合改革	662	10568	401
1545	山东	2025	综合改革	661	10844	276
1546	山东	2025	综合改革	660	11334	490
1547	山东	2025	综合改革	659	11495	161
1548	山东	2025	综合改革	658	11589	94
1549	山东	2025	综合改革	657	11690	101
1550	山东	2025	综合改革	656	11811	121
1551	山东	2025	综合改革	655	12246	435
1552	山东	2025	综合改革	654	12359	113
1553	山东	2025	综合改革	653	12710	351
1554	山东	2025	综合改革	652	13133	423
1555	山东	2025	综合改革	651	13379	246
1556	山东	2025	综合改革	650	13608	229
1557	山东	2025	综合改革	649	13877	269
1558	山东	2025	综合改革	648	14088	211
1559	山东	2025	综合改革	647	14543	455
1560	山东	2025	综合改革	646	14664	121
1561	山东	2025	综合改革	645	14840	176
1562	山东	2025	综合改革	644	15031	191
1563	山东	2025	综合改革	643	15411	380
1564	山东	2025	综合改革	642	15504	93
1565	山东	2025	综合改革	641	15681	177
1566	山东	2025	综合改革	640	16014	333
1567	山东	2025	综合改革	639	16371	357
1568	山东	2025	综合改革	638	16728	357
1569	山东	2025	综合改革	637	17147	419
1570	山东	2025	综合改革	636	17508	361
1571	山东	2025	综合改革	635	17703	195
1572	山东	2025	综合改革	634	18151	448
1573	山东	2025	综合改革	633	18554	403
1574	山东	2025	综合改革	632	18617	63
1575	山东	2025	综合改革	631	19101	484
1576	山东	2025	综合改革	630	19584	483
1577	山东	2025	综合改革	629	19971	387
1578	山东	2025	综合改革	628	20469	498
1579	山东	2025	综合改革	627	20673	204
1580	山东	2025	综合改革	626	20828	155
1581	山东	2025	综合改革	625	21143	315
1582	山东	2025	综合改革	624	21503	360
1583	山东	2025	综合改革	623	21813	310
1584	山东	2025	综合改革	622	21959	146
1585	山东	2025	综合改革	621	22391	432
1586	山东	2025	综合改革	620	22641	250
1587	山东	2025	综合改革	619	22842	201
1588	山东	2025	综合改革	618	23222	380
1589	山东	2025	综合改革	617	23299	77
1590	山东	2025	综合改革	616	23750	451
1591	山东	2025	综合改革	615	24206	456
1592	山东	2025	综合改革	614	24378	172
1593	山东	2025	综合改革	613	24681	303
1594	山东	2025	综合改革	612	24928	247
1595	山东	2025	综合改革	611	25035	107
1596	山东	2025	综合改革	610	25208	173
1597	山东	2025	综合改革	609	25513	305
1598	山东	2025	综合改革	608	25889	376
1599	山东	2025	综合改革	607	26243	354
1600	山东	2025	综合改革	606	26329	86
1601	山东	2025	综合改革	605	26649	320
1602	山东	2025	综合改革	604	26705	56
1603	山东	2025	综合改革	603	26939	234
1604	山东	2025	综合改革	602	27151	212
1605	山东	2025	综合改革	601	27268	117
1606	山东	2025	综合改革	600	27516	248
1607	山东	2025	综合改革	599	28006	490
1608	山东	2025	综合改革	598	28485	479
1609	山东	2025	综合改革	597	28826	341
1610	山东	2025	综合改革	596	29091	265
1611	山东	2025	综合改革	595	29328	237
1612	山东	2025	综合改革	594	29657	329
1613	山东	2025	综合改革	593	30056	399
1614	山东	2025	综合改革	592	30194	138
1615	山东	2025	综合改革	591	30634	440
1616	山东	2025	综合改革	590	30925	291
1617	山东	2025	综合改革	589	31369	444
1618	山东	2025	综合改革	588	31456	87
1619	山东	2025	综合改革	587	31514	58
1620	山东	2025	综合改革	586	31864	350
1621	山东	2025	综合改革	585	31948	84
1622	山东	2025	综合改革	584	32005	57
1623	山东	2025	综合改革	583	32189	184
1624	山东	2025	综合改革	582	32349	160
1625	山东	2025	综合改革	581	32419	70
1626	山东	2025	综合改革	580	32499	80
1627	山东	2025	综合改革	579	32953	454
1628	山东	2025	综合改革	578	33206	253
1629	山东	2025	综合改革	577	33515	309
1630	山东	2025	综合改革	576	33711	196
1631	山东	2025	综合改革	575	34082	371
1632	山东	2025	综合改革	574	34496	414
1633	山东	2025	综合改革	573	34802	306
1634	山东	2025	综合改革	572	35244	442
1635	山东	2025	综合改革	571	35506	262
1636	山东	2025	综合改革	570	35772	266
1637	山东	2025	综合改革	569	36181	409
1638	山东	2025	综合改革	568	36436	255
1639	山东	2025	综合改革	567	36528	92
1640	山东	2025	综合改革	566	36905	377
1641	山东	2025	综合改革	565	37229	324
1642	山东	2025	综合改革	564	37554	325
1643	山东	2025	综合改革	563	37919	365
1644	山东	2025	综合改革	562	38047	128
1645	山东	2025	综合改革	561	38239	192
1646	山东	2025	综合改革	560	38331	92
1647	山东	2025	综合改革	559	38539	208
1648	山东	2025	综合改革	558	38629	90
1649	山东	2025	综合改革	557	38940	311
1650	山东	2025	综合改革	556	39094	154
1651	山东	2025	综合改革	555	39557	463
1652	山东	2025	综合改革	554	39686	129
1653	山东	2025	综合改革	553	40010	324
1654	山东	2025	综合改革	552	40227	217
1655	山东	2025	综合改革	551	40477	250
1656	山东	2025	综合改革	550	40827	350
1657	山东	2025	综合改革	549	41201	374
1658	山东	2025	综合改革	548	41641	440
1659	山东	2025	综合改革	547	42118	477
1660	山东	2025	综合改革	546	42500	382
1661	山东	2025	综合改革	545	42898	398
1662	山东	2025	综合改革	544	43277	379
1663	山东	2025	综合改革	543	43360	83
1664	山东	2025	综合改革	542	43568	208
1665	山东	2025	综合改革	541	43975	407
1666	山东	2025	综合改革	540	44248	273
1667	山东	2025	综合改革	539	44671	423
1668	山东	2025	综合改革	538	45154	483
1669	山东	2025	综合改革	537	45326	172
1670	山东	2025	综合改革	536	45405	79
1671	山东	2025	综合改革	535	45580	175
1672	山东	2025	综合改革	534	45674	94
1673	山东	2025	综合改革	533	45946	272
1674	山东	2025	综合改革	532	46055	109
1675	山东	2025	综合改革	531	46337	282
1676	山东	2025	综合改革	530	46700	363
1677	山东	2025	综合改革	529	47061	361
1678	山东	2025	综合改革	528	47139	78
1679	山东	2025	综合改革	527	47347	208
1680	山东	2025	综合改革	526	47738	391
1681	山东	2025	综合改革	525	48167	429
1682	山东	2025	综合改革	524	48553	386
1683	山东	2025	综合改革	523	48982	429
1684	山东	2025	综合改革	522	49121	139
1685	山东	2025	综合改革	521	49232	111
1686	山东	2025	综合改革	520	49288	56
1687	山东	2025	综合改革	519	49700	412
1688	山东	2025	综合改革	518	49820	120
1689	山东	2025	综合改革	517	50229	409
1690	山东	2025	综合改革	516	50284	55
1691	山东	2025	综合改革	515	50417	133
1692	山东	2025	综合改革	514	50721	304
1693	山东	2025	综合改革	513	50948	227
1694	山东	2025	综合改革	512	51265	317
1695	山东	2025	综合改革	511	51579	314
1696	山东	2025	综合改革	510	52029	450
1697	山东	2025	综合改革	509	52500	471
1698	山东	2025	综合改革	508	52919	419
1699	山东	2025	综合改革	507	53101	182
1700	山东	2025	综合改革	506	53236	135
1701	山东	2025	综合改革	505	53476	240
1702	山东	2025	综合改革	504	53590	114
1703	山东	2025	综合改革	503	54023	433
1704	山东	2025	综合改革	502	54472	449
1705	山东	2025	综合改革	501	54969	497
1706	山东	2025	综合改革	500	55719	750
1707	山东	2025	综合改革	499	56160	441
1708	山东	2025	综合改革	498	56420	260
1709	山东	2025	综合改革	497	57306	886
1710	山东	2025	综合改革	496	58385	1079
1711	山东	2025	综合改革	495	59142	757
1712	山东	2025	综合改革	494	60414	1272
1713	山东	2025	综合改革	493	60744	330
1714	山东	2025	综合改革	492	61482	738
1715	山东	2025	综合改革	491	62862	1380
1716	山东	2025	综合改革	490	64347	1485
1717	山东	2025	综合改革	489	64704	357
1718	山东	2025	综合改革	488	65920	1216
1719	山东	2025	综合改革	487	67052	1132
1720	山东	2025	综合改革	486	68298	1246
1721	山东	2025	综合改革	485	69235	937
1722	山东	2025	综合改革	484	69548	313
1723	山东	2025	综合改革	483	70771	1223
1724	山东	2025	综合改革	482	72131	1360
1725	山东	2025	综合改革	481	72672	541
1726	山东	2025	综合改革	480	73625	953
1727	山东	2025	综合改革	479	74147	522
1728	山东	2025	综合改革	478	74869	722
1729	山东	2025	综合改革	477	75279	410
1730	山东	2025	综合改革	476	76654	1375
1731	山东	2025	综合改革	475	77090	436
1732	山东	2025	综合改革	474	77757	667
1733	山东	2025	综合改革	473	78999	1242
1734	山东	2025	综合改革	472	79204	205
1735	山东	2025	综合改革	471	79494	290
1736	山东	2025	综合改革	470	79719	225
1737	山东	2025	综合改革	469	80419	700
1738	山东	2025	综合改革	468	80713	294
1739	山东	2025	综合改革	467	81879	1166
1740	山东	2025	综合改革	466	82824	945
1741	山东	2025	综合改革	465	83808	984
1742	山东	2025	综合改革	464	84315	507
1743	山东	2025	综合改革	463	84881	566
1744	山东	2025	综合改革	462	85153	272
1745	山东	2025	综合改革	461	86485	1332
1746	山东	2025	综合改革	460	87543	1058
1747	山东	2025	综合改革	459	88202	659
1748	山东	2025	综合改革	458	89061	859
1749	山东	2025	综合改革	457	89769	708
1750	山东	2025	综合改革	456	90821	1052
1751	山东	2025	综合改革	455	91676	855
1752	山东	2025	综合改革	454	92431	755
1753	山东	2025	综合改革	453	92790	359
1754	山东	2025	综合改革	452	94160	1370
1755	山东	2025	综合改革	451	95123	963
1756	山东	2025	综合改革	450	95567	444
1757	山东	2025	综合改革	449	96795	1228
1758	山东	2025	综合改革	448	97102	307
1759	山东	2025	综合改革	447	97669	567
1760	山东	2025	综合改革	446	98326	657
1761	山东	2025	综合改革	445	99582	1256
1762	山东	2025	综合改革	444	99876	294
1763	山东	2025	综合改革	443	100897	1021
1764	山东	2025	综合改革	442	101238	341
1765	山东	2025	综合改革	441	102390	1152
1766	山东	2025	综合改革	440	103168	778
1767	山东	2025	综合改革	439	104004	836
1768	山东	2025	综合改革	438	104874	870
1769	山东	2025	综合改革	437	105250	376
1770	山东	2025	综合改革	436	106582	1332
1771	山东	2025	综合改革	435	107717	1135
1772	山东	2025	综合改革	434	107933	216
1773	山东	2025	综合改革	433	108888	955
1774	山东	2025	综合改革	432	109498	610
1775	山东	2025	综合改革	431	110295	797
1776	山东	2025	综合改革	430	111649	1354
1777	山东	2025	综合改革	429	112471	822
1778	山东	2025	综合改革	428	113946	1475
1779	山东	2025	综合改革	427	114642	696
1780	山东	2025	综合改革	426	115792	1150
1781	山东	2025	综合改革	425	116746	954
1782	山东	2025	综合改革	424	118157	1411
1783	山东	2025	综合改革	423	119367	1210
1784	山东	2025	综合改革	422	119967	600
1785	山东	2025	综合改革	421	121286	1319
1786	山东	2025	综合改革	420	121988	702
1787	山东	2025	综合改革	419	122496	508
1788	山东	2025	综合改革	418	122709	213
1789	山东	2025	综合改革	417	123748	1039
1790	山东	2025	综合改革	416	123996	248
1791	山东	2025	综合改革	415	124673	677
1792	山东	2025	综合改革	414	125982	1309
1793	山东	2025	综合改革	413	126891	909
1794	山东	2025	综合改革	412	127110	219
1795	山东	2025	综合改革	411	127996	886
1796	山东	2025	综合改革	410	128198	202
1797	山东	2025	综合改革	409	129168	970
1798	山东	2025	综合改革	408	129997	829
1799	山东	2025	综合改革	407	130409	412
1800	山东	2025	综合改革	406	131029	620
1801	山东	2025	综合改革	405	132314	1285
1802	山东	2025	综合改革	404	133001	687
1803	山东	2025	综合改革	403	134060	1059
1804	山东	2025	综合改革	402	135267	1207
1805	山东	2025	综合改革	401	135589	322
1806	山东	2025	综合改革	400	136080	491
1807	湖北	2024	物理类	700	414	414
1808	湖北	2024	物理类	699	607	193
1809	湖北	2024	物理类	698	704	97
1810	湖北	2024	物理类	697	776	72
1811	湖北	2024	物理类	696	944	168
1812	湖北	2024	物理类	695	1426	482
1813	湖北	2024	物理类	694	1742	316
1814	湖北	2024	物理类	693	2003	261
1815	湖北	2024	物理类	692	2411	408
1816	湖北	2024	物理类	691	2651	240
1817	湖北	2024	物理类	690	2935	284
1818	湖北	2024	物理类	689	3367	432
1819	湖北	2024	物理类	688	3460	93
1820	湖北	2024	物理类	687	3807	347
1821	湖北	2024	物理类	686	3905	98
1822	湖北	2024	物理类	685	4213	308
1823	湖北	2024	物理类	684	4331	118
1824	湖北	2024	物理类	683	4707	376
1825	湖北	2024	物理类	682	5176	469
1826	湖北	2024	物理类	681	5427	251
1827	湖北	2024	物理类	680	5515	88
1828	湖北	2024	物理类	679	5868	353
1829	湖北	2024	物理类	678	6208	340
1830	湖北	2024	物理类	677	6289	81
1831	湖北	2024	物理类	676	6561	272
1832	湖北	2024	物理类	675	6950	389
1833	湖北	2024	物理类	674	7066	116
1834	湖北	2024	物理类	673	7237	171
1835	湖北	2024	物理类	672	7436	199
1836	湖北	2024	物理类	671	7619	183
1837	湖北	2024	物理类	670	8104	485
1838	湖北	2024	物理类	669	8315	211
1839	湖北	2024	物理类	668	8775	460
1840	湖北	2024	物理类	667	9026	251
1841	湖北	2024	物理类	666	9434	408
1842	湖北	2024	物理类	665	9909	475
1843	湖北	2024	物理类	664	10335	426
1844	湖北	2024	物理类	663	10552	217
1845	湖北	2024	物理类	662	10764	212
1846	湖北	2024	物理类	661	11045	281
1848	湖北	2024	物理类	659	11403	169
1849	湖北	2024	物理类	658	11491	88
1850	湖北	2024	物理类	657	11644	153
1851	湖北	2024	物理类	656	11763	119
1852	湖北	2024	物理类	655	12212	449
1853	湖北	2024	物理类	654	12656	444
1854	湖北	2024	物理类	653	13005	349
1855	湖北	2024	物理类	652	13110	105
1856	湖北	2024	物理类	651	13239	129
1857	湖北	2024	物理类	650	13343	104
1858	湖北	2024	物理类	649	13477	134
1859	湖北	2024	物理类	648	13757	280
1860	湖北	2024	物理类	647	14045	288
1861	湖北	2024	物理类	646	14255	210
1862	湖北	2024	物理类	645	14513	258
1863	湖北	2024	物理类	644	14624	111
1864	湖北	2024	物理类	643	14948	324
1865	湖北	2024	物理类	642	15181	233
1866	湖北	2024	物理类	641	15625	444
1867	湖北	2024	物理类	640	15781	156
1868	湖北	2024	物理类	639	16062	281
1869	湖北	2024	物理类	638	16269	207
1870	湖北	2024	物理类	637	16556	287
1871	湖北	2024	物理类	636	16741	185
1872	湖北	2024	物理类	635	17227	486
1873	湖北	2024	物理类	634	17338	111
1874	湖北	2024	物理类	633	17434	96
1875	湖北	2024	物理类	632	17564	130
1876	湖北	2024	物理类	631	18027	463
1877	湖北	2024	物理类	630	18428	401
1878	湖北	2024	物理类	629	18633	205
1879	湖北	2024	物理类	628	19106	473
1880	湖北	2024	物理类	627	19516	410
1881	湖北	2024	物理类	626	19922	406
1882	湖北	2024	物理类	625	20280	358
1883	湖北	2024	物理类	624	20350	70
1884	湖北	2024	物理类	623	20510	160
1885	湖北	2024	物理类	622	20987	477
1886	湖北	2024	物理类	621	21475	488
1887	湖北	2024	物理类	620	21692	217
1888	湖北	2024	物理类	619	21817	125
1889	湖北	2024	物理类	618	21913	96
1890	湖北	2024	物理类	617	22327	414
1891	湖北	2024	物理类	616	22504	177
1892	湖北	2024	物理类	615	22736	232
1893	湖北	2024	物理类	614	22988	252
1894	湖北	2024	物理类	613	23300	312
1895	湖北	2024	物理类	612	23375	75
1896	湖北	2024	物理类	611	23771	396
1897	湖北	2024	物理类	610	23974	203
1898	湖北	2024	物理类	609	24157	183
1899	湖北	2024	物理类	608	24626	469
1900	湖北	2024	物理类	607	24765	139
1901	湖北	2024	物理类	606	24830	65
1902	湖北	2024	物理类	605	25087	257
1903	湖北	2024	物理类	604	25574	487
1904	湖北	2024	物理类	603	25855	281
1905	湖北	2024	物理类	602	26189	334
1906	湖北	2024	物理类	601	26622	433
1907	湖北	2024	物理类	600	26953	331
1908	湖北	2024	物理类	599	27130	177
1909	湖北	2024	物理类	598	27228	98
1910	湖北	2024	物理类	597	27514	286
1911	湖北	2024	物理类	596	27616	102
1912	湖北	2024	物理类	595	28077	461
1913	湖北	2024	物理类	594	28533	456
1914	湖北	2024	物理类	593	28654	121
1915	湖北	2024	物理类	592	28766	112
1916	湖北	2024	物理类	591	28822	56
1917	湖北	2024	物理类	590	28903	81
1918	湖北	2024	物理类	589	29378	475
1919	湖北	2024	物理类	588	29827	449
1920	湖北	2024	物理类	587	29990	163
1921	湖北	2024	物理类	586	30106	116
1922	湖北	2024	物理类	585	30257	151
1923	湖北	2024	物理类	584	30728	471
1924	湖北	2024	物理类	583	30983	255
1925	湖北	2024	物理类	582	31223	240
1926	湖北	2024	物理类	581	31624	401
1927	湖北	2024	物理类	580	31996	372
1928	湖北	2024	物理类	579	32376	380
1929	湖北	2024	物理类	578	32469	93
1930	湖北	2024	物理类	577	32817	348
1931	湖北	2024	物理类	576	33167	350
1932	湖北	2024	物理类	575	33349	182
1933	湖北	2024	物理类	574	33815	466
1934	湖北	2024	物理类	573	33903	88
1935	湖北	2024	物理类	572	33964	61
1936	湖北	2024	物理类	571	34047	83
1937	湖北	2024	物理类	570	34198	151
1938	湖北	2024	物理类	569	34578	380
1939	湖北	2024	物理类	568	34855	277
1940	湖北	2024	物理类	567	35319	464
1941	湖北	2024	物理类	566	35434	115
1942	湖北	2024	物理类	565	35531	97
1943	湖北	2024	物理类	564	36014	483
1944	湖北	2024	物理类	563	36488	474
1945	湖北	2024	物理类	562	36952	464
1946	湖北	2024	物理类	561	37171	219
1947	湖北	2024	物理类	560	37283	112
1948	湖北	2024	物理类	559	37354	71
1949	湖北	2024	物理类	558	37640	286
1950	湖北	2024	物理类	557	37715	75
1951	湖北	2024	物理类	556	37851	136
1952	湖北	2024	物理类	555	38194	343
1953	湖北	2024	物理类	554	38465	271
1954	湖北	2024	物理类	553	38935	470
1955	湖北	2024	物理类	552	39355	420
1956	湖北	2024	物理类	551	39607	252
1957	湖北	2024	物理类	550	39911	304
1958	湖北	2024	物理类	549	39976	65
1959	湖北	2024	物理类	548	40221	245
1960	湖北	2024	物理类	547	40620	399
1961	湖北	2024	物理类	546	40888	268
1962	湖北	2024	物理类	545	41026	138
1963	湖北	2024	物理类	544	41257	231
1964	湖北	2024	物理类	543	41416	159
1965	湖北	2024	物理类	542	41561	145
1966	湖北	2024	物理类	541	41751	190
1967	湖北	2024	物理类	540	41944	193
1968	湖北	2024	物理类	539	42222	278
1969	湖北	2024	物理类	538	42348	126
1970	湖北	2024	物理类	537	42415	67
1971	湖北	2024	物理类	536	42779	364
1972	湖北	2024	物理类	535	43146	367
1973	湖北	2024	物理类	534	43511	365
1974	湖北	2024	物理类	533	43686	175
1975	湖北	2024	物理类	532	44067	381
1976	湖北	2024	物理类	531	44268	201
1977	湖北	2024	物理类	530	44573	305
1978	湖北	2024	物理类	529	44833	260
1979	湖北	2024	物理类	528	45164	331
1980	湖北	2024	物理类	527	45459	295
1981	湖北	2024	物理类	526	45540	81
1982	湖北	2024	物理类	525	45634	94
1983	湖北	2024	物理类	524	45827	193
1984	湖北	2024	物理类	523	46073	246
1985	湖北	2024	物理类	522	46193	120
1986	湖北	2024	物理类	521	46457	264
1987	湖北	2024	物理类	520	46609	152
1988	湖北	2024	物理类	519	46988	379
1989	湖北	2024	物理类	518	47446	458
1990	湖北	2024	物理类	517	47765	319
1991	湖北	2024	物理类	516	47942	177
1992	湖北	2024	物理类	515	48314	372
1993	湖北	2024	物理类	514	48774	460
1994	湖北	2024	物理类	513	49102	328
1995	湖北	2024	物理类	512	49558	456
1996	湖北	2024	物理类	511	49617	59
1997	湖北	2024	物理类	510	49862	245
1998	湖北	2024	物理类	509	50312	450
1999	湖北	2024	物理类	508	50727	415
2000	湖北	2024	物理类	507	50960	233
2001	湖北	2024	物理类	506	51255	295
2002	湖北	2024	物理类	505	51583	328
2003	湖北	2024	物理类	504	52033	450
2004	湖北	2024	物理类	503	52331	298
2005	湖北	2024	物理类	502	52557	226
2006	湖北	2024	物理类	501	52896	339
2007	湖北	2024	物理类	500	54124	1228
2008	湖北	2024	物理类	499	54982	858
2009	湖北	2024	物理类	498	55977	995
2010	湖北	2024	物理类	497	56730	753
2011	湖北	2024	物理类	496	57298	568
2012	湖北	2024	物理类	495	57551	253
2013	湖北	2024	物理类	494	58404	853
2014	湖北	2024	物理类	493	59826	1422
2015	湖北	2024	物理类	492	60474	648
2016	湖北	2024	物理类	491	60734	260
2017	湖北	2024	物理类	490	61509	775
2018	湖北	2024	物理类	489	61828	319
2019	湖北	2024	物理类	488	62994	1166
2020	湖北	2024	物理类	487	64278	1284
2021	湖北	2024	物理类	486	65210	932
2022	湖北	2024	物理类	485	66606	1396
2023	湖北	2024	物理类	484	67282	676
2024	湖北	2024	物理类	483	67808	526
2025	湖北	2024	物理类	482	68213	405
2026	湖北	2024	物理类	481	68920	707
2027	湖北	2024	物理类	480	69613	693
2028	湖北	2024	物理类	479	70358	745
2029	湖北	2024	物理类	478	71650	1292
2030	湖北	2024	物理类	477	71964	314
2031	湖北	2024	物理类	476	72613	649
2032	湖北	2024	物理类	475	73992	1379
2033	湖北	2024	物理类	474	74987	995
2034	湖北	2024	物理类	473	75913	926
2035	湖北	2024	物理类	472	76468	555
2036	湖北	2024	物理类	471	77028	560
2037	湖北	2024	物理类	470	77712	684
2038	湖北	2024	物理类	469	79125	1413
2039	湖北	2024	物理类	468	79976	851
2040	湖北	2024	物理类	467	80910	934
2041	湖北	2024	物理类	466	82321	1411
2042	湖北	2024	物理类	465	82578	257
2043	湖北	2024	物理类	464	83498	920
2044	湖北	2024	物理类	463	84860	1362
2045	湖北	2024	物理类	462	86214	1354
2046	湖北	2024	物理类	461	86705	491
2047	湖北	2024	物理类	460	88058	1353
2048	湖北	2024	物理类	459	88643	585
2049	湖北	2024	物理类	458	89851	1208
2050	湖北	2024	物理类	457	91161	1310
2051	湖北	2024	物理类	456	91993	832
2052	湖北	2024	物理类	455	92552	559
2053	湖北	2024	物理类	454	93756	1204
2054	湖北	2024	物理类	453	94033	277
2055	湖北	2024	物理类	452	94417	384
2056	湖北	2024	物理类	451	94732	315
2057	湖北	2024	物理类	450	95408	676
2058	湖北	2024	物理类	449	96840	1432
2059	湖北	2024	物理类	448	97488	648
2060	湖北	2024	物理类	447	97728	240
2061	湖北	2024	物理类	446	99006	1278
2062	湖北	2024	物理类	445	100184	1178
2063	湖北	2024	物理类	444	100385	201
2064	湖北	2024	物理类	443	101264	879
2065	湖北	2024	物理类	442	102721	1457
2066	湖北	2024	物理类	441	103333	612
2067	湖北	2024	物理类	440	103800	467
2068	湖北	2024	物理类	439	104697	897
2069	湖北	2024	物理类	438	105260	563
2070	湖北	2024	物理类	437	106122	862
2071	湖北	2024	物理类	436	106443	321
2072	湖北	2024	物理类	435	106687	244
2073	湖北	2024	物理类	434	107189	502
2074	湖北	2024	物理类	433	108590	1401
2075	湖北	2024	物理类	432	109080	490
2076	湖北	2024	物理类	431	109507	427
2077	湖北	2024	物理类	430	110784	1277
2078	湖北	2024	物理类	429	111731	947
2079	湖北	2024	物理类	428	112079	348
2080	湖北	2024	物理类	427	113044	965
2081	湖北	2024	物理类	426	114054	1010
2082	湖北	2024	物理类	425	115454	1400
2083	湖北	2024	物理类	424	115860	406
2084	湖北	2024	物理类	423	116749	889
2085	湖北	2024	物理类	422	117567	818
2086	湖北	2024	物理类	421	118427	860
2087	湖北	2024	物理类	420	118906	479
2088	湖北	2024	物理类	419	119428	522
2089	湖北	2024	物理类	418	120522	1094
2090	湖北	2024	物理类	417	121719	1197
2091	湖北	2024	物理类	416	122568	849
2092	湖北	2024	物理类	415	123124	556
2093	湖北	2024	物理类	414	124474	1350
2094	湖北	2024	物理类	413	125930	1456
2095	湖北	2024	物理类	412	126860	930
2096	湖北	2024	物理类	411	127517	657
2097	湖北	2024	物理类	410	128923	1406
2098	湖北	2024	物理类	409	129482	559
2099	湖北	2024	物理类	408	130456	974
2100	湖北	2024	物理类	407	131284	828
2101	湖北	2024	物理类	406	132087	803
2102	湖北	2024	物理类	405	132547	460
2103	湖北	2024	物理类	404	133110	563
2104	湖北	2024	物理类	403	133313	203
2105	湖北	2024	物理类	402	134686	1373
2106	湖北	2024	物理类	401	135687	1001
2107	湖北	2024	物理类	400	137049	1362
2108	湖北	2025	物理类	700	66	66
2109	湖北	2025	物理类	699	209	143
2110	湖北	2025	物理类	698	567	358
2111	湖北	2025	物理类	697	779	212
2112	湖北	2025	物理类	696	1243	464
2113	湖北	2025	物理类	695	1606	363
2114	湖北	2025	物理类	694	1769	163
2115	湖北	2025	物理类	693	2146	377
2116	湖北	2025	物理类	692	2485	339
2117	湖北	2025	物理类	691	2588	103
2118	湖北	2025	物理类	690	2892	304
2119	湖北	2025	物理类	689	3014	122
2120	湖北	2025	物理类	688	3233	219
2121	湖北	2025	物理类	687	3664	431
2122	湖北	2025	物理类	686	3753	89
2123	湖北	2025	物理类	685	3924	171
2124	湖北	2025	物理类	684	4151	227
2125	湖北	2025	物理类	683	4364	213
2126	湖北	2025	物理类	682	4499	135
2127	湖北	2025	物理类	681	4874	375
2128	湖北	2025	物理类	680	4969	95
2129	湖北	2025	物理类	679	5439	470
2130	湖北	2025	物理类	678	5851	412
2131	湖北	2025	物理类	677	6244	393
2132	湖北	2025	物理类	676	6621	377
2133	湖北	2025	物理类	675	7044	423
2134	湖北	2025	物理类	674	7265	221
2135	湖北	2025	物理类	673	7543	278
2136	湖北	2025	物理类	672	7598	55
2137	湖北	2025	物理类	671	7783	185
2138	湖北	2025	物理类	670	7940	157
2139	湖北	2025	物理类	669	8117	177
2140	湖北	2025	物理类	668	8521	404
2141	湖北	2025	物理类	667	8605	84
2142	湖北	2025	物理类	666	8834	229
2143	湖北	2025	物理类	665	9015	181
2144	湖北	2025	物理类	664	9467	452
2145	湖北	2025	物理类	663	9572	105
2146	湖北	2025	物理类	662	9990	418
2147	湖北	2025	物理类	661	10040	50
2148	湖北	2025	物理类	660	10114	74
2149	湖北	2025	物理类	659	10361	247
2150	湖北	2025	物理类	658	10635	274
2151	湖北	2025	物理类	657	11060	425
2152	湖北	2025	物理类	656	11324	264
2153	湖北	2025	物理类	655	11459	135
2154	湖北	2025	物理类	654	11720	261
2155	湖北	2025	物理类	653	12022	302
2156	湖北	2025	物理类	652	12265	243
2157	湖北	2025	物理类	651	12494	229
2158	湖北	2025	物理类	650	12823	329
2159	湖北	2025	物理类	649	13065	242
2160	湖北	2025	物理类	648	13166	101
2161	湖北	2025	物理类	647	13640	474
2162	湖北	2025	物理类	646	13935	295
2163	湖北	2025	物理类	645	14388	453
2164	湖北	2025	物理类	644	14880	492
2165	湖北	2025	物理类	643	15225	345
2166	湖北	2025	物理类	642	15608	383
2167	湖北	2025	物理类	641	16046	438
2168	湖北	2025	物理类	640	16447	401
2169	湖北	2025	物理类	639	16612	165
2170	湖北	2025	物理类	638	16745	133
2171	湖北	2025	物理类	637	17026	281
2172	湖北	2025	物理类	636	17113	87
2173	湖北	2025	物理类	635	17572	459
2174	湖北	2025	物理类	634	18055	483
2175	湖北	2025	物理类	633	18122	67
2176	湖北	2025	物理类	632	18322	200
2177	湖北	2025	物理类	631	18382	60
2178	湖北	2025	物理类	630	18595	213
2179	湖北	2025	物理类	629	18778	183
2180	湖北	2025	物理类	628	18881	103
2181	湖北	2025	物理类	627	18968	87
2182	湖北	2025	物理类	626	19193	225
2183	湖北	2025	物理类	625	19330	137
2184	湖北	2025	物理类	624	19572	242
2185	湖北	2025	物理类	623	19704	132
2186	湖北	2025	物理类	622	20128	424
2187	湖北	2025	物理类	621	20216	88
2188	湖北	2025	物理类	620	20546	330
2189	湖北	2025	物理类	619	20643	97
2190	湖北	2025	物理类	618	20866	223
2191	湖北	2025	物理类	617	21220	354
2192	湖北	2025	物理类	616	21584	364
2193	湖北	2025	物理类	615	21881	297
2194	湖北	2025	物理类	614	22291	410
2195	湖北	2025	物理类	613	22356	65
2196	湖北	2025	物理类	612	22626	270
2197	湖北	2025	物理类	611	23010	384
2198	湖北	2025	物理类	610	23144	134
2199	湖北	2025	物理类	609	23504	360
2200	湖北	2025	物理类	608	23776	272
2201	湖北	2025	物理类	607	23906	130
2202	湖北	2025	物理类	606	23983	77
2203	湖北	2025	物理类	605	24084	101
2204	湖北	2025	物理类	604	24303	219
2205	湖北	2025	物理类	603	24458	155
2206	湖北	2025	物理类	602	24605	147
2207	湖北	2025	物理类	601	24864	259
2208	湖北	2025	物理类	600	25270	406
2209	湖北	2025	物理类	599	25603	333
2210	湖北	2025	物理类	598	26022	419
2211	湖北	2025	物理类	597	26445	423
2212	湖北	2025	物理类	596	26771	326
2213	湖北	2025	物理类	595	26956	185
2214	湖北	2025	物理类	594	27344	388
2215	湖北	2025	物理类	593	27538	194
2216	湖北	2025	物理类	592	27740	202
2217	湖北	2025	物理类	591	27911	171
2218	湖北	2025	物理类	590	28010	99
2219	湖北	2025	物理类	589	28085	75
2220	湖北	2025	物理类	588	28336	251
2221	湖北	2025	物理类	587	28678	342
2222	湖北	2025	物理类	586	29009	331
2223	湖北	2025	物理类	585	29489	480
2224	湖北	2025	物理类	584	29790	301
2225	湖北	2025	物理类	583	29918	128
2226	湖北	2025	物理类	582	29995	77
2227	湖北	2025	物理类	581	30229	234
2228	湖北	2025	物理类	580	30280	51
2229	湖北	2025	物理类	579	30548	268
2230	湖北	2025	物理类	578	30642	94
2231	湖北	2025	物理类	577	30842	200
2232	湖北	2025	物理类	576	31313	471
2233	湖北	2025	物理类	575	31701	388
2234	湖北	2025	物理类	574	32071	370
2235	湖北	2025	物理类	573	32428	357
2236	湖北	2025	物理类	572	32723	295
2237	湖北	2025	物理类	571	32875	152
2238	湖北	2025	物理类	570	32974	99
2239	湖北	2025	物理类	569	33037	63
2240	湖北	2025	物理类	568	33192	155
2241	湖北	2025	物理类	567	33329	137
2242	湖北	2025	物理类	566	33705	376
2243	湖北	2025	物理类	565	33904	199
2244	湖北	2025	物理类	564	33995	91
2245	湖北	2025	物理类	563	34287	292
2246	湖北	2025	物理类	562	34769	482
2247	湖北	2025	物理类	561	34878	109
2248	湖北	2025	物理类	560	35085	207
2249	湖北	2025	物理类	559	35536	451
2250	湖北	2025	物理类	558	35789	253
2251	湖北	2025	物理类	557	36080	291
2252	湖北	2025	物理类	556	36380	300
2253	湖北	2025	物理类	555	36768	388
2254	湖北	2025	物理类	554	36953	185
2255	湖北	2025	物理类	553	37049	96
2256	湖北	2025	物理类	552	37427	378
2257	湖北	2025	物理类	551	37755	328
2258	湖北	2025	物理类	550	38003	248
2259	湖北	2025	物理类	549	38147	144
2260	湖北	2025	物理类	548	38386	239
2261	湖北	2025	物理类	547	38631	245
2262	湖北	2025	物理类	546	38870	239
2263	湖北	2025	物理类	545	39015	145
2264	湖北	2025	物理类	544	39293	278
2265	湖北	2025	物理类	543	39365	72
2266	湖北	2025	物理类	542	39549	184
2267	湖北	2025	物理类	541	39824	275
2268	湖北	2025	物理类	540	40112	288
2269	湖北	2025	物理类	539	40296	184
2270	湖北	2025	物理类	538	40461	165
2271	湖北	2025	物理类	537	40939	478
2272	湖北	2025	物理类	536	41126	187
2273	湖北	2025	物理类	535	41464	338
2274	湖北	2025	物理类	534	41545	81
2275	湖北	2025	物理类	533	41672	127
2276	湖北	2025	物理类	532	42107	435
2277	湖北	2025	物理类	531	42513	406
2278	湖北	2025	物理类	530	42904	391
2279	湖北	2025	物理类	529	43003	99
2280	湖北	2025	物理类	528	43096	93
2281	湖北	2025	物理类	527	43488	392
2282	湖北	2025	物理类	526	43714	226
2283	湖北	2025	物理类	525	44177	463
2284	湖北	2025	物理类	524	44504	327
2285	湖北	2025	物理类	523	44765	261
2286	湖北	2025	物理类	522	45202	437
2287	湖北	2025	物理类	521	45553	351
2288	湖北	2025	物理类	520	45719	166
2289	湖北	2025	物理类	519	46052	333
2290	湖北	2025	物理类	518	46133	81
2291	湖北	2025	物理类	517	46613	480
2292	湖北	2025	物理类	516	46861	248
2293	湖北	2025	物理类	515	47330	469
2294	湖北	2025	物理类	514	47647	317
2295	湖北	2025	物理类	513	47911	264
2296	湖北	2025	物理类	512	48235	324
2297	湖北	2025	物理类	511	48636	401
2298	湖北	2025	物理类	510	49129	493
2299	湖北	2025	物理类	509	49422	293
2300	湖北	2025	物理类	508	49765	343
2301	湖北	2025	物理类	507	49935	170
2302	湖北	2025	物理类	506	50228	293
2303	湖北	2025	物理类	505	50431	203
2304	湖北	2025	物理类	504	50521	90
2305	湖北	2025	物理类	503	50773	252
2306	湖北	2025	物理类	502	51260	487
2307	湖北	2025	物理类	501	51675	415
2308	湖北	2025	物理类	500	51946	271
2309	湖北	2025	物理类	499	53174	1228
2310	湖北	2025	物理类	498	54543	1369
2311	湖北	2025	物理类	497	55801	1258
2312	湖北	2025	物理类	496	57171	1370
2313	湖北	2025	物理类	495	58641	1470
2314	湖北	2025	物理类	494	59142	501
2315	湖北	2025	物理类	493	59588	446
2316	湖北	2025	物理类	492	60707	1119
2317	湖北	2025	物理类	491	61261	554
2318	湖北	2025	物理类	490	61803	542
2319	湖北	2025	物理类	489	62436	633
2320	湖北	2025	物理类	488	63030	594
2321	湖北	2025	物理类	487	63488	458
2322	湖北	2025	物理类	486	63775	287
2323	湖北	2025	物理类	485	64842	1067
2324	湖北	2025	物理类	484	65202	360
2325	湖北	2025	物理类	483	66293	1091
2326	湖北	2025	物理类	482	66906	613
2327	湖北	2025	物理类	481	68390	1484
2328	湖北	2025	物理类	480	68892	502
2329	湖北	2025	物理类	479	70310	1418
2330	湖北	2025	物理类	478	71038	728
2331	湖北	2025	物理类	477	71892	854
2332	湖北	2025	物理类	476	72229	337
2333	湖北	2025	物理类	475	72607	378
2334	湖北	2025	物理类	474	73601	994
2335	湖北	2025	物理类	473	74940	1339
2336	湖北	2025	物理类	472	75953	1013
2337	湖北	2025	物理类	471	77283	1330
2338	湖北	2025	物理类	470	78150	867
2339	湖北	2025	物理类	469	78915	765
2340	湖北	2025	物理类	468	80179	1264
2341	湖北	2025	物理类	467	81317	1138
2342	湖北	2025	物理类	466	81542	225
2343	湖北	2025	物理类	465	83018	1476
2344	湖北	2025	物理类	464	84421	1403
2345	湖北	2025	物理类	463	85691	1270
2346	湖北	2025	物理类	462	86750	1059
2347	湖北	2025	物理类	461	87180	430
2348	湖北	2025	物理类	460	88228	1048
2349	湖北	2025	物理类	459	88734	506
2350	湖北	2025	物理类	458	89237	503
2351	湖北	2025	物理类	457	90597	1360
2352	湖北	2025	物理类	456	92001	1404
2353	湖北	2025	物理类	455	93394	1393
2354	湖北	2025	物理类	454	93799	405
2355	湖北	2025	物理类	453	94215	416
2356	湖北	2025	物理类	452	95567	1352
2357	湖北	2025	物理类	451	95973	406
2358	湖北	2025	物理类	450	96758	785
2359	湖北	2025	物理类	449	98054	1296
2360	湖北	2025	物理类	448	98958	904
2361	湖北	2025	物理类	447	99999	1041
2362	湖北	2025	物理类	446	100739	740
2363	湖北	2025	物理类	445	101723	984
2364	湖北	2025	物理类	444	102917	1194
2365	湖北	2025	物理类	443	104288	1371
2366	湖北	2025	物理类	442	105735	1447
2367	湖北	2025	物理类	441	106903	1168
2368	湖北	2025	物理类	440	107179	276
2369	湖北	2025	物理类	439	107731	552
2370	湖北	2025	物理类	438	108495	764
2371	湖北	2025	物理类	437	109520	1025
2372	湖北	2025	物理类	436	110014	494
2373	湖北	2025	物理类	435	111480	1466
2374	湖北	2025	物理类	434	112926	1446
2375	湖北	2025	物理类	433	113948	1022
2376	湖北	2025	物理类	432	114227	279
2377	湖北	2025	物理类	431	115237	1010
2378	湖北	2025	物理类	430	116115	878
2379	湖北	2025	物理类	429	116801	686
2380	湖北	2025	物理类	428	117101	300
2381	湖北	2025	物理类	427	118274	1173
2382	湖北	2025	物理类	426	119024	750
2383	湖北	2025	物理类	425	119986	962
2384	湖北	2025	物理类	424	120227	241
2385	湖北	2025	物理类	423	121118	891
2386	湖北	2025	物理类	422	121938	820
2387	湖北	2025	物理类	421	122774	836
2388	湖北	2025	物理类	420	123548	774
2389	湖北	2025	物理类	419	124754	1206
2390	湖北	2025	物理类	418	125155	401
2391	湖北	2025	物理类	417	125821	666
2392	湖北	2025	物理类	416	126296	475
2393	湖北	2025	物理类	415	127111	815
2394	湖北	2025	物理类	414	128218	1107
2395	湖北	2025	物理类	413	129075	857
2396	湖北	2025	物理类	412	129826	751
2397	湖北	2025	物理类	411	130879	1053
2398	湖北	2025	物理类	410	132317	1438
2399	湖北	2025	物理类	409	132699	382
2400	湖北	2025	物理类	408	133283	584
2401	湖北	2025	物理类	407	134387	1104
2402	湖北	2025	物理类	406	135019	632
2403	湖北	2025	物理类	405	136052	1033
2404	湖北	2025	物理类	404	137244	1192
2405	湖北	2025	物理类	403	138501	1257
2406	湖北	2025	物理类	402	139466	965
2407	湖北	2025	物理类	401	139781	315
2408	湖北	2025	物理类	400	141036	1255
2409	湖北	2024	历史类	700	455	455
2410	湖北	2024	历史类	699	586	131
2411	湖北	2024	历史类	698	669	83
2412	湖北	2024	历史类	697	878	209
2413	湖北	2024	历史类	696	1291	413
2414	湖北	2024	历史类	695	1600	309
2415	湖北	2024	历史类	694	1856	256
2416	湖北	2024	历史类	693	1975	119
2417	湖北	2024	历史类	692	2424	449
2418	湖北	2024	历史类	691	2909	485
2419	湖北	2024	历史类	690	3227	318
2420	湖北	2024	历史类	689	3727	500
2421	湖北	2024	历史类	688	4068	341
2422	湖北	2024	历史类	687	4132	64
2423	湖北	2024	历史类	686	4270	138
2424	湖北	2024	历史类	685	4418	148
2425	湖北	2024	历史类	684	4916	498
2426	湖北	2024	历史类	683	5392	476
2427	湖北	2024	历史类	682	5544	152
2428	湖北	2024	历史类	681	6022	478
2429	湖北	2024	历史类	680	6101	79
2430	湖北	2024	历史类	679	6278	177
2431	湖北	2024	历史类	678	6344	66
2432	湖北	2024	历史类	677	6627	283
2433	湖北	2024	历史类	676	6702	75
2434	湖北	2024	历史类	675	6936	234
2435	湖北	2024	历史类	674	7346	410
2436	湖北	2024	历史类	673	7497	151
2437	湖北	2024	历史类	672	7687	190
2438	湖北	2024	历史类	671	7925	238
2439	湖北	2024	历史类	670	8396	471
2440	湖北	2024	历史类	669	8683	287
2441	湖北	2024	历史类	668	8991	308
2442	湖北	2024	历史类	667	9244	253
2443	湖北	2024	历史类	666	9619	375
2444	湖北	2024	历史类	665	9732	113
2445	湖北	2024	历史类	664	10130	398
2446	湖北	2024	历史类	663	10195	65
2447	湖北	2024	历史类	662	10368	173
2448	湖北	2024	历史类	661	10608	240
2449	湖北	2024	历史类	660	10908	300
2450	湖北	2024	历史类	659	11262	354
2451	湖北	2024	历史类	658	11540	278
2452	湖北	2024	历史类	657	11680	140
2453	湖北	2024	历史类	656	12175	495
2454	湖北	2024	历史类	655	12467	292
2455	湖北	2024	历史类	654	12817	350
2456	湖北	2024	历史类	653	13149	332
2457	湖北	2024	历史类	652	13378	229
2458	湖北	2024	历史类	651	13604	226
2459	湖北	2024	历史类	650	13737	133
2460	湖北	2024	历史类	649	14215	478
2461	湖北	2024	历史类	648	14397	182
2462	湖北	2024	历史类	647	14830	433
2463	湖北	2024	历史类	646	15305	475
2464	湖北	2024	历史类	645	15707	402
2465	湖北	2024	历史类	644	15803	96
2466	湖北	2024	历史类	643	15998	195
2467	湖北	2024	历史类	642	16062	64
2468	湖北	2024	历史类	641	16309	247
2469	湖北	2024	历史类	640	16384	75
2470	湖北	2024	历史类	639	16517	133
2471	湖北	2024	历史类	638	17004	487
2472	湖北	2024	历史类	637	17346	342
2473	湖北	2024	历史类	636	17795	449
2474	湖北	2024	历史类	635	17954	159
2475	湖北	2024	历史类	634	18442	488
2476	湖北	2024	历史类	633	18605	163
2477	湖北	2024	历史类	632	18986	381
2478	湖北	2024	历史类	631	19151	165
2479	湖北	2024	历史类	630	19547	396
2480	湖北	2024	历史类	629	19702	155
2481	湖北	2024	历史类	628	19889	187
2482	湖北	2024	历史类	627	20272	383
2483	湖北	2024	历史类	626	20531	259
2484	湖北	2024	历史类	625	20843	312
2485	湖北	2024	历史类	624	20903	60
2486	湖北	2024	历史类	623	21395	492
2487	湖北	2024	历史类	622	21844	449
2488	湖北	2024	历史类	621	22286	442
2489	湖北	2024	历史类	620	22685	399
2490	湖北	2024	历史类	619	22739	54
2491	湖北	2024	历史类	618	23031	292
2492	湖北	2024	历史类	617	23148	117
2493	湖北	2024	历史类	616	23529	381
2494	湖北	2024	历史类	615	23667	138
2495	湖北	2024	历史类	614	24024	357
2496	湖北	2024	历史类	613	24484	460
2497	湖北	2024	历史类	612	24538	54
2498	湖北	2024	历史类	611	24702	164
2499	湖北	2024	历史类	610	24881	179
2500	湖北	2024	历史类	609	25242	361
2501	湖北	2024	历史类	608	25704	462
2502	湖北	2024	历史类	607	25910	206
2503	湖北	2024	历史类	606	26324	414
2504	湖北	2024	历史类	605	26737	413
2505	湖北	2024	历史类	604	27116	379
2506	湖北	2024	历史类	603	27306	190
2507	湖北	2024	历史类	602	27572	266
2508	湖北	2024	历史类	601	27814	242
2509	湖北	2024	历史类	600	28300	486
2510	湖北	2024	历史类	599	28528	228
2511	湖北	2024	历史类	598	28813	285
2512	湖北	2024	历史类	597	28992	179
2513	湖北	2024	历史类	596	29153	161
2514	湖北	2024	历史类	595	29441	288
2515	湖北	2024	历史类	594	29645	204
2516	湖北	2024	历史类	593	30041	396
2517	湖北	2024	历史类	592	30357	316
2518	湖北	2024	历史类	591	30829	472
2519	湖北	2024	历史类	590	31198	369
2520	湖北	2024	历史类	589	31451	253
2521	湖北	2024	历史类	588	31800	349
2522	湖北	2024	历史类	587	31902	102
2523	湖北	2024	历史类	586	31955	53
2524	湖北	2024	历史类	585	32266	311
2525	湖北	2024	历史类	584	32655	389
2526	湖北	2024	历史类	583	33136	481
2527	湖北	2024	历史类	582	33615	479
2528	湖北	2024	历史类	581	33856	241
2529	湖北	2024	历史类	580	34193	337
2530	湖北	2024	历史类	579	34574	381
2531	湖北	2024	历史类	578	34928	354
2532	湖北	2024	历史类	577	35289	361
2533	湖北	2024	历史类	576	35483	194
2534	湖北	2024	历史类	575	35685	202
2535	湖北	2024	历史类	574	36085	400
2536	湖北	2024	历史类	573	36190	105
2537	湖北	2024	历史类	572	36486	296
2538	湖北	2024	历史类	571	36568	82
2539	湖北	2024	历史类	570	36790	222
2540	湖北	2024	历史类	569	36981	191
2541	湖北	2024	历史类	568	37358	377
2542	湖北	2024	历史类	567	37574	216
2543	湖北	2024	历史类	566	38065	491
2544	湖北	2024	历史类	565	38256	191
2545	湖北	2024	历史类	564	38439	183
2546	湖北	2024	历史类	563	38824	385
2547	湖北	2024	历史类	562	39238	414
2548	湖北	2024	历史类	561	39621	383
2549	湖北	2024	历史类	560	39823	202
2550	湖北	2024	历史类	559	39969	146
2551	湖北	2024	历史类	558	40095	126
2552	湖北	2024	历史类	557	40409	314
2553	湖北	2024	历史类	556	40850	441
2554	湖北	2024	历史类	555	41023	173
2555	湖北	2024	历史类	554	41102	79
2556	湖北	2024	历史类	553	41564	462
2557	湖北	2024	历史类	552	42052	488
2558	湖北	2024	历史类	551	42512	460
2559	湖北	2024	历史类	550	42976	464
2560	湖北	2024	历史类	549	43333	357
2561	湖北	2024	历史类	548	43589	256
2562	湖北	2024	历史类	547	43977	388
2563	湖北	2024	历史类	546	44190	213
2564	湖北	2024	历史类	545	44588	398
2565	湖北	2024	历史类	544	44709	121
2566	湖北	2024	历史类	543	45128	419
2567	湖北	2024	历史类	542	45191	63
2568	湖北	2024	历史类	541	45576	385
2569	湖北	2024	历史类	540	45880	304
2570	湖北	2024	历史类	539	46081	201
2571	湖北	2024	历史类	538	46263	182
2572	湖北	2024	历史类	537	46527	264
2573	湖北	2024	历史类	536	46784	257
2574	湖北	2024	历史类	535	47032	248
2575	湖北	2024	历史类	534	47459	427
2576	湖北	2024	历史类	533	47527	68
2577	湖北	2024	历史类	532	47875	348
2578	湖北	2024	历史类	531	48287	412
2579	湖北	2024	历史类	530	48629	342
2580	湖北	2024	历史类	529	49096	467
2581	湖北	2024	历史类	528	49243	147
2582	湖北	2024	历史类	527	49468	225
2583	湖北	2024	历史类	526	49889	421
2584	湖北	2024	历史类	525	50304	415
2585	湖北	2024	历史类	524	50467	163
2586	湖北	2024	历史类	523	50868	401
2587	湖北	2024	历史类	522	51191	323
2588	湖北	2024	历史类	521	51567	376
2589	湖北	2024	历史类	520	52018	451
2590	湖北	2024	历史类	519	52311	293
2591	湖北	2024	历史类	518	52704	393
2592	湖北	2024	历史类	517	52937	233
2593	湖北	2024	历史类	516	53246	309
2594	湖北	2024	历史类	515	53449	203
2595	湖北	2024	历史类	514	53931	482
2596	湖北	2024	历史类	513	54068	137
2597	湖北	2024	历史类	512	54548	480
2598	湖北	2024	历史类	511	54934	386
2599	湖北	2024	历史类	510	55432	498
2600	湖北	2024	历史类	509	55767	335
2601	湖北	2024	历史类	508	55909	142
2602	湖北	2024	历史类	507	56109	200
2603	湖北	2024	历史类	506	56208	99
2604	湖北	2024	历史类	505	56499	291
2605	湖北	2024	历史类	504	56614	115
2606	湖北	2024	历史类	503	57043	429
2607	湖北	2024	历史类	502	57225	182
2608	湖北	2024	历史类	501	57646	421
2609	湖北	2024	历史类	500	58990	1344
2610	湖北	2024	历史类	499	59564	574
2611	湖北	2024	历史类	498	60451	887
2612	湖北	2024	历史类	497	60833	382
2613	湖北	2024	历史类	496	61488	655
2614	湖北	2024	历史类	495	62415	927
2615	湖北	2024	历史类	494	63072	657
2616	湖北	2024	历史类	493	63900	828
2617	湖北	2024	历史类	492	64961	1061
2618	湖北	2024	历史类	491	65839	878
2619	湖北	2024	历史类	490	66800	961
2620	湖北	2024	历史类	489	67533	733
2621	湖北	2024	历史类	488	68932	1399
2622	湖北	2024	历史类	487	69734	802
2623	湖北	2024	历史类	486	70883	1149
2624	湖北	2024	历史类	485	71324	441
2625	湖北	2024	历史类	484	72487	1163
2626	湖北	2024	历史类	483	72796	309
2627	湖北	2024	历史类	482	74295	1499
2628	湖北	2024	历史类	481	75690	1395
2629	湖北	2024	历史类	480	77078	1388
2630	湖北	2024	历史类	479	78549	1471
2631	湖北	2024	历史类	478	78894	345
2632	湖北	2024	历史类	477	80061	1167
2633	湖北	2024	历史类	476	80659	598
2634	湖北	2024	历史类	475	81883	1224
2635	湖北	2024	历史类	474	82328	445
2636	湖北	2024	历史类	473	83309	981
2637	湖北	2024	历史类	472	84594	1285
2638	湖北	2024	历史类	471	85405	811
2639	湖北	2024	历史类	470	86451	1046
2640	湖北	2024	历史类	469	86761	310
2641	湖北	2024	历史类	468	87269	508
2642	湖北	2024	历史类	467	87750	481
2643	湖北	2024	历史类	466	88360	610
2644	湖北	2024	历史类	465	89261	901
2645	湖北	2024	历史类	464	90299	1038
2646	湖北	2024	历史类	463	91665	1366
2647	湖北	2024	历史类	462	92802	1137
2648	湖北	2024	历史类	461	93295	493
2649	湖北	2024	历史类	460	94142	847
2650	湖北	2024	历史类	459	94711	569
2651	湖北	2024	历史类	458	95076	365
2652	湖北	2024	历史类	457	96274	1198
2653	湖北	2024	历史类	456	97155	881
2654	湖北	2024	历史类	455	98647	1492
2655	湖北	2024	历史类	454	99209	562
2656	湖北	2024	历史类	453	100050	841
2657	湖北	2024	历史类	452	101549	1499
2658	湖北	2024	历史类	451	101867	318
2659	湖北	2024	历史类	450	102076	209
2660	湖北	2024	历史类	449	103201	1125
2661	湖北	2024	历史类	448	103961	760
2662	湖北	2024	历史类	447	104589	628
2663	湖北	2024	历史类	446	105134	545
2664	湖北	2024	历史类	445	106514	1380
2665	湖北	2024	历史类	444	107038	524
2666	湖北	2024	历史类	443	108240	1202
2667	湖北	2024	历史类	442	108620	380
2668	湖北	2024	历史类	441	109085	465
2669	湖北	2024	历史类	440	110543	1458
2670	湖北	2024	历史类	439	111631	1088
2671	湖北	2024	历史类	438	113128	1497
2672	湖北	2024	历史类	437	114207	1079
2673	湖北	2024	历史类	436	115233	1026
2674	湖北	2024	历史类	435	116311	1078
2675	湖北	2024	历史类	434	117488	1177
2676	湖北	2024	历史类	433	118473	985
2677	湖北	2024	历史类	432	118682	209
2678	湖北	2024	历史类	431	118959	277
2679	湖北	2024	历史类	430	120252	1293
2680	湖北	2024	历史类	429	120860	608
2681	湖北	2024	历史类	428	121824	964
2682	湖北	2024	历史类	427	122052	228
2683	湖北	2024	历史类	426	122911	859
2684	湖北	2024	历史类	425	124198	1287
2685	湖北	2024	历史类	424	124788	590
2686	湖北	2024	历史类	423	125024	236
2687	湖北	2024	历史类	422	125232	208
2688	湖北	2024	历史类	421	126715	1483
2689	湖北	2024	历史类	420	127424	709
2690	湖北	2024	历史类	419	128087	663
2691	湖北	2024	历史类	418	128992	905
2692	湖北	2024	历史类	417	129831	839
2693	湖北	2024	历史类	416	130295	464
2694	湖北	2024	历史类	415	130705	410
2695	湖北	2024	历史类	414	131690	985
2696	湖北	2024	历史类	413	132920	1230
2697	湖北	2024	历史类	412	134325	1405
2698	湖北	2024	历史类	411	135151	826
2699	湖北	2024	历史类	410	135693	542
2700	湖北	2024	历史类	409	136026	333
2701	湖北	2024	历史类	408	136319	293
2702	湖北	2024	历史类	407	137129	810
2703	湖北	2024	历史类	406	137924	795
2704	湖北	2024	历史类	405	139057	1133
2705	湖北	2024	历史类	404	140322	1265
2706	湖北	2024	历史类	403	141743	1421
2707	湖北	2024	历史类	402	143016	1273
2708	湖北	2024	历史类	401	143907	891
2709	湖北	2024	历史类	400	144995	1088
2710	湖北	2025	历史类	700	401	401
2711	湖北	2025	历史类	699	519	118
2712	湖北	2025	历史类	698	744	225
2713	湖北	2025	历史类	697	1044	300
2714	湖北	2025	历史类	696	1277	233
2715	湖北	2025	历史类	695	1711	434
2716	湖北	2025	历史类	694	1857	146
2717	湖北	2025	历史类	693	1991	134
2718	湖北	2025	历史类	692	2456	465
2719	湖北	2025	历史类	691	2712	256
2720	湖北	2025	历史类	690	2771	59
2721	湖北	2025	历史类	689	2937	166
2722	湖北	2025	历史类	688	3101	164
2723	湖北	2025	历史类	687	3523	422
2724	湖北	2025	历史类	686	3640	117
2725	湖北	2025	历史类	685	3798	158
2726	湖北	2025	历史类	684	4223	425
2727	湖北	2025	历史类	683	4284	61
2728	湖北	2025	历史类	682	4635	351
2729	湖北	2025	历史类	681	4943	308
2730	湖北	2025	历史类	680	5079	136
2731	湖北	2025	历史类	679	5192	113
2732	湖北	2025	历史类	678	5429	237
2733	湖北	2025	历史类	677	5843	414
2734	湖北	2025	历史类	676	6226	383
2735	湖北	2025	历史类	675	6681	455
2736	湖北	2025	历史类	674	6750	69
2737	湖北	2025	历史类	673	6992	242
2738	湖北	2025	历史类	672	7490	498
2739	湖北	2025	历史类	671	7867	377
2740	湖北	2025	历史类	670	8047	180
2741	湖北	2025	历史类	669	8491	444
2742	湖北	2025	历史类	668	8814	323
2743	湖北	2025	历史类	667	9183	369
2744	湖北	2025	历史类	666	9257	74
2745	湖北	2025	历史类	665	9611	354
2746	湖北	2025	历史类	664	9685	74
2747	湖北	2025	历史类	663	10073	388
2748	湖北	2025	历史类	662	10178	105
2749	湖北	2025	历史类	661	10562	384
2750	湖北	2025	历史类	660	11040	478
2751	湖北	2025	历史类	659	11100	60
2752	湖北	2025	历史类	658	11174	74
2753	湖北	2025	历史类	657	11577	403
2754	湖北	2025	历史类	656	11686	109
2755	湖北	2025	历史类	655	11949	263
2756	湖北	2025	历史类	654	12226	277
2757	湖北	2025	历史类	653	12470	244
2758	湖北	2025	历史类	652	12583	113
2759	湖北	2025	历史类	651	12913	330
2760	湖北	2025	历史类	650	13092	179
2761	湖北	2025	历史类	649	13384	292
2762	湖北	2025	历史类	648	13793	409
2763	湖北	2025	历史类	647	13921	128
2764	湖北	2025	历史类	646	14076	155
2765	湖北	2025	历史类	645	14481	405
2766	湖北	2025	历史类	644	14882	401
2767	湖北	2025	历史类	643	15254	372
2768	湖北	2025	历史类	642	15308	54
2769	湖北	2025	历史类	641	15512	204
2770	湖北	2025	历史类	640	15777	265
2771	湖北	2025	历史类	639	16165	388
2772	湖北	2025	历史类	638	16266	101
2773	湖北	2025	历史类	637	16655	389
2774	湖北	2025	历史类	636	16971	316
2775	湖北	2025	历史类	635	17159	188
2776	湖北	2025	历史类	634	17527	368
2777	湖北	2025	历史类	633	17887	360
2778	湖北	2025	历史类	632	18295	408
2779	湖北	2025	历史类	631	18415	120
2780	湖北	2025	历史类	630	18679	264
2781	湖北	2025	历史类	629	19154	475
2782	湖北	2025	历史类	628	19257	103
2783	湖北	2025	历史类	627	19568	311
2784	湖北	2025	历史类	626	19986	418
2785	湖北	2025	历史类	625	20352	366
2786	湖北	2025	历史类	624	20462	110
2787	湖北	2025	历史类	623	20656	194
2788	湖北	2025	历史类	622	20764	108
2789	湖北	2025	历史类	621	21215	451
2790	湖北	2025	历史类	620	21319	104
2791	湖北	2025	历史类	619	21623	304
2792	湖北	2025	历史类	618	21774	151
2793	湖北	2025	历史类	617	22135	361
2794	湖北	2025	历史类	616	22287	152
2795	湖北	2025	历史类	615	22735	448
2796	湖北	2025	历史类	614	22919	184
2797	湖北	2025	历史类	613	23394	475
2798	湖北	2025	历史类	612	23711	317
2799	湖北	2025	历史类	611	23864	153
2800	湖北	2025	历史类	610	24097	233
2801	湖北	2025	历史类	609	24507	410
2802	湖北	2025	历史类	608	24766	259
2803	湖北	2025	历史类	607	24967	201
2804	湖北	2025	历史类	606	25099	132
2805	湖北	2025	历史类	605	25169	70
2806	湖北	2025	历史类	604	25499	330
2807	湖北	2025	历史类	603	25803	304
2808	湖北	2025	历史类	602	25959	156
2809	湖北	2025	历史类	601	26361	402
2810	湖北	2025	历史类	600	26657	296
2811	湖北	2025	历史类	599	26876	219
2812	湖北	2025	历史类	598	27046	170
2813	湖北	2025	历史类	597	27097	51
2814	湖北	2025	历史类	596	27153	56
2815	湖北	2025	历史类	595	27546	393
2816	湖北	2025	历史类	594	27641	95
2817	湖北	2025	历史类	593	27747	106
2818	湖北	2025	历史类	592	28224	477
2819	湖北	2025	历史类	591	28567	343
2820	湖北	2025	历史类	590	28959	392
2821	湖北	2025	历史类	589	29261	302
2822	湖北	2025	历史类	588	29387	126
2823	湖北	2025	历史类	587	29483	96
2824	湖北	2025	历史类	586	29932	449
2825	湖北	2025	历史类	585	30243	311
2826	湖北	2025	历史类	584	30331	88
2827	湖北	2025	历史类	583	30751	420
2828	湖北	2025	历史类	582	31171	420
2829	湖北	2025	历史类	581	31272	101
2830	湖北	2025	历史类	580	31453	181
2831	湖北	2025	历史类	579	31832	379
2832	湖北	2025	历史类	578	32000	168
2833	湖北	2025	历史类	577	32283	283
2834	湖北	2025	历史类	576	32484	201
2835	湖北	2025	历史类	575	32669	185
2836	湖北	2025	历史类	574	32956	287
2837	湖北	2025	历史类	573	33031	75
2838	湖北	2025	历史类	572	33132	101
2839	湖北	2025	历史类	571	33598	466
2840	湖北	2025	历史类	570	33737	139
2841	湖北	2025	历史类	569	34234	497
2842	湖北	2025	历史类	568	34304	70
2843	湖北	2025	历史类	567	34790	486
2844	湖北	2025	历史类	566	34988	198
2845	湖北	2025	历史类	565	35222	234
2846	湖北	2025	历史类	564	35682	460
2847	湖北	2025	历史类	563	36078	396
2848	湖北	2025	历史类	562	36288	210
2849	湖北	2025	历史类	561	36556	268
2850	湖北	2025	历史类	560	36984	428
2851	湖北	2025	历史类	559	37093	109
2852	湖北	2025	历史类	558	37191	98
2853	湖北	2025	历史类	557	37676	485
2854	湖北	2025	历史类	556	38114	438
2855	湖北	2025	历史类	555	38187	73
2856	湖北	2025	历史类	554	38241	54
2857	湖北	2025	历史类	553	38727	486
2858	湖北	2025	历史类	552	38847	120
2859	湖北	2025	历史类	551	39236	389
2860	湖北	2025	历史类	550	39617	381
2861	湖北	2025	历史类	549	39754	137
2862	湖北	2025	历史类	548	39972	218
2863	湖北	2025	历史类	547	40205	233
2864	湖北	2025	历史类	546	40479	274
2865	湖北	2025	历史类	545	40847	368
2866	湖北	2025	历史类	544	41034	187
2867	湖北	2025	历史类	543	41533	499
2868	湖北	2025	历史类	542	41958	425
2869	湖北	2025	历史类	541	42055	97
2870	湖北	2025	历史类	540	42295	240
2871	湖北	2025	历史类	539	42762	467
2872	湖北	2025	历史类	538	42987	225
2873	湖北	2025	历史类	537	43130	143
2874	湖北	2025	历史类	536	43238	108
2875	湖北	2025	历史类	535	43493	255
2876	湖北	2025	历史类	534	43747	254
2877	湖北	2025	历史类	533	44030	283
2878	湖北	2025	历史类	532	44219	189
2879	湖北	2025	历史类	531	44696	477
2880	湖北	2025	历史类	530	44943	247
2881	湖北	2025	历史类	529	45346	403
2882	湖北	2025	历史类	528	45831	485
2883	湖北	2025	历史类	527	46125	294
2884	湖北	2025	历史类	526	46584	459
2885	湖北	2025	历史类	525	46849	265
2886	湖北	2025	历史类	524	47231	382
2887	湖北	2025	历史类	523	47689	458
2888	湖北	2025	历史类	522	47824	135
2889	湖北	2025	历史类	521	47931	107
2890	湖北	2025	历史类	520	48048	117
2891	湖北	2025	历史类	519	48454	406
2892	湖北	2025	历史类	518	48875	421
2893	湖北	2025	历史类	517	48955	80
2894	湖北	2025	历史类	516	49437	482
2895	湖北	2025	历史类	515	49568	131
2896	湖北	2025	历史类	514	49671	103
2897	湖北	2025	历史类	513	49934	263
2898	湖北	2025	历史类	512	50286	352
2899	湖北	2025	历史类	511	50583	297
2900	湖北	2025	历史类	510	51043	460
2901	湖北	2025	历史类	509	51384	341
2902	湖北	2025	历史类	508	51781	397
2903	湖北	2025	历史类	507	52055	274
2904	湖北	2025	历史类	506	52197	142
2905	湖北	2025	历史类	505	52559	362
2906	湖北	2025	历史类	504	52803	244
2907	湖北	2025	历史类	503	53251	448
2908	湖北	2025	历史类	502	53484	233
2909	湖北	2025	历史类	501	53847	363
2910	湖北	2025	历史类	500	54106	259
2911	湖北	2025	历史类	499	54573	467
2912	湖北	2025	历史类	498	55762	1189
2913	湖北	2025	历史类	497	56961	1199
2914	湖北	2025	历史类	496	57392	431
2915	湖北	2025	历史类	495	58434	1042
2916	湖北	2025	历史类	494	59536	1102
2917	湖北	2025	历史类	493	59830	294
2918	湖北	2025	历史类	492	60159	329
2919	湖北	2025	历史类	491	60894	735
2920	湖北	2025	历史类	490	61737	843
2921	湖北	2025	历史类	489	61962	225
2922	湖北	2025	历史类	488	63236	1274
2923	湖北	2025	历史类	487	64616	1380
2924	湖北	2025	历史类	486	65973	1357
2925	湖北	2025	历史类	485	66631	658
2926	湖北	2025	历史类	484	67523	892
2927	湖北	2025	历史类	483	68786	1263
2928	湖北	2025	历史类	482	70057	1271
2929	湖北	2025	历史类	481	71523	1466
2930	湖北	2025	历史类	480	71918	395
2931	湖北	2025	历史类	479	73004	1086
2932	湖北	2025	历史类	478	73713	709
2933	湖北	2025	历史类	477	74899	1186
2934	湖北	2025	历史类	476	75807	908
2935	湖北	2025	历史类	475	76795	988
2936	湖北	2025	历史类	474	77299	504
2937	湖北	2025	历史类	473	78642	1343
2938	湖北	2025	历史类	472	80097	1455
2939	湖北	2025	历史类	471	80408	311
2940	湖北	2025	历史类	470	80631	223
2941	湖北	2025	历史类	469	81152	521
2942	湖北	2025	历史类	468	82387	1235
2943	湖北	2025	历史类	467	83548	1161
2944	湖北	2025	历史类	466	84763	1215
2945	湖北	2025	历史类	465	85301	538
2946	湖北	2025	历史类	464	85654	353
2947	湖北	2025	历史类	463	86860	1206
2948	湖北	2025	历史类	462	87716	856
2949	湖北	2025	历史类	461	88409	693
2950	湖北	2025	历史类	460	89286	877
2951	湖北	2025	历史类	459	90055	769
2952	湖北	2025	历史类	458	90358	303
2953	湖北	2025	历史类	457	91596	1238
2954	湖北	2025	历史类	456	92252	656
2955	湖北	2025	历史类	455	93579	1327
2956	湖北	2025	历史类	454	94554	975
2957	湖北	2025	历史类	453	95579	1025
2958	湖北	2025	历史类	452	96260	681
2959	湖北	2025	历史类	451	96621	361
2960	湖北	2025	历史类	450	97761	1140
2961	湖北	2025	历史类	449	98870	1109
2962	湖北	2025	历史类	448	100243	1373
2963	湖北	2025	历史类	447	101360	1117
2964	湖北	2025	历史类	446	101740	380
2965	湖北	2025	历史类	445	102960	1220
2966	湖北	2025	历史类	444	104075	1115
2967	湖北	2025	历史类	443	104922	847
2968	湖北	2025	历史类	442	105365	443
2969	湖北	2025	历史类	441	106583	1218
2970	湖北	2025	历史类	440	106819	236
2971	湖北	2025	历史类	439	107229	410
2972	湖北	2025	历史类	438	108255	1026
2973	湖北	2025	历史类	437	109299	1044
2974	湖北	2025	历史类	436	109572	273
2975	湖北	2025	历史类	435	110913	1341
2976	湖北	2025	历史类	434	112237	1324
2977	湖北	2025	历史类	433	112437	200
2978	湖北	2025	历史类	432	112823	386
2979	湖北	2025	历史类	431	114260	1437
2980	湖北	2025	历史类	430	115727	1467
2981	湖北	2025	历史类	429	116550	823
2982	湖北	2025	历史类	428	117791	1241
2983	湖北	2025	历史类	427	119142	1351
2984	湖北	2025	历史类	426	119765	623
2985	湖北	2025	历史类	425	120899	1134
2986	湖北	2025	历史类	424	121797	898
2987	湖北	2025	历史类	423	122741	944
2988	湖北	2025	历史类	422	123052	311
2989	湖北	2025	历史类	421	123708	656
2990	湖北	2025	历史类	420	124838	1130
2991	湖北	2025	历史类	419	125717	879
2992	湖北	2025	历史类	418	127064	1347
2993	湖北	2025	历史类	417	128533	1469
2994	湖北	2025	历史类	416	129961	1428
2995	湖北	2025	历史类	415	131129	1168
2996	湖北	2025	历史类	414	132073	944
2997	湖北	2025	历史类	413	133199	1126
2998	湖北	2025	历史类	412	133632	433
2999	湖北	2025	历史类	411	134031	399
3000	湖北	2025	历史类	410	134685	654
3001	湖北	2025	历史类	409	134889	204
3002	湖北	2025	历史类	408	135788	899
3003	湖北	2025	历史类	407	136715	927
3004	湖北	2025	历史类	406	138212	1497
3005	湖北	2025	历史类	405	139009	797
3006	湖北	2025	历史类	404	140330	1321
3007	湖北	2025	历史类	403	141599	1269
3008	湖北	2025	历史类	402	142564	965
3009	湖北	2025	历史类	401	142981	417
3010	湖北	2025	历史类	400	143274	293
\.


--
-- Data for Name: zhiyuan_universities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zhiyuan_universities (id, name, province, city, level, type, nature, website, intro, master_points, doctor_points, key_disciplines) FROM stdin;
1	清华大学	北京	北京	985	综合	公办			55	40	计算机科学与技术,电子科学与技术,机械工程
2	北京大学	北京	北京	985	综合	公办			53	38	数学,物理学,中国语言文学
3	浙江大学	浙江	杭州	985	综合	公办			50	35	计算机科学与技术,光学工程,控制科学与工程
4	上海交通大学	上海	上海	985	理工	公办			48	33	机械工程,船舶与海洋工程,电子信息
5	复旦大学	上海	上海	985	综合	公办			45	30	数学,物理学,基础医学
6	南京大学	江苏	南京	985	综合	公办			42	28	天文学,地质学,物理学
7	中国科学技术大学	安徽	合肥	985	理工	公办			38	25	物理学,化学,数学
8	哈尔滨工业大学	黑龙江	哈尔滨	985	理工	公办			40	26	机械工程,材料科学,航天
9	西安交通大学	陕西	西安	985	综合	公办			42	27	电气工程,动力工程,管理科学
10	武汉大学	湖北	武汉	985	综合	公办			46	30	测绘科学,水利工程,法学
11	武汉理工大学	湖北	武汉	211	理工	公办			30	15	材料科学,船舶与海洋工程
12	华中师范大学	湖北	武汉	211	师范	公办			28	12	教育学,中国语言文学
13	中南财经政法大学	湖北	武汉	211	财经	公办			20	8	应用经济学,法学
14	南京理工大学	江苏	南京	211	理工	公办			25	12	兵器科学,光学工程
15	郑州大学	河南	郑州	211	综合	公办			35	18	化学,材料科学,临床医学
16	河南大学	河南	开封	双一流	综合	公办			25	10	生物学,地理学
17	山东大学	山东	济南	985	综合	公办			44	28	数学,材料科学,临床医学
18	中国海洋大学	山东	青岛	985	综合	公办			22	12	海洋科学,水产
19	湖北工业大学	湖北	武汉	普通	理工	公办			12	2	轻工技术
20	武汉科技大学	湖北	武汉	普通	理工	公办			10	3	材料科学,冶金工程
21	河南科技大学	河南	洛阳	普通	理工	公办			8	1	机械工程
22	河南工业大学	河南	郑州	普通	理工	公办			7	1	食品科学
23	山东科技大学	山东	青岛	普通	理工	公办			9	2	矿业工程,安全科学
24	济南大学	山东	济南	普通	综合	公办			10	2	材料科学,化学
\.


--
-- Name: agent_envs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agent_envs_id_seq', 1, false);


--
-- Name: agent_run_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agent_run_requests_id_seq', 3, true);


--
-- Name: agents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agents_id_seq', 6, true);


--
-- Name: api_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_keys_id_seq', 1, true);


--
-- Name: cli_auth_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cli_auth_sessions_id_seq', 1, false);


--
-- Name: config_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.config_options_id_seq', 4, true);


--
-- Name: conversation_stats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conversation_stats_id_seq', 3, true);


--
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conversations_id_seq', 3, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 3, true);


--
-- Name: evaluation_dataset_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.evaluation_dataset_items_id_seq', 1, false);


--
-- Name: evaluation_datasets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.evaluation_datasets_id_seq', 1, false);


--
-- Name: evaluation_run_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.evaluation_run_items_id_seq', 1, false);


--
-- Name: evaluation_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.evaluation_runs_id_seq', 1, false);


--
-- Name: knowledge_bases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_bases_id_seq', 1, true);


--
-- Name: knowledge_chunks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_chunks_id_seq', 1, true);


--
-- Name: knowledge_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_files_id_seq', 1, true);


--
-- Name: knowledge_graph_entities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_graph_entities_id_seq', 1, false);


--
-- Name: knowledge_graph_entity_mentions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_graph_entity_mentions_id_seq', 1, false);


--
-- Name: knowledge_graph_triple_mentions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_graph_triple_mentions_id_seq', 1, false);


--
-- Name: knowledge_graph_triples_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.knowledge_graph_triples_id_seq', 1, false);


--
-- Name: mcp_servers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mcp_servers_id_seq', 1, true);


--
-- Name: message_feedbacks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.message_feedbacks_id_seq', 1, false);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.messages_id_seq', 6, true);


--
-- Name: model_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.model_providers_id_seq', 22, true);


--
-- Name: operation_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operation_logs_id_seq', 30, true);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.skills_id_seq', 6, true);


--
-- Name: subagent_threads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.subagent_threads_id_seq', 1, false);


--
-- Name: tool_calls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tool_calls_id_seq', 1, false);


--
-- Name: user_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_config_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 21, true);


--
-- Name: zhiyuan_admission_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_admission_scores_id_seq', 361, true);


--
-- Name: zhiyuan_colleges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_colleges_id_seq', 1, false);


--
-- Name: zhiyuan_enrollment_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_enrollment_plans_id_seq', 61, true);


--
-- Name: zhiyuan_majors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_majors_id_seq', 103, true);


--
-- Name: zhiyuan_province_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_province_rules_id_seq', 3, true);


--
-- Name: zhiyuan_score_ranks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_score_ranks_id_seq', 3010, true);


--
-- Name: zhiyuan_universities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.zhiyuan_universities_id_seq', 24, true);


--
-- Name: agent_envs agent_envs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_envs
    ADD CONSTRAINT agent_envs_pkey PRIMARY KEY (id);


--
-- Name: agent_run_requests agent_run_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_requests
    ADD CONSTRAINT agent_run_requests_pkey PRIMARY KEY (id);


--
-- Name: agent_runs agent_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: checkpoint_blobs checkpoint_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_blobs
    ADD CONSTRAINT checkpoint_blobs_pkey PRIMARY KEY (thread_id, checkpoint_ns, channel, version);


--
-- Name: checkpoint_migrations checkpoint_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_migrations
    ADD CONSTRAINT checkpoint_migrations_pkey PRIMARY KEY (v);


--
-- Name: checkpoint_writes checkpoint_writes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoint_writes
    ADD CONSTRAINT checkpoint_writes_pkey PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id, task_id, idx);


--
-- Name: checkpoints checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkpoints
    ADD CONSTRAINT checkpoints_pkey PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id);


--
-- Name: cli_auth_sessions cli_auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cli_auth_sessions
    ADD CONSTRAINT cli_auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: config_options config_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_options
    ADD CONSTRAINT config_options_pkey PRIMARY KEY (id);


--
-- Name: conversation_stats conversation_stats_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_stats
    ADD CONSTRAINT conversation_stats_conversation_id_key UNIQUE (conversation_id);


--
-- Name: conversation_stats conversation_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_stats
    ADD CONSTRAINT conversation_stats_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: evaluation_dataset_items evaluation_dataset_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items
    ADD CONSTRAINT evaluation_dataset_items_pkey PRIMARY KEY (id);


--
-- Name: evaluation_datasets evaluation_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_datasets
    ADD CONSTRAINT evaluation_datasets_pkey PRIMARY KEY (id);


--
-- Name: evaluation_run_items evaluation_run_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_run_items
    ADD CONSTRAINT evaluation_run_items_pkey PRIMARY KEY (id);


--
-- Name: evaluation_runs evaluation_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_runs
    ADD CONSTRAINT evaluation_runs_pkey PRIMARY KEY (id);


--
-- Name: knowledge_bases knowledge_bases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_bases
    ADD CONSTRAINT knowledge_bases_pkey PRIMARY KEY (id);


--
-- Name: knowledge_chunks knowledge_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT knowledge_chunks_pkey PRIMARY KEY (id);


--
-- Name: knowledge_files knowledge_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_files
    ADD CONSTRAINT knowledge_files_pkey PRIMARY KEY (id);


--
-- Name: knowledge_graph_entities knowledge_graph_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entities
    ADD CONSTRAINT knowledge_graph_entities_pkey PRIMARY KEY (id);


--
-- Name: knowledge_graph_entity_mentions knowledge_graph_entity_mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT knowledge_graph_entity_mentions_pkey PRIMARY KEY (id);


--
-- Name: knowledge_graph_triple_mentions knowledge_graph_triple_mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT knowledge_graph_triple_mentions_pkey PRIMARY KEY (id);


--
-- Name: knowledge_graph_triples knowledge_graph_triples_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples
    ADD CONSTRAINT knowledge_graph_triples_pkey PRIMARY KEY (id);


--
-- Name: mcp_servers mcp_servers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_servers
    ADD CONSTRAINT mcp_servers_pkey PRIMARY KEY (id);


--
-- Name: message_feedbacks message_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_feedbacks
    ADD CONSTRAINT message_feedbacks_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: model_providers model_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_providers
    ADD CONSTRAINT model_providers_pkey PRIMARY KEY (id);


--
-- Name: operation_logs operation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_logs
    ADD CONSTRAINT operation_logs_pkey PRIMARY KEY (id);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: subagent_threads subagent_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subagent_threads
    ADD CONSTRAINT subagent_threads_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tool_calls tool_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_pkey PRIMARY KEY (id);


--
-- Name: evaluation_dataset_items uq_evaluation_dataset_items_dataset_index; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items
    ADD CONSTRAINT uq_evaluation_dataset_items_dataset_index UNIQUE (dataset_id, item_index);


--
-- Name: evaluation_dataset_items uq_evaluation_dataset_items_item_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items
    ADD CONSTRAINT uq_evaluation_dataset_items_item_id UNIQUE (item_id);


--
-- Name: evaluation_datasets uq_evaluation_datasets_dataset_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_datasets
    ADD CONSTRAINT uq_evaluation_datasets_dataset_id UNIQUE (dataset_id);


--
-- Name: evaluation_run_items uq_evaluation_run_items_run_index; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_run_items
    ADD CONSTRAINT uq_evaluation_run_items_run_index UNIQUE (run_id, item_index);


--
-- Name: evaluation_runs uq_evaluation_runs_run_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_runs
    ADD CONSTRAINT uq_evaluation_runs_run_id UNIQUE (run_id);


--
-- Name: knowledge_bases uq_knowledge_bases_kb_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_bases
    ADD CONSTRAINT uq_knowledge_bases_kb_id UNIQUE (kb_id);


--
-- Name: knowledge_chunks uq_knowledge_chunks_chunk_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT uq_knowledge_chunks_chunk_id UNIQUE (chunk_id);


--
-- Name: knowledge_files uq_knowledge_files_file_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_files
    ADD CONSTRAINT uq_knowledge_files_file_id UNIQUE (file_id);


--
-- Name: knowledge_graph_entities uq_knowledge_graph_entities_entity_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entities
    ADD CONSTRAINT uq_knowledge_graph_entities_entity_id UNIQUE (entity_id);


--
-- Name: knowledge_graph_entities uq_knowledge_graph_entities_identity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entities
    ADD CONSTRAINT uq_knowledge_graph_entities_identity UNIQUE (kb_id, normalized_name, label);


--
-- Name: knowledge_graph_entity_mentions uq_knowledge_graph_entity_mentions_entity_chunk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT uq_knowledge_graph_entity_mentions_entity_chunk UNIQUE (entity_id, chunk_id);


--
-- Name: knowledge_graph_triple_mentions uq_knowledge_graph_triple_mentions_triple_chunk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT uq_knowledge_graph_triple_mentions_triple_chunk UNIQUE (triple_id, chunk_id);


--
-- Name: knowledge_graph_triples uq_knowledge_graph_triples_triple_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples
    ADD CONSTRAINT uq_knowledge_graph_triples_triple_id UNIQUE (triple_id);


--
-- Name: user_config user_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_config
    ADD CONSTRAINT user_config_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_admission_scores zhiyuan_admission_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_admission_scores
    ADD CONSTRAINT zhiyuan_admission_scores_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_colleges zhiyuan_colleges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_colleges
    ADD CONSTRAINT zhiyuan_colleges_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_enrollment_plans zhiyuan_enrollment_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_enrollment_plans
    ADD CONSTRAINT zhiyuan_enrollment_plans_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_majors zhiyuan_majors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_majors
    ADD CONSTRAINT zhiyuan_majors_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_province_rules zhiyuan_province_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_province_rules
    ADD CONSTRAINT zhiyuan_province_rules_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_province_rules zhiyuan_province_rules_province_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_province_rules
    ADD CONSTRAINT zhiyuan_province_rules_province_key UNIQUE (province);


--
-- Name: zhiyuan_score_ranks zhiyuan_score_ranks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_score_ranks
    ADD CONSTRAINT zhiyuan_score_ranks_pkey PRIMARY KEY (id);


--
-- Name: zhiyuan_universities zhiyuan_universities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zhiyuan_universities
    ADD CONSTRAINT zhiyuan_universities_pkey PRIMARY KEY (id);


--
-- Name: checkpoint_blobs_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoint_blobs_thread_id_idx ON public.checkpoint_blobs USING btree (thread_id);


--
-- Name: checkpoint_writes_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoint_writes_thread_id_idx ON public.checkpoint_writes USING btree (thread_id);


--
-- Name: checkpoints_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX checkpoints_thread_id_idx ON public.checkpoints USING btree (thread_id);


--
-- Name: idx_agent_runs_conversation_thread_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_runs_conversation_thread_created ON public.agent_runs USING btree (conversation_thread_id, created_at DESC);


--
-- Name: idx_agent_runs_created_by_run_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_runs_created_by_run_created ON public.agent_runs USING btree (created_by_run_id, created_at DESC);


--
-- Name: idx_agent_runs_status_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_runs_status_updated ON public.agent_runs USING btree (status, updated_at);


--
-- Name: idx_agent_runs_subagent_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_runs_subagent_lookup ON public.agent_runs USING btree (uid, conversation_thread_id, run_type, created_at DESC);


--
-- Name: idx_agent_runs_uid_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_runs_uid_created ON public.agent_runs USING btree (uid, created_at DESC);


--
-- Name: idx_kb_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_name ON public.knowledge_bases USING btree (name);


--
-- Name: idx_kb_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kb_type ON public.knowledge_bases USING btree (kb_type);


--
-- Name: idx_kf_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kf_hash ON public.knowledge_files USING btree (content_hash);


--
-- Name: idx_kf_kb_filename; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kf_kb_filename ON public.knowledge_files USING btree (kb_id, filename);


--
-- Name: idx_kf_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kf_kb_id ON public.knowledge_files USING btree (kb_id);


--
-- Name: idx_kf_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kf_parent ON public.knowledge_files USING btree (parent_id);


--
-- Name: idx_kf_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kf_status ON public.knowledge_files USING btree (status);


--
-- Name: ix_agent_envs_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_agent_envs_uid ON public.agent_envs USING btree (uid);


--
-- Name: ix_agent_run_requests_dispatched_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_run_requests_dispatched_run_id ON public.agent_run_requests USING btree (dispatched_run_id);


--
-- Name: ix_agent_run_requests_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_run_requests_queue ON public.agent_run_requests USING btree (uid, agent_slug, conversation_thread_id, status, created_at, id);


--
-- Name: ix_agent_run_requests_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_agent_run_requests_request_id ON public.agent_run_requests USING btree (request_id);


--
-- Name: ix_agent_runs_agent_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_agent_slug ON public.agent_runs USING btree (agent_slug);


--
-- Name: ix_agent_runs_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_conversation_id ON public.agent_runs USING btree (conversation_id);


--
-- Name: ix_agent_runs_conversation_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_conversation_thread_id ON public.agent_runs USING btree (conversation_thread_id);


--
-- Name: ix_agent_runs_created_by_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_created_by_run_id ON public.agent_runs USING btree (created_by_run_id);


--
-- Name: ix_agent_runs_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_agent_runs_request_id ON public.agent_runs USING btree (request_id);


--
-- Name: ix_agent_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_status ON public.agent_runs USING btree (status);


--
-- Name: ix_agent_runs_subagent_thread_relation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_subagent_thread_relation_id ON public.agent_runs USING btree (subagent_thread_relation_id);


--
-- Name: ix_agent_runs_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agent_runs_uid ON public.agent_runs USING btree (uid);


--
-- Name: ix_agents_backend_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agents_backend_id ON public.agents USING btree (backend_id);


--
-- Name: ix_agents_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agents_created_by ON public.agents USING btree (created_by);


--
-- Name: ix_agents_is_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agents_is_default ON public.agents USING btree (is_default);


--
-- Name: ix_agents_is_subagent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_agents_is_subagent ON public.agents USING btree (is_subagent);


--
-- Name: ix_agents_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_agents_slug ON public.agents USING btree (slug);


--
-- Name: ix_api_keys_department_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_api_keys_department_id ON public.api_keys USING btree (department_id);


--
-- Name: ix_api_keys_key_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_api_keys_key_hash ON public.api_keys USING btree (key_hash);


--
-- Name: ix_api_keys_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_api_keys_user_id ON public.api_keys USING btree (user_id);


--
-- Name: ix_cli_auth_sessions_api_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_cli_auth_sessions_api_key_id ON public.cli_auth_sessions USING btree (api_key_id);


--
-- Name: ix_cli_auth_sessions_approved_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_cli_auth_sessions_approved_user_id ON public.cli_auth_sessions USING btree (approved_user_id);


--
-- Name: ix_cli_auth_sessions_device_code_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_cli_auth_sessions_device_code_hash ON public.cli_auth_sessions USING btree (device_code_hash);


--
-- Name: ix_cli_auth_sessions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_cli_auth_sessions_status ON public.cli_auth_sessions USING btree (status);


--
-- Name: ix_cli_auth_sessions_user_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_cli_auth_sessions_user_code ON public.cli_auth_sessions USING btree (user_code);


--
-- Name: ix_config_options_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_config_options_key ON public.config_options USING btree (key);


--
-- Name: ix_conversations_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversations_agent_id ON public.conversations USING btree (agent_id);


--
-- Name: ix_conversations_is_pinned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversations_is_pinned ON public.conversations USING btree (is_pinned);


--
-- Name: ix_conversations_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_conversations_thread_id ON public.conversations USING btree (thread_id);


--
-- Name: ix_conversations_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_conversations_uid ON public.conversations USING btree (uid);


--
-- Name: ix_departments_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_departments_name ON public.departments USING btree (name);


--
-- Name: ix_evaluation_dataset_items_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_dataset_items_dataset_id ON public.evaluation_dataset_items USING btree (dataset_id);


--
-- Name: ix_evaluation_dataset_items_dataset_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_dataset_items_dataset_index ON public.evaluation_dataset_items USING btree (dataset_id, item_index);


--
-- Name: ix_evaluation_dataset_items_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_evaluation_dataset_items_item_id ON public.evaluation_dataset_items USING btree (item_id);


--
-- Name: ix_evaluation_dataset_items_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_dataset_items_kb_id ON public.evaluation_dataset_items USING btree (kb_id);


--
-- Name: ix_evaluation_datasets_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_evaluation_datasets_dataset_id ON public.evaluation_datasets USING btree (dataset_id);


--
-- Name: ix_evaluation_datasets_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_datasets_kb_id ON public.evaluation_datasets USING btree (kb_id);


--
-- Name: ix_evaluation_run_items_dataset_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_run_items_dataset_item_id ON public.evaluation_run_items USING btree (dataset_item_id);


--
-- Name: ix_evaluation_run_items_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_run_items_run_id ON public.evaluation_run_items USING btree (run_id);


--
-- Name: ix_evaluation_run_items_run_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_run_items_run_index ON public.evaluation_run_items USING btree (run_id, item_index);


--
-- Name: ix_evaluation_runs_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_runs_dataset_id ON public.evaluation_runs USING btree (dataset_id);


--
-- Name: ix_evaluation_runs_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_runs_kb_id ON public.evaluation_runs USING btree (kb_id);


--
-- Name: ix_evaluation_runs_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_evaluation_runs_run_id ON public.evaluation_runs USING btree (run_id);


--
-- Name: ix_evaluation_runs_started; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_runs_started ON public.evaluation_runs USING btree (started_at DESC);


--
-- Name: ix_evaluation_runs_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_runs_started_at ON public.evaluation_runs USING btree (started_at);


--
-- Name: ix_evaluation_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evaluation_runs_status ON public.evaluation_runs USING btree (status);


--
-- Name: ix_knowledge_bases_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_knowledge_bases_kb_id ON public.knowledge_bases USING btree (kb_id);


--
-- Name: ix_knowledge_bases_kb_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_bases_kb_type ON public.knowledge_bases USING btree (kb_type);


--
-- Name: ix_knowledge_bases_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_bases_name ON public.knowledge_bases USING btree (name);


--
-- Name: ix_knowledge_chunks_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_chunks_file_id ON public.knowledge_chunks USING btree (file_id);


--
-- Name: ix_knowledge_chunks_graph_extraction_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_chunks_graph_extraction_status ON public.knowledge_chunks USING btree (kb_id, ((graph_extraction_details ->> 'status'::text)));


--
-- Name: ix_knowledge_chunks_graph_indexed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_chunks_graph_indexed ON public.knowledge_chunks USING btree (graph_indexed);


--
-- Name: ix_knowledge_chunks_graph_structure_indexed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_chunks_graph_structure_indexed ON public.knowledge_chunks USING btree (graph_structure_indexed);


--
-- Name: ix_knowledge_chunks_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_chunks_kb_id ON public.knowledge_chunks USING btree (kb_id);


--
-- Name: ix_knowledge_files_content_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_files_content_hash ON public.knowledge_files USING btree (content_hash);


--
-- Name: ix_knowledge_files_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_knowledge_files_file_id ON public.knowledge_files USING btree (file_id);


--
-- Name: ix_knowledge_files_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_files_kb_id ON public.knowledge_files USING btree (kb_id);


--
-- Name: ix_knowledge_files_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_files_parent_id ON public.knowledge_files USING btree (parent_id);


--
-- Name: ix_knowledge_files_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_files_status ON public.knowledge_files USING btree (status);


--
-- Name: ix_knowledge_graph_entities_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_entities_kb_id ON public.knowledge_graph_entities USING btree (kb_id);


--
-- Name: ix_knowledge_graph_entities_vector_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_entities_vector_pending ON public.knowledge_graph_entities USING btree (kb_id, vector_status, vector_next_retry_at);


--
-- Name: ix_knowledge_graph_entity_mentions_chunk_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_entity_mentions_chunk_id ON public.knowledge_graph_entity_mentions USING btree (chunk_id);


--
-- Name: ix_knowledge_graph_entity_mentions_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_entity_mentions_file_id ON public.knowledge_graph_entity_mentions USING btree (file_id);


--
-- Name: ix_knowledge_graph_entity_mentions_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_entity_mentions_kb_id ON public.knowledge_graph_entity_mentions USING btree (kb_id);


--
-- Name: ix_knowledge_graph_triple_mentions_chunk_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_triple_mentions_chunk_id ON public.knowledge_graph_triple_mentions USING btree (chunk_id);


--
-- Name: ix_knowledge_graph_triple_mentions_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_triple_mentions_file_id ON public.knowledge_graph_triple_mentions USING btree (file_id);


--
-- Name: ix_knowledge_graph_triple_mentions_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_triple_mentions_kb_id ON public.knowledge_graph_triple_mentions USING btree (kb_id);


--
-- Name: ix_knowledge_graph_triples_kb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_triples_kb_id ON public.knowledge_graph_triples USING btree (kb_id);


--
-- Name: ix_knowledge_graph_triples_vector_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_knowledge_graph_triples_vector_pending ON public.knowledge_graph_triples USING btree (kb_id, vector_status, vector_next_retry_at);


--
-- Name: ix_mcp_servers_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_mcp_servers_slug ON public.mcp_servers USING btree (slug);


--
-- Name: ix_message_feedbacks_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_feedbacks_message_id ON public.message_feedbacks USING btree (message_id);


--
-- Name: ix_message_feedbacks_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_message_feedbacks_uid ON public.message_feedbacks USING btree (uid);


--
-- Name: ix_messages_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messages_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: ix_messages_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messages_request_id ON public.messages USING btree (request_id);


--
-- Name: ix_messages_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_messages_run_id ON public.messages USING btree (run_id);


--
-- Name: ix_model_providers_is_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_model_providers_is_enabled ON public.model_providers USING btree (is_enabled);


--
-- Name: ix_model_providers_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_model_providers_provider_id ON public.model_providers USING btree (provider_id);


--
-- Name: ix_skills_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_skills_slug ON public.skills USING btree (slug);


--
-- Name: ix_skills_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_skills_source_type ON public.skills USING btree (source_type);


--
-- Name: ix_subagent_threads_child_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_subagent_threads_child_conversation_id ON public.subagent_threads USING btree (child_conversation_id);


--
-- Name: ix_subagent_threads_child_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_subagent_threads_child_thread_id ON public.subagent_threads USING btree (child_thread_id);


--
-- Name: ix_subagent_threads_created_by_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_subagent_threads_created_by_run_id ON public.subagent_threads USING btree (created_by_run_id);


--
-- Name: ix_subagent_threads_parent_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_subagent_threads_parent_conversation ON public.subagent_threads USING btree (parent_conversation_id);


--
-- Name: ix_subagent_threads_parent_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_subagent_threads_parent_conversation_id ON public.subagent_threads USING btree (parent_conversation_id);


--
-- Name: ix_subagent_threads_subagent_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_subagent_threads_subagent_slug ON public.subagent_threads USING btree (subagent_slug);


--
-- Name: ix_subagent_threads_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_subagent_threads_uid ON public.subagent_threads USING btree (uid);


--
-- Name: ix_tasks_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tasks_created_at ON public.tasks USING btree (created_at);


--
-- Name: ix_tasks_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tasks_status ON public.tasks USING btree (status);


--
-- Name: ix_tasks_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tasks_type ON public.tasks USING btree (type);


--
-- Name: ix_tool_calls_langgraph_tool_call_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tool_calls_langgraph_tool_call_id ON public.tool_calls USING btree (langgraph_tool_call_id);


--
-- Name: ix_tool_calls_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tool_calls_message_id ON public.tool_calls USING btree (message_id);


--
-- Name: ix_user_config_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_user_config_uid ON public.user_config USING btree (uid);


--
-- Name: ix_users_is_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_is_deleted ON public.users USING btree (is_deleted);


--
-- Name: ix_users_phone_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_phone_number ON public.users USING btree (phone_number);


--
-- Name: ix_users_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_uid ON public.users USING btree (uid);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: ix_zhiyuan_admission_scores_major_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_admission_scores_major_id ON public.zhiyuan_admission_scores USING btree (major_id);


--
-- Name: ix_zhiyuan_admission_scores_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_admission_scores_province ON public.zhiyuan_admission_scores USING btree (province);


--
-- Name: ix_zhiyuan_admission_scores_university_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_admission_scores_university_id ON public.zhiyuan_admission_scores USING btree (university_id);


--
-- Name: ix_zhiyuan_admission_scores_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_admission_scores_year ON public.zhiyuan_admission_scores USING btree (year);


--
-- Name: ix_zhiyuan_colleges_university_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_colleges_university_id ON public.zhiyuan_colleges USING btree (university_id);


--
-- Name: ix_zhiyuan_enrollment_plans_major_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_enrollment_plans_major_id ON public.zhiyuan_enrollment_plans USING btree (major_id);


--
-- Name: ix_zhiyuan_enrollment_plans_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_enrollment_plans_province ON public.zhiyuan_enrollment_plans USING btree (province);


--
-- Name: ix_zhiyuan_enrollment_plans_university_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_enrollment_plans_university_id ON public.zhiyuan_enrollment_plans USING btree (university_id);


--
-- Name: ix_zhiyuan_enrollment_plans_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_enrollment_plans_year ON public.zhiyuan_enrollment_plans USING btree (year);


--
-- Name: ix_zhiyuan_majors_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_majors_name ON public.zhiyuan_majors USING btree (name);


--
-- Name: ix_zhiyuan_majors_university_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_majors_university_id ON public.zhiyuan_majors USING btree (university_id);


--
-- Name: ix_zhiyuan_score_ranks_province; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_score_ranks_province ON public.zhiyuan_score_ranks USING btree (province);


--
-- Name: ix_zhiyuan_score_ranks_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_score_ranks_score ON public.zhiyuan_score_ranks USING btree (score);


--
-- Name: ix_zhiyuan_score_ranks_subject_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_score_ranks_subject_type ON public.zhiyuan_score_ranks USING btree (subject_type);


--
-- Name: ix_zhiyuan_score_ranks_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_score_ranks_year ON public.zhiyuan_score_ranks USING btree (year);


--
-- Name: ix_zhiyuan_universities_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zhiyuan_universities_name ON public.zhiyuan_universities USING btree (name);


--
-- Name: uq_agent_runs_one_active_per_thread; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_agent_runs_one_active_per_thread ON public.agent_runs USING btree (uid, agent_slug, conversation_thread_id) WHERE ((status)::text <> ALL ((ARRAY['completed'::character varying, 'failed'::character varying, 'cancelled'::character varying, 'interrupted'::character varying])::text[]));


--
-- Name: uq_agents_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_agents_default ON public.agents USING btree (is_default) WHERE (is_default IS TRUE);


--
-- Name: agent_envs agent_envs_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_envs
    ADD CONSTRAINT agent_envs_uid_fkey FOREIGN KEY (uid) REFERENCES public.users(uid);


--
-- Name: agent_run_requests agent_run_requests_dispatched_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_requests
    ADD CONSTRAINT agent_run_requests_dispatched_run_id_fkey FOREIGN KEY (dispatched_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_run_requests agent_run_requests_input_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_requests
    ADD CONSTRAINT agent_run_requests_input_message_id_fkey FOREIGN KEY (input_message_id) REFERENCES public.messages(id);


--
-- Name: agent_runs agent_runs_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: agent_runs agent_runs_subagent_thread_relation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_subagent_thread_relation_id_fkey FOREIGN KEY (subagent_thread_relation_id) REFERENCES public.subagent_threads(id);


--
-- Name: api_keys api_keys_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cli_auth_sessions cli_auth_sessions_api_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cli_auth_sessions
    ADD CONSTRAINT cli_auth_sessions_api_key_id_fkey FOREIGN KEY (api_key_id) REFERENCES public.api_keys(id);


--
-- Name: cli_auth_sessions cli_auth_sessions_approved_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cli_auth_sessions
    ADD CONSTRAINT cli_auth_sessions_approved_user_id_fkey FOREIGN KEY (approved_user_id) REFERENCES public.users(id);


--
-- Name: conversation_stats conversation_stats_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_stats
    ADD CONSTRAINT conversation_stats_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: evaluation_dataset_items evaluation_dataset_items_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items
    ADD CONSTRAINT evaluation_dataset_items_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.evaluation_datasets(dataset_id) ON DELETE CASCADE;


--
-- Name: evaluation_dataset_items evaluation_dataset_items_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_dataset_items
    ADD CONSTRAINT evaluation_dataset_items_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: evaluation_datasets evaluation_datasets_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_datasets
    ADD CONSTRAINT evaluation_datasets_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: evaluation_run_items evaluation_run_items_dataset_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_run_items
    ADD CONSTRAINT evaluation_run_items_dataset_item_id_fkey FOREIGN KEY (dataset_item_id) REFERENCES public.evaluation_dataset_items(item_id) ON DELETE SET NULL;


--
-- Name: evaluation_run_items evaluation_run_items_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_run_items
    ADD CONSTRAINT evaluation_run_items_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.evaluation_runs(run_id) ON DELETE CASCADE;


--
-- Name: evaluation_runs evaluation_runs_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_runs
    ADD CONSTRAINT evaluation_runs_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.evaluation_datasets(dataset_id) ON DELETE SET NULL;


--
-- Name: evaluation_runs evaluation_runs_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluation_runs
    ADD CONSTRAINT evaluation_runs_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_chunks knowledge_chunks_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT knowledge_chunks_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.knowledge_files(file_id) ON DELETE CASCADE;


--
-- Name: knowledge_chunks knowledge_chunks_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT knowledge_chunks_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_files knowledge_files_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_files
    ADD CONSTRAINT knowledge_files_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_files knowledge_files_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_files
    ADD CONSTRAINT knowledge_files_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.knowledge_files(file_id) ON DELETE SET NULL;


--
-- Name: knowledge_graph_entities knowledge_graph_entities_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entities
    ADD CONSTRAINT knowledge_graph_entities_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_entity_mentions knowledge_graph_entity_mentions_chunk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT knowledge_graph_entity_mentions_chunk_id_fkey FOREIGN KEY (chunk_id) REFERENCES public.knowledge_chunks(chunk_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_entity_mentions knowledge_graph_entity_mentions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT knowledge_graph_entity_mentions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.knowledge_graph_entities(entity_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_entity_mentions knowledge_graph_entity_mentions_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT knowledge_graph_entity_mentions_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.knowledge_files(file_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_entity_mentions knowledge_graph_entity_mentions_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_entity_mentions
    ADD CONSTRAINT knowledge_graph_entity_mentions_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triple_mentions knowledge_graph_triple_mentions_chunk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT knowledge_graph_triple_mentions_chunk_id_fkey FOREIGN KEY (chunk_id) REFERENCES public.knowledge_chunks(chunk_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triple_mentions knowledge_graph_triple_mentions_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT knowledge_graph_triple_mentions_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.knowledge_files(file_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triple_mentions knowledge_graph_triple_mentions_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT knowledge_graph_triple_mentions_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triple_mentions knowledge_graph_triple_mentions_triple_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triple_mentions
    ADD CONSTRAINT knowledge_graph_triple_mentions_triple_id_fkey FOREIGN KEY (triple_id) REFERENCES public.knowledge_graph_triples(triple_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triples knowledge_graph_triples_kb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples
    ADD CONSTRAINT knowledge_graph_triples_kb_id_fkey FOREIGN KEY (kb_id) REFERENCES public.knowledge_bases(kb_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triples knowledge_graph_triples_source_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples
    ADD CONSTRAINT knowledge_graph_triples_source_entity_id_fkey FOREIGN KEY (source_entity_id) REFERENCES public.knowledge_graph_entities(entity_id) ON DELETE CASCADE;


--
-- Name: knowledge_graph_triples knowledge_graph_triples_target_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_graph_triples
    ADD CONSTRAINT knowledge_graph_triples_target_entity_id_fkey FOREIGN KEY (target_entity_id) REFERENCES public.knowledge_graph_entities(entity_id) ON DELETE CASCADE;


--
-- Name: message_feedbacks message_feedbacks_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_feedbacks
    ADD CONSTRAINT message_feedbacks_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: messages messages_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.agent_runs(id);


--
-- Name: operation_logs operation_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operation_logs
    ADD CONSTRAINT operation_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subagent_threads subagent_threads_child_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subagent_threads
    ADD CONSTRAINT subagent_threads_child_conversation_id_fkey FOREIGN KEY (child_conversation_id) REFERENCES public.conversations(id);


--
-- Name: subagent_threads subagent_threads_parent_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subagent_threads
    ADD CONSTRAINT subagent_threads_parent_conversation_id_fkey FOREIGN KEY (parent_conversation_id) REFERENCES public.conversations(id);


--
-- Name: tool_calls tool_calls_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: user_config user_config_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_config
    ADD CONSTRAINT user_config_uid_fkey FOREIGN KEY (uid) REFERENCES public.users(uid);


--
-- Name: users users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- PostgreSQL database dump complete
--

\unrestrict iFcdOYD8NSEZWwLLrpTy7AqsPmLcunTtTPkYRLMmvkwiKT5Mir7BLJny4O754zf

