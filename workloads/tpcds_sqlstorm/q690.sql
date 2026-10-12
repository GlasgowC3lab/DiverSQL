WITH store_daily_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_date,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS txn_count,
        MAX(ss.ss_ticket_number) AS max_ticket
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, d.d_date
),
store_ranked AS (
    SELECT
        sda.*,
        RANK() OVER (PARTITION BY sda.ss_store_sk ORDER BY sda.net_profit DESC) AS profit_rank,
        SUM(sda.net_profit) OVER (PARTITION BY sda.ss_store_sk ORDER BY sda.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_avg,
        CASE
            WHEN sda.net_profit IS NULL THEN NULL
            WHEN sda.net_profit < 0 THEN 'LOSS'
            ELSE 'PROFIT'
        END AS profit_flag
    FROM store_daily_agg sda
),
catalog_daily_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        d.d_date,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_catalog_page_sk, cs.cs_sold_date_sk, d.d_date
),
catalog_ranked AS (
    SELECT
        cda.*,
        RANK() OVER (PARTITION BY cda.cs_catalog_page_sk ORDER BY cda.net_profit DESC) AS profit_rank,
        SUM(cda.net_profit) OVER (PARTITION BY cda.cs_catalog_page_sk ORDER BY cda.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_avg,
        CASE
            WHEN cda.net_profit IS NULL THEN NULL
            WHEN cda.net_profit < 0 THEN 'LOSS'
            ELSE 'PROFIT'
        END AS profit_flag
    FROM catalog_daily_agg cda
),
web_daily_agg AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        d.d_date,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_page_sk, ws.ws_sold_date_sk, d.d_date
),
web_ranked AS (
    SELECT
        wda.*,
        RANK() OVER (PARTITION BY wda.ws_web_page_sk ORDER BY wda.net_profit DESC) AS profit_rank,
        SUM(wda.net_profit) OVER (PARTITION BY wda.ws_web_page_sk ORDER BY wda.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_avg,
        CASE
            WHEN wda.net_profit IS NULL THEN NULL
            WHEN wda.net_profit < 0 THEN 'LOSS'
            ELSE 'PROFIT'
        END AS profit_flag
    FROM web_daily_agg wda
),
top_customer_per_store_day AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS top_customer_name,
        ss.ss_net_paid AS top_sale_amount
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_net_paid = (
        SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
          AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
    )
),
final_combined AS (
    SELECT 
        'STORE' AS channel,
        COALESCE(s.s_store_id, CAST(sda.ss_store_sk AS VARCHAR)) AS entity_id,
        sda.d_date,
        sda.net_paid,
        sda.net_profit,
        sda.txn_count,
        sr.profit_rank,
        sr.profit_7day_avg,
        sr.profit_flag,
        COALESCE(tcs.top_customer_name, 'N/A') AS top_customer_name
    FROM store_daily_agg sda
    JOIN store_ranked sr ON sda.ss_store_sk = sr.ss_store_sk AND sda.ss_sold_date_sk = sr.ss_sold_date_sk
    LEFT JOIN store s ON sda.ss_store_sk = s.s_store_sk
    LEFT JOIN top_customer_per_store_day tcs ON tcs.ss_store_sk = sda.ss_store_sk AND tcs.ss_sold_date_sk = sda.ss_sold_date_sk

    UNION ALL

    SELECT
        'CATALOG' AS channel,
        COALESCE(cp.cp_catalog_page_id, CAST(cda.cs_catalog_page_sk AS VARCHAR)) AS entity_id,
        cda.d_date,
        cda.net_paid,
        cda.net_profit,
        cda.txn_count,
        cr.profit_rank,
        cr.profit_7day_avg,
        cr.profit_flag,
        NULL AS top_customer_name
    FROM catalog_daily_agg cda
    JOIN catalog_ranked cr ON cda.cs_catalog_page_sk = cr.cs_catalog_page_sk AND cda.cs_sold_date_sk = cr.cs_sold_date_sk
    LEFT JOIN catalog_page cp ON cda.cs_catalog_page_sk = cp.cp_catalog_page_sk

    UNION ALL

    SELECT
        'WEB' AS channel,
        COALESCE(wp.wp_web_page_id, CAST(wda.ws_web_page_sk AS VARCHAR)) AS entity_id,
        wda.d_date,
        wda.net_paid,
        wda.net_profit,
        wda.txn_count,
        wr.profit_rank,
        wr.profit_7day_avg,
        wr.profit_flag,
        NULL AS top_customer_name
    FROM web_daily_agg wda
    JOIN web_ranked wr ON wda.ws_web_page_sk = wr.ws_web_page_sk AND wda.ws_sold_date_sk = wr.ws_sold_date_sk
    LEFT JOIN web_page wp ON wda.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    channel,
    entity_id,
    d_date,
    net_paid,
    net_profit,
    txn_count,
    profit_rank,
    profit_7day_avg,
    profit_flag,
    top_customer_name
FROM final_combined
WHERE profit_rank <= 5
  AND (profit_flag = 'PROFIT' OR profit_flag = 'LOSS')
ORDER BY channel, profit_rank, d_date
