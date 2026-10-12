WITH ticket_excluded AS (
   SELECT sr_ticket_number FROM store_returns
   EXCEPT
   SELECT cr_order_number FROM catalog_returns
),
inv_wh AS (
   SELECT
     inv.inv_item_sk,
     inv.inv_date_sk,
     inv.inv_quantity_on_hand,
     w.w_warehouse_sk,
     w.w_warehouse_name
   FROM inventory inv
   FULL OUTER JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
base AS (
   SELECT
     d.d_year,
     i.i_category,
     c.c_customer_id,
     cd.cd_gender,
     p.p_promo_name,
     ss.ss_ticket_number,
     ss.ss_ext_sales_price,
     ss.ss_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
        AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
   LEFT JOIN web_returns wr ON ss.ss_item_sk = wr.wr_item_sk
        AND ss.ss_sold_date_sk = wr.wr_returned_date_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        OR cr.cr_reason_sk = r.r_reason_sk
        OR wr.wr_reason_sk = r.r_reason_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN inv_wh invwh ON i.i_item_sk = invwh.inv_item_sk
   WHERE d.d_year = 2001
     AND ss.ss_ticket_number NOT IN (SELECT sr_ticket_number FROM ticket_excluded)
)
SELECT
   d_year,
   i_category,
   c_customer_id,
   cd_gender,
   p_promo_name,
   SUM(ss_ext_sales_price) AS total_sales,
   SUM(ss_net_profit) AS total_profit,
   COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
   CASE
     WHEN SUM(ss_ext_sales_price) > 1000000 THEN 'HIGH'
     WHEN SUM(ss_ext_sales_price) > 500000  THEN 'MEDIUM'
     ELSE 'LOW'
   END AS sales_category
FROM base
GROUP BY d_year, i_category, c_customer_id, cd_gender, p_promo_name
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
