WITH cs AS (
  SELECT
    month(d.d_date) AS month,
    i.i_category,
    i.i_brand,
    SUM(cs.cs_net_paid_inc_tax) AS cs_net_paid,
    SUM(cs.cs_net_profit) AS cs_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS cs_order_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cp.cp_type = 'monthly'
    AND i.i_category = 'Sports'
    AND d.d_year = 2002
  GROUP BY month(d.d_date), i.i_category, i.i_brand
),
cr AS (
  SELECT
    month(d.d_date) AS month,
    i.i_category,
    i.i_brand,
    SUM(cr.cr_return_amount) AS return_amount,
    SUM(cr.cr_net_loss) AS return_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE i.i_category = 'Sports'
    AND d.d_year = 2002
  GROUP BY month(d.d_date), i.i_category, i.i_brand
),
ws AS (
  SELECT
    month(d.d_date) AS month,
    i.i_category,
    i.i_brand,
    SUM(ws.ws_net_paid_inc_tax) AS ws_net_paid,
    SUM(ws.ws_net_profit) AS ws_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_category = 'Sports'
    AND d.d_year = 2002
  GROUP BY month(d.d_date), i.i_category, i.i_brand
)
SELECT
  cs.month,
  cs.i_category,
  cs.i_brand,
  cs.cs_net_paid,
  cs.cs_net_profit,
  COALESCE(cr.return_amount, 0) AS total_return_amount,
  COALESCE(cr.return_loss, 0) AS total_return_loss,
  COALESCE(ws.ws_net_paid, 0) AS web_sales_net_paid,
  COALESCE(ws.ws_net_profit, 0) AS web_sales_net_profit,
  CASE WHEN cs.cs_net_paid = 0 THEN 0
       ELSE COALESCE(cr.return_amount, 0) / cs.cs_net_paid END AS return_to_sales_ratio
FROM cs
LEFT JOIN cr ON cs.month = cr.month
  AND cs.i_category = cr.i_category
  AND cs.i_brand = cr.i_brand
LEFT JOIN ws ON cs.month = ws.month
  AND cs.i_category = ws.i_category
  AND cs.i_brand = ws.i_brand
ORDER BY cs.month, cs.i_category, cs.i_brand
