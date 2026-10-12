WITH item_sales AS (
    SELECT
        ws_item_sk,
        ws_bill_hdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_mode_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS profit,
        SUM(ws_quantity) AS qty,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451088
      AND ws_net_profit > 0
    GROUP BY
        ws_item_sk,
        ws_bill_hdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_mode_sk,
        ws_web_site_sk
)
SELECT
    ws.web_name AS website,
    ws.web_state,
    sm.sm_type AS ship_mode_type,
    hd_bill.hd_income_band_sk AS bill_income_band,
    hd_ship.hd_income_band_sk AS ship_income_band,
    i.i_category,
    i.i_brand,
    SUM(isales.profit) AS total_profit,
    SUM(isales.qty) AS total_quantity,
    AVG(isales.avg_discount) AS avg_discount,
    COUNT(DISTINCT isales.ws_item_sk) AS distinct_items,
    RANK() OVER (PARTITION BY ws.web_state ORDER BY SUM(isales.profit) DESC) AS profit_rank_state
FROM item_sales isales
JOIN item i ON isales.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON isales.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws ON isales.ws_web_site_sk = ws.web_site_sk
JOIN household_demographics hd_bill ON isales.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON isales.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE i.i_category = 'Electronics'
  AND sm.sm_type = 'AIR'
  AND ws.web_state = 'CA'
  AND hd_bill.hd_income_band_sk BETWEEN 5 AND 10
GROUP BY
    ws.web_name,
    ws.web_state,
    sm.sm_type,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_income_band_sk,
    i.i_category,
    i.i_brand
HAVING SUM(isales.profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
