WITH base AS (
   SELECT
       s.s_store_id,
       cc.cc_name,
       d_sale.d_year,
       ss.ss_net_paid,
       cr.cr_return_amount,
       sr.sr_return_amt,
       wr.wr_return_amt,
       inv.inv_quantity_on_hand
   FROM store_sales ss
   JOIN catalog_sales cs
     ON cs.cs_item_sk = ss.ss_item_sk
   JOIN date_dim d_sale
     ON ss.ss_sold_date_sk = d_sale.d_date_sk
        AND cs.cs_sold_date_sk = d_sale.d_date_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
        AND cs.cs_item_sk = i.i_item_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sale.d_date_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sale.d_date_sk
   LEFT JOIN date_dim d_return
     ON sr.sr_returned_date_sk = d_return.d_date_sk
        AND cr.cr_returned_date_sk = d_return.d_date_sk
        AND wr.wr_returned_date_sk = d_return.d_date_sk
   LEFT JOIN web_site ws
     ON ws.web_open_date_sk = d_sale.d_date_sk
   WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND wr2.wr_returned_date_sk = d_sale.d_date_sk
   )
),
store_agg AS (
   SELECT
       s_store_id AS store_id,
       d_year,
       SUM(ss_net_paid) AS total_sales,
       SUM(cr_return_amount) AS total_catalog_returns,
       SUM(sr_return_amt) AS total_store_returns,
       SUM(wr_return_amt) AS total_web_returns,
       SUM(inv_quantity_on_hand) AS total_inventory,
       ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(ss_net_paid) DESC) AS rnk
   FROM base
   GROUP BY s_store_id, d_year
),
callcenter_agg AS (
   SELECT
       cc_name AS store_id,
       d_year,
       SUM(ss_net_paid) AS total_sales,
       SUM(cr_return_amount) AS total_catalog_returns,
       SUM(sr_return_amt) AS total_store_returns,
       SUM(wr_return_amt) AS total_web_returns,
       SUM(inv_quantity_on_hand) AS total_inventory,
       ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(ss_net_paid) DESC) AS rnk
   FROM base
   GROUP BY cc_name, d_year
)
SELECT store_id, d_year, total_sales, total_catalog_returns, total_store_returns, total_web_returns, total_inventory
FROM (
   SELECT store_id, d_year, total_sales, total_catalog_returns, total_store_returns, total_web_returns, total_inventory
   FROM store_agg
   WHERE rnk <= 3
   UNION DISTINCT
   SELECT store_id, d_year, total_sales, total_catalog_returns, total_store_returns, total_web_returns, total_inventory
   FROM callcenter_agg
   WHERE rnk <= 3
) combined
ORDER BY total_sales DESC
LIMIT 100
