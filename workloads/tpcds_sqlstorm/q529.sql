WITH all_sales AS (
   SELECT
      d.d_year AS year,
      COALESCE(cc.cc_state, w.w_state) AS state,
      cs.cs_net_paid AS net_paid,
      cs.cs_net_profit AS net_profit,
      CAST(0 AS decimal(7,2)) AS net_loss
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   UNION ALL
   SELECT
      d.d_year AS year,
      s.s_state AS state,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      CAST(0 AS decimal(7,2)) AS net_loss
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT
      d.d_year AS year,
      w2.w_state AS state,
      ws.ws_net_paid AS net_paid,
      ws.ws_net_profit AS net_profit,
      CAST(0 AS decimal(7,2)) AS net_loss
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
), all_returns AS (
   SELECT
      d.d_year AS year,
      COALESCE(cc.cc_state, w.w_state) AS state,
      CAST(0 AS decimal(7,2)) AS net_paid,
      CAST(0 AS decimal(7,2)) AS net_profit,
      cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   UNION ALL
   SELECT
      d.d_year AS year,
      s.s_state AS state,
      CAST(0 AS decimal(7,2)) AS net_paid,
      CAST(0 AS decimal(7,2)) AS net_profit,
      sr.sr_net_loss AS net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   UNION ALL
   SELECT
      d.d_year AS year,
      w3.w_state AS state,
      CAST(0 AS decimal(7,2)) AS net_paid,
      CAST(0 AS decimal(7,2)) AS net_profit,
      wr.wr_net_loss AS net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_sales ws2 ON wr.wr_order_number = ws2.ws_order_number
   LEFT JOIN warehouse w3 ON ws2.ws_warehouse_sk = w3.w_warehouse_sk
)
SELECT *
FROM (
   SELECT
      year,
      state,
      SUM(net_paid) AS total_net_paid,
      SUM(net_profit) AS total_net_profit,
      SUM(net_loss) AS total_net_loss,
      SUM(net_paid) - SUM(net_loss) AS net_revenue,
      ROUND(
         CASE WHEN SUM(net_paid) = 0 THEN 0
              ELSE (SUM(net_profit) - SUM(net_loss)) / SUM(net_paid)
         END,
         4
      ) AS profit_margin
   FROM (
      SELECT * FROM all_sales
      UNION ALL
      SELECT * FROM all_returns
   ) AS combined
   WHERE state IS NOT NULL
   GROUP BY year, state
) t
WHERE total_net_paid > 0
ORDER BY year DESC, state
