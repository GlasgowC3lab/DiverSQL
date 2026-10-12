SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    ss_agg.total_store_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    ws.ws_ship_mode_sk
FROM household_demographics hd
JOIN (
    SELECT
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451121 AND 2451206
    GROUP BY ss_hdemo_sk
) ss_agg
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE ws.ws_sold_date_sk = 2452220
GROUP BY
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    ss_agg.total_store_sales,
    ws.ws_ship_mode_sk
HAVING SUM(cr.cr_return_amount) > 23.17
