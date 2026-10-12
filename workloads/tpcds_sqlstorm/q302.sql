WITH sales_union AS (
  SELECT ss_sold_date_sk AS date_sk,
         ss_item_sk AS item_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_item_sk,
         cs_quantity,
         cs_net_paid,
         cs_net_profit,
         'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         'web'
  FROM web_sales
),
returns_union AS (
  SELECT sr_returned_date_sk AS date_sk,
         sr_item_sk AS item_sk,
         sr_return_quantity AS return_qty,
         sr_return_amt AS return_amt,
         sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT cr_returned_date_sk,
         cr_item_sk,
         cr_return_quantity,
         cr_return_amount,
         cr_net_loss,
         'catalog'
  FROM catalog_returns
  UNION ALL
  SELECT wr_returned_date_sk,
         wr_item_sk,
         wr_return_quantity,
         wr_return_amt,
         wr_net_loss,
         'web'
  FROM web_returns
),
sales_agg AS (
  SELECT d.d_year AS calendar_year,
         d.d_month_seq AS month_seq,
         s.channel,
         SUM(s.quantity) AS total_quantity,
         SUM(s.net_paid) AS total_net_paid,
         SUM(s.net_profit) AS total_net_profit
  FROM sales_union s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, s.channel
),
returns_agg AS (
  SELECT d.d_year AS calendar_year,
         d.d_month_seq AS month_seq,
         r.channel,
         SUM(r.return_qty) AS total_return_qty,
         SUM(r.return_amt) AS total_return_amount,
         SUM(r.net_loss) AS total_net_loss
  FROM returns_union r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, r.channel
),
monthly_combined AS (
  SELECT COALESCE(s.calendar_year, r.calendar_year) AS calendar_year,
         COALESCE(s.month_seq, r.month_seq) AS month_seq,
         COALESCE(s.channel, r.channel) AS channel,
         COALESCE(s.total_quantity, 0) AS total_quantity,
         COALESCE(s.total_net_paid, 0) AS total_net_paid,
         COALESCE(s.total_net_profit, 0) AS total_net_profit,
         COALESCE(r.total_return_qty, 0) AS total_return_qty,
         COALESCE(r.total_return_amount, 0) AS total_return_amount,
         COALESCE(r.total_net_loss, 0) AS total_net_loss,
         (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.calendar_year = r.calendar_year
    AND s.month_seq = r.month_seq
    AND s.channel = r.channel
),
monthly_change AS (
  SELECT calendar_year,
         month_seq,
         channel,
         total_quantity,
         total_net_paid,
         total_net_profit,
         total_return_qty,
         total_return_amount,
         total_net_loss,
         net_profit_after_returns,
         LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY calendar_year, month_seq) AS prev_month_profit,
         CASE
           WHEN LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY calendar_year, month_seq) = 0 THEN NULL
           ELSE (net_profit_after_returns - LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY calendar_year, month_seq))
                / LAG(net_profit_after_returns) OVER (PARTITION BY channel ORDER BY calendar_year, month_seq) * 100
         END AS mom_profit_change_pct
  FROM monthly_combined
),
top_items AS (
  SELECT s.channel,
         i.i_item_id,
         i.i_product_name,
         SUM(s.quantity) AS item_quantity,
         SUM(s.net_profit) AS item_profit,
         RANK() OVER (PARTITION BY s.channel ORDER BY SUM(s.net_profit) DESC) AS profit_rank
  FROM sales_union s
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY s.channel, i.i_item_id, i.i_product_name
  HAVING SUM(s.net_profit) > 0
),
top_items_filtered AS (
  SELECT *
  FROM top_items
  WHERE profit_rank <= 10
)
SELECT mc.calendar_year,
       mc.month_seq,
       mc.channel,
       mc.total_quantity,
       mc.total_net_paid,
       mc.total_net_profit,
       mc.total_return_qty,
       mc.total_return_amount,
       mc.total_net_loss,
       mc.net_profit_after_returns,
       mc.mom_profit_change_pct,
       ti.i_item_id,
       ti.i_product_name,
       ti.item_quantity,
       ti.item_profit,
       ti.profit_rank
FROM monthly_change mc
LEFT JOIN top_items_filtered ti
  ON mc.channel = ti.channel
WHERE mc.mom_profit_change_pct IS NOT NULL
ORDER BY mc.channel, mc.calendar_year, mc.month_seq, ti.profit_rank
