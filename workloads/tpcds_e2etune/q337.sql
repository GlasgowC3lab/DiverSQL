WITH store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        SUM(sr.sr_return_amt_inc_tax) AS sum_return_amt_inc_tax,
        SUM(sr.sr_return_quantity) AS sum_return_quantity,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        SUM(sr.sr_fee) AS sum_fee,
        SUM(sr.sr_return_tax) AS sum_return_tax
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2452000 AND 2453000
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk, sr.sr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.c_birth_country,
    COUNT(*) AS num_return_events,
    SUM(a.sum_return_amt) AS total_return_amt,
    SUM(a.sum_return_amt_inc_tax) AS total_return_amt_inc_tax,
    SUM(a.sum_return_quantity) AS total_quantity,
    AVG(a.avg_net_loss) AS avg_net_loss,
    SUM(a.sum_fee) AS total_fee,
    SUM(a.sum_return_tax) AS total_return_tax,
    RANK() OVER (PARTITION BY c.c_birth_country ORDER BY SUM(a.sum_return_amt) DESC) AS store_rank_by_country
FROM store_return_agg a
JOIN customer c ON a.sr_customer_sk = c.c_customer_sk
JOIN store s ON a.sr_store_sk = s.s_store_sk
WHERE c.c_birth_country IN ('MEXICO', 'CHILE')
  AND s.s_country = 'USA'
  AND s.s_closed_date_sk IS NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.c_birth_country
HAVING COUNT(*) > 5
ORDER BY c.c_birth_country, store_rank_by_country
LIMIT 50
