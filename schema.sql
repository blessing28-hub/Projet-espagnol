-- ¿ÉXITO O FRACASO? · Supabase schema. Run once in Supabase > SQL Editor.
-- 1) CHANGE THE PIN below before running. It is the presenter password.
create extension if not exists pgcrypto;

create table if not exists config(id int primary key default 1 check(id=1), admin_pin text not null);
insert into config values (1,'CHANGE-ME-1234') on conflict do nothing;

create table if not exists game(id int primary key default 1 check(id=1),
  status text not null default 'lobby',  -- lobby | ready | open | closed | revealed | final
  round int not null default 0, closes_at timestamptz);
insert into game(id) values(1) on conflict do nothing;

create table if not exists players(id uuid primary key default gen_random_uuid(),
  name text not null check(char_length(name) between 1 and 20),
  score int not null default 0, created_at timestamptz default now());

create table if not exists answers(player_id uuid references players(id) on delete cascade,
  round int not null check(round between 1 and 5), choice int not null check(choice between 0 and 2),
  points int not null default 0, created_at timestamptz default now(), primary key(player_id,round));

-- Hidden scoring matrix: (round, story picked in round 1, choice) -> points. Edit freely.
create table if not exists scoring(round int, story int, choice int, pts int, primary key(round,story,choice));
insert into scoring(round,story,choice,pts) values
(1,0,0,7),(1,0,1,10),(1,0,2,5),
(2,0,0,20),(2,0,1,12),(2,0,2,8),(3,0,0,20),(3,0,1,12),(3,0,2,6),(4,0,0,16),(4,0,1,10),(4,0,2,4),(5,0,0,14),(5,0,1,20),(5,0,2,8),
(2,1,0,8),(2,1,1,12),(2,1,2,20),(3,1,0,10),(3,1,1,20),(3,1,2,12),(4,1,0,8),(4,1,1,16),(4,1,2,6),(5,1,0,8),(5,1,1,14),(5,1,2,20),
(2,2,0,6),(2,2,1,20),(2,2,2,12),(3,2,0,4),(3,2,1,14),(3,2,2,20),(4,2,0,4),(4,2,1,8),(4,2,2,16),(5,2,0,20),(5,2,1,10),(5,2,2,14)
on conflict do nothing;

-- Row Level Security: browsers can only READ game + players. Everything else goes through the functions below.
alter table config enable row level security;
alter table game enable row level security;
alter table players enable row level security;
alter table answers enable row level security;
alter table scoring enable row level security;
drop policy if exists "read game" on game;   create policy "read game" on game for select using (true);
drop policy if exists "read players" on players; create policy "read players" on players for select using (true);

create or replace function get_state() returns json language sql stable as
$$ select json_build_object('status',status,'round',round,'closes_at',closes_at,'now',now()) from game where id=1 $$;

create or replace function join_player(n text) returns uuid language plpgsql security definer set search_path=public as $$
declare v uuid; begin n:=trim(n);
  if char_length(n)<1 or char_length(n)>20 then raise exception 'bad name'; end if;
  insert into players(name) values(n) returning id into v; return v; end $$;

create or replace function submit_answer(p uuid, r int, c int) returns void language plpgsql security definer set search_path=public as $$
declare g game%rowtype; begin select * into g from game where id=1;
  if g.status<>'open' or g.round<>r or now()>g.closes_at then raise exception 'closed'; end if;
  insert into answers(player_id,round,choice) values(p,r,c) on conflict do nothing; end $$;

create or replace function my_answers(p uuid) returns table(round int, choice int, points int) language sql security definer set search_path=public as $$
  select a.round,a.choice,a.points from answers a where a.player_id=p $$;

create or replace function chk(pin text) returns void language plpgsql security definer set search_path=public as $$
begin if pin is distinct from (select admin_pin from config where id=1) then raise exception 'bad pin'; end if; end $$;

create or replace function admin_check(pin text) returns boolean language sql security definer set search_path=public as $$
  select pin is not distinct from (select admin_pin from config where id=1) $$;

create or replace function admin_set(pin text, st text, rnd int, secs int) returns void language plpgsql security definer set search_path=public as $$
begin perform chk(pin);
  update game set status=st, round=rnd, closes_at=case when st='open' then now()+make_interval(secs=>secs) else null end where id=1; end $$;

create or replace function admin_counts(pin text, r int) returns table(choice int, n bigint) language plpgsql security definer set search_path=public as $$
begin perform chk(pin); return query select a.choice,count(*) from answers a where a.round=r group by a.choice; end $$;

create or replace function admin_reveal(pin text) returns void language plpgsql security definer set search_path=public as $$
declare r int; begin perform chk(pin); select round into r from game where id=1;
  update answers a set points=coalesce((select s.pts from scoring s where s.round=r and s.choice=a.choice
    and s.story=case when r=1 then 0 else coalesce((select a1.choice from answers a1 where a1.player_id=a.player_id and a1.round=1),-1) end),0)
  where a.round=r;
  if r=4 then -- consistency: strategy matches audience chosen in round 3 (+4)
    update answers a set points=least(20,a.points+4) where a.round=4 and a.points>0
      and a.choice=(select a3.choice from answers a3 where a3.player_id=a.player_id and a3.round=3); end if;
  if r=5 then -- consistency bonus: 4 strong rounds (+10) or 3 (+5)
    update answers a set points=a.points+case (select count(*) from answers b where b.player_id=a.player_id and b.round between 2 and 5 and b.points>=16)
      when 4 then 10 when 3 then 5 else 0 end where a.round=5 and a.points>0; end if;
  update players p set score=coalesce((select sum(x.points) from answers x where x.player_id=p.id),0) where true;
  update game set status='revealed', closes_at=null where id=1; end $$;

create or replace function admin_reset(pin text) returns void language plpgsql security definer set search_path=public as $$
begin perform chk(pin); delete from answers where true; delete from players where true;
  update game set status='lobby', round=0, closes_at=null where id=1; end $$;

create or replace function admin_delete_tests(pin text) returns void language plpgsql security definer set search_path=public as $$
begin perform chk(pin); delete from players where name like 'TEST %'; end $$;

-- Realtime: broadcast changes of these two tables to all connected browsers.
alter publication supabase_realtime add table game, players;
