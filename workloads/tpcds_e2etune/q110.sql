WITH wp_agg AS (
    SELECT wp_customer_sk,
           COUNT(DISTINCT wp_web_page_sk) AS web_page_cnt
    FROM web_page
    GROUP BY wp_customer_sk
),
agg_sales AS (
    SELECT
        c.c_birth_country AS birth_country,
        i.i_category AS item_category,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        SUM(COALESCE(wp_agg.web_page_cnt, 0)) AS total_web_pages
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN wp_agg
        ON c.c_customer_sk = wp_agg.wp_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND cs.cs_ext_discount_amt > 100
      AND i.i_category_id IN (1, 2, 3)
    GROUP BY
        c.c_birth_country,
        i.i_category,
        sm.sm_type
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    birth_country,
    item_category,
    ship_mode_type,
    total_net_profit,
    avg_discount_amount,
    total_quantity,
    distinct_customers,
    distinct_items,
    total_web_pages,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 20
