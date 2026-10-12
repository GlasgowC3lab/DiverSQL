WITH store_perf AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(*) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_city, s.s_state
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    total_returns,
    total_net_loss,
    avg_return_amount,
    total_return_qty,
    CASE
        WHEN total_net_loss > 50000 THEN 'High Loss'
        WHEN total_net_loss > 20000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM store_perf
ORDER BY loss_rank
LIMIT 10
