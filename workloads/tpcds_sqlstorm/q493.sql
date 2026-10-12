WITH sales_by_channel AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_store_sk AS store_sk,
           SUM(ss.ss_ext_sales_price) AS sales,
           SUM(ss.ss_net_profit) AS profit,
           COUNT(*) AS orders
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_store_sk

    UNION ALL

    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_call_center_sk AS store_sk,
           SUM(cs.cs_ext_sales_price) AS sales,
           SUM(cs.cs_net_profit) AS profit,
           COUNT(*) AS orders
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_call_center_sk

    UNION ALL

    SELECT 'web' AS channel,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_web_page_sk AS store_sk,
           SUM(ws.ws_ext_sales_price) AS sales,
           SUM(ws.ws_net_profit) AS profit,
           COUNT(*) AS orders
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_web_page_sk
),
ranked_sales AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY channel, date_sk ORDER BY sales DESC) AS rn
    FROM sales_by_channel
),
top_daily_sales AS (
    SELECT channel,
           date_sk,
           item_sk,
           store_sk,
           sales,
           profit,
           orders,
           rn
    FROM ranked_sales
    WHERE rn <= 5
),
enriched AS (
    SELECT t.channel,
           d.d_date AS sale_date,
           i.i_product_name,
           t.item_sk,
           t.rn,
           COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS location_name,
           t.sales,
           t.profit,
           t.orders,
           CASE 
               WHEN t.profit < 0 THEN 'Loss'
               WHEN t.profit = 0 THEN 'BreakEven'
               ELSE 'Profit'
           END AS profit_flag,
           CONCAT('Top', CAST(t.rn AS VARCHAR), '_', t.channel) AS rank_label,
           (SELECT MAX(s2.sales) FROM sales_by_channel s2 WHERE s2.item_sk = t.item_sk AND s2.channel = t.channel) AS max_item_sales,
           (SELECT COUNT(*) FROM sales_by_channel s3 WHERE s3.item_sk = t.item_sk AND s3.channel = t.channel AND s3.sales > t.sales) AS better_days_count
    FROM top_daily_sales t
    LEFT JOIN date_dim d ON d.d_date_sk = t.date_sk
    LEFT JOIN item i ON i.i_item_sk = t.item_sk
    LEFT JOIN store st ON st.s_store_sk = t.store_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = t.store_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = t.store_sk
),
final_aggregates AS (
    SELECT channel,
           DATE_TRUNC('month', sale_date) AS sale_month,
           COUNT(DISTINCT item_sk) AS distinct_items_sold,
           SUM(sales) AS total_sales,
           SUM(profit) AS total_profit,
           AVG(profit) AS avg_profit_per_day,
           SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END) AS loss_days,
           MAX(sales) AS max_daily_sales,
           MIN(sales) AS min_daily_sales,
           APPROX_PERCENTILE(sales, 0.5) AS median_daily_sales,
           array_join(array_agg(rank_label ORDER BY rn), ', ') AS rank_labels_concat
    FROM enriched
    GROUP BY channel, DATE_TRUNC('month', sale_date)
),
comparative AS (
    SELECT f.channel,
           f.sale_month,
           f.total_sales,
           f.total_profit,
           COALESCE(lag_total_sales, 0) AS prev_month_sales,
           f.total_sales - COALESCE(lag_total_sales, 0) AS sales_delta,
           CASE 
               WHEN f.total_sales > COALESCE(lag_total_sales, 0) THEN 'Increase'
               WHEN f.total_sales < COALESCE(lag_total_sales, 0) THEN 'Decrease'
               ELSE 'NoChange'
           END AS sales_trend,
           f.rank_labels_concat,
           COUNT(*) OVER (PARTITION BY f.channel) AS channel_months
    FROM (
        SELECT *,
               LAG(total_sales) OVER (PARTITION BY channel ORDER BY sale_month) AS lag_total_sales
        FROM final_aggregates
    ) f
)
SELECT *
FROM comparative
WHERE sales_trend <> 'NoChange'
ORDER BY channel, sale_month DESC
