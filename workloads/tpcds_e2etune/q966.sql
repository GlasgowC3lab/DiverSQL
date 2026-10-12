WITH warehouse_stats AS (
    SELECT w_state,
           COUNT(*) AS warehouse_cnt,
           SUM(w_warehouse_sq_ft) AS total_sq_ft,
           AVG(w_gmt_offset) AS avg_gmt_offset
    FROM warehouse
    GROUP BY w_state
),
returns_stats AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(wr.wr_return_amt) AS total_return_amt,
           AVG(wr.wr_return_quantity) AS avg_return_qty,
           COUNT(*) AS return_cnt,
           SUM(wr.wr_fee) AS total_fee
    FROM web_returns wr
    JOIN income_band ib
      ON wr.wr_reason_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT rs.ib_income_band_sk,
       rs.ib_lower_bound,
       rs.ib_upper_bound,
       rs.total_return_amt,
       rs.avg_return_qty,
       rs.return_cnt,
       rs.total_fee,
       ws.warehouse_cnt,
       ws.total_sq_ft,
       ws.avg_gmt_offset,
       RANK() OVER (ORDER BY rs.total_return_amt DESC) AS return_amt_rank
FROM returns_stats rs
LEFT JOIN warehouse_stats ws
  ON ws.w_state = CASE rs.ib_income_band_sk
                    WHEN 1 THEN 'NM'
                    WHEN 2 THEN 'SD'
                    WHEN 3 THEN 'OH'
                    WHEN 4 THEN 'SC'
                    ELSE 'GA'
                  END
WHERE rs.total_return_amt > 0
ORDER BY rs.total_return_amt DESC
LIMIT 10
