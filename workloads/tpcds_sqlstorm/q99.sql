WITH sales_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_quantity) AS quantity,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_quantity) AS quantity,
           AVG(cs.cs_ext_discount_amt) AS avg_discount,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_quantity) AS quantity,
           AVG(ws.ws_ext_discount_amt) AS avg_discount,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, i.i_category
),
category_sales AS (
    SELECT
        year,
        month,
        i_category,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        AVG(avg_discount) AS avg_discount,
        SUM(promo_cost) AS total_promo_cost,
        SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_profit,
        SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_profit,
        SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_profit
    FROM sales_agg
    GROUP BY year, month, i_category
)
SELECT
    year,
    month,
    i_category,
    total_profit,
    total_quantity,
    avg_discount,
    total_promo_cost,
    store_profit,
    catalog_profit,
    web_profit,
    SUM(total_profit) OVER (PARTITION BY i_category ORDER BY year, month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_profit DESC) AS profit_rank
FROM category_sales
ORDER BY year, month, profit_rank
LIMIT 100
