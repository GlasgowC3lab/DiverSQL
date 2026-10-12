WITH
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_customer_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_quantity) AS total_qty
    FROM store_sales
    GROUP BY ss_item_sk, ss_customer_sk
  ),
  customers_no_returns AS (
    SELECT c_customer_sk
    FROM customer
    EXCEPT
    SELECT cr_refunded_customer_sk
    FROM catalog_returns
  ),
  joined AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      i.i_item_sk,
      i.i_product_name,
      i.i_category,
      i.i_rec_start_date,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      ss.total_net_paid,
      ss.total_qty,
      sm.sm_type,
      cc.cc_name,
      ws.ws_net_paid,
      wp.wp_type,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.total_net_paid DESC) AS category_rank,
      CASE WHEN cr.cr_return_quantity IS NULL THEN 'No Return' ELSE 'Returned' END AS return_flag
    FROM customers_no_returns cnr
    JOIN customer c ON cnr.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN ss_agg ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND ca.ca_state IN ('CA', 'MO')
      AND sm.sm_type = 'AIR'
  )
SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  ca_state,
  i_item_sk,
  i_product_name,
  i_category,
  i_rec_start_date,
  cr_return_quantity,
  cr_return_amount,
  total_net_paid,
  total_qty,
  sm_type,
  cc_name,
  ws_net_paid,
  wp_type,
  category_rank,
  return_flag
FROM joined
ORDER BY category_rank, total_net_paid DESC
LIMIT 100
