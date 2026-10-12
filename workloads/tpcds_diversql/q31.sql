/*
  Goal: Analyze combined catalog and web sales by customer birth month, billing state, return reason, web page type, and web site. The query joins all ten selected tables (including two aliases of customer_address), computes distinct order counts and total sales, uses a CUBE for grouping, includes multiple DISTINCT aggregates, and filters with an IN subquery and an EXISTS subquery.
*/
WITH filtered_birth_months AS (
    SELECT DISTINCT c2.c_birth_month
    FROM tpcds.customer c2
    WHERE c2.c_birth_year BETWEEN 1960 AND 1970
)
SELECT
    c.c_birth_month,
    ca_bill.ca_state,
    r.r_reason_desc,
    wp.wp_type,
    ws_site.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items
FROM tpcds.catalog_returns cr
JOIN tpcds.catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca_bill
  ON cr.cr_refunded_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cr.cr_returning_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN tpcds.household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN tpcds.web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE c.c_birth_month IN (SELECT c_birth_month FROM filtered_birth_months)
  AND wp.wp_type IN ('ad', 'dynamic')
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_promo_sk <> ws.ws_promo_sk
    )
GROUP BY CUBE (c.c_birth_month, ca_bill.ca_state, r.r_reason_desc, wp.wp_type, ws_site.web_name)
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
LIMIT 100
