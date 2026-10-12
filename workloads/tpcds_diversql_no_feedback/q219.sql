WITH inv_agg AS (
        SELECT
            w.w_warehouse_sk,
            w.w_city,
            SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory inv
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_sk, w.w_city
    ),
    promo_subset AS (
        SELECT p.p_promo_sk, p.p_discount_active
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
        LIMIT 5
    )
SELECT
    w.w_city,
    cp.cp_department,
    sm.sm_type,
    ib.ib_lower_bound,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    inv_agg.total_qty_on_hand,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_indicator
FROM catalog_sales cs
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
JOIN time_dim t_store_sale ON ss.ss_sold_time_sk = t_store_sale.t_time_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim t_store_ret ON sr.sr_return_time_sk = t_store_ret.t_time_sk
JOIN web_returns wr ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
JOIN time_dim t_web_ret ON wr.wr_returned_time_sk = t_web_ret.t_time_sk
JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
JOIN inv_agg ON inv_agg.w_warehouse_sk = w.w_warehouse_sk
CROSS JOIN promo_subset ps
WHERE p.p_promo_sk = ps.p_promo_sk
GROUP BY
    w.w_city,
    cp.cp_department,
    sm.sm_type,
    ib.ib_lower_bound,
    inv_agg.total_qty_on_hand
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
