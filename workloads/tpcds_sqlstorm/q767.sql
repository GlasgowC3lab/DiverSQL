SELECT
    channel,
    i.i_category,
    d.d_year,
    region,
    SUM(net_profit) AS total_net_profit,
    SUM(ext_sales_price) AS total_sales
FROM (
    SELECT 'store' AS channel,
           ss.ss_item_sk AS item_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_sales_price AS ext_sales_price,
           s.s_state AS region
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_sales_price AS ext_sales_price,
           cc.cc_state AS region
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_item_sk AS item_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_sales_price AS ext_sales_price,
           wp.wp_type AS region
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
) f
JOIN item i ON f.item_sk = i.i_item_sk
JOIN date_dim d ON f.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY channel, i.i_category, d.d_year, region
ORDER BY channel, d.d_year, total_net_profit DESC
LIMIT 100
