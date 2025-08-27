--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:vh3OXhMPIyhiF8ll3j0FNg==$dfoXFwubd94bxYzMO+QXtW9Se3/OEzVIFiKoyiop8PU=:/AewUjj9hek1ARGngOR0EwzlqvbyNeBr9PyEzbomHPE=';

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Debian 16.9-1.pgdg120+1)
-- Dumped by pg_dump version 16.9 (Debian 16.9-1.pgdg120+1)

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

--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Debian 16.9-1.pgdg120+1)
-- Dumped by pg_dump version 16.9 (Debian 16.9-1.pgdg120+1)

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

--
-- PostgreSQL database dump complete
--

--
-- Database "sxpr_db" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Debian 16.9-1.pgdg120+1)
-- Dumped by pg_dump version 16.9 (Debian 16.9-1.pgdg120+1)

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

--
-- Name: sxpr_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE sxpr_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE sxpr_db OWNER TO postgres;

\connect sxpr_db

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
-- Name: attempt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attempt (
    id bigint NOT NULL,
    problem_id bigint NOT NULL,
    submitted_text text NOT NULL,
    is_correct boolean NOT NULL,
    stage text,
    error_reason text,
    details_json jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id bigint
);


ALTER TABLE public.attempt OWNER TO postgres;

--
-- Name: attempt_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attempt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attempt_id_seq OWNER TO postgres;

--
-- Name: attempt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attempt_id_seq OWNED BY public.attempt.id;


--
-- Name: lesson; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lesson (
    id bigint NOT NULL,
    title text NOT NULL,
    body_md text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    validator_default text DEFAULT 'cfg'::text NOT NULL,
    validator_spec jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.lesson OWNER TO postgres;

--
-- Name: lesson_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lesson_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lesson_id_seq OWNER TO postgres;

--
-- Name: lesson_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lesson_id_seq OWNED BY public.lesson.id;


--
-- Name: problem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.problem (
    id bigint NOT NULL,
    lesson_id bigint NOT NULL,
    prompt_text text NOT NULL,
    answer_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    validator_kind text,
    validator_spec jsonb
);


ALTER TABLE public.problem OWNER TO postgres;

--
-- Name: problem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.problem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.problem_id_seq OWNER TO postgres;

--
-- Name: problem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.problem_id_seq OWNED BY public.problem.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    user_id bigint NOT NULL,
    active_lesson bigint,
    lessons bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    username text NOT NULL,
    CONSTRAINT user_active_in_lessons_chk CHECK (((active_lesson IS NULL) OR (active_lesson = ANY (lessons))))
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_user_id_seq OWNER TO postgres;

--
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- Name: attempt id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attempt ALTER COLUMN id SET DEFAULT nextval('public.attempt_id_seq'::regclass);


--
-- Name: lesson id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson ALTER COLUMN id SET DEFAULT nextval('public.lesson_id_seq'::regclass);


--
-- Name: problem id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.problem ALTER COLUMN id SET DEFAULT nextval('public.problem_id_seq'::regclass);


--
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- Data for Name: attempt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attempt (id, problem_id, submitted_text, is_correct, stage, error_reason, details_json, created_at, user_id) FROM stdin;
37	1	(+ 5 4)	t	eval	\N	{"tests": 1, "value": 9, "passed": 1, "results": [{"expr": "(+ 5 4)", "pass": true, "type": "expr", "index": 0, "actual": 9, "exprValue": 9}]}	2025-08-26 04:35:38.443412+00	4
38	2	(- 22 9)	t	eval	\N	{"tests": 1, "value": 13, "passed": 1, "results": [{"expr": "(- 22 9)", "pass": true, "type": "expr", "index": 0, "actual": 13, "exprValue": 13}]}	2025-08-26 04:36:07.372047+00	4
39	3	(* 2 24)	t	eval	\N	{"tests": 1, "value": 48, "passed": 1, "results": [{"expr": "(* 2 24)", "pass": true, "type": "expr", "index": 0, "actual": 48, "exprValue": 48}]}	2025-08-26 04:36:14.157703+00	4
\.


--
-- Data for Name: lesson; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lesson (id, title, body_md, created_at, validator_default, validator_spec) FROM stdin;
1	Intro to S-expressions	An S-expression is a syntax for expressing data and operations on the data.\r\n\r\nThe "S" in S-expression stands for "symbolic" so S-expression is shorthand for "Symbolic Expression."\r\n\r\nFor example, the expression `2 + 3` can be translated into an S-expression\r\n\r\n```lisp\r\n(+ 2 3)\r\n```\r\n\r\nNote the following:\r\n\r\n- An S-expression must *always* be surrounded by matched parentheses\r\n- The operation comes first. In the example above, this is an addition\r\n- The operation must be followed by the inputs to the operation\r\n\r\nExample:\r\n\r\nWrite `22 + 3` as an S-expression\r\n\r\nAnswer:\r\n\r\n(+ 22 3)\r\n\r\nNote that since the order of addition does not matter, we could have written the S-expression as (+ 3 22). However, that is not the case for operations where order matters.\r\n\r\nExample:\r\n\r\nWrite `56 - 4` as an S-expression\r\n\r\nAnswer:\r\n\r\n(- 56 4)\r\n\r\nWe need to know that 4 is being subtracted from 56, not 56 from 4. Therefore, the 56 goes first, followed by the 4.\r\n\r\nExample:\r\n\r\nWrite `2 * 6` as an S-expression. Here, * means "multiply"\r\n\r\nAnswer:\r\n\r\n(* 2 6)\r\n\r\nAgain, we write the operation first, followed by the inputs.	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "mem_mb": 64, "time_ms": 300}
2	Spaces within an S-expression	An s-expression always has the form\r\n\r\n`<left parenthesis> op data <right parenthesis>`\r\n\r\nFor example, `(+ 5 6)` is an s-expression that adds 5 to 6.\r\n\r\nAn s-expression can have multiple spaces in them. The following are valid s-expressions\r\n\r\n- `( + 5 6)`\r\n- `(+ 5     6)`\r\n- `( + 5 6 )`\r\n- `(   +  5  6 )`\r\n\r\nThe one rule is that we must keep at least one space between the operator and the data.\r\n\r\nFor example, the following is not a valid s-expression:\r\n\r\n`(+5 6)`\r\n\r\nbecause there is no space between + and 5.\r\n\r\nThe following is also not valid:\r\n\r\n`(+ 56)`\r\n\r\nFor neatness purposes, don't put any spaces next to the parentheses even though you are allowed to do so. Also, only use one space between the data and the operator.\r\n\r\nExample:\r\n\r\nMake the following s-expression neater\r\n\r\n( + 32  61 )\r\n\r\nAnswer:\r\n\r\n(+ 32 61)\r\n\r\nExample:\r\n\r\nMake the following s-expression neater\r\n\r\n( + 24  3)\r\n\r\nAnswer:\r\n\r\n(+ 24 3)	2025-08-21 05:58:15.038614+00	racket	{"lang": "racket/base", "mode": "eval", "mem_mb": 64, "time_ms": 300}
3	Fixing invalid S-expressions	An s-expression must always have the form\r\n\r\n`<left parenthesis> op data <right parenthesis>`\r\n\r\nFor example, `(* 2 3)` is an s-expression.\r\n\r\nIf any of these parts are missing, it is not a valid s-expression, and the computer cannot understand it.\r\n\r\nExample:\r\nFix the following s-expression (2 * 5)\r\n\r\nAnswer:\r\n(* 2 5)\r\n\r\nAlthough it looks like a valid math expression, it is not a valid s-expression because the operator must come first.\r\n\r\nExample:\r\nFix the following s-expression (- 12 3\r\n\r\nAnswer:\r\n(- 12 3)\r\n\r\nThe one above is missing a parenthesis on the right.	2025-08-21 09:15:12.659617+00	racket	{"lang": "racket/base", "mode": "eval", "mem_mb": 64, "time_ms": 300}
4	Negative numbers in S-expressions	We can put negative numbers into an s-expression. The syntax for this is what you would expect.\r\n\r\nThe following s-expression adds 3 to negative 1:\r\n\r\n(+ 3 -1)\r\n\r\nThe following expression multiplies 3 by -5:\r\n\r\n(* 3 -5)	2025-08-21 09:18:33.520669+00	racket	{"lang": "racket/base", "mode": "eval", "mem_mb": 64, "time_ms": 300}
5	Division in S-expressions	The symbol for division in s-expressions (and most programming languages) is /\r\n\r\nFor example, 6 ÷ 3 is written as\r\n\r\n(/ 6 3)\r\n\r\nOrder matters in division, so the following is completely wrong:\r\n\r\n(/ 3 6)\r\n\r\nIt is not important the division results in a fraction. The following s-expression is the correct transation of 7 ÷ 3\r\n\r\n(/ 7 3)	2025-08-21 09:25:27.664126+00	racket	{"lang": "racket/base", "mode": "eval", "mem_mb": 64, "time_ms": 300}
\.


--
-- Data for Name: problem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.problem (id, lesson_id, prompt_text, answer_text, created_at, validator_kind, validator_spec) FROM stdin;
1	1	Write 5 + 4 as an S-expression	(+ 5 4)	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 5 4)"}]}
2	1	Write 22 - 9 as an S-expression	(- 22 9)	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 22 9)"}]}
3	1	Write 2 * 24 as an S-expression	(* 2 24)	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 2 24)"}]}
4	1	Write 5 - 4 as an S-expression	(- 5 4)	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 5 4)"}]}
5	1	Write 3 * 3 as an S-expression	(* 3 3)	2025-08-20 04:07:18.105892+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 3 3)"}]}
6	1	Write (2 + 3) * 4 as an S-expression	(* (+ 2 3) 4)	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (+ 2 3) 4)"}]}
7	1	Write 7 + (8 * 2) as an S-expression	(+ 7 (* 8 2))	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 7 (* 8 2))"}]}
8	1	Write (6 - 2) + (3 * 5) as an S-expression	(+ (- 6 2) (* 3 5))	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (- 6 2) (* 3 5))"}]}
9	1	Write (10 - (3 + 2)) * 4 as an S-expression	(* (- 10 (+ 3 2)) 4)	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (- 10 (+ 3 2)) 4)"}]}
10	1	Write 20 - (3 * 4) as an S-expression	(- 20 (* 3 4))	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 20 (* 3 4))"}]}
11	1	Write (18 - 6) - 5 as an S-expression	(- (- 18 6) 5)	2025-08-20 06:52:56.062118+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- (- 18 6) 5)"}]}
12	1	Write 7 + (3 * 2) as an S-expression	(+ 7 (* 3 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 7 (* 3 2))"}]}
13	1	Write (8 - 5) + 9 as an S-expression	(+ (- 8 5) 9)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (- 8 5) 9)"}]}
14	1	Write 12 - 4 as an S-expression	(- 12 4)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 12 4)"}]}
15	1	Write 6 * 5 as an S-expression	(* 6 5)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 6 5)"}]}
16	1	Write 20 / 4 as an S-expression	(/ 20 4)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 20 4)"}]}
17	1	Write 3 + 4 as an S-expression	(+ 3 4)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 3 4)"}]}
18	1	Write 15 - 9 as an S-expression	(- 15 9)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 15 9)"}]}
19	1	Write 9 + (10 / 2) as an S-expression	(+ 9 (/ 10 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 9 (/ 10 2))"}]}
20	1	Write (5 + 7) * 2 as an S-expression	(* (+ 5 7) 2)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (+ 5 7) 2)"}]}
21	1	Write 18 / (3 + 3) as an S-expression	(/ 18 (+ 3 3))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 18 (+ 3 3))"}]}
22	1	Write (9 - 2) * 4 as an S-expression	(* (- 9 2) 4)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (- 9 2) 4)"}]}
23	1	Write 14 + (6 - 3) as an S-expression	(+ 14 (- 6 3))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 14 (- 6 3))"}]}
24	1	Write (4 * 3) + 11 as an S-expression	(+ (* 4 3) 11)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (* 4 3) 11)"}]}
25	1	Write 25 - (8 + 6) as an S-expression	(- 25 (+ 8 6))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 25 (+ 8 6))"}]}
26	1	Write (12 / 3) + 7 as an S-expression	(+ (/ 12 3) 7)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (/ 12 3) 7)"}]}
27	1	Write 5 * (2 + 9) as an S-expression	(* 5 (+ 2 9))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 5 (+ 2 9))"}]}
28	1	Write (10 - 4) / 3 as an S-expression	(/ (- 10 4) 3)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ (- 10 4) 3)"}]}
29	1	Write 16 / (2 * 2) as an S-expression	(/ 16 (* 2 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 16 (* 2 2))"}]}
30	1	Write (7 + 8) / 5 as an S-expression	(/ (+ 7 8) 5)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ (+ 7 8) 5)"}]}
31	1	Write 19 - (5 * 3) as an S-expression	(- 19 (* 5 3))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 19 (* 5 3))"}]}
32	1	Write (6 + 6) - 4 as an S-expression	(- (+ 6 6) 4)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- (+ 6 6) 4)"}]}
33	1	Write 8 * (3 - 1) as an S-expression	(* 8 (- 3 1))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 8 (- 3 1))"}]}
34	1	Write (9 * 2) - 7 as an S-expression	(- (* 9 2) 7)	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- (* 9 2) 7)"}]}
35	1	Write 22 - (12 / 3) as an S-expression	(- 22 (/ 12 3))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 22 (/ 12 3))"}]}
36	1	Write (5 + 5) + (6 * 2) as an S-expression	(+ (+ 5 5) (* 6 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (+ 5 5) (* 6 2))"}]}
37	1	Write (18 - 9) + (3 * 4) as an S-expression	(+ (- 18 9) (* 3 4))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (- 18 9) (* 3 4))"}]}
38	1	Write 21 / (7 - 4) as an S-expression	(/ 21 (- 7 4))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 21 (- 7 4))"}]}
39	1	Write (8 + 12) / (5 - 2) as an S-expression	(/ (+ 8 12) (- 5 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ (+ 8 12) (- 5 2))"}]}
40	1	Write (9 - 3) * (4 + 2) as an S-expression	(* (- 9 3) (+ 4 2))	2025-08-20 09:49:14.424681+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (- 9 3) (+ 4 2))"}]}
41	2	Make the following s-expression neater:\\n\\n( + 7 3 )	(+ 7 3)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 7 3)"}]}
42	2	Make the following s-expression neater:\\n\\n( * 9 4 )	(* 9 4)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 9 4)"}]}
43	2	Make the following s-expression neater:\\n\\n( - 10 2)	(- 10 2)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 10 2)"}]}
44	2	Make the following s-expression neater:\\n\\n(+ 5 14 )	(+ 5 14)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 5 14)"}]}
45	2	Make the following s-expression neater:\\n\\n( * 6 6)	(* 6 6)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 6 6)"}]}
46	2	Make the following s-expression neater:\\n\\n( - 25 7 )	(- 25 7)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 25 7)"}]}
47	2	Make the following s-expression neater:\\n\\n( + 12 8)	(+ 12 8)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 12 8)"}]}
48	2	Make the following s-expression neater:\\n\\n( * 3 11 )	(* 3 11)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 3 11)"}]}
49	2	Make the following s-expression neater:\\n\\n( - 18 9)	(- 18 9)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 18 9)"}]}
50	2	Make the following s-expression neater:\\n\\n( + 30 1 )	(+ 30 1)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 30 1)"}]}
51	2	Make the following s-expression neater:\\n\\n( + 5 ( * 2 3 ) )	(+ 5 (* 2 3))	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 5 (* 2 3))"}]}
52	2	Make the following s-expression neater:\\n\\n( * ( + 4 6 ) 2 )	(* (+ 4 6) 2)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (+ 4 6) 2)"}]}
53	2	Make the following s-expression neater:\\n\\n( - ( * 3 4 ) 5 )	(- (* 3 4) 5)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- (* 3 4) 5)"}]}
54	2	Make the following s-expression neater:\\n\\n( * 7 ( - 12 5 ) )	(* 7 (- 12 5))	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 7 (- 12 5))"}]}
55	2	Make the following s-expression neater:\\n\\n( + ( + 2 3 ) 4 )	(+ (+ 2 3) 4)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ (+ 2 3) 4)"}]}
56	2	Make the following s-expression neater:\\n\\n( - 20 ( + 7 1 ) )	(- 20 (+ 7 1))	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 20 (+ 7 1))"}]}
57	2	Make the following s-expression neater:\\n\\n( * ( - 15 5 ) 2 )	(* (- 15 5) 2)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (- 15 5) 2)"}]}
58	2	Make the following s-expression neater:\\n\\n( + 9 ( + 8 7 ) )	(+ 9 (+ 8 7))	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 9 (+ 8 7))"}]}
59	2	Make the following s-expression neater:\\n\\n( - ( + 13 4 ) 6 )	(- (+ 13 4) 6)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- (+ 13 4) 6)"}]}
60	2	Make the following s-expression neater:\\n\\n( * ( * 2 5 ) 3 )	(* (* 2 5) 3)	2025-08-21 05:58:55.764041+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* (* 2 5) 3)"}]}
61	3	Fix the following s-expression:\\n\\n(4 + 7)	(+ 4 7)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 4 7)"}]}
62	3	Fix the following s-expression:\\n\\n(- 12 3	(- 12 3)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 12 3)"}]}
63	3	Fix the following s-expression:\\n\\n* (8 9)	(* 8 9)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 8 9)"}]}
64	3	Fix the following s-expression:\\n\\n(+ 15 20	(+ 15 20)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 15 20)"}]}
65	3	Fix the following s-expression:\\n\\n(25 - 5)	(- 25 5)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 25 5)"}]}
66	3	Fix the following s-expression:\\n\\n( 6 7 * )	(* 6 7)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 6 7)"}]}
67	3	Fix the following s-expression:\\n\\n(* 3, 4)	(* 3 4)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 3 4)"}]}
68	3	Fix the following s-expression:\\n\\n+ 10 11)	(+ 10 11)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 10 11)"}]}
69	3	Fix the following s-expression:\\n\\n((+ 2 3)	(+ 2 3)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 2 3)"}]}
70	3	Fix the following s-expression:\\n\\n(- 18, 6)	(- 18 6)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 18 6)"}]}
71	3	Fix the following s-expression:\\n\\n(* 4 5))	(* 4 5)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 4 5)"}]}
72	3	Fix the following s-expression:\\n\\n( 14 3 -)	(- 14 3)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 14 3)"}]}
73	3	Fix the following s-expression:\\n\\n(+ 21 9))	(+ 21 9)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 21 9)"}]}
74	3	Fix the following s-expression:\\n\\n(+ (5 6))	(+ 5 6)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 5 6)"}]}
75	3	Fix the following s-expression:\\n\\n(* 2 3 ]	(* 2 3)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 2 3)"}]}
76	3	Fix the following s-expression:\\n\\n[* 11 4)	(* 11 4)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 11 4)"}]}
77	3	Fix the following s-expression:\\n\\n(24 6 +)	(+ 24 6)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 24 6)"}]}
78	3	Fix the following s-expression:\\n\\n(- 27; 3)	(- 27 3)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 27 3)"}]}
79	3	Fix the following s-expression:\\n\\n(* 5 6	(* 5 6)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 5 6)"}]}
80	3	Fix the following s-expression:\\n\\n+ (4 4)	(+ 4 4)	2025-08-21 09:17:32.535366+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 4 4)"}]}
81	4	Write -3 + -5 as an S-expression	(+ -3 -5)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ -3 -5)"}]}
82	4	Write -7 * -2 as an S-expression	(* -7 -2)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* -7 -2)"}]}
83	4	Write -12 - -8 as an S-expression	(- -12 -8)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- -12 -8)"}]}
84	4	Write -4 + -9 as an S-expression	(+ -4 -9)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ -4 -9)"}]}
85	4	Write -6 * -5 as an S-expression	(* -6 -5)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* -6 -5)"}]}
86	4	Write -15 - -3 as an S-expression	(- -15 -3)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- -15 -3)"}]}
87	4	Write -10 + -11 as an S-expression	(+ -10 -11)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ -10 -11)"}]}
88	4	Write -2 * -9 as an S-expression	(* -2 -9)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* -2 -9)"}]}
89	4	Write -13 - -14 as an S-expression	(- -13 -14)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- -13 -14)"}]}
90	4	Write -20 + -7 as an S-expression	(+ -20 -7)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ -20 -7)"}]}
91	4	Write -25 * -3 as an S-expression	(* -25 -3)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* -25 -3)"}]}
92	4	Write -30 - -1 as an S-expression	(- -30 -1)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- -30 -1)"}]}
93	4	Write 5 + -8 as an S-expression	(+ 5 -8)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 5 -8)"}]}
94	4	Write 9 * -3 as an S-expression	(* 9 -3)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* 9 -3)"}]}
95	4	Write -14 + 6 as an S-expression	(+ -14 6)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ -14 6)"}]}
96	4	Write 7 - -12 as an S-expression	(- 7 -12)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 7 -12)"}]}
97	4	Write -18 * 2 as an S-expression	(* -18 2)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(* -18 2)"}]}
98	4	Write 15 - -5 as an S-expression	(- 15 -5)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- 15 -5)"}]}
99	4	Write 3 + -27 as an S-expression	(+ 3 -27)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(+ 3 -27)"}]}
100	4	Write -22 - 4 as an S-expression	(- -22 4)	2025-08-21 09:22:17.7784+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(- -22 4)"}]}
101	5	Write 7 ÷ 3 as an S-expression	(/ 7 3)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 7 3)"}]}
102	5	Write 5 ÷ 2 as an S-expression	(/ 5 2)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 5 2)"}]}
103	5	Write 9 ÷ 4 as an S-expression	(/ 9 4)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 9 4)"}]}
104	5	Write 11 ÷ 6 as an S-expression	(/ 11 6)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 11 6)"}]}
105	5	Write 13 ÷ 5 as an S-expression	(/ 13 5)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 13 5)"}]}
106	5	Write 8 ÷ 3 as an S-expression	(/ 8 3)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 8 3)"}]}
107	5	Write 10 ÷ 3 as an S-expression	(/ 10 3)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 10 3)"}]}
108	5	Write 14 ÷ 9 as an S-expression	(/ 14 9)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 14 9)"}]}
109	5	Write 25 ÷ 12 as an S-expression	(/ 25 12)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 25 12)"}]}
110	5	Write 29 ÷ 8 as an S-expression	(/ 29 8)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 29 8)"}]}
111	5	Write 19 ÷ 7 as an S-expression	(/ 19 7)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 19 7)"}]}
112	5	Write 17 ÷ 15 as an S-expression	(/ 17 15)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 17 15)"}]}
113	5	Write 6 ÷ 3 as an S-expression	(/ 6 3)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 6 3)"}]}
114	5	Write 12 ÷ 4 as an S-expression	(/ 12 4)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 12 4)"}]}
115	5	Write 24 ÷ 6 as an S-expression	(/ 24 6)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 24 6)"}]}
116	5	Write 28 ÷ 7 as an S-expression	(/ 28 7)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 28 7)"}]}
117	5	Write 30 ÷ 5 as an S-expression	(/ 30 5)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 30 5)"}]}
118	5	Write 20 ÷ 10 as an S-expression	(/ 20 10)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 20 10)"}]}
119	5	Write 21 ÷ 7 as an S-expression	(/ 21 7)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 21 7)"}]}
120	5	Write 18 ÷ 9 as an S-expression	(/ 18 9)	2025-08-21 09:28:41.14044+00	racket	{"lang": "racket/base", "mode": "eval", "tests": [{"expr": "(/ 18 9)"}]}
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (user_id, active_lesson, lessons, created_at, username) FROM stdin;
4	2	{1,2}	2025-08-26 04:32:37.857613+00	aziz
\.


--
-- Name: attempt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attempt_id_seq', 39, true);


--
-- Name: lesson_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lesson_id_seq', 1, true);


--
-- Name: problem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.problem_id_seq', 120, true);


--
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_user_id_seq', 4, true);


--
-- Name: attempt attempt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attempt
    ADD CONSTRAINT attempt_pkey PRIMARY KEY (id);


--
-- Name: lesson lesson_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_pkey PRIMARY KEY (id);


--
-- Name: lesson lesson_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson
    ADD CONSTRAINT lesson_title_key UNIQUE (title);


--
-- Name: problem problem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.problem
    ADD CONSTRAINT problem_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- Name: user user_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_username_key UNIQUE (username);


--
-- Name: attempt_problem_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attempt_problem_id_created_at_idx ON public.attempt USING btree (problem_id, created_at DESC);


--
-- Name: attempt_user_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attempt_user_created_at_idx ON public.attempt USING btree (user_id, created_at DESC);


--
-- Name: idx_problem_lesson_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_problem_lesson_id ON public.problem USING btree (lesson_id);


--
-- Name: idx_user_active_lesson; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_active_lesson ON public."user" USING btree (active_lesson);


--
-- Name: idx_user_lessons_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_lessons_gin ON public."user" USING gin (lessons);


--
-- Name: attempt attempt_problem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attempt
    ADD CONSTRAINT attempt_problem_id_fkey FOREIGN KEY (problem_id) REFERENCES public.problem(id) ON DELETE CASCADE;


--
-- Name: attempt attempt_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attempt
    ADD CONSTRAINT attempt_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON DELETE CASCADE;


--
-- Name: problem problem_lesson_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.problem
    ADD CONSTRAINT problem_lesson_id_fkey FOREIGN KEY (lesson_id) REFERENCES public.lesson(id) ON DELETE CASCADE;


--
-- Name: user user_active_lesson_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_active_lesson_fkey FOREIGN KEY (active_lesson) REFERENCES public.lesson(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

