WITH
  sub1 AS (
    SELECT
      s.s_state,
      d.d_year,
      SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND i.inv_warehouse_sk = 4
    GROUP BY CUBE(s.s_state, d.d_year)
  ),
  sub2 AS (
    SELECT
      s.s_state,
      d.d_year,
      SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.inv_warehouse_sk = 5
    GROUP BY CUBE(s.s_state, d.d_year)
  ),
  combined AS (
    SELECT s_state, d_year, total_qty FROM sub1
    UNION ALL
    SELECT s_state, d_year, total_qty FROM sub2
  ),
  ranked AS (
    SELECT
      s_state,
      d_year,
      total_qty,
      ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_qty DESC) AS rn
    FROM combined
  )
SELECT
  s_state,
  d_year,
  total_qty
FROM ranked
WHERE rn <= 5
ORDER BY s_state, d_year, total_qty DESC
LIMIT 100
