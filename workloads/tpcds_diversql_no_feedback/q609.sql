WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows for faster analysis
)
SELECT
    d_year,
    d_day_name,
    c_customer_id,
    order_count,
    total_store_sales,
    total_catalog_sales,
    avg_store_quantity,
    max_promo_cost,
    min_inventory_on_hand,
    RANK() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year,
        d.d_day_name,
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number)               AS order_count,
        SUM(ss.ss_net_paid)                               AS total_store_sales,
        SUM(cs.cs_net_paid)                               AS total_catalog_sales,
        AVG(ss.ss_quantity)                               AS avg_store_quantity,
        MAX(p.p_cost)                                     AS max_promo_cost,
        MIN(inv.inv_quantity_on_hand)                     AS min_inventory_on_hand
    FROM sampled_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                                 AND cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2001                                 -- filter to a single year
        AND d.d_day_name = 'Saturday'                  -- restrict to Saturdays
        AND c.c_birth_year = 1975                      -- customers born in 1975
        AND p.p_channel_email = 'N'                    -- promotions not sent by email
        AND inv.inv_quantity_on_hand < 100            -- low inventory levels
    GROUP BY
        d.d_year,
        d.d_day_name,
        c.c_customer_id
) agg
ORDER BY total_store_sales DESC
LIMIT 100
