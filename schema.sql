-- ALBRIGHT JUNIOR SCHOOL: initial Supabase schema
-- Run in Supabase Dashboard > SQL Editor. Review before production use.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text unique,
  role text not null check (role in ('admin','teacher','bursar','parent')) default 'parent',
  created_at timestamptz not null default now()
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  admission_no text not null unique,
  full_name text not null,
  class_name text not null,
  annual_fee numeric(12,2) not null default 0 check (annual_fee >= 0),
  portrait_url text,
  created_at timestamptz not null default now()
);
create table if not exists public.parent_students (
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  primary key(parent_id,student_id)
);
create table if not exists public.fee_payments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  amount numeric(12,2) not null check(amount > 0),
  reference text not null,
  recorded_by uuid references public.profiles(id),
  paid_at timestamptz not null default now()
);
create table if not exists public.marks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  term text not null check(term in ('Term 1','Term 2','Term 3')),
  subject text not null,
  score numeric(5,2) not null check(score >= 0 and score <= 100),
  teacher_comment text,
  entered_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create index if not exists idx_parent_students_parent on public.parent_students(parent_id);
create index if not exists idx_fee_payments_student on public.fee_payments(student_id);
create index if not exists idx_marks_student on public.marks(student_id);
create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.is_linked_parent(sid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.parent_students where parent_id=auth.uid() and student_id=sid) $$;
create or replace function public.fees_fully_paid(sid uuid) returns boolean language sql stable security definer set search_path=public as $$ select coalesce((select sum(amount) from public.fee_payments where student_id=sid),0) >= coalesce((select annual_fee from public.students where id=sid),0) $$;
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.parent_students enable row level security;
alter table public.fee_payments enable row level security;
alter table public.marks enable row level security;
-- Profiles: user can read own profile; admin can manage profiles.
create policy "profile read own or admin" on public.profiles for select to authenticated using (id=auth.uid() or public.current_role()='admin');
create policy "admin manage profiles" on public.profiles for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
-- Students: staff read; parents only linked children. Admin manages records.
create policy "staff read students" on public.students for select to authenticated using (public.current_role() in ('admin','teacher','bursar'));
create policy "parent read linked student" on public.students for select to authenticated using (public.current_role()='parent' and public.is_linked_parent(id));
create policy "admin manage students" on public.students for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
-- Parent/student links are managed only by admin; parent may read their own links.
create policy "read own parent links" on public.parent_students for select to authenticated using (parent_id=auth.uid() or public.current_role()='admin');
create policy "admin manage parent links" on public.parent_students for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
-- Fees: bursar/admin manage; parents can see own children's payments only.
create policy "staff read fees" on public.fee_payments for select to authenticated using (public.current_role() in ('admin','bursar','teacher'));
create policy "parent read linked fees" on public.fee_payments for select to authenticated using (public.current_role()='parent' and public.is_linked_parent(student_id));
create policy "bursar admin record fees" on public.fee_payments for insert to authenticated with check (public.current_role() in ('admin','bursar'));
create policy "admin update or delete fees" on public.fee_payments for update to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
create policy "admin delete fees" on public.fee_payments for delete to authenticated using (public.current_role()='admin');
-- Marks: staff can read; parents only read marks if child is linked AND annual fees fully paid.
create policy "staff read marks" on public.marks for select to authenticated using (public.current_role() in ('admin','teacher'));
create policy "parent read marks when paid" on public.marks for select to authenticated using (public.current_role()='parent' and public.is_linked_parent(student_id) and public.fees_fully_paid(student_id));
create policy "teacher admin enter marks" on public.marks for insert to authenticated with check (public.current_role() in ('admin','teacher'));
create policy "teacher admin update marks" on public.marks for update to authenticated using (public.current_role() in ('admin','teacher')) with check (public.current_role() in ('admin','teacher'));
create policy "admin delete marks" on public.marks for delete to authenticated using (public.current_role()='admin');
-- IMPORTANT: After creating users in Authentication, an admin must create/update each profile's role and link parent IDs to student IDs.
-- Create the first admin securely: sign up the admin in Authentication, then run an UPDATE in SQL Editor using that user's UUID.
-- Example (replace UUID and email): update public.profiles set role='admin', full_name='School Administrator', email='admin@school.example' where id='USER-UUID';
-- For a new user with no profile, insert it from SQL Editor using their auth.users UUID.
