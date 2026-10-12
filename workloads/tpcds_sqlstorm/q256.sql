WITH combined_sales AS (
   SELECT d.d_year AS sale_year,
          s.s_state AS state,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   UNION ALL
   SELECT d.d_year AS sale_year,
          cc.cc_state AS state,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          'catalog' AS channel
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   UNION ALL
   SELECT d.d_year AS sale_year,
          w.web_state AS state,
          ws.ws_net_paid AS net_paid,
          ws.ws_net_profit AS net_profit,
          'web' AS channel
   FROM web_sales ws
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT sale_year,
       state,
       channel,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count
FROM combined_sales
GROUP BY sale_year, state, channel
ORDER BY sale_year, state, channel
