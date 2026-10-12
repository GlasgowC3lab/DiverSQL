SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    ROUND(
        (SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0)) * 100,
        2
    ) AS net_loss_percentage,
    CASE
        WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH_LOSS'
        WHEN SUM(wr.wr_net_loss) > 0    THEN 'MODERATE_LOSS'
        ELSE 'NO_LOSS'
    END AS loss_category
FROM date_dim AS d
JOIN web_returns AS wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2018 AND 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
