# Jinja, Macros, and Packages

Date: April 2, 2026
Category: dbt
Sources (link): https://learn.getdbt.com/courses/jinja-macros-and-packages-vs-code

# What is Jinja?

## Jinja as language

Jinja is **python templating language engine** and bringing functional aspect to SQL. This will enables collaboration and write sql faster with less line of code

## How Jinja works?

dbt utilize 3 programming language below, thus make it so powerful. These 3 languages are:

- SQL: Defining data transformations
- YAML: Configuring, documenting and testing the SQL transformations
- Jinja: for templating and lineage. 
Jinja is the major part of dbt’s compilation process, allowing dbt to build and understand relationships between models and test in the DAG and properly modelling the relationship between your project files and warehouse objects.

Jinja can be powerful tools to both speed up the process of developing SQL, as well as can allowing more sophisticated dbt operations, like:

- Environment specific behaviors
- Permission control on the warehouse
- Automated removal of depecrated or stale models from warehouse

## Jinja Syntax

### The basics

1. The curly percents bracket:  `{% %}` 
This indicates some sorts of operation is happening inside jinja context. It will be invisible to the user after its compiled into output
2. The double curly brackets `{{ }}` 
Indicates we are pulling something out of the Jinja context, and printing it into file we are interacting with in order to produce some sort of written material

```sql
{% set cool_string  = 'Hello, World!' %}
{% set second_cool_string  = 'this is jinja' %}
{% set my_fav  = 'it is a great language' %}
{% set dur  = 1 %}

{{ cool_string }} {{ second_cool_string }} {{ my_fav }}. I want to learn it for {{ dur }} month
```

Lines above is jinja, and run `dbtf compile` or `dbt compile` will result like this:

```sql
Hello, World! this is jinja it is a great language. I want to learn it for 1 month
```

### IF and For Loop Statements

1. Example 1 - Using set to define variables of list

```sql
--This is the set blocks:
{% set animals = ['elephant', 'panda', 'dog', 'cat', 'beluga'] %}

{{ animals[0] }}
{{ animals[1] }}
{{ animals[2] }}
{{ animals[3] }}
{{ animals[4] }}
```

Execute `dbtf compile` or `dbt compile` will result like this:

```sql
elephant
panda
dog
cat
beluga
```

> `set A = [ ]` is the function to set variables value. 
It is the same with python list and has 0 as index start
> 

b. Example 2 - Combined set list & for loops

```sql
--This is the set blocks:
{% set animals = ['elephant', 'panda', 'dog', 'cat', 'beluga'] %}

{% for animal in animals %} -- The start of loop
	My favorit animal is the {{ animal }}
{% endfor %} -- The end of loop
```

Execute `dbtf compile` or `dbt compile` will result like this:

```sql
My favorit animal is the elephant
My favorit animal is the panda
My favorit animal is the dog
My favorit animal is the cat
My favorit animal is the beluga
```

c. Example 3 - Combine set list + for loops + if else statements

```sql
--This is the set blocks:
{% set foods = ['nasi goreng', 'yakiniku', 'sushi', 'ramen', 'takoyaki', 'risoles'] %}

{%- for food in foods -%} -- The start of for loop

-- This is the if-else logic:    
    {%- if food == 'nasi goreng' or food == 'yakiniku' or food == 'sushi' -%}
        {%- set food_type = 'main course' -%}
    {%- else -%}
        {%- set food_type = 'snack' -%}
    {%- endif -%}
    My favorites {{ food_type }} is {{ food }} 
    
{% endfor %} -- The end of for loop

-- Below is muted syntax by {# #}

{#
{% set foods = ['nasi goreng', 'yakiniku', 'sushi', 'ramen', 'takoyaki', 'risoles'] %}
{% for food in foods %}
    My favorites are {{ food }}
{% endfor %}
#}
```

> Curly pound sign `{# #}` is to comment, that execute nothing
The `-` on near the the curly sign is to remove extra lines when the dbt reading Jinja
> 

d. Example 4 - set dictionary

```sql
{% set dicitionary  = 
	'word' : 'data',
	'part of speech' : 'noun',
	'definition' : 'the building block of life'
 %}

{{ dictionary['word'] }} is a {{ dictionary['part of speech'] }} that means {{ dictionary['definition'] }}
```

Lines above is jinja, and run `dbtf compile` or `dbt compile` will result like this:

```sql
data is a noun that means the building block of life
```

e. Example 5 - Using jinja in `.sql` model to refer another `.sql` model

```sql
WITH payment AS (
    SELECT * FROM {{ ref('stg_stripe__payment') }} --this double curly bracket jinja
    ),
    pivoted AS (
        SELECT
        order_id,
        SUM(CASE WHEN payment_method = 'bank_transfer' THEN amount ELSE 0 END) AS bank_transfer_amount 
        FROM payment
        GROUP BY order_id
    )

SELECT * FROM pivoted
```

f. Example 6 - set dictionary

My data contains multiple payment_method: bank_transfer, coupon, credit_card and gift_card

Instead of written multiple times in query like this

```sql
WITH payment AS (
    SELECT * FROM {{ ref('stg_stripe__payment') }} --this double curly bracket jinja
    ),
    pivoted AS (
        SELECT
        order_id,
        SUM(CASE WHEN payment_method = 'bank_transfer' THEN amount ELSE 0 END) AS bank_transfer_amount,
        SUM(CASE WHEN payment_method = 'coupon' THEN amount ELSE 0 END) AS coupon_amount,
        SUM(CASE WHEN payment_method = 'credit_card' THEN amount ELSE 0 END) AS credit_amount,
        SUM(CASE WHEN payment_method = 'gift_card' THEN amount ELSE 0 END) AS gift_amount  
        FROM payment
        GROUP BY order_id
    )

SELECT * FROM pivoted
```

It can be written like this:

```sql
-- This block will list unique values of payment_method from stg_stripe__payment table
{% set payment_method = dbt_utils.get_column_values(
                table=ref('stg_stripe__payment'),
                column='payment_method')-%}

WITH payment AS (
    SELECT * FROM {{ ref('stg_stripe__payment') }}
    ),
    pivoted AS (
        SELECT
        order_id,
        
        -- The for loop to generate multiple query of SUM for each payment_method
        {%- for method in payment_method -%}
        SUM(CASE WHEN payment_method = '{{ method }}' THEN amount ELSE 0 END) AS {{ method }}_amount 
        
        {%- if not loop.last -%}, {% endif -%} ****-- this will not include the last comma in last iteration, prevent the query bugs
        
        
        {% endfor %}
        FROM payment
        GROUP BY order_id
    )

SELECT * FROM pivoted
```

The instruction will read as say *keep iterating :*

`SUM(CASE WHEN payment_method = '{{ method }}' THEN amount ELSE 0 END) AS {{ method }}_amount 
{%- if not loop.last -%}, {% endif -%}`

*But when it is last iteration remove trailing comma in the end of the for loop*.

This will prevent error and query bugs when the models are compiled, read more about this on [**Jinja - Template Designer Documentation**](https://jinja.palletsprojects.com/en/stable/templates/#for)

![image.png](images_screencaps/image%2018.png)

Worth to be back to read:
[https://learn.getdbt.com/learn/course/jinja-macros-and-packages-vs-code/getting-started-with-jinja-40min/jinja-basics?page=11](https://learn.getdbt.com/learn/course/jinja-macros-and-packages-vs-code/getting-started-with-jinja-40min/jinja-basics?page=11)

# What is Macro?

## Definition

Macro is reusable function are repeating our code over and over, and can be popped into macro and then used again and again, just one call to that macro.

Instead of using .sql model without macro like this
`models/staging/stripe/stg_stripe__payment.sql`

```
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status,
        -- amount is stored in cents, convert it to dollars
        amount * 1.0 / 100 as amount,
        created as created_at
    from {{source('stripe', 'payment')}}
```

We can use macro by creating this on `macros/cents_to_dollars.sql`:

```
{% macro cents_to_dollars(column_name, precision=2) %}
    ROUND({{ column_name }} / 100.0, {{ precision }})
{% endmacro %}
```

And use the macro here `models/staging/stripe/stg_stripe__payment.sql`

```
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status,
        -- amount is stored in cents, convert it to dollars
        {{ cents_to_dollars('amount',4) }} as amount,
        created as created_at
    from {{source('stripe', 'payment')}}
```

## **DRY Code**

Macros allow us to write DRY (Don’t Repeat Yourself) code in our dbt project. This allows us to take one model file that was 200 lines of code and compress it down to 50 lines of code. We can do this by abstracting away the logic into macros.

## **Tradeoff**

As you work through your dbt project, it is important to balance the readability/maintainability of your code with how concise your code (or DRY) your code is. Always remember that you are not the only one using this code, so be mindful and intentional about where you use macros.

# Packages

## What is it for?

- A collection of codes that already created by someone else and can be used for import models and macros into the dbt project
- Leverage modelling of common sources
- Find all of the packages in this [link](https://www.notion.so/Membuat-medalliion-Lot-1-dan-Lot-2-Compliance-Tools-2fe3b8fd528180f79a25f43ed760154e?pvs=21)
- Write packages needed in packages.yml

```yaml
packages:
  - git: "https://github.com/dbt-labs/dbt-codegen.git"
    revision: main
  - package: brooklyn-data/dbt_artifacts
    version: 2.10.0
  - package: dbt-labs/dbt_utils
    version: 1.3.3
```

- run `dbt deps` or `dbtf deps`  to install all the packages listed in `YAML`

## Package usage with macro

Example 1 - `models/date_spine_test.sql` 
This will create list of dates since 01 Jan 2019 - 31 Dec 2019

```sql
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2019-01-01' as date)",
    end_date="cast('2020-01-01' as date)"
   )
}}
```

Example 2 - `models/customers_daily_summary.sql` 

```sql
SELECT 
    customer_id,
    order_date,
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'order_date']) }} AS pk,
    count(*) AS c
FROM {{ ref('stg_jaffle_shop__orders') }}
GROUP BY ALL
```

## Package usage with models

Packages in dbt are not limited to macros only, there are sorts of packages like models, seeds, analysis and etc. In this tutorial, I learnt to use packages with models that called snowflake_spend

[https://hub.getdbt.com/gitlabhq/snowflake_spend/latest/](https://hub.getdbt.com/gitlabhq/snowflake_spend/latest/)

1. Install the packages below, and run `dbtf deps`
[https://hub.getdbt.com/gitlabhq/snowflake_spend/latest/](https://hub.getdbt.com/gitlabhq/snowflake_spend/latest/)

```sql
  - package: gitlabhq/snowflake_spend
    version: 1.4.0 -- update if newer version released
```

1. Create `seeds/snowflake_contract_rates.csv` like below:

```
EFFECTIVE_DATE,rate
2018-06-01,2.55
2019-08-01,2.48
```

1. Run `dbtf seed` and then `dbtf build`
2. We can view what the models do that create this lineage that comes from snowflake_spend package `dbt_packages/snowflake_spend`

![image.png](images_screencaps/image%2019.png)

1. The models from snowflake_spend is added into the target project
2. If we want the snowflake_spend into our project, update the `dbt_project.yml` like this

```yaml
models:
  jaffle_shop: #usually the name of the project is used as the top level key, but it can be changed to any name
    staging: 
      +materialized: view #usually intermediate tables are materialized as views, but it can be changed to table if needed
    marts:
      +materialized: table #final tables are usually materialized as tables, but it can be changed to view if needed
    snowflake_spend:
      +enabled: True
```

1. Then run selected build by using command 
`dbtf build -—select package:snowflake_spend`

## Lesson learn macro vs model packages

**Model packages** (like `snowflake_spend`) give you *pre-built pipelines* — someone already wrote the bronze → silver → gold transformations for a specific data source, so you don't have to.

Here's what `snowflake_spend` specifically does: 
Snowflake stores your platform usage data in raw system tables (how much compute, storage, queries each team runs). This package takes that raw data and transforms it into clean, analysis-ready tables — so a team can answer "how much are we spending on Snowflake per team per month?" without writing the transformations themselves.

Think of it this way with an analogy like this:

Imagine someone published a `service_billing` dbt package that already contained models to transform raw service claim data into clean tables — with all the deduplication, status mapping, and aggregation logic already done. You'd run `dbt deps`, then `dbt run`, and suddenly you have finished tables in your warehouse. That's what model packages do.

**When you run `dbt deps` + `dbt run`:**

- Macro packages → nothing happens until you call the macros yourself
- Model packages → new tables/views get created in your warehouse automatically, because the package contains SELECT statements that dbt materializes

**The practical use pattern is:** you're a Snowflake customer, you want to monitor your cloud spend, and instead of spending days writing the SQL to parse Snowflake's system tables, you install this package and get a working spend dashboard in minutes.

For the course, the point isn't that you'll use `snowflake_spend` 
The point is understanding that packages can ship *both* macros and models — and that model packages are essentially plug-and-play analytics pipelines someone else already built and tested.

# **Advanced Jinja and Macros**

## 1.  grant_select macro

**The problem it solves:** After dbt builds your tables, you need to give other roles (e.g., analysts, dashboards) permission to read them. Doing this manually every time is tedious. This macro automates it.

```sql
{% macro grant_select(schema=target.schema, role=target.role, database=target.database) %}
    {% set sql %}
        use database {{ database }};
        grant usage on schema {{ schema }} to role {{ role }};
        grant select on all tables in schema {{ schema }} to role {{ role }};
        grant select on all views in schema {{ schema }} to role {{ role }};
    {% endset %}

    {{ log ('Granting select on schema ' ~ schema ~ ' to role ' ~ role, info=True) }}
    {% do run_query(sql) %}
    {{ log ('Finished granting select on schema ' ~ schema ~ ' to role ' ~ role, info=True) }}
{% endmacro %}
```

This is how to use a macro to execute multiple permissions statements in a parameterized way.

Depends on the adapter used for the warehouse, the naming of `target._____` depends on the adapter.  [https://docs.getdbt.com/reference/dbt-jinja-functions/target](https://docs.getdbt.com/reference/dbt-jinja-functions/target)

Query explanation:

```sql
{% macro grant_select(schema=target.schema, role=target.role, database=target.database) %}
```

This defines the macro with **default parameters** pulled from `target`. The `target` object contains your connection profile info from `profiles.yml` — so if you don't pass arguments, it uses whatever environment you're running in.

```sql
    {% set sql %}
        use database {{ database }};
        grant usage on schema {{ schema }} to role {{ role }};
        grant select on all tables in schema {{ schema }} to role {{ role }};
        grant select on all views in schema {{ schema }} to role {{ role }};
    {% endset %}
```

`{% set sql %}...{% endset %}` is a **block set** — it captures everything between the tags as a string variable called `sql`. This is how you build multi-line SQL strings in Jinja. The `{{ database }}`, `{{ schema }}`, `{{ role }}` get replaced with actual values at runtime.

So if you call `grant_select(schema='analytics', role='reporter', database='prod_db')`, the `sql` variable becomes:

```sql
use database prod_db;
grant usage on schema analytics to role reporter;
grant select on all tables in schema analytics to role reporter;
grant select on all views in schema analytics to role reporter;
```

```sql
{{ log('Granting select on schema ' ~ schema ~ ' to role ' ~ role, info=True) }}
```

`log()` prints to your terminal. The `~` is Jinja's string concatenation operator (like `||` in SQL or `+` in Python). `info=True` means it shows during normal runs, not just debug mode.

sql

```sql
    {% do run_query(sql) %}
```

`run_query()` executes the SQL against your warehouse. The `{% do %}` tag means "run this but don't output anything to the compiled SQL file." Without `do`, the return value would get printed.

**How you call it:**

```bash
dbt run-operation grant_select
# uses defaults from target

dbt run-operation grant_select --args '{role: analyst_role}'
# overrides just the role
```

**BigQuery note:** This exact macro is Snowflake-specific (`USE DATABASE`, `GRANT` syntax). BigQuery handles permissions through IAM, not SQL grants. But the *pattern* — build a SQL string, then execute it — is universal.

## 2. union_tables_by_prefix macro

**The problem it solves:** You have multiple tables with the same structure but different names, like following:

1. Create dummy data on snowflake using this query. This will create table `orders__shopify` and `orders__amazon`

```sql
create table raw.jaffle_shop.orders__shopify as (

    select 
        1 as order_id,
        45 as order_amount,
        '2021-03-24 19:29:23.000'::timestamp as order_date
    
    union all 

    select 
        2 as order_id,
        35 as order_amount,
        '2021-03-25 09:31:38.000'::timestamp as order_date

);

create table raw.jaffle_shop.orders__amazon as (

    select 
        3 as order_id,
        45 as order_amount,
        '2021-03-26 01:26:23.000'::timestamp as order_date
    
    union all 

    select 
        4 as order_id,
        450 as order_amount,
        '2021-03-24 19:12:52.000'::timestamp as order_date

);
```

Now we have 2 tables with the same structure but different names:

- `orders__shopify`
- `orders__amazon`

b. Create the macro like this in `macros/union_tables_by_prefix.sql`

```sql
{%- macro union_tables_by_prefix(database, schema, prefix) -%}

    {%- set tables = dbt_utils.get_relations_by_prefix(database=database, schema=schema, prefix=prefix) -%}

    {% for table in tables %}

        {%- if not loop.first -%}
        union all 
        {%- endif %}
        
        select * from {{ table.database }}.{{ table.schema }}.{{ table.name }}
      
    {% endfor -%}
  
{%- endmacro -%}
```

***Query Explanation:***

- You want to UNION the 2 tables above into one table without manually listing every single one.

```sql
{%- macro union_tables_by_prefix(database, schema, prefix) -%}
```

- This calls a macro from the `dbt_utils` package. It queries your warehouse's information schema and returns a list of all tables whose name starts with `prefix`. So `prefix='orders__'` would find all the 2 tables above.

```sql
    {%- set tables = dbt_utils.get_relations_by_prefix(
        database=database, schema=schema, prefix=prefix
    ) -%}
    
    {% for table in tables %}
```

- Standard Jinja for-loop — iterates over each table found.
`loop.first` is a built-in Jinja variable — it's `True` only on the first iteration. This means: put `UNION ALL` before every table *except* the first one. Without this check, you'd get a syntax error from a leading `UNION ALL`.

```sql
{%- if not loop.first -%}
        union all 
        {%- endif %}
```

- Each relation object has `.database`, `.schema`, `.name` properties.

```sql
        select * from {{ table.database }}.{{ table.schema }}.{{ table.name }}
    {% endfor -%}
```

c. Calling this macro in any blank `.sql` worksheet

```sql
{{ union_tables_by_prefix(database = 'raw', schema = 'jaffle_shop', prefix = 'orders__')}}
```

will result SQL compilation like this, since on the database we only create 2 dummy table that has `orders__` as prefix on raw.JAFFLE_SHOP (poin a)

```sql
      select * from raw.JAFFLE_SHOP.ORDERS__AMAZON
      
  union all
        
      select * from raw.JAFFLE_SHOP.ORDERS__SHOPIFY
```

*Why would we use this macro?*

Imagine if in our schema has multiple orders table, listing it one-by-one in our query can be quite tedious. The above query can automatically union all the table within the same schema that has specific nomenclature for example `orders__xxx`

## 3. clean_slate_macro

**The problem it solves:** Over time, you rename or delete dbt models, but the old tables/views stay in your warehouse as orphans. This macro finds and drops them.

```sql
{#  
    -- let's develop a macro that 
    1. queries the information schema of a database
    2. finds objects that are > 1 week old (no longer maintained)
    3. generates automated drop statements
    4. has the ability to execute those drop statements

#}

{% macro clean_stale_models(database=target.database, schema=target.schema, days=7, dry_run=True) %}
    
    {% set get_drop_commands_query %}
        select 
	        case when table_type = 'VIEW' then table_type else 'TABLE' end as drop_type, 
          'DROP ' || drop_type || ' {{ database | upper }}.' || table_schema || '.' || table_name || ';'
        from {{ database }}.information_schema.tables 
        where table_schema = upper('{{ schema }}')
        and last_altered <= current_date - {{ days }} 
    {% endset %}

    {{ log('\nGenerating cleanup queries...\n', info=True) }}
    {% set drop_queries = run_query(get_drop_commands_query).columns[1].values() %}

    {% for query in drop_queries %}
        {% if dry_run %}
            {{ log(query, info=True) }}
        {% else %}
            {{ log('Dropping object with command: ' ~ query, info=True) }}
            {% do run_query(query) %} 
        {% endif %}       
    {% endfor %}
    
{% endmacro %} 
```

***Query Explanation:***

- Four parameters. The key one is `dry_run=True` — by default, it only *prints* what it would drop without actually dropping anything. Safety first.

```sql
{% macro clean_stale_models(database=target.database, schema=target.schema, days=7, dry_run=True) %}
```

- This builds a query against the `information_schema` — the warehouse's catalog of all tables. It finds objects not modified in the last `days` days, and generates a DROP statement for each one. The `| upper` is a Jinja **filter** — it uppercases the database name.

```sql
{% set get_drop_commands_query %}
	select
		case when table_type = 'VIEW' then table_type else 'TABLE' end as drop_type,
		'DROP ' || drop_type || ' {{ database | upper }}.' || table_schema || '.' || table_name || ';'
	from {{ database }}.information_schema.tables
	where table_schema = upper('{{ schema }}')
				and last_altered <= current_date - {{ days }}
{% endset %}
```

- The second column of the result is a string like `DROP TABLE PROD_DB.ANALYTICS.OLD_MODEL;`.

```sql
{% set drop_queries = run_query(get_drop_commands_query).columns[1].values() %}
```

- Breaking it down:
    - `run_query(...)` — executes the query, returns a result table
    - `.columns[1]` — gets the second column (index 0 = drop_type, index 1 = the DROP statement)
    - `.values()` — extracts all values as a list
- So `drop_queries` is now a Python list like:

```python
['DROP TABLE PROD_DB.ANALYTICS.OLD_MODEL;', 'DROP VIEW PROD_DB.ANALYTICS.DEPRECATED_VIEW;']
```

- Loop through each DROP statement. If `dry_run` is True, just print it. If False, actually execute it.

```sql
{% for query in drop_queries %}
	{% if dry_run %}
		{{ log(query, info=True) }}
	{% else %}
		{{ log('Dropping object with command: ' ~ query, info=True) }}
		{% do run_query(query) %}
	{% endif %}
{% endfor %}
```

**How to call it:**

```bash
# Preview what would be dropped (safe)
dbt run-operation clean_stale_models

# Actually drop them
dbt run-operation clean_stale_models --args '{dry_run: False}'

# Custom: only objects older than 30 days
dbt run-operation clean_stale_models --args '{days: 30, dry_run: False}'
```

## **4. generate_schema_name macro and c**ustomizing schema by environment

**The problem:** By default, dbt puts all models into whatever schema is in your `profiles.yml`. But in real projects, you want structure:

```bash
warehouse/
  ├── raw/          ← bronze layer
  ├── staging/      ← silver layer  
  └── analytics/    ← gold layer
```

You control this by adding `schema` in your `dbt_project.yml`:

```yaml
models:
  my_project:
    staging:
      +schema: staging
    marts:
      +schema: analytics
```

**But here's the catch.** dbt doesn't use the schema name directly. By default, it *concatenates* your target schema with the custom schema:

```yaml
target_schema = 'dbt_yudit'
custom_schema = 'staging'
result = 'dbt_yudit_staging'   ← not what you wanted
```

This is controlled by a macro called `generate_schema_name`. The **default** behavior:

```sql
{% macro generate_schema_name(custom_schema_name, node) %}
    {%- set default_schema = target.schema -%}
    
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name }}
    {%- endif -%}
{% endmacro %}
```

Translation: if no custom schema → use target schema. If custom schema is set → concatenate with underscore.

**To override this**, you create your own version in `macros/generate_schema_name.sql`:

```sql
{% macro generate_schema_name(custom_schema_name, node) %}
    {%- set default_schema = target.schema -%}
    
    {%- if target.name == 'prod' -%}
        {# In production: use the custom schema directly #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}
    
    {%- else -%}
        {# In dev: prefix with your name to avoid conflicts #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}
    
    {%- endif -%}
{% endmacro %}
```

**What this gives you:**

| Environment | Model schema config | Resulting schema |
| --- | --- | --- |
| dev (`target.name = 'dev'`) | none | `dbt_yudit` |
| dev | `staging` | `dbt_yudit_staging` |
| prod (`target.name = 'prod'`) | none | `dbt_yudit` (or whatever prod schema is) |
| prod | `staging` | `staging` ← clean! |
| prod | `analytics` | `analytics` ← clean! |

**Why this matters:**  We can always see clean schema names like `staging` and `analytics`. 
In development, everyone's work is sandboxed under their own prefix so nobody overwrites each other's tables.

`target.name` comes from your `profiles.yml` — it's the name of the profile target you're running with (`dbt run --target prod` vs `dbt run --target dev`).