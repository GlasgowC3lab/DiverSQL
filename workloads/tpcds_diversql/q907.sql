WITH
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
  ),
  sales_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  )
SELECT
  s.s_state,
  p.p_purpose,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_ext_sales_price) AS total_sales_amount,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(inv_agg.total_on_hand) AS total_inventory_on_hand,
  AVG(p.p_cost) AS avg_promo_cost,
  MAX(ws.ws_net_paid) AS max_web_net_paid
FROM catalog_sales cs
FULL OUTER JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
 AND cs.cs_item_sk = cr.cr_item_sk
JOIN inv_agg
  ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN store_returns sr
  ON hd.hd_demo_sk = sr.sr_hdemo_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
 AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
WHERE p.p_purpose = 'Unknown'
  AND p.p_channel_radio = 'N'
  AND we.web_mkt_id = 5
  AND s.s_state = 'CA'
  AND cs.cs_order_number IN (SELECT cs_order_number FROM sales_without_returns)
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_channel_details LIKE '%available%'
      )
GROUP BY
  s.s_state,
  p.p_purpose,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
ORDER BY total_sales_amount DESC
LIMIT 100
