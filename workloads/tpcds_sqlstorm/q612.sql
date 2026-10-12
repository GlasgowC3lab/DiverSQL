WITH
sales AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           i.i_category,
           s.s_state AS state,
           'store' AS channel,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           w.web_state AS state,
           'web' AS channel,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           cc.cc_state AS state,
           'catalog' AS channel,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
returns AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           i.i_category,
           s.s_state AS state,
           'store' AS channel,
           SUM(sr.sr_return_quantity) AS return_qty,
           SUM(sr.sr_return_amt) AS return_amt,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, s.s_state
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           NULL AS state,
           'web' AS channel,
           SUM(wr.wr_return_quantity) AS return_qty,
           SUM(wr.wr_return_amt) AS return_amt,
           SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
    UNION ALL
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           cc.cc_state AS state,
           'catalog' AS channel,
           SUM(cr.cr_return_quantity) AS return_qty,
           SUM(cr.cr_return_amount) AS return_amt,
           SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cc.cc_state
),
agg_sales AS (
    SELECT d_year,
           month,
           i_category,
           state,
           channel,
           SUM(quantity) AS total_quantity,
           SUM(net_paid) AS total_sales,
           SUM(profit) AS total_profit
    FROM sales
    GROUP BY d_year, month, i_category, state, channel
),
agg_returns AS (
    SELECT d_year,
           month,
           i_category,
           state,
           channel,
           SUM(return_qty) AS total_return_qty,
           SUM(return_amt) AS total_return_amt,
           SUM(loss) AS total_return_loss
    FROM returns
    GROUP BY d_year, month, i_category, state, channel
),
combined AS (
    SELECT s.d_year,
           s.month,
           s.i_category,
           COALESCE(s.state, r.state) AS state,
           s.channel,
           s.total_quantity,
           s.total_sales,
           s.total_profit,
           COALESCE(r.total_return_qty, 0) AS total_return_qty,
           COALESCE(r.total_return_amt, 0) AS total_return_amt,
           COALESCE(r.total_return_loss, 0) AS total_return_loss,
           s.total_sales - COALESCE(r.total_return_amt, 0) AS net_sales,
           s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit
    FROM agg_sales s
    LEFT JOIN agg_returns r
      ON s.d_year = r.d_year
     AND s.month = r.month
     AND s.i_category = r.i_category
     AND (s.state = r.state OR r.state IS NULL)
     AND s.channel = r.channel
)
SELECT
    d_year,
    month,
    state,
    channel,
    i_category,
    total_quantity,
    total_sales,
    total_return_amt,
    net_sales,
    total_profit,
    total_return_loss,
    net_profit,
    RANK() OVER (PARTITION BY d_year, month, state, channel ORDER BY net_profit DESC) AS profit_rank,
    AVG(net_profit) OVER (PARTITION BY i_category ORDER BY d_year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3m_moving_avg
FROM combined
ORDER BY d_year, month, state, channel, net_profit DESC
