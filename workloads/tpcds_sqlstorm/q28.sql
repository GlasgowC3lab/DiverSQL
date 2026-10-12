WITH sales AS (
  SELECT cs_sold_date_sk AS date_sk,
         cs_item_sk AS item_sk,
         cs_net_profit AS net_profit,
         cs_ext_sales_price AS sales_price,
         cs_ext_discount_amt AS discount_amt,
         cs_quantity AS quantity
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_item_sk,
         ss_net_profit,
         ss_ext_sales_price,
         ss_ext_discount_amt,
         ss_quantity
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_net_profit,
         ws_ext_sales_price,
         ws_ext_discount_amt,
         ws_quantity
  FROM web_sales
), returns AS (
  SELECT cr_returned_date_sk AS date_sk,
         cr_item_sk AS item_sk,
         cr_net_loss AS net_loss,
         cr_return_quantity AS quantity
  FROM catalog_returns
  UNION ALL
  SELECT sr_returned_date_sk,
         sr_item_sk,
         sr_net_loss,
         sr_return_quantity
  FROM store_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         wr_net_loss,
         wr_return_quantity
  FROM web_returns
), agg_sales AS (
  SELECT d.d_year,
         d.d_moy AS month,
         i.i_item_id,
         i.i_product_name,
         SUM(s.net_profit) AS total_sales_net_profit,
         SUM(s.sales_price) AS total_sales_amount,
         SUM(s.quantity) AS total_quantity_sold,
         AVG(CASE WHEN s.sales_price = 0 THEN 0 ELSE s.discount_amt / s.sales_price END) AS avg_discount_ratio
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE i.i_category = 'Electronics'
  GROUP BY d.d_year, d.d_moy, i.i_item_id, i.i_product_name
), agg_returns AS (
  SELECT d.d_year,
         d.d_moy AS month,
         i.i_item_id,
         i.i_product_name,
         SUM(r.net_loss) AS total_return_net_loss,
         SUM(r.quantity) AS total_quantity_returned
  FROM returns r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  WHERE i.i_category = 'Electronics'
  GROUP BY d.d_year, d.d_moy, i.i_item_id, i.i_product_name
), combined AS (
  SELECT COALESCE(s.d_year, r.d_year) AS year,
         COALESCE(s.month, r.month) AS month,
         COALESCE(s.i_item_id, r.i_item_id) AS item_id,
         COALESCE(s.i_product_name, r.i_product_name) AS product_name,
         COALESCE(s.total_sales_net_profit, 0) - COALESCE(r.total_return_net_loss, 0) AS net_profit,
         COALESCE(s.total_sales_amount, 0) AS sales_amount,
         COALESCE(s.total_quantity_sold, 0) AS quantity_sold,
         COALESCE(r.total_quantity_returned, 0) AS quantity_returned,
         COALESCE(s.avg_discount_ratio, 0) AS avg_discount_ratio
  FROM agg_sales s
  FULL OUTER JOIN agg_returns r
    ON s.d_year = r.d_year AND s.month = r.month AND s.i_item_id = r.i_item_id
), ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY year, month ORDER BY net_profit DESC) AS rpt_rank
  FROM combined
)
SELECT year,
       month,
       item_id,
       product_name,
       net_profit,
       sales_amount,
       quantity_sold,
       quantity_returned,
       avg_discount_ratio,
       rpt_rank
FROM ranked
WHERE rpt_rank <= 5
ORDER BY year, month, rpt_rank
