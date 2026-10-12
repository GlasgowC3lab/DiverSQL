WITH sr_agg AS (
  SELECT
    s.s_store_id,
    r.r_reason_desc,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS cnt_returns,
    COALESCE(cat.cat_return_amount, 0) AS cat_return_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  CROSS JOIN LATERAL (
    SELECT SUM(cr.cr_return_amount) AS cat_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = sr.sr_returned_date_sk
      AND cr.cr_reason_sk = sr.sr_reason_sk
  ) AS cat
  WHERE s.s_geography_class = 'Unknown'
    AND d.d_year BETWEEN 2000 AND 2002
    AND r.r_reason_desc LIKE '%missing%'
  GROUP BY s.s_store_id, r.r_reason_desc, d.d_year, cat.cat_return_amount
),

ws_agg AS (
  SELECT
    wp.wp_url,
    c.c_customer_id,
    d.d_year,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS cnt_sales
  FROM web_sales ws
  RIGHT OUTER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE wp.wp_type = 'I'
    AND d.d_year = 2001
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY wp.wp_url, c.c_customer_id, d.d_year
),

union_set AS (
  SELECT s_store_id AS id, r_reason_desc AS description, d_year, total_net_loss AS metric, cnt_returns AS cnt
  FROM sr_agg
  UNION DISTINCT
  SELECT wp_url AS id, c_customer_id AS description, d_year, total_profit AS metric, cnt_sales AS cnt
  FROM ws_agg
),

filtered AS (
  SELECT *
  FROM union_set
  WHERE metric > 0
    AND cnt >= 5
    AND d_year >= 2000
),

low_activity AS (
  SELECT id, description, d_year, metric, cnt
  FROM union_set
  WHERE cnt < 10
)

SELECT f.id, f.description, f.d_year, f.metric, f.cnt
FROM filtered f
EXCEPT
SELECT la.id, la.description, la.d_year, la.metric, la.cnt
FROM low_activity la
ORDER BY metric DESC, d_year
LIMIT 100
