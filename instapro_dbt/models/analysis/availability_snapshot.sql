-- this model can be changed to use the incremental model. that's the ideal case.
with active_professionals as (
    select
        professional_id_anonymized as professional_id,
        created_at as created_at
    from {{ source('events_logs', 'events') }}
    where event_type = 'became_able_to_propose'
     and DATE(created_at) <= (select DATE(max(created_at)) from events)
     and (created_at, professional_id_anonymized) not in (
     	select
     	  min(created_at), professional_id_anonymized
     	from events
     	where event_type = 'became_unable_to_propose' and Date(created_at) <= (select DATE(max(created_at)) from events)
     	group by professional_id_anonymized
     )
),
date_range as (
    select
        date(calendar_date) as calendar_date
    from {{ ref('dim_date') }}
    where Date(calendar_date) <= '2020-03-10'
),
dates_with_active_professionals as (
    select
        calendar_date as day,
        count(distinct p.professional_id) as active_professionals
    from date_range d
    join active_professionals p on date(p.created_at) <= d.calendar_date
    group by calendar_date
)
select
    *
from dates_with_active_professionals

