WITH
  sales_agg AS (
    SELECT
      ca.ca_state AS state,
      p.p_channel_email AS channel,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM store_sales ss
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451200
      AND p.p_discount_active = 'Y'
      AND ca.ca_state IS NOT NULL
    GROUP BY ca.ca_state, p.p_channel_email
  ),
  catalog_ret_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(cr.cr_return_amt_inc_tax) AS total_cat_return,
      SUM(cr.cr_return_quantity) AS total_cat_return_qty
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451200
      AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
      )
    GROUP BY ca.ca_state
  ),
  web_ret_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(wr.wr_return_amt_inc_tax) AS total_web_return,
      SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451200
      AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = wr.wr_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
      )
    GROUP BY ca.ca_state
  )
SELECT
  s.state,
  s.channel,
  s.total_sales,
  COALESCE(c.total_cat_return, 0) AS total_catalog_return,
  COALESCE(w.total_web_return, 0) AS total_web_return,
  s.total_sales - COALESCE(c.total_cat_return, 0) - COALESCE(w.total_web_return, 0) AS net_revenue,
  COALESCE(c.total_cat_return_qty, 0) + COALESCE(w.total_web_return_qty, 0) AS total_return_qty,
  CASE
    WHEN (COALESCE(c.total_cat_return_qty, 0) + COALESCE(w.total_web_return_qty, 0)) > 0
    THEN (COALESCE(c.total_cat_return, 0) + COALESCE(w.total_web_return, 0)) /
         (COALESCE(c.total_cat_return_qty, 0) + COALESCE(w.total_web_return_qty, 0))
    ELSE NULL
  END AS avg_return_amount,
  RANK() OVER (
    PARTITION BY s.channel
    ORDER BY (s.total_sales - COALESCE(c.total_cat_return, 0) - COALESCE(w.total_web_return, 0)) DESC
  ) AS state_rank
FROM sales_agg s
LEFT JOIN catalog_ret_agg c
  ON s.state = c.state
LEFT JOIN web_ret_agg w
  ON s.state = w.state
ORDER BY net_revenue DESC
