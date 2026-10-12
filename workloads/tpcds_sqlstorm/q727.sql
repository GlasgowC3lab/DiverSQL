WITH
store_sales_monthly AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(DISTINCT ss.ss_item_sk) AS distinct_items
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_id, d.d_year, d.d_month_seq
),
web_sales_monthly AS (
    SELECT NULL AS s_store_sk,
           'WEB' AS s_store_id,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
catalog_sales_monthly AS (
    SELECT NULL AS s_store_sk,
           'CATALOG' AS s_store_id,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_quantity) AS total_quantity,
           COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
combined_sales AS (
    SELECT * FROM store_sales_monthly
    UNION ALL
    SELECT * FROM web_sales_monthly
    UNION ALL
    SELECT * FROM catalog_sales_monthly
),
ranked_sales AS (
    SELECT
        s_store_sk,
        s_store_id,
        d_year,
        month_seq,
        net_profit,
        total_quantity,
        distinct_items,
        CASE
            WHEN net_profit > 0 THEN 'POSITIVE'
            WHEN net_profit < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_category,
        CONCAT('Month ', CAST(month_seq AS VARCHAR), ' of ', CAST(d_year AS VARCHAR)) AS month_desc,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY net_profit DESC NULLS LAST) AS profit_rank,
        AVG(net_profit) OVER (PARTITION BY d_year, month_seq) AS avg_month_profit,
        net_profit / NULLIF(AVG(net_profit) OVER (PARTITION BY d_year, month_seq), 0) AS profit_vs_avg
    FROM combined_sales
),
top_item_lateral AS (
    SELECT
        rs.s_store_sk,
        rs.s_store_id,
        rs.d_year,
        rs.month_seq,
        rs.net_profit,
        rs.total_quantity,
        rs.distinct_items,
        rs.profit_category,
        rs.month_desc,
        rs.profit_rank,
        rs.avg_month_profit,
        rs.profit_vs_avg,
        ti.top_item_id,
        ti.top_item_qty
    FROM ranked_sales rs
    LEFT JOIN LATERAL (
        SELECT i.i_item_id AS top_item_id,
               SUM(ss.ss_quantity) AS top_item_qty
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE ss.ss_store_sk = rs.s_store_sk
          AND d.d_year = rs.d_year
          AND d.d_month_seq = rs.month_seq
        GROUP BY i.i_item_id
        ORDER BY top_item_qty DESC NULLS LAST
        LIMIT 1
    ) AS ti ON true
),
final_result AS (
    SELECT
        st.s_store_sk,
        COALESCE(ti.s_store_id, 'NO_SALES') AS store_identifier,
        ti.d_year,
        ti.month_seq,
        ti.month_desc,
        ti.net_profit,
        ti.total_quantity,
        ti.distinct_items,
        ti.profit_category,
        ti.profit_rank,
        ti.avg_month_profit,
        ti.profit_vs_avg,
        CASE
            WHEN ti.profit_vs_avg > 2 THEN 'HIGH'
            WHEN ti.profit_vs_avg < 0.5 THEN 'LOW'
            ELSE 'NORMAL'
        END AS profit_vs_avg_category,
        ti.top_item_id,
        COALESCE(ti.top_item_qty, 0) AS top_item_quantity,
        (SELECT COALESCE(SUM(prev.net_profit), 0)
         FROM combined_sales prev
         WHERE prev.s_store_sk = ti.s_store_sk
           AND prev.d_year = ti.d_year
           AND prev.month_seq = ti.month_seq - 1
        ) AS prev_month_net_profit,
        CASE
            WHEN lower(st.s_store_name) LIKE '%market%' THEN true
            ELSE false
        END AS is_market_store,
        CASE
            WHEN st.s_manager IS NULL OR trim(st.s_manager) = '' THEN 'NO_MANAGER'
            ELSE st.s_manager
        END AS manager_status,
        COALESCE(st.s_city, 'UNKNOWN_CITY') || ', ' || COALESCE(st.s_state, 'UNKNOWN_STATE') AS city_state
    FROM top_item_lateral ti
    RIGHT JOIN store st ON ti.s_store_sk = st.s_store_sk
    WHERE
        (st.s_country = 'United States' OR st.s_country IS NULL)
        AND (st.s_tax_percentage IS NOT NULL AND st.s_tax_percentage > 0 OR st.s_tax_percentage IS NULL)
        AND (ti.profit_category IS NOT NULL OR ti.s_store_sk IS NULL)
        AND ti.profit_rank = 1
)
SELECT *
FROM final_result
UNION ALL
SELECT
    s.s_store_sk,
    s.s_store_id,
    NULL AS d_year,
    NULL AS month_seq,
    NULL AS month_desc,
    0.0 AS net_profit,
    0 AS total_quantity,
    0 AS distinct_items,
    'NO_DATA' AS profit_category,
    NULL AS profit_rank,
    NULL AS avg_month_profit,
    NULL AS profit_vs_avg,
    'NO_DATA' AS profit_vs_avg_category,
    NULL AS top_item_id,
    0 AS top_item_quantity,
    NULL AS prev_month_net_profit,
    FALSE AS is_market_store,
    COALESCE(s.s_manager, 'NO_MANAGER') AS manager_status,
    COALESCE(s.s_city, 'UNKNOWN_CITY') || ', ' || COALESCE(s.s_state, 'UNKNOWN_STATE') AS city_state
FROM store s
WHERE NOT EXISTS (SELECT 1 FROM combined_sales cs WHERE cs.s_store_sk = s.s_store_sk)
ORDER BY net_profit DESC NULLS LAST
