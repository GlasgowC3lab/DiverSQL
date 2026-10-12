WITH base_agg AS (
   SELECT
       w.w_warehouse_name,
       ca.ca_state,
       hd.hd_buy_potential,
       SUM(ss.ss_ext_sales_price) AS total_store_sales,
       SUM(sr.sr_net_loss) AS total_store_returns_loss,
       SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
       SUM(wr.wr_net_loss) AS total_web_returns_loss,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
       AVG(ss.ss_ext_discount_amt) AS avg_store_discount
   FROM store_sales ss
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_sales cs
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    AND cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN inventory i
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_returns wr
     ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE ca.ca_state = 'CA'
     AND hd.hd_buy_potential = '>10000'
     AND w.w_warehouse_sq_ft > 100000
     AND i.inv_quantity_on_hand > 0
     AND cs.cs_ext_sales_price > 1000
   GROUP BY w.w_warehouse_name, ca.ca_state, hd.hd_buy_potential
   HAVING SUM(ss.ss_ext_sales_price) > 5000
      AND SUM(cs.cs_ext_sales_price) > 10000
      AND SUM(sr.sr_net_loss) < 2000
)
SELECT
    agg.w_warehouse_name,
    agg.ca_state,
    agg.hd_buy_potential,
    agg.total_store_sales,
    agg.total_store_returns_loss,
    agg.total_catalog_sales,
    agg.total_web_returns_loss,
    agg.distinct_tickets,
    agg.avg_store_discount,
    SUM(agg.total_store_sales) OVER (
        ORDER BY agg.w_warehouse_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_store_sales
FROM base_agg agg
ORDER BY agg.w_warehouse_name
