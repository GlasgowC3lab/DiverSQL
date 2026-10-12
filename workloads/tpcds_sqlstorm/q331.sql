WITH
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_year,
        d.d_qoy AS quarter,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        MAX(cs.cs_net_profit) AS max_profit,
        MIN(cs.cs_net_profit) AS min_profit
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year, d.d_qoy
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_year,
        d.d_qoy AS quarter,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(ws.ws_net_profit) AS min_profit
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_year, d.d_qoy
),
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year,
        d.d_qoy AS quarter,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        MAX(ss.ss_net_profit) AS max_profit,
        MIN(ss.ss_net_profit) AS min_profit
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_year, d.d_qoy
),
combined_sales AS (
    SELECT
        ca.item_sk,
        ca.d_year,
        ca.quarter,
        ca.total_net_profit,
        ca.total_sales,
        ca.txn_count,
        ca.max_profit,
        ca.min_profit,
        'Catalog' AS channel
    FROM catalog_sales_agg ca
    UNION ALL
    SELECT
        wa.item_sk,
        wa.d_year,
        wa.quarter,
        wa.total_net_profit,
        wa.total_sales,
        wa.txn_count,
        wa.max_profit,
        wa.min_profit,
        'Web' AS channel
    FROM web_sales_agg wa
    UNION ALL
    SELECT
        sa.item_sk,
        sa.d_year,
        sa.quarter,
        sa.total_net_profit,
        sa.total_sales,
        sa.txn_count,
        sa.max_profit,
        sa.min_profit,
        'Store' AS channel
    FROM store_sales_agg sa
),
sales_windowed AS (
    SELECT
        cs.*,
        LAG(cs.total_net_profit) OVER (PARTITION BY cs.item_sk, cs.channel ORDER BY cs.d_year, cs.quarter) AS prior_net_profit,
        SUM(cs.total_net_profit) OVER (PARTITION BY cs.channel ORDER BY cs.d_year, cs.quarter ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit
    FROM combined_sales cs
),
sales_ranked AS (
    SELECT
        sw.*,
        ROW_NUMBER() OVER (PARTITION BY sw.d_year, sw.channel ORDER BY sw.total_net_profit DESC) AS profit_rank
    FROM sales_windowed sw
),
promo_flag AS (
    SELECT
        p.p_item_sk AS item_sk,
        MAX(CASE WHEN UPPER(p.p_discount_active) = 'Y' THEN 1 ELSE 0 END) AS has_active_promo
    FROM promotion p
    GROUP BY p.p_item_sk
),
sales_enriched AS (
    SELECT
        sr.*,
        i.i_item_id,
        i.i_product_name,
        COALESCE(pf.has_active_promo, 0) AS has_active_promo
    FROM sales_ranked sr
    LEFT JOIN item i ON sr.item_sk = i.i_item_sk
    LEFT JOIN promo_flag pf ON sr.item_sk = pf.item_sk
),
filtered_sales AS (
    SELECT
        se.*,
        CASE
            WHEN se.total_sales = 0 THEN NULL
            ELSE se.total_net_profit / NULLIF(se.total_sales, 0)
        END AS profit_margin,
        CASE
            WHEN se.max_profit = se.min_profit THEN 0
            ELSE se.max_profit
        END *
        CASE
            WHEN se.channel = 'Web' THEN 1.1
            WHEN se.channel = 'Store' THEN 1.05
            ELSE 1
        END AS adjusted_max_profit,
        CASE
            WHEN se.profit_rank = 1 THEN 'TopProfitable'
            WHEN se.total_net_profit / NULLIF(se.total_sales, 0) > 0.5 THEN 'HighMargin'
            ELSE 'Regular'
        END AS profit_category,
        CASE
            WHEN se.total_net_profit / NULLIF(se.total_sales, 0) IS NULL THEN NULL
            WHEN se.total_net_profit / NULLIF(se.total_sales, 0) = 0 THEN 'ZeroProfit'
            ELSE format('%s_%s', se.channel, CAST(FLOOR((se.total_net_profit / NULLIF(se.total_sales, 0)) * 100) AS varchar))
        END AS profit_code
    FROM sales_enriched se
    WHERE NOT EXISTS (
        SELECT 1
        FROM combined_sales cs_neg
        WHERE cs_neg.item_sk = se.item_sk
          AND cs_neg.total_net_profit < 0
    )
      AND (se.total_sales > 1000 OR se.txn_count > 10)
      AND ( (se.channel = 'Catalog' AND MOD(se.d_year, 2) = 0) OR se.channel <> 'Catalog')
      AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_call_center_id = CONCAT('CC', CAST(se.item_sk AS varchar))
          AND cc.cc_closed_date_sk IS NULL
      )
)
SELECT
    d_year,
    quarter,
    channel,
    COUNT(DISTINCT item_sk) AS distinct_items,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(total_sales) AS sum_total_sales,
    AVG(profit_margin) AS avg_profit_margin,
    MAX(adjusted_max_profit) AS max_adjusted_max_profit,
    COUNT_IF(profit_category = 'TopProfitable') AS top_profitable_cnt,
    COUNT_IF(profit_category = 'HighMargin') AS high_margin_cnt,
    SUM(CASE WHEN has_active_promo = 1 THEN total_sales ELSE 0 END) AS promo_sales,
    MAX(cum_net_profit) AS cum_net_profit
FROM filtered_sales
GROUP BY GROUPING SETS (
    (d_year, quarter, channel),
    (d_year, quarter),
    (channel),
    ()
)
HAVING SUM(total_net_profit) > 0
ORDER BY d_year DESC NULLS LAST, quarter DESC NULLS LAST, channel, sum_net_profit DESC
LIMIT 100
