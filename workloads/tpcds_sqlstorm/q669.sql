WITH catalog_agg AS (
   SELECT d.d_year AS year,
          'catalog' AS channel,
          cc.cc_state AS region,
          i.i_category AS category,
          SUM(cs.cs_net_paid) AS sum_net_paid,
          SUM(cs.cs_net_profit) AS sum_net_profit,
          COALESCE(SUM(cr.cr_net_loss), 0) AS sum_net_loss
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   GROUP BY d.d_year, cc.cc_state, i.i_category
),
store_agg AS (
   SELECT d.d_year AS year,
          'store' AS channel,
          s.s_state AS region,
          i.i_category AS category,
          SUM(ss.ss_net_paid) AS sum_net_paid,
          SUM(ss.ss_net_profit) AS sum_net_profit,
          COALESCE(SUM(sr.sr_net_loss), 0) AS sum_net_loss
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   GROUP BY d.d_year, s.s_state, i.i_category
),
web_agg AS (
   SELECT d.d_year AS year,
          'web' AS channel,
          w.web_state AS region,
          i.i_category AS category,
          SUM(ws.ws_net_paid) AS sum_net_paid,
          SUM(ws.ws_net_profit) AS sum_net_profit,
          COALESCE(SUM(wr.wr_net_loss), 0) AS sum_net_loss
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   GROUP BY d.d_year, w.web_state, i.i_category
)
SELECT *
FROM (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM web_agg
) t
WHERE t.year >= 1998
ORDER BY t.year, t.channel, t.sum_net_paid DESC
LIMIT 100
