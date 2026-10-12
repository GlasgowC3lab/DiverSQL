WITH channel_data AS (
   SELECT
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     i.i_brand AS brand,
     cd.cd_gender AS gender,
     SUM(cs.cs_net_profit) AS net_profit,
     SUM(cs.cs_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT cs.cs_order_number) AS orders,
     SUM(cr.cr_net_loss) AS net_loss,
     SUM(cr.cr_return_quantity) AS return_qty,
     COUNT(DISTINCT cr.cr_order_number) AS return_orders
   FROM catalog_sales cs
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_brand, cd.cd_gender

   UNION ALL

   SELECT
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     i.i_brand AS brand,
     cd.cd_gender AS gender,
     SUM(ss.ss_net_profit) AS net_profit,
     SUM(ss.ss_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT ss.ss_ticket_number) AS orders,
     SUM(sr.sr_net_loss) AS net_loss,
     SUM(sr.sr_return_quantity) AS return_qty,
     COUNT(DISTINCT sr.sr_ticket_number) AS return_orders
   FROM store_sales ss
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_brand, cd.cd_gender

   UNION ALL

   SELECT
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     i.i_brand AS brand,
     cd.cd_gender AS gender,
     SUM(ws.ws_net_profit) AS net_profit,
     SUM(ws.ws_ext_discount_amt) AS total_discount,
     COUNT(DISTINCT ws.ws_order_number) AS orders,
     SUM(wr.wr_net_loss) AS net_loss,
     SUM(wr.wr_return_quantity) AS return_qty,
     COUNT(DISTINCT wr.wr_order_number) AS return_orders
   FROM web_sales ws
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_brand, cd.cd_gender
),
aggregated AS (
   SELECT
     year,
     month_seq,
     brand,
     gender,
     COALESCE(SUM(net_profit),0) AS total_net_profit,
     COALESCE(SUM(total_discount),0) AS total_discount,
     COALESCE(SUM(net_loss),0) AS total_net_loss,
     COALESCE(SUM(orders),0) AS total_orders,
     COALESCE(SUM(return_qty),0) AS total_return_qty,
     COALESCE(SUM(return_orders),0) AS total_return_orders
   FROM channel_data
   GROUP BY year, month_seq, brand, gender
)
SELECT *
FROM (
   SELECT
     year,
     month_seq,
     brand,
     gender,
     total_net_profit,
     total_discount,
     total_net_loss,
     total_orders,
     total_return_qty,
     total_return_orders,
     DENSE_RANK() OVER (PARTITION BY year, month_seq ORDER BY total_net_profit DESC) AS profit_rank
   FROM aggregated
) q
WHERE profit_rank <= 5
ORDER BY year, month_seq, profit_rank
