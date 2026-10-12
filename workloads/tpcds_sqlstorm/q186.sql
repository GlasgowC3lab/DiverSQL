WITH sales AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           'store' AS channel,
           i.i_category AS category,
           SUM(ss.ss_net_paid) AS net_sales,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           'catalog' AS channel,
           i.i_category,
           SUM(cs.cs_net_paid) AS net_sales,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           'web' AS channel,
           i.i_category,
           SUM(ws.ws_net_paid) AS net_sales,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           'store' AS channel,
           i.i_category AS category,
           -SUM(sr.sr_return_amt_inc_tax) AS net_sales_adj,
           -SUM(sr.sr_net_loss) AS net_profit_adj
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           'catalog' AS channel,
           i.i_category,
           -SUM(cr.cr_return_amt_inc_tax) AS net_sales_adj,
           -SUM(cr.cr_net_loss) AS net_profit_adj
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           'web' AS channel,
           i.i_category,
           -SUM(wr.wr_return_amt_inc_tax) AS net_sales_adj,
           -SUM(wr.wr_net_loss) AS net_profit_adj
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT s.d_year,
       s.month,
       s.channel,
       s.category,
       s.net_sales + COALESCE(r.net_sales_adj, 0) AS total_net_sales,
       s.net_profit + COALESCE(r.net_profit_adj, 0) AS total_net_profit
FROM sales s
LEFT JOIN returns r
  ON s.d_year = r.d_year
 AND s.month = r.month
 AND s.channel = r.channel
 AND s.category = r.category
WHERE s.d_year = 2000
ORDER BY s.channel, s.category, s.month
