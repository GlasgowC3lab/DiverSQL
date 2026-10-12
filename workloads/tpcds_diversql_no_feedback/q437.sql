WITH sr_join AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    sr.sr_customer_sk,
    ws.ws_bill_customer_sk,
    ws.ws_ext_ship_cost,
    t.t_am_pm
  FROM date_dim d
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND regexp_like(r.r_reason_desc, 'purchase')
    AND t.t_am_pm LIKE 'A%'
)

SELECT
  d_year,
  d_month_seq,
  COUNT(DISTINCT sr_customer_sk)               AS distinct_return_customers,
  COUNT(DISTINCT ws_bill_customer_sk)          AS distinct_bill_customers,
  SUM(ws_ext_ship_cost)                         AS total_ship_cost,
  MAX(model_word)                               AS example_model_word,
  MAX(reason_prefix)                            AS example_reason_prefix,
  CONCAT('Year-', CAST(d_year AS VARCHAR))      AS year_label
FROM (
  SELECT
    d_year,
    d_month_seq,
    sr_customer_sk,
    ws_bill_customer_sk,
    ws_ext_ship_cost,
    SUBSTRING(r_reason_desc FROM 1 FOR 10) AS reason_prefix,
    lt.model_word
  FROM sr_join
  CROSS JOIN LATERAL (
    SELECT regexp_extract(r_reason_desc, '(\\w+)\\s+model', 1) AS model_word
  ) AS lt
) q
GROUP BY d_year, d_month_seq
ORDER BY total_ship_cost DESC
LIMIT 100
