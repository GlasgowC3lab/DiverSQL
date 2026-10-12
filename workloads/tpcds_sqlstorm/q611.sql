WITH unified_sales AS (
  SELECT
    ss_sold_date_sk AS sold_date_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS location_sk,
    'store' AS sales_type,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_item_sk,
    cs_call_center_sk,
    'catalog',
    cs_net_paid,
    cs_net_profit
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_item_sk,
    ws_web_site_sk,
    'web',
    ws_net_paid,
    ws_net_profit
  FROM web_sales
)
SELECT
  d.d_year,
  d.d_month_seq,
  i.i_category,
  sales.sales_type,
  sum(sales.net_paid) AS total_net_paid,
  sum(sales.net_profit) AS total_net_profit,
  sum(sales.net_paid) / nullif(sum(sales.net_profit), 0) AS profit_ratio
FROM unified_sales sales
JOIN date_dim d ON sales.sold_date_sk = d.d_date_sk
JOIN item i ON sales.item_sk = i.i_item_sk
LEFT JOIN store s ON sales.sales_type = 'store' AND sales.location_sk = s.s_store_sk
LEFT JOIN call_center cc ON sales.sales_type = 'catalog' AND sales.location_sk = cc.cc_call_center_sk
LEFT JOIN web_site w ON sales.sales_type = 'web' AND sales.location_sk = w.web_site_sk
GROUP BY d.d_year, d.d_month_seq, i.i_category, sales.sales_type
ORDER BY d.d_year, d.d_month_seq, i.i_category, sales.sales_type
