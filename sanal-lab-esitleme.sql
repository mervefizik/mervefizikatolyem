-- Sanal Fizik Laboratuvari: öğretmen çalışma notlarını cihazlar arasında eşitleme
-- Supabase Dashboard > SQL Editor bölümünde bir kez çalıştırın.

create table if not exists public.lab_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  lab_id text not null,
  notes jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, lab_id)
);

alter table public.lab_notes enable row level security;
revoke all on table public.lab_notes from anon, public;
grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.lab_notes to authenticated;

drop policy if exists "Teacher manages own lab notes" on public.lab_notes;
create policy "Teacher manages own lab notes"
  on public.lab_notes
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'lab_notes'
  ) then
    alter publication supabase_realtime add table public.lab_notes;
  end if;
end $$;
