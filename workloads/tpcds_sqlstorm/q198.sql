WITH catalog_returns_agg AS (
   SELECT cr_order_number AS order_number,
          SUM(cr_return_amt_inc_tax) AS return_amt_inc_tax,
          SUM(cr_net_loss) AS net_loss
   FROM catalog_returns
   GROUP BY cr_order_number
),
store_returns_agg AS (
   SELECT sr_ticket_number AS ticket_number,
          SUM(sr_return_amt_inc_tax) AS return_amt_inc_tax,
          SUM(sr_net_loss) AS net_loss
   FROM store_returns
   GROUP BY sr_ticket_number
),
web_returns_agg AS (
   SELECT wr_order_number AS order_number,
          SUM(wr_return_amt_inc_tax) AS return_amt_inc_tax,
          SUM(wr_net_loss) AS net_loss
   FROM web_returns
   GROUP BY wr_order_number
),
catalog_sales_agg AS (
   SELECT cs.cs_order_number AS order_number,
          d.d_year AS year,
          d.d_month_seq AS month_seq,
          cc.cc_state AS state,
          SUM(cs.cs_ext_sales_price) AS order_sales_amount,
          SUM(cs.cs_net_profit) AS order_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   GROUP BY cs.cs_order_number, d.d_year, d.d_month_seq, cc.cc_state
),
store_sales_agg AS (
   SELECT ss.ss_ticket_number AS ticket_number,
          d.d_year AS year,
          d.d_month_seq AS month_seq,
          s.s_state AS state,
          SUM(ss.ss_ext_sales_price) AS order_sales_amount,
          SUM(ss.ss_net_profit) AS order_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY ss.ss_ticket_number, d.d_year, d.d_month_seq, s.s_state
),
web_sales_agg AS (
   SELECT ws.ws_order_number AS order_number,
          d.d_year AS year,
          d.d_month_seq AS month_seq,
          wsite.web_state AS state,
          SUM(ws.ws_ext_sales_price) AS order_sales_amount,
          SUM(ws.ws_net_profit) AS order_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   GROUP BY ws.ws_order_number, d.d_year, d.d_month_seq, wsite.web_state
),
catalog_combined AS (
   SELECT c.year,
          c.month_seq,
          c.state,
          'catalog' AS channel,
          SUM(c.order_sales_amount) AS sales_amount,
          SUM(c.order_profit) AS profit,
          SUM(COALESCE(r.return_amt_inc_tax, 0)) AS return_amount,
          SUM(COALESCE(r.net_loss, 0)) AS return_loss
   FROM catalog_sales_agg c
   LEFT JOIN catalog_returns_agg r ON c.order_number = r.order_number
   GROUP BY c.year, c.month_seq, c.state
),
store_combined AS (
   SELECT s.year,
          s.month_seq,
          s.state,
          'store' AS channel,
          SUM(s.order_sales_amount) AS sales_amount,
          SUM(s.order_profit) AS profit,
          SUM(COALESCE(r.return_amt_inc_tax, 0)) AS return_amount,
          SUM(COALESCE(r.net_loss, 0)) AS return_loss
   FROM store_sales_agg s
   LEFT JOIN store_returns_agg r ON s.ticket_number = r.ticket_number
   GROUP BY s.year, s.month_seq, s.state
),
web_combined AS (
   SELECT w.year,
          w.month_seq,
          w.state,
          'web' AS channel,
          SUM(w.order_sales_amount) AS sales_amount,
          SUM(w.order_profit) AS profit,
          SUM(COALESCE(r.return_amt_inc_tax, 0)) AS return_amount,
          SUM(COALESCE(r.net_loss, 0)) AS return_loss
   FROM web_sales_agg w
   LEFT JOIN web_returns_agg r ON w.order_number = r.order_number
   GROUP BY w.year, w.month_seq, w.state
),
combined AS (
   SELECT *
   FROM catalog_combined
   UNION ALL
   SELECT *
   FROM store_combined
   UNION ALL
   SELECT *
   FROM web_combined
)
SELECT year,
       month_seq,
       state,
       channel,
       sales_amount,
       profit,
       return_amount,
       return_loss,
       profit - return_loss AS net_profit,
       ROW_NUMBER() OVER (PARTITION BY year, month_seq, channel ORDER BY (profit - return_loss) DESC) AS profit_rank
FROM combined
ORDER BY year, month_seq, channel, profit_rank
