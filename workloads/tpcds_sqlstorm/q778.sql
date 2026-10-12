WITH
date_bounds AS (
    SELECT MIN(d_date) AS min_date, MAX(d_date) AS max_date FROM date_dim
),
date_series AS (
    SELECT d AS sales_date
    FROM date_bounds
    CROSS JOIN UNNEST(sequence(min_date, max_date, INTERVAL '1' DAY)) AS t(d)
),
unified_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'Catalog' AS channel,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS ext_discount_amt,
           cs.cs_ext_list_price AS ext_list_price,
           cs.cs_item_sk AS item_sk,
           cs.cs_catalog_page_sk AS location_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           'Store',
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           ss.ss_ext_list_price,
           ss.ss_item_sk,
           ss.ss_store_sk
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'Web',
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_ext_list_price,
           ws.ws_item_sk,
           ws.ws_web_page_sk
    FROM web_sales ws
),
sales_by_date AS (
    SELECT ds.sales_date,
           d.d_date_sk,
           us.channel,
           us.quantity,
           us.net_paid,
           us.net_profit,
           us.ext_discount_amt,
           us.ext_list_price,
           COALESCE(s.s_store_name, wp.wp_url, cp.cp_description, 'N/A') AS location_desc
    FROM date_series ds
    LEFT JOIN date_dim d ON d.d_date = ds.sales_date
    LEFT JOIN unified_sales us ON us.date_sk = d.d_date_sk
    LEFT JOIN store s ON us.channel = 'Store' AND us.location_sk = s.s_store_sk
    LEFT JOIN web_page wp ON us.channel = 'Web' AND us.location_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_page cp ON us.channel = 'Catalog' AND us.location_sk = cp.cp_catalog_page_sk
),
aggregated AS (
    SELECT
        sales_date,
        channel,
        COALESCE(SUM(quantity), 0) AS total_quantity,
        COALESCE(SUM(net_paid), 0) AS total_net_paid,
        COALESCE(SUM(net_profit), 0) AS total_net_profit,
        COALESCE(SUM(ext_discount_amt), 0) AS total_ext_discount_amt,
        COALESCE(SUM(ext_list_price), 0) AS total_ext_list_price,
        CASE WHEN SUM(ext_list_price) = 0 THEN NULL ELSE SUM(ext_discount_amt) / SUM(ext_list_price) END AS avg_discount_rate,
        MAX(location_desc) AS location_desc,
        date_format(sales_date, '%Y-%m') AS month_year_str
    FROM sales_by_date
    GROUP BY sales_date, channel
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY sales_date ORDER BY total_net_profit DESC) AS rank_daily_profit,
        SUM(total_net_profit) OVER (ORDER BY sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_profit,
        LAG(total_net_profit) OVER (ORDER BY sales_date) AS previous_day_net_profit,
        (SELECT a2.total_net_profit FROM aggregated a2 WHERE a2.channel = a.channel AND a2.sales_date = DATE_ADD('day', -1, a.sales_date)) AS previous_day_net_profit_corr,
        CASE WHEN total_quantity = 0 THEN 'No Sales' ELSE 'Has Sales' END AS sales_flag,
        CASE WHEN total_net_paid IS NULL THEN 1 ELSE 0 END AS net_paid_null_flag,
        CONCAT(channel, ' - ', COALESCE(NULLIF(month_year_str, ''), 'Unknown')) AS channel_month_desc,
        CAST(total_net_profit AS VARCHAR) || ' profit' AS profit_str
    FROM aggregated a
)
SELECT *
FROM ranked
WHERE net_paid_null_flag = 0
ORDER BY sales_date DESC, rank_daily_profit
