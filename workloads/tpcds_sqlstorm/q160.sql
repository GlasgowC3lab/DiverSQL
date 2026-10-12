WITH
  combined_sales AS (
    SELECT
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_customer_sk AS customer_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      'store' AS channel,
      ss.ss_ticket_number AS order_number,
      ss.ss_sold_time_sk AS time_sk
    FROM store_sales ss
    UNION ALL
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_item_sk AS item_sk,
      cs.cs_bill_customer_sk AS customer_sk,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      cs.cs_net_profit AS net_profit,
      'catalog' AS channel,
      cs.cs_order_number AS order_number,
      cs.cs_sold_time_sk AS time_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      ws.ws_item_sk AS item_sk,
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      ws.ws_net_profit AS net_profit,
      'web' AS channel,
      ws.ws_order_number AS order_number,
      ws.ws_sold_time_sk AS time_sk
    FROM web_sales ws
  ),
  combined_returns AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_item_sk AS item_sk,
      sr.sr_customer_sk AS customer_sk,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_return_amt AS return_amount,
      'store' AS channel,
      sr.sr_ticket_number AS ticket_number,
      sr.sr_return_time_sk AS time_sk
    FROM store_returns sr
    UNION ALL
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_refunded_customer_sk AS customer_sk,
      cr.cr_return_quantity AS return_quantity,
      cr.cr_return_amount AS return_amount,
      'catalog' AS channel,
      cr.cr_order_number AS ticket_number,
      cr.cr_returned_time_sk AS time_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT
      wr.wr_returned_date_sk AS date_sk,
      wr.wr_item_sk AS item_sk,
      wr.wr_refunded_customer_sk AS customer_sk,
      wr.wr_return_quantity AS return_quantity,
      wr.wr_return_amt AS return_amount,
      'web' AS channel,
      wr.wr_order_number AS ticket_number,
      wr.wr_returned_time_sk AS time_sk
    FROM web_returns wr
  ),
  customer_info AS (
    SELECT
      c.c_customer_sk,
      CONCAT(COALESCE(c.c_first_name, 'UNKNOWN'), ' ', COALESCE(c.c_last_name, 'UNKNOWN')) AS full_name,
      c.c_birth_year,
      cd.cd_gender,
      cd.cd_marital_status,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  sales_returns AS (
    SELECT
      COALESCE(cs.date_sk, cr.date_sk) AS date_sk,
      COALESCE(cs.item_sk, cr.item_sk) AS item_sk,
      COALESCE(cs.customer_sk, cr.customer_sk) AS customer_sk,
      COALESCE(cs.channel, cr.channel) AS channel,
      cs.quantity,
      cs.net_paid,
      cs.net_profit,
      cr.return_quantity,
      cr.return_amount,
      cs.net_paid - COALESCE(cr.return_amount, 0) AS net_after_returns,
      cs.net_profit - COALESCE(cr.return_amount, 0) * 0.2 AS profit_after_returns,
      ROW_NUMBER() OVER (PARTITION BY COALESCE(cs.channel, cr.channel), COALESCE(cs.item_sk, cr.item_sk) ORDER BY COALESCE(cs.date_sk, cr.date_sk)) AS sales_seq,
      SUM(COALESCE(cs.net_paid, 0)) OVER (PARTITION BY COALESCE(cs.channel, cr.channel), COALESCE(cs.item_sk, cr.item_sk) ORDER BY COALESCE(cs.date_sk, cr.date_sk) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS sum_last_3_days,
      CASE WHEN cs.quantity = 0 THEN NULL ELSE cs.net_paid / cs.quantity END AS avg_price_per_unit,
      CASE WHEN COALESCE(cr.return_quantity, 0) > COALESCE(cs.quantity, 0) THEN 'RETURN_EXCEEDS_SALES' ELSE 'NORMAL' END AS return_flag,
      CONCAT('CUST_', CAST(COALESCE(cs.customer_sk, cr.customer_sk) AS VARCHAR), '_', COALESCE(cs.channel, cr.channel)) AS cust_channel_key
    FROM combined_sales cs
    FULL OUTER JOIN combined_returns cr
      ON cs.channel = cr.channel
      AND cs.item_sk = cr.item_sk
      AND cs.customer_sk = cr.customer_sk
      AND cs.date_sk = cr.date_sk
  ),
  high_value_customers AS (
    SELECT DISTINCT customer_sk
    FROM sales_returns
    WHERE net_after_returns > 1000
  ),
  store_catalog_customers AS (
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'store'
    INTERSECT
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'catalog'
  ),
  store_web_customers AS (
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'store'
    INTERSECT
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'web'
  ),
  catalog_web_customers AS (
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'catalog'
    INTERSECT
    SELECT customer_sk
    FROM sales_returns
    WHERE channel = 'web'
  ),
  customers_multi_channel AS (
    SELECT customer_sk FROM store_catalog_customers
    UNION ALL
    SELECT customer_sk FROM store_web_customers
    UNION ALL
    SELECT customer_sk FROM catalog_web_customers
  ),
  lagged_profit AS (
    SELECT
      sr.*,
      (SELECT MAX(sr2.net_profit)
       FROM sales_returns sr2
       WHERE sr2.item_sk = sr.item_sk
         AND sr2.channel = sr.channel
         AND sr2.date_sk < sr.date_sk) AS previous_max_profit
    FROM sales_returns sr
  )
SELECT
  d.d_date AS sale_date,
  i.i_item_id,
  i.i_product_name,
  lr.channel,
  ci.full_name AS customer_name,
  lr.net_after_returns,
  lr.profit_after_returns,
  lr.sales_seq,
  lr.sum_last_3_days,
  lr.avg_price_per_unit,
  lr.return_flag,
  lr.cust_channel_key,
  CASE
    WHEN lr.previous_max_profit IS NULL THEN 'NO_PREV'
    WHEN lr.net_after_returns > lr.previous_max_profit THEN 'NEW_PEAK'
    ELSE 'BELOW_PEAK'
  END AS profit_trend_flag,
  COALESCE(hb.ib_lower_bound, 0) AS income_lower,
  COALESCE(hb.ib_upper_bound, 0) AS income_upper,
  COALESCE(lr.return_quantity, 0) AS ret_qty,
  COALESCE(lr.return_amount, 0) AS ret_amt
FROM lagged_profit lr
LEFT JOIN date_dim d ON lr.date_sk = d.d_date_sk
LEFT JOIN item i ON lr.item_sk = i.i_item_sk
LEFT JOIN customer_info ci ON lr.customer_sk = ci.c_customer_sk
LEFT JOIN income_band hb ON ci.hd_income_band_sk = hb.ib_income_band_sk
WHERE
  ((lr.net_after_returns > 0 AND lr.return_flag = 'NORMAL')
   OR (lr.return_flag = 'RETURN_EXCEEDS_SALES' AND lr.net_after_returns IS NOT NULL))
  AND (lr.channel = 'web' OR lr.channel = 'catalog')
  AND (CASE WHEN lr.avg_price_per_unit IS NULL THEN 0 ELSE lr.avg_price_per_unit END) BETWEEN 10 AND 1000
  AND EXISTS (SELECT 1 FROM high_value_customers hvc WHERE hvc.customer_sk = lr.customer_sk)
  AND lr.customer_sk IN (SELECT customer_sk FROM customers_multi_channel)
ORDER BY
  d.d_date DESC,
  lr.net_after_returns DESC
LIMIT 100
