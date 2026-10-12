WITH band_ship_returns AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           sm.sm_type,
           COUNT(*) AS return_cnt,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
           SUM(wr.wr_net_loss) AS total_net_loss,
           AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN income_band ib
      ON wr.wr_return_amt_inc_tax BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    JOIN ship_mode sm
      ON ( (sm.sm_code = 'AIR' AND wr.wr_return_ship_cost < 10)
           OR (sm.sm_code = 'SURFACE' AND wr.wr_return_ship_cost BETWEEN 10 AND 20)
           OR (sm.sm_code = 'SEA' AND wr.wr_return_ship_cost BETWEEN 20 AND 30)
           OR (sm.sm_code = 'BIKE' AND wr.wr_return_ship_cost >= 30) )
    WHERE wr.wr_returned_date_sk BETWEEN 20200101 AND 20201231
      AND ib.ib_income_band_sk IN (1, 2, 3, 4, 5)
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, sm.sm_type
    HAVING COUNT(*) > 10
)
SELECT *,
       RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_loss DESC) AS loss_rank
FROM band_ship_returns
ORDER BY total_net_loss DESC, total_return_amt DESC
LIMIT 100
