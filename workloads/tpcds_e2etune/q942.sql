WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(*) AS total_returns
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND sr.sr_returned_date_sk BETWEEN 2452500 AND 2452600
      AND p.p_discount_active = 'Y'
      AND s.s_tax_percentage > 5.0
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        i.i_category
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.i_category,
    a.total_return_amount,
    a.avg_return_qty,
    a.distinct_customers,
    a.total_returns,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_return_amount DESC) AS store_state_rank,
    SUM(a.total_return_amount) OVER (PARTITION BY a.s_state ORDER BY a.total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount_state
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
