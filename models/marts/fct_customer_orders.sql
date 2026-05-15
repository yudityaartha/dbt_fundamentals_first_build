-- import CTE
with customers as (
    select * from {{ ref('stg_jaffle_shop__customers') }}
),
orders as (
    select * from {{ ref('int_orders') }}
),


customer_orders as (
    select orders.*,
    customers.full_name,
    customers.surname,
    customers.given_name,
    min(order_date) over (
        partition by orders.customer_id
    ) as customer_first_order_date,

    min(valid_order_date) over (
        partition by orders.customer_id
    )as customer_first_non_returned_order_date,

    max(valid_order_date) over (
        partition by orders.customer_id
    ) as customer_most_recent_non_returned_order_date,

    count(*) over (
        partition by orders.customer_id
    ) as customer_order_count,

    -- coalesce(
    --     count(case when orders.valid_order_date is not null then 1 end),
    --     0) 
    -- as non_returned_order_count,

    -- nvl2 is not supported in DuckDB; use CASE instead (nvl2 works in Oracle/Snowflake)
    -- sum(
    --     nvl2(
    --         orders.valid_order_date, orders.order_value_dollars, 0)
    -- ) as customer_non_returned_order_count,

    sum(
        case
            when orders.valid_order_date is not null
            then orders.order_value_dollars
            else 0
        end
    ) over (partition by orders.customer_id) as customer_non_returned_order_count,

    sum(
        case
            when orders.valid_order_date is not null
            then orders.order_value_dollars
            else 0
        end
    ) over (partition by orders.customer_id) as customer_total_lifetime_value,
    
    array_agg(distinct orders.order_id) over(
        partition by orders.customer_id
    ) as customer_order_ids
    from orders
    inner join customers
    on orders.customer_id = customers.customer_id
),
   average_customer_order_totals as (
    SELECT
    customer_orders.*,
    customer_total_lifetime_value / customer_non_returned_order_count as average_non_returned_order_value
    from customer_orders
    ),


-- final CTE
final as (

select 
    
    order_id,
    customer_id,
    surname,
    given_name,
    customer_first_order_date as first_order_date,
    customer_order_count as order_count,
    customer_total_lifetime_value,
    order_value_dollars,
    order_status,
    payment_status

from average_customer_order_totals as orders
)

select * from final
