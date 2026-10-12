WITH channel_lookup AS (
    SELECT CAST('store' AS varchar) AS channel
    UNION ALL SELECT 'web'
    UNION ALL SELECT 'catalog'
    UNION ALL SELECT 'other'
),
date_range AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        CASE WHEN d.d_holiday = 'Y' THEN 'HOLIDAY' ELSE 'REGULAR' END AS day_type
    FROM date_dim d
    WHERE d.d_year BETWEEN 1999 AND 2000
),
agg_store AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_orders
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk
),
agg_web AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
agg_catalog AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
agg_combined AS (
    SELECT * FROM agg_store
    UNION ALL
    SELECT * FROM agg_web
    UNION ALL
    SELECT * FROM agg_catalog
),
full_matrix AS (
    SELECT
        dr.d_date_sk,
        dr.d_date,
        dr.day_type,
        cl.channel
    FROM date_range dr
    CROSS JOIN channel_lookup cl
),
sales_filled AS (
    SELECT
        fm.d_date_sk,
        fm.d_date,
        fm.day_type,
        fm.channel,
        COALESCE(a.net_profit, 0) AS net_profit,
        COALESCE(a.net_paid, 0) AS net_paid,
        COALESCE(a.num_orders, 0) AS num_orders
    FROM full_matrix fm
    LEFT JOIN agg_combined a
        ON fm.d_date_sk = a.date_sk
        AND fm.channel = a.channel
),
ranked_sales AS (
    SELECT
        sf.d_date_sk,
        sf.d_date,
        sf.day_type,
        sf.channel,
        sf.net_profit,
        sf.net_paid,
        sf.num_orders,
        ROW_NUMBER() OVER (PARTITION BY sf.d_date ORDER BY sf.net_profit DESC) AS profit_rank,
        MAX(sf.net_profit) OVER (
            PARTITION BY sf.channel
            ORDER BY sf.d_date
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS max_30d_profit,
        CASE
            WHEN sf.net_profit IS NULL THEN 'NO_DATA'
            WHEN sf.net_profit = 0 THEN 'ZERO'
            ELSE 'NONZERO'
        END AS profit_flag,
        CONCAT('Channel_', UPPER(sf.channel)) AS channel_label,
        REGEXP_REPLACE(CONCAT('Channel_', UPPER(sf.channel)), '^Channel_(.*)$', '$1') AS stripped_channel,
        substr(CONCAT('Channel_', UPPER(sf.channel)), 1, 3) AS channel_abbr,
        LENGTH(sf.channel) AS channel_len,
        sf.net_profit / NULLIF(sf.num_orders, 0) AS profit_per_order,
        CASE
            WHEN sf.net_profit / NULLIF(sf.num_orders, 0) > 1000 THEN 'HIGH'
            WHEN sf.net_profit / NULLIF(sf.num_orders, 0) > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM sales_filled sf
),
filtered AS (
    SELECT *
    FROM ranked_sales
    WHERE profit_rank <= 3
      AND profit_flag <> 'ZERO'
),
final_with_returns AS (
    SELECT
        f.*,
        CASE
            WHEN f.channel = 'store' THEN (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_returned_date_sk = f.d_date_sk)
            WHEN f.channel = 'web' THEN (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returned_date_sk = f.d_date_sk)
            WHEN f.channel = 'catalog' THEN (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returned_date_sk = f.d_date_sk)
            ELSE NULL
        END AS return_cnt
    FROM filtered f
)
SELECT *
FROM (
    SELECT
        f.d_date_sk,
        f.d_date,
        f.day_type,
        f.channel,
        f.channel_label,
        f.stripped_channel,
        f.net_profit,
        f.net_paid,
        f.num_orders,
        f.profit_per_order,
        f.max_30d_profit,
        f.profit_rank,
        f.profit_category,
        f.return_cnt
    FROM final_with_returns f
    WHERE f.profit_category = 'HIGH'
    EXCEPT
    SELECT
        f.d_date_sk,
        f.d_date,
        f.day_type,
        f.channel,
        f.channel_label,
        f.stripped_channel,
        f.net_profit,
        f.net_paid,
        f.num_orders,
        f.profit_per_order,
        f.max_30d_profit,
        f.profit_rank,
        f.profit_category,
        f.return_cnt
    FROM final_with_returns f
    WHERE f.day_type = 'HOLIDAY' OR f.net_profit IS NULL
) result
ORDER BY result.d_date, result.profit_rank
