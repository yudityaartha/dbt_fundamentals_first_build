-- import CTE
with raw_customers as (
    select * from {{ source('jaffle_shop', 'customers') }}
),

raw_orders as (
    select * from {{ source('jaffle_shop', 'orders') }}
),

raw_payments as (
    select * from {{ source('stripe', 'payment') }}
),

-- logical CTE
customers as
(

    select
        id as customer_id ,
        first_name as given_name,
        last_name as surname,
        first_name || ' ' || last_name as full_name,
    from raw_customers as customers

),

orders as (

        select 

            row_number() over (
                partition by user_id 
                order by order_date, id
            ) as user_order_seq,
            id as order_id,
            user_id as customer_id,
            order_date,
            status as order_status,
            _etl_loaded_at

        from raw_orders as orders

     ), 

payments as (

    select 

        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status as payment_status,
        round(amount/100.0,2) as payment_amount,
        created as payment_created_at,
        _batched_at

    from raw_payments
),

customer_order_history as (

    select
        customers.customer_id,
        customers.full_name,
        customers.surname,
        customers.given_name,
        min(order_date) as first_order_date,

        min(
            case 
                when orders.order_status not in ('returned', 'return_pending') 
                then order_date 
            end) 
            as first_non_returned_order_date,

        max(
            case 
                when orders.order_status not in ('returned', 'return_pending') 
                then order_date 
            end) 
            as most_recent_non_returned_order_date,
            
        coalesce(max(user_order_seq), 0) as order_count,

        coalesce(
            count(case when orders.order_status != 'returned' then 1 end),
            0) 
        as non_returned_order_count,

        sum(
            case 
            when orders.order_status not in ('returned', 'return_pending') 
            then c.payment_amount
            else 0 
        end) 
        as total_lifetime_value,

        sum(
            case 
                when orders.order_status not in ('returned', 'return_pending') 
                then c.payment_amount
                else 0 
            end) / 
            nullif(
                count(
                    case 
                    when orders.order_status not in ('returned', 'return_pending')
                    then 1 
                end), 0
            ) 
        as avg_non_returned_order_value,
        
        array_agg(distinct orders.order_id) as order_ids
        
    from orders

    join customers
    on orders.customer_id = customers.customer_id
    
    left outer join payments as c
    on orders.order_id = c.order_id

    where orders.order_status not in ('pending') and c.payment_status != 'failed'
    group by customers.customer_id, customers.full_name, customers.surname, customers.given_name

) 

-- final CTE

select 
    
    orders.order_id,
    orders.customer_id,
    customers.surname,
    customers.given_name,
    first_order_date,
    order_count,
    total_lifetime_value,
    payment_amount as order_value_dollars,
    orders.order_status,
    c.payment_status

from orders

join customers
on orders.customer_id = customers.customer_id

join customer_order_history
on orders.customer_id = customer_order_history.customer_id

left outer join payments as c
on orders.order_id = c.order_id

where c.payment_status != 'failed'
