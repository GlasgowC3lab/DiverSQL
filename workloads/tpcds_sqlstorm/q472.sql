WITH cs_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        COUNT(*) AS cs_orders,
        AVG(cs.cs_quantity) AS cs_avg_qty,
        MAX(cs.cs_net_profit) FILTER (WHERE cs.cs_quantity > 0) AS cs_max_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS cs_rnk,
        CONCAT_WS(' ', i.i_brand, i.i_class, i.i_category) AS i_description,
        COALESCE(c.c_preferred_cust_flag, 'N') AS cust_flag
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_profit IS NOT NULL
      AND (i.i_size = 'MEDIUM' OR i.i_size IS NULL)
    GROUP BY i.i_item_sk, i.i_product_name, d.d_year, i.i_brand, i.i_class, i.i_category, c.c_preferred_cust_flag
),
ss_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS ss_total_profit,
        COUNT(*) AS ss_orders,
        AVG(ss.ss_quantity) AS ss_avg_qty,
        MAX(ss.ss_net_profit) FILTER (WHERE ss.ss_quantity > 1) AS ss_max_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS ss_rnk,
        CONCAT_WS(' ', i.i_brand, i.i_class, i.i_category) AS i_desc2,
        COALESCE(s.s_store_name, 'UNKNOWN') AS store_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_net_profit IS NOT NULL
      AND s.s_state NOT IN ('ZZ', 'XX')
    GROUP BY i.i_item_sk, d.d_year, s.s_store_name, i.i_brand, i.i_class, i.i_category
),
ws_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        COUNT(*) AS ws_orders,
        AVG(ws.ws_quantity) AS ws_avg_qty,
        MAX(ws.ws_net_profit) FILTER (WHERE ws.ws_quantity > 0) AS ws_max_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS ws_rnk,
        CONCAT_WS('-', CAST(i.i_brand_id AS VARCHAR), CAST(i.i_category_id AS VARCHAR)) AS brand_category_key,
        LOWER(CAST(ws.ws_promo_sk AS VARCHAR)) AS promo_sk_str
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
    WHERE ws.ws_net_profit IS NOT NULL
      AND (p.p_promo_name IS NOT NULL OR ws.ws_promo_sk IS NULL)
    GROUP BY i.i_item_sk, d.d_year, i.i_brand_id, i.i_category_id, ws.ws_promo_sk
),
combined AS (
    SELECT
        COALESCE(cs.i_item_sk, ss.i_item_sk, ws.i_item_sk) AS item_sk,
        COALESCE(cs.d_year, ss.d_year, ws.d_year) AS year,
        cs.cs_total_profit,
        ss.ss_total_profit,
        ws.ws_total_profit,
        cs.cs_orders,
        ss.ss_orders,
        ws.ws_orders,
        cs.cs_avg_qty,
        ss.ss_avg_qty,
        ws.ws_avg_qty,
        cs.cs_max_profit,
        ss.ss_max_profit,
        ws.ws_max_profit,
        CASE
            WHEN cs.cs_total_profit > ss.ss_total_profit AND cs.cs_total_profit > ws.ws_total_profit THEN 'Catalog'
            WHEN ss.ss_total_profit > cs.cs_total_profit AND ss.ss_total_profit > ws.ws_total_profit THEN 'Store'
            WHEN ws.ws_total_profit > cs.cs_total_profit AND ws.ws_total_profit > ss.ss_total_profit THEN 'Web'
            ELSE 'Tie'
        END AS top_channel,
        CONCAT_WS('|', cs.i_description, ss.i_desc2, ws.brand_category_key) AS combined_desc,
        COALESCE(cs.cust_flag, ss.store_name, ws.promo_sk_str) AS representative_flag,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cs.i_item_sk, ss.i_item_sk, ws.i_item_sk) ORDER BY GREATEST(COALESCE(cs.cs_total_profit, 0), COALESCE(ss.ss_total_profit, 0), COALESCE(ws.ws_total_profit, 0)) DESC) AS overall_rnk,
        (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_year <= COALESCE(cs.d_year, ss.d_year, ws.d_year) AND d2.d_year >= COALESCE(cs.d_year, ss.d_year, ws.d_year) - 5) AS max_recent_year
    FROM cs_agg cs
    FULL OUTER JOIN ss_agg ss ON cs.i_item_sk = ss.i_item_sk AND cs.d_year = ss.d_year
    FULL OUTER JOIN ws_agg ws ON COALESCE(cs.i_item_sk, ss.i_item_sk) = ws.i_item_sk AND COALESCE(cs.d_year, ss.d_year) = ws.d_year
    WHERE (COALESCE(cs.cs_total_profit,0) + COALESCE(ss.ss_total_profit,0) + COALESCE(ws.ws_total_profit,0)) > 1000
      AND (cs.i_description IS NOT NULL OR ss.i_desc2 IS NOT NULL OR ws.brand_category_key IS NOT NULL)
      AND COALESCE(cs.cust_flag, ss.store_name, ws.promo_sk_str) <> 'UNKNOWN'
      AND NOT (cs.cs_total_profit IS NULL AND ss.ss_total_profit IS NULL AND ws.ws_total_profit IS NULL)
),
final AS (
    SELECT *
    FROM combined
    WHERE overall_rnk <= 10
      AND (year % 2 = 0 OR year % 3 = 0)
      AND top_channel IN ('Store','Web')
      AND (representative_flag LIKE '%5%' OR representative_flag LIKE 'A%')
      AND max_recent_year IS NOT NULL
    ORDER BY overall_rnk, year DESC
)
SELECT *
FROM final
UNION ALL
SELECT
    NULL AS item_sk,
    d.d_year AS year,
    0.0 AS cs_total_profit,
    0.0 AS ss_total_profit,
    -1.0 AS ws_total_profit,
    0 AS cs_orders,
    0 AS ss_orders,
    0 AS ws_orders,
    NULL AS cs_avg_qty,
    NULL AS ss_avg_qty,
    NULL AS ws_avg_qty,
    NULL AS cs_max_profit,
    NULL AS ss_max_profit,
    NULL AS ws_max_profit,
    'Synthetic' AS top_channel,
    'No Data' AS combined_desc,
    'N/A' AS representative_flag,
    9999 AS overall_rnk,
    d.d_year AS max_recent_year
FROM date_dim d
WHERE d.d_year NOT IN (SELECT year FROM final)
ORDER BY overall_rnk, year DESC
