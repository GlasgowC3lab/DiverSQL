WITH sales_data AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    wp.wp_url AS url,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    ws.ws_net_paid,
    ws.ws_net_profit,
    i.i_product_name AS product_name,
    CASE WHEN regexp_like(i.i_product_name, '(?i).*toy.*') THEN 'TOY' ELSE 'OTHER' END AS product_flag,
    CASE WHEN i.i_product_name LIKE '%Pro%' THEN 1 ELSE 0 END AS has_pro
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE wp.wp_url LIKE 'http://%'
    AND i.i_product_name LIKE '%Toy%'
)
SELECT
  year,
  month_seq,
  category,
  domain,
  COUNT(*) AS order_cnt,
  SUM(ws_net_paid) AS total_paid,
  SUM(ws_net_profit) AS total_profit,
  SUM(CASE WHEN product_flag = 'TOY' THEN 1 ELSE 0 END) AS toy_orders,
  SUM(has_pro) AS pro_flag_count
FROM sales_data
GROUP BY GROUPING SETS (
  (year, month_seq, category, domain),
  (year, month_seq, category),
  (year, month_seq),
  (year)
)
ORDER BY total_paid DESC
LIMIT 100
