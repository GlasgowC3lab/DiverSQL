SELECT sr.sr_ticket_number,
       sr.sr_return_amt * 1.1 AS increased_return_amt,
       sr.sr_return_quantity + sr.sr_fee AS qty_plus_fee,
       CASE WHEN hd.hd_vehicle_count > hd.hd_dep_count THEN 'MoreVehicles' ELSE 'FewerOrEqualVehicles' END AS vehicle_category,
       CASE WHEN sr.sr_return_quantity = 46 THEN 985.92 ELSE sr.sr_return_amt / sr.sr_return_quantity END AS avg_return_amt_per_qty,
       (sr.sr_return_amt - sr.sr_return_tax) AS net_return_before_tax,
       CASE WHEN hd.hd_buy_potential = '5001-10000     ' THEN 1001-5000       ELSE 501-1000        END AS buy_potential_score
FROM store_returns AS sr
JOIN household_demographics AS hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE sr.sr_returned_date_sk = 2451053
