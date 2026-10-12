WITH unified_sales AS (
  SELECT d.d_year AS sale_year,
         i.i_category AS category,
         i.i_brand AS brand,
         cs.cs_ext_sales_price AS sales,
         cs.cs_net_profit AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         ss.ss_ext_sales_price,
         ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         ws.ws_ext_sales_price,
         ws.ws_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
), aggregated_sales AS (
  SELECT sale_year,
         category,
         brand,
         sum(sales) AS total_sales,
         sum(profit) AS total_profit
  FROM unified_sales
  GROUP BY sale_year, category, brand
), unified_returns AS (
  SELECT d.d_year AS sale_year,
         i.i_category AS category,
         i.i_brand AS brand,
         sum(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         sum(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         sum(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_brand
), aggregated_returns AS (
  SELECT sale_year,
         category,
         brand,
         sum(total_return_loss) AS total_return_loss
  FROM unified_returns
  GROUP BY sale_year, category, brand
)
SELECT s.sale_year,
       s.category,
       s.brand,
       s.total_sales,
       s.total_profit,
       coalesce(r.total_return_loss, 0) AS total_return_loss
FROM aggregated_sales s
LEFT JOIN aggregated_returns r
  ON s.sale_year = r.sale_year
 AND s.category = r.category
 AND s.brand = r.brand
ORDER BY s.sale_year, s.category, s.brand
