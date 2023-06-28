with event_date_diff as (
    select
        professional_id_anonymized,
        created_at,
        event_type,
        lead(created_at) over (partition by professional_id_anonymized order by created_at) as next_date
    from {{ source('events_logs', 'events') }}
    where event_type in ('became_able_to_propose', 'became_not_able_to_propose')
),
filtered_date_dim as (
    select
        Date(dd.calendar_date) as date
    from {{ ref('dim_date') }} dd
    where DATE(dd.calendar_date) >= (select Date(min(created_at)) from events) AND DATE(dd.calendar_date) <= '2020-03-10'
),
join_calendar_dim_with_edd as (
    select
        dd.date,
        edd.*
    from filtered_date_dim dd
    join event_date_diff edd on dd.date < coalesce(DATE(edd.next_date), '2020-03-11') and Date(dd.date) >= Date(edd.created_at)
),
active_professionals_per_day as (
    select date,
           count(distinct professional_id_anonymized) as active_professionals
    from join_calendar_dim_with_edd
    where event_type = 'became_able_to_propose'
    group by date
),
days_with_zero_active_professionals as (
    select
       date,
      0 as active_professionals
    from filtered_date_dim dd
    where date not in (
        select date from active_professionals_per_day
    )
)
select
    *
from days_with_zero_active_professionals
union all
select * from active_professionals_per_day
order by date
