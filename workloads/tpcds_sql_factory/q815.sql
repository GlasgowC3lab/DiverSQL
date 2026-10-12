WITH catalog_agg AS (
  SELECT
    cp.cp_department,
    p.p_channel_tv,
    COUNT(*) AS sales_count,
    SUM(cs.cs_ext_discount_amt) AS total_discount
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_sold_date_sk >= 2450000
  GROUP BY cp.cp_department, p.p_channel_tv
),
web_agg AS (
  SELECT
    'Web' AS cp_department,
    p.p_channel_tv,
    COUNT(*) AS sales_count,
    SUM(ws.ws_ext_discount_amt) AS total_discount
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_sold_date_sk >= 2450000
  GROUP BY p.p_channel_tv
)
SELECT
  department,
  channel_tv,
  sales_count,
  total_discount,
  CASE WHEN total_discount > 5000 THEN 'Heavy' ELSE 'Light' END AS discount_level,
  ROW_NUMBER() OVER (PARTITION BY department ORDER BY sales_count DESC) AS dept_rank
FROM (
  SELECT cp_department AS department, p_channel_tv AS channel_tv, sales_count, total_discount FROM catalog_agg
  UNION ALL
  SELECT cp_department AS department, p_channel_tv AS channel_tv, sales_count, total_discount FROM web_agg
) t
ORDER BY department, dept_rank
