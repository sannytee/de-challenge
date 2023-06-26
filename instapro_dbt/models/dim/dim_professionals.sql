{{
    config(
        indexes = [{'columns': ['professional_id'], 'unique': True}],
    )
}}

-- currently, we only have professional_id_anonymized in the events table
-- but we can add more fields here if we want to.

select
    professional_id_anonymized as professional_id
from {{ source('events_logs', 'events')}}
group by professional_id_anonymized
