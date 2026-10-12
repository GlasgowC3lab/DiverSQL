SELECT
    hd.hd_buy_potential,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt
FROM
    store_returns sr
JOIN
    household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE
    hd.hd_vehicle_count = 2
    AND hd.hd_buy_potential = '>10000'
    AND sr.sr_return_ship_cost > 100
GROUP BY
    hd.hd_buy_potential
