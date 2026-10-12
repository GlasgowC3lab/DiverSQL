WITH sampled_inventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),

returns_refunded AS (
    SELECT
        d.d_year,
        t.t_hour,
        ib.ib_upper_bound AS income_upper,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN sampled_inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = wr.wr_item_sk
    WHERE ib.ib_upper_bound > 50000
      AND NOT EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_date_sk = d.d_date_sk
            AND i.inv_item_sk = wr.wr_item_sk
      )
),

returns_returning AS (
    SELECT
        d.d_year,
        t.t_hour,
        ib.ib_upper_bound AS income_upper,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN sampled_inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = wr.wr_item_sk
    WHERE ib.ib_upper_bound <= 50000
      AND NOT EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_date_sk = d.d_date_sk
            AND i.inv_item_sk = wr.wr_item_sk
      )
),

combined AS (
    SELECT * FROM returns_refunded
    UNION ALL
    SELECT * FROM returns_returning
)
SELECT
    d_year,
    t_hour,
    income_upper,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    COUNT(*) AS return_count
FROM combined
GROUP BY CUBE (d_year, t_hour, income_upper)
HAVING SUM(wr_return_amt) > 0
ORDER BY d_year ASC NULLS LAST, t_hour ASC NULLS LAST, income_upper ASC NULLS LAST
