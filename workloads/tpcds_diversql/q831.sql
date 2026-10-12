/*
Goal: Identify customers who both received a catalog refund and made a web purchase within a recent period, and compare their refund amounts (catalog) to their net paid sales (web). The query uses a set operation (UNION) to combine catalog‑return rows with web‑sales rows, a FULL OUTER JOIN inside each side, an INTERSECT to find customers appearing in both domains, and a correlated scalar subquery that counts each customer’s web returns.
*/
WITH
  /* Customers with catalog refunds in the target window */
  catalog_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
  ),

  /* Customers with web sales in the same window */
  web_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  ),

  /* Customers that appear in BOTH sets */
  common_customers AS (
    SELECT cust_sk FROM catalog_customers
    INTERSECT
    SELECT cust_sk FROM web_customers
  ),

  /* Catalog‑return side – full outer join to bring call‑center, ship‑mode and warehouse info */
  catalog_side AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_refunded_customer_sk,
      cc.cc_name,
      sm.sm_type,
      wh.w_warehouse_name
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse wh
      ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
  ),

  /* Web‑sales side – full outer join to promotion, ship‑mode and warehouse */
  web_side AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      ws.ws_quantity,
      ws.ws_bill_customer_sk,
      p.p_promo_name,
      sm.sm_type,
      wh.w_warehouse_name
    FROM web_sales ws
    FULL OUTER JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse wh
      ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  )

SELECT
  cs.cr_order_number            AS order_id,
  cs.cr_return_amount           AS amount,
  cs.cc_name                    AS location,
  cs.sm_type                    AS ship_mode,
  cs.w_warehouse_name           AS warehouse,
  cs.cr_return_quantity         AS quantity,
  (SELECT COUNT(*)
     FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = cs.cr_refunded_customer_sk
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910) AS related_web_returns
FROM catalog_side cs
WHERE cs.cr_refunded_customer_sk IN (SELECT cust_sk FROM common_customers)

UNION

SELECT
  ws.ws_order_number            AS order_id,
  ws.ws_net_paid                AS amount,
  ws.p_promo_name               AS location,
  ws.sm_type                    AS ship_mode,
  ws.w_warehouse_name           AS warehouse,
  ws.ws_quantity                AS quantity,
  (SELECT COUNT(*)
     FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = ws.ws_bill_customer_sk
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910) AS related_web_returns
FROM web_side ws
WHERE ws.ws_bill_customer_sk IN (SELECT cust_sk FROM common_customers)

ORDER BY amount DESC, order_id
