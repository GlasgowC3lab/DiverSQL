/*
Goal: Identify the top‑5 product categories per year (for 2001) by net sales, broken down by catalog department and customer state, while filtering to high‑value items, active customers, and excluding transactions that have zero quantity.
*/
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_wholesale_cost,
        c.c_customer_id,
        c.c_email_address,
        ca.ca_state,
        cp.cp_department
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk   = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_wholesale_cost > 10.00
      AND c.c_email_address LIKE '%@xRtDqM1eLBVQNoYAJ.com'
      AND ss.ss_quantity > 1
      AND ss.ss_ticket_number NOT IN (
          SELECT ss2.ss_ticket_number
          FROM store_sales ss2
          WHERE ss2.ss_quantity = 0
      )
),
agg AS (
    SELECT
        d_year,
        i_category,
        cp_department,
        ca_state,
        COUNT(DISTINCT c_customer_id)               AS unique_customers,
        SUM(ss_net_paid)                             AS total_net_paid,
        AVG(ss_ext_sales_price)                      AS avg_ext_sales_price,
        MIN(ss_net_profit)                           AS min_net_profit,
        MAX(ss_net_profit)                           AS max_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY SUM(ss_net_paid) DESC) AS rnk
    FROM base
    GROUP BY d_year, i_category, cp_department, ca_state
    HAVING SUM(ss_net_paid) > 1000
)
SELECT
    d_year,
    i_category,
    cp_department,
    ca_state,
    unique_customers,
    total_net_paid,
    avg_ext_sales_price,
    min_net_profit,
    max_net_profit
FROM agg
WHERE rnk <= 5
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
