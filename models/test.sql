{{
    config(
    pre_hook= "{{ combine_ga4_data() }}",
    partition_by={
        "field": "event_date_dt",
        "data_type": "date",
    },
    cluster_by=['event_name']
    )
}}

SELECT * FROM {{ source('ga4', 'events') }}