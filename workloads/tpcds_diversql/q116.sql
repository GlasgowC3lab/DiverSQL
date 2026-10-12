WITH inv_agg AS (
  SELECT inv_warehouse_sk,
         SUM(inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory
  GROUP BY inv_warehouse_sk
)
SELECT
  t.t_hour,
  t.t_shift,
  w.w_warehouse_name,
  inv_agg.total_qty_on_hand,
  COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  AVG(p.p_cost) AS avg_promo_cost,
  MIN(cs.cs_sales_price) AS min_catalog_sales_price,
  MAX(ws.ws_sales_price) AS max_web_sales_price
FROM time_dim t
JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
               AND r.r_reason_sk = cr.cr_reason_sk
               AND r.r_reason_sk = wr.wr_reason_sk
JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
               AND c.c_customer_sk = cr.cr_refunded_customer_sk
               AND c.c_customer_sk = cr.cr_returning_customer_sk
               AND c.c_customer_sk = cs.cs_bill_customer_sk
               AND c.c_customer_sk = ws.ws_bill_customer_sk
               AND c.c_customer_sk = wr.wr_refunded_customer_sk
               AND c.c_customer_sk = wr.wr_returning_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
               AND ca.ca_address_sk = cr.cr_refunded_addr_sk
               AND ca.ca_address_sk = cr.cr_returning_addr_sk
               AND ca.ca_address_sk = cs.cs_bill_addr_sk
               AND ca.ca_address_sk = ws.ws_bill_addr_sk
               AND ca.ca_address_sk = wr.wr_refunded_addr_sk
               AND ca.ca_address_sk = wr.wr_returning_addr_sk
JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
               AND w.w_warehouse_sk = ws.ws_warehouse_sk
               AND w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
               AND p.p_promo_sk = ws.ws_promo_sk
JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
WHERE
  t.t_hour = 12
  AND t.t_shift = 'first'
  AND c.c_birth_year = 1975
  AND w.w_state = 'CA'
  AND cs.cs_quantity > 2
  AND ws.ws_quantity <= 5
  AND p.p_cost > 1000
  AND r.r_reason_desc = 'Defective'
  AND inv_agg.total_qty_on_hand > 5000
  AND cs.cs_ext_sales_price > (
        SELECT AVG(cs_sub.cs_ext_sales_price)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_sold_date_sk = 2451110
      )
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
      )
GROUP BY
  t.t_hour,
  t.t_shift,
  w.w_warehouse_name,
  inv_agg.total_qty_on_hand
ORDER BY total_catalog_sales DESC
LIMIT 100
