WITH returns_by_hour AS (
  SELECT
    t.t_hour,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS revenue_rank
  FROM web_returns wr
  JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 17
  GROUP BY t.t_hour
  HAVING COUNT(*) > 10
),
total_inventory AS (
  SELECT
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    AVG(i.inv_quantity_on_hand) AS avg_qty_per_item
  FROM inventory i
  JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_state = 'CA'
)
SELECT
  r.t_hour,
  r.return_cnt,
  r.total_return_amt,
  r.avg_return_amt,
  r.revenue_rank,
  ti.total_qty,
  ti.distinct_items,
  ti.avg_qty_per_item
FROM returns_by_hour r
CROSS JOIN total_inventory ti
ORDER BY r.total_return_amt DESC
LIMIT 100
