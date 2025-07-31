--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

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
-- Data for Name: aggregatedcounter; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.aggregatedcounter (id, key, value, expireat) FROM stdin;
\.


--
-- Data for Name: counter; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.counter (id, key, value, expireat) FROM stdin;
\.


--
-- Data for Name: hash; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.hash (id, key, field, value, expireat, updatecount) FROM stdin;
\.


--
-- Data for Name: job; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.job (id, stateid, statename, invocationdata, arguments, createdat, expireat, updatecount) FROM stdin;
\.


--
-- Data for Name: jobparameter; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.jobparameter (id, jobid, name, value, updatecount) FROM stdin;
\.


--
-- Data for Name: jobqueue; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.jobqueue (id, jobid, queue, fetchedat, updatecount) FROM stdin;
\.


--
-- Data for Name: list; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.list (id, key, value, expireat, updatecount) FROM stdin;
\.


--
-- Data for Name: lock; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.lock (resource, updatecount, acquired) FROM stdin;
\.


--
-- Data for Name: schema; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.schema (version) FROM stdin;
22
\.


--
-- Data for Name: server; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.server (id, data, lastheartbeat, updatecount) FROM stdin;
\.


--
-- Data for Name: set; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.set (id, key, score, value, expireat, updatecount) FROM stdin;
\.


--
-- Data for Name: state; Type: TABLE DATA; Schema: hangfire; Owner: app_user
--

COPY hangfire.state (id, jobid, name, reason, createdat, data, updatecount) FROM stdin;
\.


--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20250729213410_InitialCreate	9.0.7
\.


--
-- Data for Name: clinics; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public.clinics (id, name, type, address, phone_number, email, cnpj, is_active, latitude, longitude, created_at, updated_at) FROM stdin;
0560c90b-289f-454c-99cf-c152e0bc91e0	SingleClin Administrativo	3	Rua Virtual, 123 - Centro, São Paulo - SP	(11) 9999-9999	admin@singleclin.com.br	00.000.000/0001-00	t	-23.55052	-46.633308	2025-07-29 18:36:56.094902-03	2025-07-29 18:36:56.094902-03
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public.plans (id, name, description, credits, price, original_price, validity_days, is_active, display_order, is_featured, created_at, updated_at) FROM stdin;
04b56c3f-91dc-453d-884a-863de112bab3	Plano Enterprise	Solução completa para empresas e equipes	100	399.90	\N	365	t	3	f	2025-07-29 18:36:56.094902-03	2025-07-29 18:36:56.094902-03
0a6d9137-d56f-40f9-ad0a-dd3513ad2887	Plano Premium	Para usuários frequentes com necessidades regulares	30	129.90	149.90	365	t	2	t	2025-07-29 18:36:56.094902-03	2025-07-29 18:36:56.094902-03
2d7dd0a9-3494-42b6-9988-fd27238951b5	Plano Básico	Ideal para usuários ocasionais	10	49.90	\N	365	t	1	f	2025-07-29 18:36:56.094902-03	2025-07-29 18:36:56.094902-03
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public.users (id, email, role, display_name, phone_number, firebase_uid, is_active, created_at, updated_at) FROM stdin;
786c15a2-f243-4fc8-a511-2d8f362f9eb9	admin@singleclin.com.br	4	Administrador	(11) 9999-9999	\N	t	2025-07-29 18:36:56.094902-03	2025-07-29 18:36:56.094902-03
\.


--
-- Data for Name: user_plans; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public.user_plans (id, user_id, plan_id, credits, credits_remaining, amount_paid, expiration_date, is_active, payment_method, payment_transaction_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: app_user
--

COPY public.transactions (id, code, user_plan_id, clinic_id, status, credits_used, service_description, validation_date, validated_by, validation_notes, ip_address, user_agent, latitude, longitude, cancellation_reason, cancellation_date, created_at, updated_at) FROM stdin;
\.


--
-- Name: aggregatedcounter_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.aggregatedcounter_id_seq', 1, false);


--
-- Name: counter_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.counter_id_seq', 1, false);


--
-- Name: hash_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.hash_id_seq', 1, false);


--
-- Name: job_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.job_id_seq', 1, false);


--
-- Name: jobparameter_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.jobparameter_id_seq', 1, false);


--
-- Name: jobqueue_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.jobqueue_id_seq', 1, false);


--
-- Name: list_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.list_id_seq', 1, false);


--
-- Name: set_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.set_id_seq', 1, false);


--
-- Name: state_id_seq; Type: SEQUENCE SET; Schema: hangfire; Owner: app_user
--

SELECT pg_catalog.setval('hangfire.state_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

