WITH monthly_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        d.d_year,
        d.d_moy AS month,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2023
      AND w.w_state IN ('CA', 'TX', 'NY')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_state, d.d_year, d.d_moy
    HAVING SUM(i.inv_quantity_on_hand) > 0
),
monthly_with_lag AS (
    SELECT
        mi.*, 
        LAG(total_qty) OVER (PARTITION BY w_warehouse_sk ORDER BY month) AS prev_month_qty
    FROM monthly_inventory mi
),
monthly_growth AS (
    SELECT
        *,
        CASE
            WHEN prev_month_qty IS NULL OR prev_month_qty = 0 THEN NULL
            ELSE (total_qty - prev_month_qty) / prev_month_qty
        END AS mom_growth
    FROM monthly_with_lag
),
warehouse_yearly AS (
    SELECT
        w_warehouse_sk,
        SUM(total_qty) AS yearly_qty
    FROM monthly_inventory
    GROUP BY w_warehouse_sk
),
ranked_warehouses AS (
    SELECT
        w_warehouse_sk,
        yearly_qty,
        RANK() OVER (ORDER BY yearly_qty DESC) AS warehouse_rank
    FROM warehouse_yearly
)
SELECT
    mg.w_warehouse_name,
    mg.w_state,
    mg.month,
    mg.total_qty,
    mg.prev_month_qty,
    mg.mom_growth,
    rw.yearly_qty,
    rw.warehouse_rank
FROM monthly_growth mg
JOIN ranked_warehouses rw
  ON mg.w_warehouse_sk = rw.w_warehouse_sk
ORDER BY rw.warehouse_rank, mg.month
