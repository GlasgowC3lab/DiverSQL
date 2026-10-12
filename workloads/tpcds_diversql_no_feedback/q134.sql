WITH sales_agg AS (
  SELECT
    d.d_year,
    cp.cp_department,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    ARRAY[SUM(cs.cs_ext_sales_price), SUM(cs.cs_net_profit)] AS metrics_arr
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  GROUP BY GROUPING SETS (
    (d.d_year, cp.cp_department),
    (d.d_year)
  )
),
sales_unnest AS (
  SELECT
    s.d_year,
    s.cp_department,
    metric,
    CASE WHEN metric = s.total_sales THEN 'sales' ELSE 'profit' END AS metric_type,
    s.total_sales,
    s.total_profit
  FROM sales_agg s
  CROSS JOIN UNNEST(s.metrics_arr) AS t(metric)
),
returns_agg AS (
  SELECT
    d.d_year,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    ARRAY[SUM(cr.cr_return_amount), SUM(cr.cr_net_loss)] AS metrics_arr
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  GROUP BY GROUPING SETS (
    (d.d_year, r.r_reason_desc),
    (d.d_year)
  )
),
returns_unnest AS (
  SELECT
    r.d_year,
    r.r_reason_desc,
    metric,
    CASE WHEN metric = r.total_return_amount THEN 'return_amount' ELSE 'net_loss' END AS metric_type,
    r.total_return_amount,
    r.total_net_loss
  FROM returns_agg r
  CROSS JOIN UNNEST(r.metrics_arr) AS t(metric)
),
-- small dimension set of years (only 2001) and a limited set of income bands
year_set AS (
  SELECT DISTINCT d_year FROM date_dim WHERE d_year = 2001
),
cross_joined AS (
  SELECT y.d_year, ib.ib_income_band_sk
  FROM year_set y
  CROSS JOIN (SELECT ib_income_band_sk FROM income_band LIMIT 5) ib
)
SELECT
  combined.src,
  combined.year,
  combined.category,
  combined.metric_type,
  combined.metric_value,
  cj.ib_income_band_sk
FROM (
  SELECT
    'sales'   AS src,
    s.d_year  AS year,
    s.cp_department AS category,
    s.metric_type,
    s.metric AS metric_value
  FROM sales_unnest s
  UNION ALL
  SELECT
    'returns' AS src,
    r.d_year  AS year,
    r.r_reason_desc AS category,
    r.metric_type,
    r.metric AS metric_value
  FROM returns_unnest r
) combined
JOIN cross_joined cj ON combined.year = cj.d_year
ORDER BY combined.year DESC, combined.metric_value DESC
LIMIT 100
