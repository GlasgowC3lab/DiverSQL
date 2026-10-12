WITH base AS (
  SELECT
    wr.wr_order_number,
    wr.wr_returned_date_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_refunded_cash,
    wr.wr_web_page_sk,
    wr.wr_returning_hdemo_sk,
    d.d_year,
    d.d_month_seq,
    ARRAY[wr.wr_return_quantity, CAST(wr.wr_return_amt AS double)] AS qty_amt_arr
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year IN (1910, 1911, 1915, 1918, 1919)
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND wr.wr_refunded_cash > 0
    AND wr.wr_web_page_sk IN (42, 589, 1041)
    AND wr.wr_return_quantity >= 1
    AND d.d_fy_quarter_seq BETWEEN 6 AND 9
),
agg AS (
  SELECT
    d_year,
    d_month_seq,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(wr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT wr_order_number) AS distinct_orders,
    AVG(wr_return_quantity) AS avg_quantity
  FROM base
  GROUP BY d_year, d_month_seq
),
filtered AS (
  SELECT *
  FROM agg
  WHERE total_return_amt > 1000
    AND total_refunded_cash > 500
    AND distinct_orders >= 10
    AND avg_quantity BETWEEN 1 AND 5
    AND d_year = 1910
),
order_excluded AS (
  SELECT o1.wr_order_number
  FROM (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 1910
    )
  ) o1
  EXCEPT
  SELECT wr_order_number
  FROM web_returns
  WHERE wr_returned_date_sk IN (
    SELECT d_date_sk FROM date_dim WHERE d_year = 1915
  )
)
SELECT
  f.d_year,
  f.d_month_seq,
  f.total_return_amt,
  f.total_refunded_cash,
  f.distinct_orders,
  f.avg_quantity,
  u.metric
FROM filtered f
JOIN base b
  ON b.d_year = f.d_year
 AND b.d_month_seq = f.d_month_seq
LEFT JOIN LATERAL (
  SELECT metric
  FROM UNNEST(b.qty_amt_arr) AS t(metric)
) u ON true
WHERE EXISTS (
  SELECT 1 FROM order_excluded oe WHERE oe.wr_order_number = b.wr_order_number
)
LIMIT 100
