create_event_table = """
CREATE TABLE IF NOT EXISTS events (
    event_id VARCHAR(255) NOT NULL PRIMARY KEY,
    professional_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    service_id VARCHAR(255),
    service_name_nl VARCHAR(255),
    service_name_en VARCHAR(255),
    service_lead_fee float,
    created_at TIMESTAMP NOT NULL
)
"""
