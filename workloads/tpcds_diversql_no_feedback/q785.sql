/*
  Goal: Analyze net paid amounts for electronic catalog sales by store state, ship carrier, and hour of day, applying several realistic filters, excluding orders that have a matching store return, and focusing on order numbers that appear in catalog returns but not in catalog sales. The query joins all 14 selected tables using only the permitted join relationships, aggregates key financial and quantity measures, orders the result by total net paid, and limits the output.
*/
WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        st.s_state AS store_state,
        sm.sm_carrier,
        td_sold.t_hour,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td_sold.t_time_sk
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN store st
        ON sr.sr_store_sk = st.s_store_sk
    WHERE sm.sm_carrier IN ('BARIAN', 'PRIVATECARRIER')
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
      AND td_sold.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
      AND st.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_order_number NOT IN (
          SELECT sr2.sr_ticket_number
          FROM store_returns sr2
          WHERE sr2.sr_return_quantity > 0
      )
      AND cs.cs_order_number IN (
          SELECT cr2.cr_order_number
          FROM catalog_returns cr2
          EXCEPT
          SELECT cs2.cs_order_number
          FROM catalog_sales cs2
      )
)
SELECT
    store_state,
    sm_carrier,
    t_hour,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    MAX(inv_quantity_on_hand) AS max_inventory_qty
FROM sales_base
GROUP BY store_state, sm_carrier, t_hour
ORDER BY total_net_paid DESC
LIMIT 100
