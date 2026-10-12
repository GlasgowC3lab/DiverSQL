WITH daily_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_fee) AS avg_fee
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, s.s_store_name, s.s_state, r.r_reason_desc
),
ranked AS (
    SELECT
        d_year,
        s_store_name,
        s_state,
        r_reason_desc,
        total_return_amt,
        total_return_tax,
        return_cnt,
        avg_fee,
        ROW_NUMBER() OVER (PARTITION BY d_year, s_store_name ORDER BY total_return_amt DESC) AS rn
    FROM daily_agg
)
SELECT
    d_year,
    s_store_name,
    s_state,
    r_reason_desc,
    total_return_amt,
    total_return_tax,
    return_cnt,
    avg_fee,
    rn AS reason_rank
FROM ranked
WHERE rn <= 5
ORDER BY d_year, total_return_amt DESC
LIMIT 200
