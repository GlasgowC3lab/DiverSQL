WITH agg AS (
    SELECT
        d.d_year,
        s.s_state,
        w.web_mkt_id,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS unique_items,
        AVG(i.inv_quantity_on_hand) AS avg_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 2500 AND 2600
      AND i.inv_quantity_on_hand > 50
      AND s.s_state = 'CA'
      AND w.web_manager = 'Peter Cassidy'
      AND w.web_mkt_id IN (2, 3, 4)
      AND i.inv_warehouse_sk IN (SELECT web_site_sk FROM web_site WHERE web_mkt_id = 3)
    GROUP BY GROUPING SETS (
        (d.d_year, s.s_state, w.web_mkt_id),
        (d.d_year, s.s_state),
        (d.d_year)
    )
)
SELECT
    d_year,
    s_state,
    web_mkt_id,
    total_qty,
    unique_items,
    avg_qty,
    LAG(total_qty) OVER (PARTITION BY s_state ORDER BY d_year) AS prev_year_qty,
    SUM(total_qty) OVER (PARTITION BY s_state ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_qty
FROM agg
ORDER BY d_year, s_state
