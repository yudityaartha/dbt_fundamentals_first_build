{{ config(enabled=false) }}
SELECT
    orders.id AS order_id,
    orders.user_id As customer_id,
    last_name AS surname,
    first_name AS givenname,
    first_order_date
    order_count,
    total_lifetime_value,
    round(amount/100.0,2) AS order_value_dollars,
    orders.status AS order_status,
    payment.status AS payment_status,
FROM raw.jaffle_shop.orders AS orders

JOIN (
    SELECT
        first_name || ' ' || last_name AS name,
        *
        FROM (raw.jaffle_shop.customers AS customers
        )
) AS customers
ON orders.user_id = customers.id

join (
    SELECT
        b.id AS customer_id,
        b.name AS full_name,
        b.last_name AS surname,
        b.first_name AS givenname,
        min(order_date) AS first_order_date,
        min(case when a.status NOT IN ('returned', 'return_pending') then order_date end) AS first_non_returned_order_date,
        max(case when a.status NOT IN ('returned', 'return_pending') then order_date end) AS most_recent_non_returned_order_date,
        coalesce(max(user_order_seq), 0) AS order_count,
        coalesce(count(case when a.status != 'returned' then 1 end),0) AS non_returned_order_count,
        sum(case when a.status NOT IN ('returned', 'return_pending') then ROUND(c.amount/100.0,2) else 0 end) AS total_lifetime_value,
        sum(case when a.status NOT IN ('returned', 'return_pending') then ROUND(c.amount/100.0,2) else 0 end) / NULLIF(COUNT(CASE WHEN a.status NOT In ('returned', 'return_pending')then 1 end), 0) AS avg_non_returned_order_value,
        array_agg(distinct a.id) AS order_ids
        
    FROM (
        SELECT 
            row_number() over (partition by user_id order by order_date, id) AS user_order_seq,
            *
        FROM raw.jaffle_shop.orders AS a
    ) AS a
    JOIN (
        SELECT 
            first_name || ' ' || last_name AS name,
            *
        FROM raw.jaffle_shop.customers AS b
    ) AS b
    ON a.user_id = b.id
    
    LEFT OUTER JOIN raw.stripe.payment AS c
    ON a.id = c.orderid

    WHERE a.status NOT IN ('pending') and c.status != 'fail'
    GROUP BY b.id, b.name, b.last_name, b.first_name

) AS customer_order_history
on orders.user_id = customer_order_history.customer_id

LEFT OUTER JOIN raw.stripe.payment AS payment
ON orders.id = payment.orderid

WHERE payment.status != 'failed'
