WITH filtered_promo AS (
    SELECT *
    FROM promotion p
    WHERE p.p_promo_id IN (
        SELECT r.r_reason_id
        FROM reason r
        WHERE r.r_reason_desc LIKE '%Discount%'
    )
)
SELECT
    s.s_state,
    p.p_promo_name,
    ib_bill.ib_upper_bound AS income_upper_bill,
    ib_ship.ib_upper_bound AS income_upper_ship,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt
FROM web_sales ws
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN filtered_promo p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN store_returns sr2
    ON sr2.sr_hdemo_sk = hd_ship.hd_demo_sk
GROUP BY
    s.s_state,
    p.p_promo_name,
    ib_bill.ib_upper_bound,
    ib_ship.ib_upper_bound
HAVING
    SUM(ws.ws_net_profit) > 10000
    AND SUM(sr.sr_net_loss) > 0
LIMIT 100
