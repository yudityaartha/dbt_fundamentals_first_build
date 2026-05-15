# Refactoring SQL for Modularity (VS Code)

Date: April 6, 2026
Category: dbt
Sources (link): https://courses.getdbt.com

## What & Why

Refactoring SQL for modularity means restructuring a query **without changing its logic**. The goal is readability, maintainability, and making it easier to debug, for others and for future me.

---

## Steps of Refactoring Process

1. Copy the legacy query into dbt as-is
2. **Replace hardcoded source paths** with `{{ ref() }}` and `{{ source() }}`
3. **Cosmetic cleanup** — lowercase keywords, consistent indentation, line breaks on `CASE WHEN`
4. **Restructure into the CTE grouping pattern** (import → logical → final)
5. Split into staging/intermediate/final layers, 
6. audit with `audit_helper` to make sure the refactored output matches the original
7. Deploy

---

## The CTE Grouping Pattern

This is the core takeaway. Every well-refactored query follows this three-layer structure:

| Layer | Purpose | Example |
| --- | --- | --- |
| **Import CTEs** | Thin wrappers around `{{ source() }}`, always `SELECT *` | `raw_orders`, `raw_customers`, `raw_payments` |
| **Logical CTEs** | Transformations, joins, enrichment, subquery replacement | `customer_order_history`, `orders_with_seq`, `customers_with_fullname` |
| **Final SELECT** | Assembles output by referencing logical CTEs — no computation here | The final `SELECT` block |

```sql
-- import CTEs
with raw_customers as (
    select * from {{ source('jaffle_shop', 'customers') }}
),
raw_orders as (
    select * from {{ source('jaffle_shop', 'orders') }}
),
raw_payments as (
    select * from {{ source('stripe', 'payment') }}
),

-- logical CTEs
customers_with_fullname as (
    select
        first_name || ' ' || last_name as name,
        *
    from raw_customers
),
customer_order_history as (
    ...
),

-- final CTE
select
    orders.id as order_id,
    ...
from raw_orders as orders
join customers_with_fullname on ...
join customer_order_history on ...
```

---

## Deeper Notes & Caveats

### 1. Name CTEs well — don't just lift aliases

A common mistake when refactoring is pulling subquery aliases directly into CTE names. The original query had `FROM ... AS a` and `FROM ... AS b`, and the refactored version kept those as CTE names `a` and `b`.

This is an **antipattern**. A reader coming in cold has no idea what `a` is — they'd have to scroll up and read the CTE definition first. Unnecessary cognitive overhead.

```sql
-- ❌ Lifted from original alias — tells you nothing
from a
join b on a.user_id = b.id

-- ✅ Self-documenting
from orders_with_seq
join customers_with_fullname on orders_with_seq.user_id = customers_with_fullname.id
```

Good CTE names = self-documenting SQL. No scrolling required.

---

### 2. Import CTEs are intentionally thin — and that's a feature

Import CTEs always look like this:

```sql
raw_orders as (
    select * from {{ source('jaffle_shop', 'orders') }}
)
```

Why bother wrapping it? Why not reference `{{ source() }}` directly in logical CTEs?

Because this creates **one single point of truth** for each source. If the source schema changes — say `raw.jaffle_shop.orders` moves to `raw.jaffle_shop.v2_orders` — you fix it in exactly one line, and every downstream CTE inherits the change automatically.

If you scattered `{{ source('jaffle_shop', 'orders') }}` across 4 logical CTEs, you'd have 4 places to hunt down and fix. That's how bugs sneak in.

---

### 3. This CTE pattern is a micro-version of dbt's layered architecture

The three-layer CTE structure directly maps to dbt's recommended project layout:

| dbt Layer | CTE Equivalent | Responsibility |
| --- | --- | --- |
| **Staging** | Import CTEs | Thin wrappers around source, no business logic |
| **Intermediate** | Logical CTEs | Joins, transformations, enrichment |
| **Mart** | Final SELECT | Business-ready output |

When writing a well-structured CTE file, you're doing dbt's entire layered philosophy — just inside one file. Once this clicks, scaling up to a full dbt project feels natural because it's the same mental model, just spread across separate model files.

---

### 4. A well-refactored final SELECT is declarative

In the original messy query, the final SELECT had computation baked in — `ROUND(amount/100.0, 2)`, inline subqueries, everything jumbled together.

In the refactored version, the final SELECT just picks and names columns:

```sql
select
    orders.id as order_id,
    orders.user_id as customer_id,
    last_name as surname,
    first_order_date,
    order_count,
    total_lifetime_value,
    ...
from raw_orders as orders
join customers_with_fullname on ...
join customer_order_history on ...
```

No computation happening. The "how" already happened in the logical CTEs. The final SELECT describes **what** to assemble.

This is what **declarative** means in SQL: you state what you want, not how to compute it. It reads almost like a sentence: *"Take orders, attach customer info, attach order history, attach payments."*

This is the clearest sign of a well-refactored query — the final output is easy to audit at a glance.