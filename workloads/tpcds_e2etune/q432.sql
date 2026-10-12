SELECT
    t.t_shift,
    t.t_meal_time,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    COUNT(*) AS total_returns,
    (SELECT COUNT(*) FROM promotion p WHERE p.p_channel_tv = 'Y' AND p.p_discount_active = 'Y') AS active_tv_promotions
FROM web_returns wr
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
WHERE t.t_shift = 'Evening'
  AND t.t_meal_time = 'Dinner'
  AND wr.wr_return_amt > 0
GROUP BY t.t_shift, t.t_meal_time
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 20
