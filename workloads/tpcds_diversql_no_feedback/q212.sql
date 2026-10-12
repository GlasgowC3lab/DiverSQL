WITH base AS (
    SELECT
        d_sold.d_year,
        i.i_brand_id,
        ca_bill.ca_state,
        ws.ws_net_profit        AS ws_net_profit,
        sr.sr_net_loss          AS sr_net_loss,
        cr.cr_return_amount     AS cr_return_amount,
        wr.wr_return_amt        AS wr_return_amt,
        ws.ws_order_number      AS ws_order_number
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold          ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.time_dim t_sold          ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN tpcds.date_dim d_ship          ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.item i                  ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd_bill   ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_address ca_bill        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.ship_mode sm                     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p                     ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN tpcds.date_dim d_wr          ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN tpcds.time_dim t_wr          ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN tpcds.reason r_wr            ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN tpcds.household_demographics hd_wr_ref   ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_wr_ref        ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd_wr_ret   ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_wr_ret        ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN tpcds.date_dim d_sr          ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN tpcds.time_dim t_sr          ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN tpcds.reason r_sr            ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN tpcds.household_demographics hd_sr   ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_sr        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN tpcds.date_dim d_cr          ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN tpcds.time_dim t_cr          ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN tpcds.reason r_cr            ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN tpcds.ship_mode sm_cr        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN tpcds.call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.customer_address ca_cr_ref   ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_cr_ret   ON cr.cr_returning_addr_sk = ca_cr_ret.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd_cr_ret ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN tpcds.income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sold.d_year = 1998
      AND i.i_brand_id IN (3003001, 6016006)
      AND hd_bill.hd_vehicle_count >= 1
      AND cr.cr_return_amount > 100
      AND ws.ws_quantity >= 2
      AND p.p_discount_active = 'Y'
)
SELECT
    year,
    brand_id,
    state,
    SUM(total_net_profit)               AS total_net_profit,
    SUM(total_store_return_loss)        AS total_store_return_loss,
    SUM(total_catalog_return_amount)    AS total_catalog_return_amount,
    SUM(total_web_return_amount)        AS total_web_return_amount,
    COUNT(DISTINCT order_number)        AS order_cnt,
    COUNT(*) FILTER (WHERE total_web_return_amount IS NOT NULL) AS web_return_cnt,
    RANK() OVER (PARTITION BY year ORDER BY SUM(total_net_profit) DESC) AS profit_rank
FROM (
    SELECT
        d_year        AS year,
        i_brand_id    AS brand_id,
        ca_state      AS state,
        ws_net_profit AS total_net_profit,
        sr_net_loss   AS total_store_return_loss,
        cr_return_amount AS total_catalog_return_amount,
        wr_return_amt AS total_web_return_amount,
        ws_order_number AS order_number
    FROM base
) agg
GROUP BY ROLLUP (year, brand_id, state)
ORDER BY year, profit_rank
LIMIT 100
