WITH
  cat_sales AS (
    SELECT
      cs.cs_bill_customer_sk      AS customer_sk,
      cs.cs_warehouse_sk          AS warehouse_sk,
      cs.cs_ship_mode_sk          AS ship_mode_sk,
      SUM(cs.cs_net_paid_inc_tax) AS cat_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_quantity > 0
      AND cs.cs_ext_discount_amt < 500
      AND cs.cs_coupon_amt < 100
    GROUP BY cs.cs_bill_customer_sk, cs.cs_warehouse_sk, cs.cs_ship_mode_sk
  ),
  cat_returns AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      cr.cr_warehouse_sk         AS warehouse_sk,
      cr.cr_ship_mode_sk         AS ship_mode_sk,
      SUM(cr.cr_return_amt_inc_tax) AS cat_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee < 30
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_warehouse_sk, cr.cr_ship_mode_sk
  ),
  web_sales AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_warehouse_sk     AS warehouse_sk,
      ws.ws_ship_mode_sk     AS ship_mode_sk,
      ws.ws_web_page_sk      AS web_page_sk,
      ws.ws_web_site_sk      AS web_site_sk,
      SUM(ws.ws_net_paid_inc_tax) AS web_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws.ws_quantity > 0
      AND ws.ws_ext_discount_amt < 300
      AND ws.ws_coupon_amt < 80
    GROUP BY ws.ws_bill_customer_sk, ws.ws_warehouse_sk, ws.ws_ship_mode_sk,
             ws.ws_web_page_sk, ws.ws_web_site_sk
  ),
  web_returns AS (
    SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      SUM(wr.wr_return_amt_inc_tax) AS web_return_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND wr.wr_return_quantity > 0
      AND wr.wr_fee < 20
    GROUP BY wr.wr_refunded_customer_sk
  ),
  store_sales AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      SUM(ss.ss_net_paid_inc_tax) AS store_net_paid
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss.ss_quantity > 0
      AND ss.ss_ext_discount_amt < 150
    GROUP BY ss.ss_customer_sk
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  w.w_warehouse_name,
  sm.sm_type                 AS ship_mode_type,
  wp.wp_type                 AS web_page_type,
  ws_site.web_name           AS web_site_name,
  total_contribution,
  sales_rank
FROM (
  SELECT
    COALESCE(cs.customer_sk, cr.customer_sk, ws.customer_sk, wr.customer_sk, st.customer_sk) AS customer_sk,
    COALESCE(cs.warehouse_sk, cr.warehouse_sk, ws.warehouse_sk)                AS warehouse_sk,
    COALESCE(cs.ship_mode_sk, cr.ship_mode_sk, ws.ship_mode_sk)                AS ship_mode_sk,
    ws.web_page_sk                                                          AS web_page_sk,
    ws.web_site_sk                                                          AS web_site_sk,
    COALESCE(cs.cat_net_paid, 0) - COALESCE(cr.cat_return_amount, 0) +
    COALESCE(ws.web_net_paid, 0) - COALESCE(wr.web_return_amount, 0) +
    COALESCE(st.store_net_paid, 0)                                            AS total_contribution,
    RANK() OVER (ORDER BY
      COALESCE(cs.cat_net_paid, 0) - COALESCE(cr.cat_return_amount, 0) +
      COALESCE(ws.web_net_paid, 0) - COALESCE(wr.web_return_amount, 0) +
      COALESCE(st.store_net_paid, 0) DESC)                                   AS sales_rank
  FROM (SELECT DISTINCT * FROM cat_sales) cs
  FULL JOIN (SELECT DISTINCT * FROM cat_returns) cr ON cr.customer_sk = cs.customer_sk
  FULL JOIN (SELECT DISTINCT * FROM web_sales) ws ON ws.customer_sk = COALESCE(cs.customer_sk, cr.customer_sk)
  FULL JOIN (SELECT DISTINCT * FROM web_returns) wr ON wr.customer_sk = COALESCE(cs.customer_sk, cr.customer_sk, ws.customer_sk)
  FULL JOIN (SELECT DISTINCT * FROM store_sales) st ON st.customer_sk = COALESCE(cs.customer_sk, cr.customer_sk, ws.customer_sk, wr.customer_sk)
) agg
JOIN customer c ON c.c_customer_sk = agg.customer_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = agg.warehouse_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = agg.ship_mode_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = agg.web_page_sk
LEFT JOIN web_site ws_site ON ws_site.web_site_sk = agg.web_site_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND w.w_city = 'Ash'
  AND sm.sm_carrier = 'UPS'
  AND wp.wp_type = 'home'
  AND ws_site.web_market_manager = 'John Doe'
ORDER BY total_contribution DESC
LIMIT 100
