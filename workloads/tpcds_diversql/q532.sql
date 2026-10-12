WITH joined AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_year,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        ARRAY[wr.wr_return_quantity, CAST(wr.wr_return_amt AS double)] AS qty_amt_arr
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year IN (2001, 2002)
),
with_total AS (
    SELECT
        j.*, 
        lt.total_val
    FROM joined j
    CROSS JOIN LATERAL (
        SELECT SUM(v) AS total_val
        FROM UNNEST(j.qty_amt_arr) AS t(v)
    ) lt
),
expanded AS (
    SELECT
        w.wr_returned_date_sk,
        w.d_year,
        w.wr_return_quantity,
        w.wr_return_amt,
        w.total_val,
        u.val AS metric,
        CASE WHEN u.ordinality = 1 THEN 'quantity' ELSE 'amount' END AS metric_type
    FROM with_total w
    CROSS JOIN UNNEST(w.qty_amt_arr) WITH ORDINALITY AS u(val, ordinality)
)
SELECT
    e.wr_returned_date_sk,
    e.d_year,
    e.metric_type,
    e.metric AS metric_value,
    e.total_val
FROM expanded e
WHERE e.metric_type = 'amount' AND e.metric > 150
UNION ALL
SELECT
    e.wr_returned_date_sk,
    e.d_year,
    e.metric_type,
    e.metric AS metric_value,
    e.total_val
FROM expanded e
WHERE e.metric_type = 'quantity' AND e.metric >= 2
EXCEPT
SELECT
    e.wr_returned_date_sk,
    e.d_year,
    e.metric_type,
    e.metric AS metric_value,
    e.total_val
FROM expanded e
WHERE e.total_val < 200
ORDER BY d_year DESC, metric_type, metric_value DESC
