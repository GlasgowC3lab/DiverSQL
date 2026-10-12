WITH date_range AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
store_agg AS (
    SELECT
        dr.d_date,
        dr.d_year,
        s.s_store_name AS entity_name,
        'store' AS channel,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS net_paid,
        COALESCE(SUM(ss.ss_net_profit), 0) AS profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS txn_cnt
    FROM date_range dr
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = dr.d_date_sk
    LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
    GROUP BY dr.d_date, dr.d_year, s.s_store_name
),
web_agg AS (
    SELECT
        dr.d_date,
        dr.d_year,
        w.web_name AS entity_name,
        'web' AS channel,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS net_paid,
        COALESCE(SUM(ws.ws_net_profit), 0) AS profit,
        COUNT(DISTINCT ws.ws_order_number) AS txn_cnt
    FROM date_range dr
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = dr.d_date_sk
    LEFT JOIN web_site w ON w.web_site_sk = ws.ws_web_site_sk
    GROUP BY dr.d_date, dr.d_year, w.web_name
),
catalog_agg AS (
    SELECT
        dr.d_date,
        dr.d_year,
        cc.cc_manager AS entity_name,
        'catalog' AS channel,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS net_paid,
        COALESCE(SUM(cs.cs_net_profit), 0) AS profit,
        COUNT(DISTINCT cs.cs_order_number) AS txn_cnt
    FROM date_range dr
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = dr.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    GROUP BY dr.d_date, dr.d_year, cc.cc_manager
),
combined_sales AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM catalog_agg
),
top_brand AS (
    SELECT *
    FROM (
        SELECT
            dr.d_date,
            'store' AS channel,
            i.i_brand AS brand,
            ROW_NUMBER() OVER (PARTITION BY dr.d_date ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
        FROM date_range dr
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = dr.d_date_sk
        LEFT JOIN item i ON i.i_item_sk = ss.ss_item_sk
        GROUP BY dr.d_date, i.i_brand
        UNION ALL
        SELECT
            dr.d_date,
            'web' AS channel,
            i.i_brand AS brand,
            ROW_NUMBER() OVER (PARTITION BY dr.d_date ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
        FROM date_range dr
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = dr.d_date_sk
        LEFT JOIN item i ON i.i_item_sk = ws.ws_item_sk
        GROUP BY dr.d_date, i.i_brand
        UNION ALL
        SELECT
            dr.d_date,
            'catalog' AS channel,
            i.i_brand AS brand,
            ROW_NUMBER() OVER (PARTITION BY dr.d_date ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn
        FROM date_range dr
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = dr.d_date_sk
        LEFT JOIN item i ON i.i_item_sk = cs.cs_item_sk
        GROUP BY dr.d_date, i.i_brand
    ) t
    WHERE t.rn = 1
)
SELECT
    cs.d_date AS sale_date,
    cs.channel,
    cs.entity_name AS primary_entity,
    cs.net_paid,
    cs.profit,
    cs.txn_cnt,
    LAG(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.d_date) AS prev_day_net_paid,
    CASE
        WHEN LAG(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.d_date) = 0 THEN NULL
        ELSE (cs.net_paid - LAG(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.d_date)) /
             LAG(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.d_date)
    END AS pct_change_day,
    (SELECT tb.brand FROM top_brand tb WHERE tb.d_date = cs.d_date AND tb.channel = cs.channel) AS top_brand,
    (SELECT prev.net_paid
     FROM combined_sales prev
     WHERE prev.channel = cs.channel
       AND prev.d_date = cs.d_date - INTERVAL '1' YEAR) AS net_paid_prev_year,
    CASE
        WHEN (SELECT prev.net_paid
              FROM combined_sales prev
              WHERE prev.channel = cs.channel
                AND prev.d_date = cs.d_date - INTERVAL '1' YEAR) IS NULL THEN NULL
        ELSE (cs.net_paid - (SELECT prev.net_paid
                             FROM combined_sales prev
                             WHERE prev.channel = cs.channel
                               AND prev.d_date = cs.d_date - INTERVAL '1' YEAR)) /
             (SELECT prev.net_paid
              FROM combined_sales prev
              WHERE prev.channel = cs.channel
                AND prev.d_date = cs.d_date - INTERVAL '1' YEAR)
    END AS pct_change_year,
    SUM(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cs.channel ORDER BY cs.net_paid DESC) AS revenue_rank,
    CONCAT(cs.channel, '-', CAST(cs.d_date AS VARCHAR)) AS channel_date_key
FROM combined_sales cs
WHERE cs.net_paid > 0
ORDER BY cs.channel, cs.d_date
