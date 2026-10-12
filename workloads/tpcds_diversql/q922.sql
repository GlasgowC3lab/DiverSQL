WITH
  -- Sample a fraction of web_sales and join to all related dimension tables
  ws_data AS (
    SELECT
      ws.ws_order_number        AS order_number,
      ws.ws_bill_customer_sk    AS customer_sk,
      ws.ws_warehouse_sk        AS warehouse_sk,
      ws.ws_web_site_sk         AS website_sk,
      ws.ws_ext_list_price      AS amount,
      c.c_current_addr_sk,
      c.c_current_hdemo_sk,
      c.c_customer_sk,
      ca.ca_state,
      ca.ca_city,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      w.w_city,
      ws_site.web_state,
      ws_site.web_name
    FROM web_sales ws
      TABLESAMPLE BERNOULLI (10)
      INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
      INNER JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
      INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      INNER JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_ext_list_price > 1000
  ),

  -- Store returns (filtered) joined to the same dimensions (minus warehouse & website)
  sr_data AS (
    SELECT
      sr.sr_ticket_number       AS order_number,
      sr.sr_customer_sk         AS customer_sk,
      CAST(NULL AS INTEGER)    AS warehouse_sk,
      CAST(NULL AS INTEGER)    AS website_sk,
      sr.sr_return_amt          AS amount,
      c.c_current_addr_sk,
      c.c_current_hdemo_sk,
      c.c_customer_sk,
      ca.ca_state,
      ca.ca_city,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      CAST(NULL AS VARCHAR)    AS w_city,
      CAST(NULL AS VARCHAR)    AS web_state,
      CAST(NULL AS VARCHAR)    AS web_name
    FROM store_returns sr
      INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
      INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
      INNER JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
      INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND sr.sr_return_amt > 1000
  ),

  -- Union the two sales streams (distinct by default)
  union_sales AS (
    SELECT * FROM ws_data
    UNION
    SELECT * FROM sr_data
  ),

  -- Intersect the set of customers that appear in catalog returns and store returns
  intersect_customers AS (
    SELECT cr.cr_returning_customer_sk AS customer_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk >= 2450000
    INTERSECT
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk >= 2450000
  ),

  -- Join the unioned sales to catalog_returns for extra attributes
  enriched_sales AS (
    SELECT
      us.order_number,
      us.customer_sk,
      us.warehouse_sk,
      us.website_sk,
      us.amount,
      us.ca_state,
      us.ca_city,
      us.w_city,
      us.web_state,
      us.web_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cr.cr_reason_sk,
      cr.cr_return_ship_cost
    FROM union_sales us
      INNER JOIN catalog_returns cr
        ON us.customer_sk = cr.cr_returning_customer_sk
       AND us.order_number = cr.cr_order_number
      INNER JOIN income_band ib
        ON us.hd_income_band_sk = ib.ib_income_band_sk
    WHERE us.amount > 2000
      AND us.ca_state = 'TX'
      AND ib.ib_upper_bound <= 80000
      AND (us.w_city = 'Seattle' OR us.w_city IS NULL)
      AND (us.web_state = 'WA' OR us.web_state IS NULL)
  )
SELECT
  es.customer_sk,
  COUNT(DISTINCT es.order_number) AS distinct_orders,
  SUM(es.amount)                     AS total_amount,
  AVG(es.amount)                     AS avg_amount,
  MIN(es.amount)                     AS min_amount,
  MAX(es.amount)                     AS max_amount
FROM enriched_sales es
WHERE es.customer_sk IN (SELECT customer_sk FROM intersect_customers)
GROUP BY es.customer_sk
HAVING SUM(es.amount) > 5000
ORDER BY total_amount DESC
LIMIT 100
