WITH aggregated_sales AS (
  SELECT
    d.d_year,
    i.i_category,
    'store' AS sales_channel,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category

  UNION ALL

  SELECT
    d.d_year,
    i.i_category,
    'catalog' AS sales_channel,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category

  UNION ALL

  SELECT
    d.d_year,
    i.i_category,
    'web' AS sales_channel,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category
)
SELECT
  d_year,
  i_category,
  sales_channel,
  total_sales,
  total_discount,
  total_profit,
  total_sales - total_discount AS net_sales,
  total_sales / NULLIF(total_profit, 0) AS sales_to_profit_ratio,
  ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS sales_rank
FROM aggregated_sales
ORDER BY d_year, sales_channel, total_sales DESC
