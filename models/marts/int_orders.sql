with payments as (
    select * from {{ ref('stg_jaffle_shop__payments') }}
    where payment_status != 'failed'
),

orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
),

order_totals as (
    select 
        order_id, 
        payment_status,
        sum(payment_amount) as payment_amount
    from payments
    group by order_id, payment_status
),  

orders_values_joined as (
    select 
        orders.*,
        order_totals.payment_amount as order_value_dollars,
        order_totals.payment_status
    from orders
    left join order_totals
    on orders.order_id = order_totals.order_id
)

select * from orders_values_joined