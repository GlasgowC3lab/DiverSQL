WITH store_closure AS (
  SELECT
    s.s_store_sk,
    s.s_state,
    d_closure.d_date AS closure_date,
    d_closure.d_year AS closure_year
  FROM store s
  JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
),
web_site_window AS (
  SELECT
    w.web_site_sk,
    w.web_state,
    d_open.d_date AS open_date,
    d_close.d_date AS close_date,
    d_open.d_year AS open_year
  FROM web_site w
  JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
  JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
),
customer_details AS (
  SELECT
    c.c_customer_sk,
    c.c_birth_year,
    ca.ca_state,
    d_shipto.d_date AS shipto_date,
    d_sales.d_date AS sales_date,
    d_review.d_date AS review_date
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
  JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
  JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
),
aggregated AS (
  SELECT
    sc.s_store_sk,
    sc.s_state,
    wsw.web_site_sk,
    wsw.web_state,
    sc.closure_year,
    wsw.open_year,
    COUNT(DISTINCT cd.c_customer_sk) AS num_customers,
    AVG(date_diff('day', cd.sales_date, cd.review_date)) AS avg_days_sales_to_review,
    AVG(date_diff('day', cd.shipto_date, wsw.open_date)) AS avg_days_shipto_to_ws_open,
    AVG(cd.c_birth_year) AS avg_birth_year
  FROM store_closure sc
  JOIN web_site_window wsw
    ON wsw.open_date <= sc.closure_date
  JOIN customer_details cd
    ON cd.shipto_date BETWEEN wsw.open_date AND wsw.close_date
    AND cd.sales_date <= sc.closure_date
  WHERE cd.ca_state = sc.s_state
  GROUP BY
    sc.s_store_sk,
    sc.s_state,
    wsw.web_site_sk,
    wsw.web_state,
    sc.closure_year,
    wsw.open_year
)
SELECT
  a.s_store_sk,
  a.s_state,
  a.web_site_sk,
  a.web_state,
  a.closure_year,
  a.open_year,
  a.num_customers,
  a.avg_days_sales_to_review,
  a.avg_days_shipto_to_ws_open,
  a.avg_birth_year,
  RANK() OVER (PARTITION BY a.s_state ORDER BY a.num_customers DESC) AS state_customer_rank
FROM aggregated a
ORDER BY a.num_customers DESC
LIMIT 100
