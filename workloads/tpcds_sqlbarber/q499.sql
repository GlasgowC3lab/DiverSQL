SELECT
    s.s_store_name,
    SUM(sr.sr_net_loss) AS total_net_loss
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
WHERE sr.sr_returned_date_sk = 100
GROUP BY s.s_store_name
