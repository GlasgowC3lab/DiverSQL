WITH sales_agg AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    cc.cc_name,
    cp.cp_type,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
    COUNT(*) AS num_sales
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2001
    AND cc.cc_class = 'A'
    AND cp.cp_type = 'PROMO'
  GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cc.cc_name, cp.cp_type
),

returns_agg AS (
  SELECT
    sr.sr_customer_sk AS customer_sk,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS num_returns
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND sr.sr_return_amt > 0
  GROUP BY sr.sr_customer_sk
),

web_agg AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_paid,
    COUNT(*) AS num_web_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ws.ws_ext_tax > 10
  GROUP BY ws.ws_bill_customer_sk
),

intersect_customers AS (
  SELECT customer_sk FROM sales_agg
  INTERSECT
  SELECT customer_sk FROM returns_agg
),

final AS (
  SELECT
    s.customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.d_year,
    s.cc_name,
    s.cp_type,
    s.total_net_paid,
    r.total_return_amt,
    w.total_web_paid,
    (s.total_net_paid - COALESCE(r.total_return_amt, 0) + COALESCE(w.total_web_paid, 0)) AS net_contribution,
    (s.num_sales + COALESCE(r.num_returns, 0) + COALESCE(w.num_web_sales, 0)) AS total_transactions
  FROM sales_agg s
  LEFT JOIN returns_agg r ON s.customer_sk = r.customer_sk
  LEFT JOIN web_agg w ON s.customer_sk = w.customer_sk
  WHERE s.customer_sk IN (SELECT customer_sk FROM intersect_customers)
    AND s.total_net_paid > 1000
    AND COALESCE(r.total_return_amt, 0) < 500
)
SELECT
  customer_sk,
  c_first_name,
  c_last_name,
  d_year,
  cc_name,
  cp_type,
  net_contribution,
  total_transactions
FROM final
ORDER BY net_contribution DESC
LIMIT 100
