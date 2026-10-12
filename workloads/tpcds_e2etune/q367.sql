WITH inv_by_month AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_week_seq,
           d.d_dow,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT d.d_date_id) AS distinct_days
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_weekend = 'Y'
      AND i.inv_quantity_on_hand > 0
    GROUP BY d.d_year, d.d_month_seq, d.d_week_seq, d.d_dow
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT ibm.d_year,
       ibm.d_month_seq,
       ibm.d_week_seq,
       ibm.d_dow,
       ibm.total_qty,
       ibm.distinct_days,
       (SELECT AVG(ib.ib_lower_bound)
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_vehicle_count >= 2) AS avg_income_lower_bound,
       RANK() OVER (ORDER BY ibm.total_qty DESC) AS qty_rank
FROM inv_by_month ibm
ORDER BY ibm.total_qty DESC
LIMIT 10
