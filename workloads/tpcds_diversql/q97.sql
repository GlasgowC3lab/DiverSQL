WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
  SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    cs.cs_net_paid,
    cr.cr_return_amount,
    ws.ws_net_paid
  FROM sampled_sales cs
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  FULL OUTER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                        AND ws.ws_sold_date_sk = d.d_date_sk
                        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                        AND ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
    AND i.i_brand = 'Brand#23'
    AND cp.cp_type = 'monthly'
),
aggregated AS (
  SELECT
    d_year,
    i_category,
    p_promo_name,
    cc_name,
    SUM(cs_net_paid) AS catalog_sales_total,
    SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(ws_net_paid, 0)) AS web_sales_total
  FROM joined_data
  GROUP BY CUBE (d_year, i_category, p_promo_name, cc_name)
)
SELECT
  d_year,
  i_category,
  p_promo_name,
  cc_name,
  catalog_sales_total,
  total_returns,
  web_sales_total,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY catalog_sales_total DESC) AS sales_rank
FROM aggregated
ORDER BY d_year, sales_rank
LIMIT 100
