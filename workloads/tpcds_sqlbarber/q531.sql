SELECT hd.hd_buy_potential,
       hd.hd_vehicle_count,
       SUM(sr.sr_return_amt) AS total_return_amount,
       AVG(ss.ss_net_paid) AS avg_net_paid
FROM store_returns sr
JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE sr.sr_returned_date_sk = 2452165
GROUP BY hd.hd_buy_potential, hd.hd_vehicle_count
ORDER BY total_return_amount DESC
