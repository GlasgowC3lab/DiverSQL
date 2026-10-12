WITH sampled_store AS (
    SELECT *
    FROM tpcds.store TABLESAMPLE BERNOULLI (10)
),
sampled_returns AS (
    SELECT *
    FROM tpcds.store_returns TABLESAMPLE BERNOULLI (5)
)
SELECT
    st.s_store_id,
    st.s_state,
    COUNT(sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(CASE WHEN sr.sr_fee > 50 THEN sr.sr_fee ELSE 0 END) AS high_fee_total,
    MIN(sr.sr_return_quantity) AS min_qty,
    MAX(sr.sr_return_quantity) AS max_qty
FROM sampled_store st
FULL OUTER JOIN sampled_returns sr
    ON sr.sr_store_sk = st.s_store_sk
WHERE
    st.s_state IN ('CA', 'TX', 'NY') AND
    st.s_city = 'San Jose' AND
    st.s_zip LIKE '94%' AND
    st.s_floor_space > 2000 AND
    st.s_number_employees BETWEEN 50 AND 500 AND
    st.s_tax_percentage < 10 AND
    sr.sr_fee BETWEEN 10 AND 100 AND
    sr.sr_return_amt > 0 AND
    sr.sr_addr_sk IN (2436041, 151332)
GROUP BY
    st.s_store_id,
    st.s_state

UNION DISTINCT

SELECT
    st2.s_store_id,
    st2.s_state,
    COUNT(sr2.sr_ticket_number) AS return_transactions,
    SUM(sr2.sr_return_amt) AS total_return_amount,
    AVG(sr2.sr_fee) AS avg_fee,
    SUM(CASE WHEN sr2.sr_fee > 50 THEN sr2.sr_fee ELSE 0 END) AS high_fee_total,
    MIN(sr2.sr_return_quantity) AS min_qty,
    MAX(sr2.sr_return_quantity) AS max_qty
FROM tpcds.store st2
FULL OUTER JOIN tpcds.store_returns sr2
    ON sr2.sr_store_sk = st2.s_store_sk
WHERE
    st2.s_state IN ('FL', 'IL') AND
    st2.s_city = 'Chicago' AND
    st2.s_zip LIKE '60%' AND
    st2.s_floor_space > 1500 AND
    st2.s_number_employees BETWEEN 30 AND 300 AND
    st2.s_tax_percentage < 8 AND
    sr2.sr_fee BETWEEN 20 AND 80 AND
    sr2.sr_return_amt > 50 AND
    sr2.sr_addr_sk IN (2059685, 217160)
GROUP BY
    st2.s_store_id,
    st2.s_state
ORDER BY
    total_return_amount DESC,
    return_transactions DESC
