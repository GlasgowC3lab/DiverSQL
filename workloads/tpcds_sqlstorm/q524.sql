WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        s.s_store_sk AS entity_sk,
        s.s_store_name AS entity_name,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS txn_count,
        MAX(ss.ss_quantity) AS max_qty,
        MIN(ss.ss_quantity) AS min_qty,
        AVG(ss.ss_quantity) AS avg_qty
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY 1,2,3,4
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_call_center_sk AS entity_sk,
        cc.cc_name AS entity_name,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS txn_count,
        MAX(cs.cs_quantity) AS max_qty,
        MIN(cs.cs_quantity) AS min_qty,
        AVG(cs.cs_quantity) AS avg_qty
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY 1,2,3,4
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        wp.wp_web_page_sk AS entity_sk,
        wp.wp_url AS entity_name,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS txn_count,
        MAX(ws.ws_quantity) AS max_qty,
        MIN(ws.ws_quantity) AS min_qty,
        AVG(ws.ws_quantity) AS avg_qty
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 1,2,3,4
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_with_dates AS (
    SELECT
        cs.date_sk,
        cs.entity_sk,
        cs.entity_name,
        cs.channel,
        cs.net_paid,
        cs.net_profit,
        cs.txn_count,
        cs.max_qty,
        cs.min_qty,
        cs.avg_qty,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        SUM(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.channel ORDER BY cs.net_profit DESC) AS profit_rank,
        LAG(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.date_sk) AS prev_net_paid,
        LEAD(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.date_sk) AS next_net_paid,
        CASE 
            WHEN cs.channel = 'store' AND cs.max_qty > 100 THEN 'HIGH_QTY'
            WHEN cs.channel = 'catalog' AND cs.avg_qty < 1 THEN 'LOW_AVG_QTY'
            WHEN cs.channel = 'web' AND cs.txn_count >= 1000 THEN 'HIGH_VOLUME'
            ELSE 'NORMAL'
        END AS volume_flag,
        REPLACE(LOWER(CONCAT(cs.entity_name, '_', cs.channel)), ' ', '_') AS entity_key,
        CASE cs.channel
            WHEN 'store' THEN (
                SELECT SUM(sr.sr_net_loss)
                FROM store_returns sr
                WHERE sr.sr_store_sk = cs.entity_sk
                  AND sr.sr_returned_date_sk = cs.date_sk
            )
            WHEN 'catalog' THEN (
                SELECT SUM(cr.cr_net_loss)
                FROM catalog_returns cr
                WHERE cr.cr_call_center_sk = cs.entity_sk
                  AND cr.cr_returned_date_sk = cs.date_sk
            )
            WHEN 'web' THEN (
                SELECT SUM(wr.wr_net_loss)
                FROM web_returns wr
                WHERE wr.wr_web_page_sk = cs.entity_sk
                  AND wr.wr_returned_date_sk = cs.date_sk
            )
            ELSE NULL
        END AS total_return_net_loss
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
),
final_filtered AS (
    SELECT *
    FROM sales_with_dates
    WHERE
        net_paid IS NOT NULL
        AND (profit_rank <= 5 OR total_return_net_loss > 0 OR (net_paid < 0 AND prev_net_paid IS NULL))
        AND entity_key IS NOT DISTINCT FROM REPLACE(LOWER(CONCAT(entity_name, '_', channel)), ' ', '_')
)
SELECT
    date_sk,
    d_date,
    channel,
    entity_sk,
    entity_name,
    net_paid,
    net_profit,
    txn_count,
    volume_flag,
    entity_key,
    running_net_paid,
    profit_rank,
    prev_net_paid,
    next_net_paid,
    total_return_net_loss,
    (COALESCE(net_profit, 0) - COALESCE(prev_net_paid, 0)) AS profit_delta,
    CASE WHEN txn_count = 0 THEN NULL ELSE net_paid / txn_count END AS avg_paid_per_txn,
    POWER(1.05, COALESCE(d_year - 2000, 0)) AS growth_factor
FROM final_filtered
WHERE (CASE WHEN volume_flag = 'HIGH_QTY' THEN net_paid * 1.1 ELSE net_paid END) > 0
ORDER BY channel, date_sk, net_paid DESC
LIMIT 100
