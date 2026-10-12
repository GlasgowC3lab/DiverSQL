WITH sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cc.cc_state AS state,
          'Catalog' AS channel,
          cs.cs_ext_discount_amt AS discount_amt,
          cs.cs_ext_sales_price AS sales_price,
          cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   UNION ALL
   SELECT ss.ss_sold_date_sk AS date_sk,
          s.s_state AS state,
          'Store' AS channel,
          ss.ss_ext_discount_amt AS discount_amt,
          ss.ss_ext_sales_price AS sales_price,
          ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT ws.ws_sold_date_sk AS date_sk,
          w.w_state AS state,
          'Web' AS channel,
          ws.ws_ext_discount_amt AS discount_amt,
          ws.ws_ext_sales_price AS sales_price,
          ws.ws_net_profit AS net_profit
   FROM web_sales ws
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
agg AS (
   SELECT d.d_year,
          s.state,
          s.channel,
          SUM(s.sales_price) AS total_sales,
          SUM(s.net_profit) AS total_net_profit,
          AVG(CASE WHEN s.sales_price > 0 THEN s.discount_amt / s.sales_price END) AS avg_discount_ratio,
          COUNT(*) AS num_transactions
   FROM sales s
   JOIN date_dim d ON s.date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
   GROUP BY d.d_year, s.state, s.channel
)
SELECT a.*,
       ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.d_year, a.state, a.channel
