WITH unified_sales AS (
  SELECT
    ss_sold_date_sk AS date_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS store_sk,
    NULL AS warehouse_sk,
    NULL AS call_center_sk,
    NULL AS web_page_sk,
    ss_promo_sk AS promo_sk,
    ss_quantity AS quantity,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_item_sk,
    NULL,
    cs_warehouse_sk,
    cs_call_center_sk,
    NULL,
    cs_promo_sk,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_item_sk,
    NULL,
    ws_warehouse_sk,
    NULL,
    ws_web_page_sk,
    ws_promo_sk,
    ws_quantity,
    ws_net_paid,
    ws_net_profit,
    'web'
  FROM web_sales
)
SELECT
  d.d_year,
  d.d_moy AS month_of_year,
  i.i_category,
  COUNT(DISTINCT us.item_sk) AS distinct_items_sold,
  SUM(us.quantity) AS total_quantity_sold,
  SUM(us.net_paid) AS total_net_paid,
  SUM(us.net_profit) AS total_net_profit,
  SUM(CASE WHEN p.p_discount_active = 'Y' THEN us.net_paid * 0.1 ELSE 0 END) AS estimated_discount_amount,
  COUNT(DISTINCT s.s_store_id) AS distinct_stores,
  COUNT(DISTINCT w.w_warehouse_id) AS distinct_warehouses,
  COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
  COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
LEFT JOIN store s ON us.store_sk = s.s_store_sk
LEFT JOIN warehouse w ON us.warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2022-12-31'
GROUP BY d.d_year, d.d_moy, i.i_category
ORDER BY d.d_year, d.d_moy, i.i_category
