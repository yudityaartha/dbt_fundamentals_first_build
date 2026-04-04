SELECT 
    customer_id,
    order_date,
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'order_date']) }} AS pk,
    count(*) AS c
FROM {{ ref('stg_jaffle_shop__orders') }}
GROUP BY ALL