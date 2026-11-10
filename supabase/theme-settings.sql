-- One List theme settings. Run once in the Supabase SQL editor.
alter table public.business_details
 add column if not exists theme_accent text not null default '#F28C28',
 add column if not exists theme_background text not null default '#171A1D',
 add column if not exists theme_surface text not null default '#292E31';
update public.business_details set theme_accent=coalesce(theme_accent,'#F28C28'),theme_background=coalesce(theme_background,'#171A1D'),theme_surface=coalesce(theme_surface,'#292E31') where id=1;
