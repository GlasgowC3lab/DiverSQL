WITH store_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           s.s_state AS state,
           i.i_category AS category,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_ext_discount_amt) AS total_discount,
           COUNT(*) AS order_cnt,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           wsite.web_state AS state,
           i.i_category AS category,
           SUM(ws.ws_net_paid) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS order_cnt,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, wsite.web_state, i.i_category
),
catalog_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           cc.cc_state AS state,
           i.i_category AS category,
           SUM(cs.cs_net_paid) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_ext_discount_amt) AS total_discount,
           COUNT(*) AS order_cnt,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_category
),
store_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           s.s_state AS state,
           i.i_category AS category,
           SUM(sr.sr_return_amt) AS return_amount,
           SUM(sr.sr_net_loss) AS return_loss,
           'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_category
),
catalog_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           cc.cc_state AS state,
           i.i_category AS category,
           SUM(cr.cr_return_amount) AS return_amount,
           SUM(cr.cr_net_loss) AS return_loss,
           'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_category
),
sales_combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
returns_combined AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
),
final AS (
    SELECT s.year,
           s.month,
           s.channel,
           s.state,
           s.category,
           s.total_sales,
           s.total_profit,
           s.total_discount,
           s.order_cnt,
           COALESCE(r.return_amount, 0) AS return_amount,
           COALESCE(r.return_loss, 0) AS return_loss,
           (s.total_sales - COALESCE(r.return_amount, 0)) AS net_sales,
           (s.total_profit - COALESCE(r.return_loss, 0)) AS net_profit
    FROM sales_combined s
    LEFT JOIN returns_combined r
      ON s.year = r.year
         AND s.month = r.month
         AND s.channel = r.channel
         AND s.state = r.state
         AND s.category = r.category
)
SELECT year,
       month,
       channel,
       state,
       category,
       net_sales,
       net_profit,
       total_discount,
       order_cnt,
       ROW_NUMBER() OVER (PARTITION BY year, channel ORDER BY net_profit DESC) AS profit_rank
FROM final
WHERE year BETWEEN 1999 AND 2002
ORDER BY year, channel, profit_rank
LIMIT 100
