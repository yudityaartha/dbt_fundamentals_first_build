{% set cool_string  = 'Hello, World!' %}
{% set second_cool_string  = 'this is jinja' %}
{% set my_fav  = 'it is a great language' %}
{% set dur  = 1 %}

{{ cool_string }} {{ second_cool_string }} {{ my_fav }}. I want to learn it for {{ dur }} month

{#
{% set foods = ['nasi goreng', 'yakiniku', 'sushi', 'ramen', 'takoyaki', 'risoles'] %}
{% for food in foods %}
    My favorites are {{ food }}
{% endfor %}
#}

{% set foods = ['nasi goreng', 'yakiniku', 'sushi', 'ramen', 'takoyaki', 'risoles'] %}
{%- for food in foods -%}
    {%- if food == 'nasi goreng' or food == 'yakiniku' or food == 'sushi' -%}
        {%- set food_type = 'main course' -%}
    {%- else -%}
        {%- set food_type = 'snack' -%}
    {%- endif -%}
    My favorites {{ food_type }} is {{ food }} 
{% endfor %}

{% set yas_dictionary = {
    'hobbies': 'reading & gaming',
    'food': 'Tenpura Don',
    'drinks': 'coffee latte',
} 
%}

I love {{ yas_dictionary['hobbies'] }} so much, I like {{yas_dictionary['food']}} and {{ yas_dictionary['drinks'] }}. 


{{ target.name }}
{{ target.role }}
{{ target.schema }}

{{ template_example() }}

{{ union_tables_by_prefix(database = 'raw', schema = 'jaffle_shop', prefix = 'orders__')}}


{% set database = target.database %}
{% set schema = target.schema %}

SELECT 
    table_type,
    table_schema,
    last_altered,
    case when table_type = 'VIEW' then 'VIEW' else 'TABLE' end as object_type,
    'DROP ' || object_type || ' ' || '{{ database | upper }}' || '.' || table_schema || '.' || table_name || ';' as drop_command
FROM {{ database }}.information_schema.tables
WHERE table_schema = upper('{{ schema }}')
AND date(last_altered) <= date(dateadd('day', -1 , current_date))

{{ clean_stale_models(database=database, schema=schema, days=7, dry_run=True) }}