{{
    config(
        indexes = [{'columns': ['service_id'], 'unique': True}],
    )
}}
select
    distinct
    service_id as service_id,
    service_name_nl as service_name_nl,
    service_name_en as service_name_en
from {{ source('events_logs', 'events')}}
where event_type = 'proposed' -- only proposed events have a service metadata
