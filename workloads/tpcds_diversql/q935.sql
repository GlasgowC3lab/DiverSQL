WITH fo_join AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    d.d_year,
    d.d_day_name
  FROM call_center cc
  FULL OUTER JOIN catalog_sales cs
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE (cc.cc_name IS NOT NULL OR cs.cs_order_number IS NOT NULL)
    AND (cc.cc_name LIKE '%Center%' OR d.d_day_name LIKE '%day%')
),
wr_part AS (
  SELECT
    wr.wr_order_number,
    d.d_year,
    d.d_day_name,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE wr.wr_return_amt > 150
    AND REGEXP_LIKE(CAST(wr.wr_fee AS varchar), '^1')
)
SELECT
  fo.cc_call_center_sk,
  fo.cc_name,
  CONCAT(fo.cc_name, '_', CAST(fo.cc_call_center_sk AS varchar)) AS full_center,
  SUBSTRING(fo.cc_name, 1, 4) AS name_prefix,
  REGEXP_EXTRACT(fo.cc_name, 'Center (.*)', 1) AS name_suffix,
  fo.d_year,
  fo.d_day_name,
  fo.cs_quantity AS quantity,
  fo.cs_ext_sales_price AS amount,
  CASE WHEN fo.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
FROM fo_join fo
WHERE EXISTS (
  SELECT 1 FROM wr_part wr WHERE wr.wr_order_number = fo.cs_order_number
)

UNION DISTINCT

SELECT
  NULL AS cc_call_center_sk,
  NULL AS cc_name,
  NULL AS full_center,
  NULL AS name_prefix,
  NULL AS name_suffix,
  wr.d_year,
  wr.d_day_name,
  wr.wr_return_quantity AS quantity,
  wr.wr_return_amt AS amount,
  CASE WHEN wr.wr_net_loss > 0 THEN 'LOSS' ELSE 'NOLOSS' END AS profit_flag
FROM wr_part wr
WHERE EXISTS (
  SELECT 1 FROM fo_join fo WHERE fo.cs_order_number = wr.wr_order_number
)

ORDER BY cc_call_center_sk NULLS LAST, d_year DESC
LIMIT 100
