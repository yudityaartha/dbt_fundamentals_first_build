{% set payment_method = dbt_utils.get_column_values(
                table=ref('stg_stripe__payment'),
                column='payment_method')-%}

WITH payment AS (
    SELECT * FROM {{ ref('stg_stripe__payment') }}
    ),
    pivoted AS (
        SELECT
        order_id,
        
        {%- for method in payment_method -%}
        SUM(CASE WHEN payment_method = '{{ method }}' THEN amount ELSE 0 END) AS {{ method }}_amount 
        {%- if not loop.last -%},
        {% endif -%}
        {% endfor %}
        FROM payment
        GROUP BY order_id
    )

SELECT * FROM pivoted