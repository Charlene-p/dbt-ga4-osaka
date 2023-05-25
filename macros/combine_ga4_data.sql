{%- macro combine_ga4_data()  -%}
    {{ return(adapter.dispatch('combine_ga4_data', 'ga4')()) }}
{%- endmacro -%}

{% macro default__combine_ga4_data() %}
    CREATE SCHEMA IF NOT EXISTS `{{var('project')}}.{{var('dataset')}}`;
    {%- if not should_full_refresh() -%}
        {% set earliest_shard_to_retrieve = (modules.datetime.date.today() - modules.datetime.timedelta(days=var('static_incremental_days')))|string|replace("-", "")|int %}
    {%- else-%}
        {% set earliest_shard_to_retrieve = var('start_date')|int %}
    {%- endif -%}

    {% for property_id in var('property_ids') %}
        {%- set schema_name = "analytics_" + property_id|string -%}
        {%- if var('frequency', daily) == 'streaming' -%}
            {%- set relations = dbt_utils.get_relations_by_pattern(schema_pattern=schema_name, table_pattern='events_intraday_%', database=var('project')) -%}
            {% for relation in relations %}
                {%- set relation_suffix = relation.identifier|replace('events_intraday_', '') -%}
                {%- if relation_suffix|int >= earliest_shard_to_retrieve|int -%}
                    CREATE OR REPLACE TABLE `{{var('project')}}.{{var('dataset')}}.events_intraday_{{property_id}}_{{relation_suffix}}` CLONE `{{var('project')}}.analytics_{{property_id}}.events_intraday_{{relation_suffix}}`;
                {%- endif -%}
            {% endfor %}
        {%- else -%}
            {%- set relations = dbt_utils.get_relations_by_pattern(schema_pattern=schema_name, table_pattern='events_%', exclude='events_intraday_%', database=var('project')) -%}
            {% for relation in relations %}
                {%- set relation_suffix = relation.identifier|replace('events_', '') -%}
                {%- if relation_suffix|int >= earliest_shard_to_retrieve|int -%}
                    CREATE OR REPLACE TABLE `{{var('project')}}.{{var('dataset')}}.events_{{property_id}}_{{relation_suffix}}` CLONE `{{var('project')}}.analytics_{{property_id}}.events_{{relation_suffix}}`;
                {%- endif -%}
            {% endfor %}
        {%- endif -%}
    {% endfor %}
{% endmacro %}