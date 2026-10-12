WITH unified_sales AS (
  SELECT cs_sold_date_sk AS date_sk,
         cs_item_sk AS item_sk,
         cs_net_paid AS net_amount,
         cs_net_profit AS profit
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_item_sk,
         ss_net_paid,
         ss_net_profit
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_net_paid,
         ws_net_profit
  FROM web_sales
  UNION ALL
  SELECT cr_returned_date_sk,
         cr_item_sk,
         -cr_return_amt_inc_tax,
         -cr_net_loss
  FROM catalog_returns
  UNION ALL
  SELECT sr_returned_date_sk,
         sr_item_sk,
         -sr_return_amt_inc_tax,
         -sr_net_loss
  FROM store_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         -wr_return_amt_inc_tax,
         -wr_net_loss
  FROM web_returns
)
SELECT d_year,
       d_month_seq,
       i_item_sk,
       i_product_name,
       total_sales,
       total_returns,
       net_revenue,
       total_profit,
       profit_margin,
       item_rank
FROM (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_item_sk,
         i.i_product_name,
         SUM(CASE WHEN us.net_amount > 0 THEN us.net_amount ELSE 0 END) AS total_sales,
         SUM(CASE WHEN us.net_amount < 0 THEN -us.net_amount ELSE 0 END) AS total_returns,
         SUM(us.net_amount) AS net_revenue,
         SUM(us.profit) AS total_profit,
         CASE WHEN SUM(us.net_amount) = 0 THEN 0 ELSE SUM(us.profit) / SUM(us.net_amount) END AS profit_margin,
         RANK() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(us.profit) DESC) AS item_rank
  FROM unified_sales us
  JOIN date_dim d ON us.date_sk = d.d_date_sk
  JOIN item i ON us.item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
) t
WHERE t.item_rank <= 5
ORDER BY t.d_year, t.d_month_seq, t.item_rank
