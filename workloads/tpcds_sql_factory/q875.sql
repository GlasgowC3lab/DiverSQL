WITH filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    t.s_store_id,
    t.s_store_name,
    t.s_city,
    t.s_state,
    t.total_net_loss,
    t.total_return_amount,
    t.avg_return_quantity,
    t.return_count,
    t.net_loss_category,
    RANK() OVER (ORDER BY t.total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(f.sr_net_loss) AS total_net_loss,
        SUM(f.sr_return_amt) AS total_return_amount,
        AVG(f.sr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(f.sr_net_loss) > 50000 THEN 'HIGH'
            WHEN SUM(f.sr_net_loss) BETWEEN 20000 AND 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS net_loss_category
    FROM filtered f
    JOIN store s ON f.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
) t
ORDER BY t.total_net_loss DESC
LIMIT 10
