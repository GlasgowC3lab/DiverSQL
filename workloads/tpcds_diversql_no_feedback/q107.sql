WITH sales_data AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(i.i_current_price * ss.ss_quantity) AS total_revenue,
        SUM(CASE WHEN ss.ss_sales_price > 50 THEN ss.ss_quantity ELSE 0 END) AS high_price_qty,
        cs.cs_ship_mode_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        cs.cs_ship_mode_sk
)
SELECT
    sd.s_store_id,
    sd.d_year,
    sd.d_month_seq,
    sd.total_profit,
    sd.total_revenue,
    CASE WHEN sd.total_profit < 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    smc.ship_mode_count
FROM sales_data sd
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT sm2.sm_ship_mode_id) AS ship_mode_count
    FROM ship_mode sm2
    WHERE sm2.sm_ship_mode_sk = sd.cs_ship_mode_sk
) smc ON true
WHERE sd.d_year = 2001
  AND sd.total_revenue > 10000
  AND sd.total_profit IS NOT NULL
ORDER BY sd.total_profit DESC
LIMIT 100
