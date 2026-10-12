WITH store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS total_returns
    FROM store_returns sr
    WHERE sr.sr_return_amt_inc_tax > 100
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY sr.sr_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    s.s_number_employees,
    agg.total_return_amt_inc_tax,
    agg.total_net_loss,
    agg.avg_return_quantity,
    agg.distinct_customers,
    agg.total_refunded_cash,
    agg.total_fee,
    agg.total_returns,
    RANK() OVER (PARTITION BY s.s_state ORDER BY agg.total_return_amt_inc_tax DESC) AS state_return_rank
FROM store_return_agg agg
JOIN store s ON agg.sr_store_sk = s.s_store_sk
WHERE agg.total_return_amt_inc_tax > 5000
ORDER BY s.s_state, state_return_rank
LIMIT 100
