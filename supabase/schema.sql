-- Bastoners d'Arbeca · Supabase
-- Enganxa-ho tot al SQL Editor de Supabase i prem "Run".
-- Abans, canvia EL-TEU-CORREU@exemple.cat (a baix de tot) pel teu correu.

-- 1) Taules
create table if not exists public.editors (
  email text primary key
);

create table if not exists public.balls (
  id          text primary key,
  dades       jsonb not null,          -- el ball sencer (figures, balladors, música, repartiments...)
  ordre       int  not null default 0, -- ordre a la llista de balls
  actualitzat timestamptz not null default now(),
  autor       text
);

create table if not exists public.cataleg (
  clau        text primary key,        -- 'cops' o 'combis'
  dades       jsonb not null,
  actualitzat timestamptz not null default now(),
  autor       text
);

-- 2) Qui és editor? (compara el correu de l'usuari connectat amb la taula editors)
create or replace function public.es_editor()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.editors
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
grant execute on function public.es_editor() to anon, authenticated;

-- 3) Permisos (RLS): tothom llegeix, només els editors escriuen
alter table public.editors enable row level security;
alter table public.balls   enable row level security;
alter table public.cataleg enable row level security;

grant select on public.balls, public.cataleg to anon, authenticated;
grant insert, update, delete on public.balls, public.cataleg to authenticated;

drop policy if exists "llegir balls" on public.balls;
create policy "llegir balls" on public.balls for select to anon, authenticated using (true);
drop policy if exists "editors balls" on public.balls;
create policy "editors balls" on public.balls for all to authenticated
  using (public.es_editor()) with check (public.es_editor());

drop policy if exists "llegir cataleg" on public.cataleg;
create policy "llegir cataleg" on public.cataleg for select to anon, authenticated using (true);
drop policy if exists "editors cataleg" on public.cataleg;
create policy "editors cataleg" on public.cataleg for all to authenticated
  using (public.es_editor()) with check (public.es_editor());
-- La taula editors no té cap política: ningú la pot llegir des de l'app.
-- Només es gestiona des del panell de Supabase (Table Editor > editors).

-- 4) Tu com a primera editora
insert into public.editors (email) values ('EL-TEU-CORREU@exemple.cat')
on conflict do nothing;

-- Per afegir algú més endavant:
-- insert into public.editors (email) values ('correu@exemple.cat');
