WITH
  joined_data AS (
    SELECT
      cc.cc_name,
      cc.cc_state,
      cp.cp_department,
      cp.cp_catalog_page_number,
      i.i_brand,
      i.i_category,
      w.w_warehouse_name,
      cs.cs_order_number,
      cs.cs_net_paid,
      ws.ws_net_paid,
      cr.cr_return_quantity,
      wr.wr_return_quantity AS wr_return_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                       AND ws.ws_warehouse_sk = w.w_warehouse_sk
                       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_catalog_page_number = 15
      AND i.i_category = 'Electronics'
      AND wr.wr_return_quantity > 2
  ),
  agg_a AS (
    SELECT
      cc_name,
      cc_state,
      cp_department,
      i_brand,
      w_warehouse_name,
      SUM(cs_net_paid) AS total_cs_net_paid,
      SUM(ws_net_paid) AS total_ws_net_paid,
      COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    GROUP BY GROUPING SETS (
      (cc_name, cc_state, cp_department),
      (i_brand, w_warehouse_name),
      ()
    )
  ),
  agg_b AS (
    SELECT
      cc_name,
      cc_state,
      cp_department,
      i_brand,
      w_warehouse_name,
      SUM(cs_net_paid) AS total_cs_net_paid,
      SUM(ws_net_paid) AS total_ws_net_paid,
      COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    WHERE i_brand = 'BrandX'
    GROUP BY GROUPING SETS (
      (cc_name, cc_state, cp_department),
      (i_brand, w_warehouse_name),
      ()
    )
  )
SELECT *
FROM agg_a
EXCEPT
SELECT *
FROM agg_b
ORDER BY total_cs_net_paid DESC
LIMIT 100
