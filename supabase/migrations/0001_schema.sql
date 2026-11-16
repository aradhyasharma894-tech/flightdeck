-- FLIGHTDECK production schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null,
 role text not null check(role in ('admin','student')) default 'student',
 created_at timestamptz not null default now()
);
create table if not exists public.tests(
 id uuid primary key default gen_random_uuid(),
 slug text unique not null,
 title text not null,
 subject text not null,
 description text not null default '',
 duration_minutes int not null default 60 check(duration_minutes > 0),
 total_marks int not null default 100 check(total_marks > 0),
 is_published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.questions(
 id uuid primary key default gen_random_uuid(),
 test_id uuid not null references public.tests(id) on delete cascade,
 topic text not null,
 prompt text not null,
 options jsonb not null check(jsonb_typeof(options)='array' and jsonb_array_length(options)=4),
 correct_option smallint not null check(correct_option between 0 and 3),
 explanation text not null,
 marks int not null default 1 check(marks > 0),
 difficulty text not null default 'moderate' check(difficulty in ('easy','moderate','difficult')),
 source_note text not null default '',
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create index if not exists questions_test_idx on public.questions(test_id,is_active,topic);
create table if not exists public.attempts(
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id),
 test_id uuid not null references public.tests(id),
 started_at timestamptz not null default now(),
 submitted_at timestamptz,
 score int,
 total_marks int not null,
 status text not null default 'in_progress' check(status in ('in_progress','submitted','expired')),
 focus_events int not null default 0,
 unique(id,student_id)
);
create table if not exists public.attempt_answers(
 id uuid primary key default gen_random_uuid(),
 attempt_id uuid not null references public.attempts(id) on delete cascade,
 question_id uuid not null references public.questions(id),
 selected_option smallint check(selected_option between 0 and 3),
 is_correct boolean not null default false,
 marks_awarded int not null default 0,
 unique(attempt_id,question_id)
);
create table if not exists public.test_assignments(
 test_id uuid not null references public.tests(id) on delete cascade,
 student_id uuid not null references public.profiles(id) on delete cascade,
 assigned_at timestamptz not null default now(),
 primary key(test_id,student_id)
);
alter table public.profiles enable row level security;
alter table public.tests enable row level security;
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.attempt_answers enable row level security;
alter table public.test_assignments enable row level security;
-- Students can read their own profile. Admin profile read is granted by edge functions (service role).
create policy "profile self read" on public.profiles for select to authenticated using(id=auth.uid());
create policy "tests none direct" on public.tests for select to authenticated using(false);
create policy "questions none direct" on public.questions for all to authenticated using(false) with check(false);
create policy "attempts self read" on public.attempts for select to authenticated using(student_id=auth.uid());
create policy "answers self read via attempt" on public.attempt_answers for select to authenticated using(exists(select 1 from public.attempts a where a.id=attempt_id and a.student_id=auth.uid()));
create policy "assignments self read" on public.test_assignments for select to authenticated using(student_id=auth.uid());
revoke all on public.questions from anon,authenticated;
revoke all on public.tests from anon,authenticated;
revoke all on public.attempts from anon,authenticated;
revoke all on public.attempt_answers from anon,authenticated;
revoke all on public.test_assignments from anon,authenticated;
-- Admins are provisioned manually after creating their Auth user:
-- insert into profiles(id,display_name,role) values('<AUTH-UUID>','Administrator','admin');
-- Student provisioning: create Auth user in Supabase Dashboard, then insert a profiles row and test_assignments rows.
