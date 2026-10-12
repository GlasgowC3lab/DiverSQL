WITH sr AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        sr_store_sk AS store_sk,
        SUM(sr_return_amt) AS store_return_amt,
        SUM(sr_return_quantity) AS store_return_qty
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk
),
wr AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS web_return_amt,
        SUM(wr_return_quantity) AS web_return_qty
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
inv AS (
    SELECT
        inv_date_sk AS date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_market_id,
    SUM(sr.store_return_amt) AS total_store_return_amt,
    SUM(sr.store_return_qty) AS total_store_return_qty,
    SUM(wr.web_return_amt) AS total_web_return_amt,
    SUM(wr.web_return_qty) AS total_web_return_qty,
    MAX(inv.total_inventory_qty) AS total_inventory_qty,
    (SUM(sr.store_return_qty) * 1.0 / NULLIF(MAX(inv.total_inventory_qty), 0)) AS store_return_inventory_ratio,
    (SUM(wr.web_return_qty) * 1.0 / NULLIF(MAX(inv.total_inventory_qty), 0)) AS web_return_inventory_ratio,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    AVG(s.s_floor_space) AS avg_floor_space,
    AVG(s.s_number_employees) AS avg_employees
FROM date_dim d
JOIN sr ON sr.date_sk = d.d_date_sk
JOIN store s ON s.s_store_sk = sr.store_sk
JOIN wr ON wr.date_sk = d.d_date_sk
JOIN inv ON inv.date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2025
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_market_id,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
HAVING SUM(sr.store_return_amt) > 10000
ORDER BY d.d_year DESC, d.d_quarter_name, s.s_state
