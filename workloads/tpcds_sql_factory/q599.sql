SELECT
    c.c_birth_month,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High'
        WHEN SUM(sr.sr_net_loss) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (PARTITION BY c.c_birth_month ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_month,
    DENSE_RANK() OVER (ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_overall
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
GROUP BY c.c_birth_month, r.r_reason_desc
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY c.c_birth_month, loss_rank_month
