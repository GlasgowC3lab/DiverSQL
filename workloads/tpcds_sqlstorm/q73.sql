WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_order_number AS order_num,
           cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ticket_number,
           NULL
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_order_number,
           NULL
    FROM web_sales ws
),
sales_dim AS (
    SELECT us.sold_date_sk,
           us.item_sk,
           us.net_paid,
           us.net_profit,
           us.order_num,
           us.call_center_sk,
           d.d_year,
           d.d_month_seq,
           i.i_item_id,
           i.i_item_desc,
           cc.cc_name AS call_center_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON d.d_date_sk = us.sold_date_sk
    LEFT JOIN item i ON i.i_item_sk = us.item_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = us.call_center_sk
),
agg_sales AS (
    SELECT i_item_id,
           i_item_desc,
           d_year,
           d_month_seq,
           call_center_name,
           SUM(COALESCE(net_paid, 0)) AS total_net_paid,
           SUM(COALESCE(net_profit, 0)) AS total_net_profit,
           COUNT(DISTINCT order_num) AS order_cnt
    FROM sales_dim
    GROUP BY GROUPING SETS (
        (i_item_id, i_item_desc, d_year, d_month_seq, call_center_name),
        (i_item_id, i_item_desc, call_center_name),
        (d_year, d_month_seq, call_center_name),
        (call_center_name),
        ()
    )
),
final_data AS (
    SELECT agg.i_item_id,
           agg.i_item_desc,
           agg.d_year,
           agg.d_month_seq,
           agg.call_center_name,
           agg.total_net_paid,
           agg.total_net_profit,
           agg.order_cnt,
           CASE
               WHEN agg.total_net_profit < 0 THEN 'Loss'
               WHEN agg.total_net_profit = 0 THEN 'Break-even'
               ELSE 'Profit'
           END AS profit_status,
           COALESCE(
               (SELECT COUNT(*)
                FROM store_returns sr
                JOIN date_dim dr ON dr.d_date_sk = sr.sr_returned_date_sk
                WHERE sr.sr_item_sk = i.i_item_sk
                  AND dr.d_year = agg.d_year), 0)
           + COALESCE(
               (SELECT COUNT(*)
                FROM catalog_returns cr
                JOIN date_dim dr ON dr.d_date_sk = cr.cr_returned_date_sk
                WHERE cr.cr_item_sk = i.i_item_sk
                  AND dr.d_year = agg.d_year), 0)
           + COALESCE(
               (SELECT COUNT(*)
                FROM web_returns wr
                JOIN date_dim dr ON dr.d_date_sk = wr.wr_returned_date_sk
                WHERE wr.wr_item_sk = i.i_item_sk
                  AND dr.d_year = agg.d_year), 0) AS total_returns,
           ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_net_paid DESC) AS sales_rank,
           CONCAT('Item-', COALESCE(agg.i_item_id, 'NULL'), '-', COALESCE(CAST(agg.d_month_seq AS VARCHAR), 'UNK')) AS item_key,
           (agg.total_net_paid - agg.total_net_profit) AS cost_vs_profit_diff,
           COALESCE(agg.total_net_paid / NULLIF(agg.order_cnt, 0), 0) AS avg_paid_per_order,
           CASE
               WHEN (agg.total_net_paid + agg.total_net_profit) IS NOT NULL
                    AND (agg.total_net_paid - agg.total_net_profit) IS NOT NULL
               THEN 'VALID' ELSE 'INVALID' END AS validity_flag,
           CASE WHEN agg.total_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_volume_flag,
           CASE WHEN EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk) THEN 1 ELSE 0 END AS has_store_return
    FROM agg_sales agg
    LEFT JOIN item i ON i.i_item_id = agg.i_item_id
)
SELECT *
FROM (
    SELECT *
    FROM final_data
    WHERE profit_status = 'Profit'
      AND d_year >= 2000
      AND i_item_id IN (SELECT i_item_id FROM item WHERE i_color IS NOT NULL)
      AND (LOWER(call_center_name) LIKE '%center%' OR REGEXP_LIKE(i_item_desc, '^.*(shirt|shoes).*$'))
    UNION ALL
    SELECT *
    FROM final_data
    WHERE profit_status = 'Loss'
      AND (d_year IS NULL OR d_year < 2000)
      AND i_item_id NOT IN (SELECT i_item_id FROM item WHERE i_color IS NOT NULL)
      AND (LOWER(call_center_name) LIKE '%center%' OR REGEXP_LIKE(i_item_desc, '^.*(shirt|shoes).*$'))
) q
ORDER BY d_year DESC NULLS LAST, total_net_paid DESC
LIMIT 200
