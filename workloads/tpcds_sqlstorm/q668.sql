SELECT
    d.d_year,
    d.d_month_seq,
    f.channel,
    COALESCE(s.s_state, cc.cc_state, w.w_state) AS region_state,
    i.i_category,
    SUM(f.ext_sales_price) AS total_sales,
    SUM(f.net_profit) AS total_profit,
    COUNT(*) AS txn_cnt
FROM (
    SELECT ss_sold_date_sk AS date_sk,
           'store' AS channel,
           ss_store_sk AS location_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_ext_sales_price AS ext_sales_price,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           cs_call_center_sk AS location_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_ext_sales_price AS ext_sales_price,
           cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           'web' AS channel,
           ws_warehouse_sk AS location_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_ext_sales_price AS ext_sales_price,
           ws_net_profit AS net_profit
    FROM web_sales
) AS f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
LEFT JOIN store s ON f.channel = 'store' AND f.location_sk = s.s_store_sk
LEFT JOIN call_center cc ON f.channel = 'catalog' AND f.location_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w ON f.channel = 'web' AND f.location_sk = w.w_warehouse_sk
GROUP BY d.d_year, d.d_month_seq, f.channel, COALESCE(s.s_state, cc.cc_state, w.w_state), i.i_category
ORDER BY d.d_year, d.d_month_seq, f.channel, region_state, i.i_category
