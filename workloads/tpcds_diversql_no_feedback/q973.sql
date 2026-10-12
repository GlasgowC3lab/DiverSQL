WITH filtered_sr AS (
    SELECT *
    FROM store_returns sr
    WHERE sr.sr_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity = 0
    )
)
SELECT
    d.d_year,
    i_cs.i_category,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt
FROM filtered_sr sr
-- Join to date dimension (store returns side)
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
-- Join to time dimension (store returns side)
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
-- First alias of item (store returns side)
JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
-- Second alias of item (catalog sales side)
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
-- Join to time dimension for catalog sales
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
-- Join to call center
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
-- Join to ship mode
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
-- Join to reason (store returns side)
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
-- Join to customer address (store returns side)
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
-- Join to household demographics (store returns side)
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
-- Join to income band via household demographics
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- Join to catalog returns via order number
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i_cs.i_item_sk
-- Join to web returns (using the store‑returns date and the first item alias)
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = i_sr.i_item_sk
-- Join to inventory (using the store‑returns date and the first item alias)
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i_sr.i_item_sk
GROUP BY d.d_year, i_cs.i_category, r.r_reason_desc
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
