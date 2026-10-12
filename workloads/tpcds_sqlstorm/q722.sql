WITH store_sales_summary AS (
    SELECT
        'store' AS channel,
        d.d_date AS sales_date,
        s.s_store_name AS store_name,
        i.i_item_id AS item_id,
        i.i_category AS item_category,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS transaction_id
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
catalog_sales_summary AS (
    SELECT
        'catalog' AS channel,
        d.d_date AS sales_date,
        CAST(NULL AS VARCHAR) AS store_name,
        i.i_item_id AS item_id,
        i.i_category AS item_category,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS transaction_id
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
web_sales_summary AS (
    SELECT
        'web' AS channel,
        d.d_date AS sales_date,
        CAST(NULL AS VARCHAR) AS store_name,
        i.i_item_id AS item_id,
        i.i_category AS item_category,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS transaction_id
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
combined_sales AS (
    SELECT * FROM store_sales_summary
    UNION ALL
    SELECT * FROM catalog_sales_summary
    UNION ALL
    SELECT * FROM web_sales_summary
),
sales_with_rank AS (
    SELECT
        cs.channel,
        cs.sales_date,
        cs.store_name,
        cs.item_id,
        cs.item_category,
        cs.net_paid,
        cs.net_profit,
        cs.transaction_id,
        ROW_NUMBER() OVER (PARTITION BY cs.channel ORDER BY cs.sales_date DESC, cs.net_paid DESC) AS rn,
        SUM(cs.net_paid) OVER (PARTITION BY cs.channel) AS total_channel_net_paid,
        AVG(cs.net_profit) OVER (PARTITION BY cs.channel) AS avg_channel_profit,
        SUM(cs.net_paid) OVER (PARTITION BY cs.channel ORDER BY cs.sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
    FROM combined_sales cs
),
prev_day_sales AS (
    SELECT
        swr.channel,
        swr.sales_date,
        (SELECT SUM(c2.net_paid)
           FROM combined_sales c2
          WHERE c2.channel = swr.channel
            AND c2.sales_date = DATE_ADD('day', -1, swr.sales_date)) AS prev_day_net_paid
    FROM sales_with_rank swr
),
channel_return_stats AS (
    SELECT
        channel,
        SUM(return_amount) AS total_return_amount,
        COUNT(DISTINCT return_id) AS distinct_return_cnt,
        SUM(CASE WHEN return_amount > 0 THEN 1 ELSE 0 END) AS positive_return_cnt,
        SUM(CASE WHEN return_amount IS NULL THEN 1 ELSE 0 END) AS null_return_cnt
    FROM (
        SELECT 'store' AS channel, sr.sr_return_quantity AS return_id, sr.sr_return_amt AS return_amount
        FROM store_returns sr
        UNION ALL
        SELECT 'catalog' AS channel, cr.cr_return_quantity AS return_id, cr.cr_return_amount AS return_amount
        FROM catalog_returns cr
        UNION ALL
        SELECT 'web' AS channel, wr.wr_return_quantity AS return_id, wr.wr_return_amt AS return_amount
        FROM web_returns wr
    ) r
    GROUP BY channel
),
overlapping_items AS (
    SELECT item_id FROM store_sales_summary
    INTERSECT
    SELECT item_id FROM web_sales_summary
),
final_report AS (
    SELECT
        swr.channel,
        swr.sales_date,
        COALESCE(swr.store_name, 'N/A') AS store_name,
        swr.item_id,
        swr.item_category,
        swr.net_paid,
        swr.net_profit,
        swr.rn,
        swr.total_channel_net_paid,
        swr.avg_channel_profit,
        swr.cumulative_net_paid,
        pds.prev_day_net_paid,
        crs.total_return_amount,
        crs.distinct_return_cnt,
        crs.positive_return_cnt,
        crs.null_return_cnt,
        CASE
            WHEN swr.net_paid IS NULL THEN 'No Sales'
            WHEN swr.net_paid = 0 THEN 'Zero Sales'
            ELSE 'Has Sales'
        END AS sales_status,
        COALESCE(swr.net_profit / NULLIF(swr.net_paid, 0), 0) * 100 AS profit_pct,
        CONCAT('RPT-', swr.channel, '-', CAST(EXTRACT(year FROM swr.sales_date) AS VARCHAR), '-', LPAD(CAST(swr.rn AS VARCHAR), 3, '0')) AS report_id,
        (SELECT MAX(cs2.net_profit)
           FROM combined_sales cs2
          WHERE cs2.channel = swr.channel
            AND cs2.item_id = swr.item_id
            AND cs2.sales_date = DATE_ADD('day', -1, swr.sales_date)) AS prev_day_item_profit,
        CASE WHEN swr.item_id IN (SELECT item_id FROM overlapping_items) THEN TRUE ELSE FALSE END AS is_overlap
    FROM sales_with_rank swr
    LEFT JOIN prev_day_sales pds ON swr.channel = pds.channel AND swr.sales_date = pds.sales_date
    LEFT JOIN channel_return_stats crs ON swr.channel = crs.channel
    WHERE swr.rn = 1
)
SELECT *
FROM final_report
WHERE (sales_status = 'Has Sales' AND total_return_amount > 1000)
   OR (sales_status = 'No Sales' AND total_return_amount IS NULL)
ORDER BY channel, sales_date DESC
LIMIT 200
