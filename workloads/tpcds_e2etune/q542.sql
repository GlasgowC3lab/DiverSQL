WITH grouped_sales AS (
    SELECT
        hd_bill.hd_buy_potential AS buy_potential,
        hd_ship.hd_vehicle_count AS ship_vehicle_count,
        p.p_channel_email AS promo_channel,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE hd_bill.hd_income_band_sk = 4
      AND p.p_discount_active = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2458840 AND 2459205
      AND ws.ws_quantity > 0
      AND hd_ship.hd_vehicle_count >= 1
    GROUP BY hd_bill.hd_buy_potential, hd_ship.hd_vehicle_count, p.p_channel_email
    HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT
    gs.buy_potential,
    gs.ship_vehicle_count,
    gs.promo_channel,
    gs.order_cnt,
    gs.total_profit,
    gs.avg_discount,
    gs.total_quantity,
    gs.total_net_paid,
    ROUND(gs.total_profit / tot.total_profit_all * 100, 2) AS profit_pct_of_total
FROM grouped_sales gs
CROSS JOIN (SELECT SUM(total_profit) AS total_profit_all FROM grouped_sales) tot
ORDER BY gs.total_profit DESC
LIMIT 200
