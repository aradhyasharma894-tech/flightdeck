# FLIGHTDECK Pro — Vercel + Supabase pilot-exam platform

This is the production-oriented application scaffold, not the previous localStorage demo.

## Architecture
- Vite + React frontend, deployable to Vercel.
- Supabase Auth for persistent email/password login.
- Supabase Postgres for question bank, assignments, attempts and scores.
- Supabase Edge Functions for student test delivery, server-side grading, admin imports and admin reporting.
- RLS enabled. Student browser clients cannot directly read the question table or correct answers.
- Admin and student roles are provisioned in `profiles`; tests are assigned per student.

## Important: credentials and first deployment
I cannot create a Supabase project or deploy into your Vercel account from this chat. You must create/connect those accounts and set environment variables.

1. Create a Supabase project.
2. In SQL Editor, run `supabase/migrations/0001_schema.sql`.
3. Create the admin and Kanika Auth users in Supabase Authentication (email/password). Copy their Auth UUIDs.
4. Insert profiles:
   `insert into public.profiles(id,display_name,role) values ('ADMIN_AUTH_UUID','Administrator','admin'), ('KANIKA_AUTH_UUID','Kanika','student');`
5. Create tests:
   `insert into public.tests(slug,title,subject,description,duration_minutes,total_marks,is_published) values ('meteorology','Aviation Meteorology — Full Mock 01','Aviation Meteorology','IC Joshi aligned: stability, optical phenomena, precipitation, ice accretion, thunderstorms, air masses/fronts and jet streams.',60,100,false), ('air-regulations','Air Regulations — Full Mock 01','Air Regulations','R.K. Bali aligned: human performance, CRM, TEM, LOFT, aviation psychology, physiology and human factors.',60,100,false);`
6. Assign the tests:
   `insert into public.test_assignments(test_id,student_id) select id,'KANIKA_AUTH_UUID' from public.tests;`
7. Add/import at least 100 marks worth of active questions to each test. Upload from the admin dashboard using CSV/JSON. Question bank must have at least 100 active questions per test. CSV template is included.
8. Set tests published only after the question bank is complete:
   `update public.tests set is_published=true where slug in ('meteorology','air-regulations');`
9. Deploy functions using Supabase CLI:
   `supabase functions deploy student-tests`
   `supabase functions deploy submit-attempt`
   `supabase functions deploy admin-import`
   `supabase functions deploy admin-attempts`
   Set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` as function secrets (Supabase normally provides these automatically in hosted Edge Functions).
10. Install dependencies with `npm install`, copy `.env.example` to `.env.local`, set the Supabase project URL and publishable/anon key, then `npm run dev`.
11. Push to GitHub and import the repository into Vercel. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Vercel Project Settings → Environment Variables, then redeploy.

## Question-bank import format
`question-bank-template.csv` is the schema. `test_slug` must match a test slug. Each row requires topic, original question prompt, four options, correct_option A/B/C/D and a teaching explanation. `source_note` should identify the source title/chapter/page or official URL and access date. Use original wording; do not reproduce textbook questions verbatim.

## Exam engine
- Test metadata supports 60 minutes / 100 marks.
- Student test endpoint returns question prompts and options only; answer key and explanations remain server-side.
- Submission is graded on the server and saves score and topic-level analysis.
- This starter chooses a random set of questions from the active bank; the bank should contain substantially more than 100 items to avoid repeat exposure.
- For high-stakes deployment, add server-enforced attempt expiry, resume/abandon handling, rate limits, stronger audit events, signed exam snapshots, and independent security testing before relying on anti-cheating claims.

## Current limitations to resolve before production use
- The UI currently provides the question upload and performance table. Test creation/assignment/publish controls are seeded through SQL; a full CRUD test builder should be added before handing it over as an admin-managed product.
- `submit-attempt` currently uses the question IDs submitted by the client. Add server-side validation that every question belongs to the assigned active attempt and persist the exact question set at start. This is required before public production deployment.
- The exam endpoint should return the attempt ID and server should persist the randomised question set. Current schema is a base implementation, not a fully audited exam security product.
- Add question-review endpoint after submission to show explanation and answer key; keep it server-side and only for the owning student / admin.
- No question bank is bundled as a fake 100-question paper. The provided books and DGCA syllabus need careful chapter-by-chapter authoring, cross-checking and review. Import only questions that have been validated against the book / official sources. Do not expose this as DGCA's official exam or guarantee a pass.

## Source strategy
Primary syllabus/book alignment:
- Uploaded IC Joshi, *Aviation Meteorology* (chapters 9–15 requested).
- Uploaded R.K. Bali, *Air Regulations for CPL/ATPL* (Human Performance and Limitations chapter and requested subtopics).
- DGCA's official study-material list includes IC Joshi for Aviation Meteorology and R.K. Bali for Air Regulations.
Supplementary technical cross-checks:
- FAA Aviation Weather Handbook (2026 edition).
- FAA Pilot's Handbook of Aeronautical Knowledge, weather theory and aeromedical factors.
- ICAO Manual on Human Performance (Doc 10151) for TEM/CRM concepts.
- DGCA CAR for theoretical knowledge course requirements.
These foreign references are explanatory cross-checks only; Indian DGCA requirements and current Indian law take precedence.
