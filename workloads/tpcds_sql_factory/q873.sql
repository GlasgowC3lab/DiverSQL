WITH returns_with_time AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        td.t_hour,
        s.s_store_id
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    c.c_birth_year,
    c.c_birth_month,
    SUM(rwt.sr_return_amt) AS total_return_amount,
    COUNT(*) AS total_returns,
    AVG(rwt.sr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN rwt.t_hour BETWEEN 12 AND 14 THEN 1 ELSE 0 END) AS lunch_time_returns,
    COUNT(DISTINCT rwt.s_store_id) AS distinct_store_count,
    CASE
        WHEN SUM(rwt.sr_return_amt) < 1000 THEN 'Low'
        WHEN SUM(rwt.sr_return_amt) BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS return_volume_category,
    DENSE_RANK() OVER (PARTITION BY c.c_birth_country ORDER BY SUM(rwt.sr_return_amt) DESC) AS country_return_rank
FROM returns_with_time rwt
JOIN customer c ON rwt.sr_customer_sk = c.c_customer_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    c.c_birth_year,
    c.c_birth_month
HAVING COUNT(*) >= 2
ORDER BY c.c_birth_country, country_return_rank
LIMIT 100
