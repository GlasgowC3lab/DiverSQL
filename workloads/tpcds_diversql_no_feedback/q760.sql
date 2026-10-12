WITH ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
)
SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    w.w_warehouse_name,
    s.s_store_name,
    p.p_promo_name,
    td.t_hour,
    cd_bill.cd_gender,
    ib.ib_lower_bound,
    channel_detail,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM ws
-- join time dimension (central time key for many fact tables)
JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
-- customer and household dimensions for the bill side
JOIN tpcds.customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
-- ship side dimensions
JOIN tpcds.customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
-- ship mode, warehouse and promotion (fact dimensions)
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
-- expand the comma‑separated channel details into rows
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
-- catalog returns (joined through shared warehouse, ship mode and time)
JOIN tpcds.catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    AND cr.cr_returned_time_sk = td.t_time_sk
JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN tpcds.customer_demographics cd_returner ON cr.cr_returning_cdemo_sk = cd_returner.cd_demo_sk
JOIN tpcds.household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN tpcds.household_demographics hd_returner ON cr.cr_returning_hdemo_sk = hd_returner.hd_demo_sk
-- store returns (joined through time and store)
JOIN tpcds.store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.customer_demographics cd_sr_refund ON sr.sr_cdemo_sk = cd_sr_refund.cd_demo_sk
JOIN tpcds.household_demographics hd_sr_refund ON sr.sr_hdemo_sk = hd_sr_refund.hd_demo_sk
-- inventory (joined through warehouse)
JOIN tpcds.inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
-- income band (through household demographics of the bill side)
JOIN tpcds.income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- web returns (joined through order number, item and time)
JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN tpcds.customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
JOIN tpcds.household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
WHERE p.p_purpose = 'Unknown'
  AND cd_bill.cd_gender = 'F'
  AND w.w_state = 'CA'
  AND s.s_state = 'CA'
  AND cr.cr_refunded_cash > 100
ORDER BY profit_rank
LIMIT 100
