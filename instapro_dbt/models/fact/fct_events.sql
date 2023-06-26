{{
    config(
        indexes = [{'columns': ['event_fact_id'], 'unique': True}],
    )
}}

with events_with_facts as (
    select
        {{
            dbt_utils.generate_surrogate_key(['event_id', 'professional_id_anonymized', 'service_id'])
        }} as event_fact_id,
        event_id as event_id,
        professional_id_anonymized as professional_id,
        service_id as service_id,
        created_at as created_at,
        service_lead_fee as service_lead_fee
    from {{ source('events_logs', 'events')}}
    where event_type = 'proposed' -- only proposed events have a service_lead_fee.
)
SELECT
    *
FROM events_with_facts

