WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS daily_qty,
        LAG(SUM(inv_quantity_on_hand)) OVER (PARTITION BY inv_warehouse_sk ORDER BY inv_date_sk) AS prev_daily_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    SUM(ia.daily_qty) AS total_qty,
    AVG(ia.daily_qty) AS avg_daily_qty,
    SUM(CASE WHEN ia.prev_daily_qty IS NOT NULL THEN ia.daily_qty - ia.prev_daily_qty ELSE 0 END) AS total_qty_change,
    COUNT(DISTINCT ia.inv_date_sk) AS active_days,
    RANK() OVER (ORDER BY SUM(ia.daily_qty) DESC) AS warehouse_rank
FROM inv_agg ia
JOIN warehouse w
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
WHERE ia.daily_qty > 0
  AND EXISTS (
      SELECT 1
      FROM call_center cc
      WHERE cc.cc_city = w.w_city
        AND cc.cc_class = 'large'
  )
  AND EXISTS (
      SELECT 1
      FROM web_site ws
      WHERE ws.web_city = w.w_city
        AND ws.web_open_date_sk <= ia.inv_date_sk
        AND (ws.web_close_date_sk IS NULL OR ia.inv_date_sk <= ws.web_close_date_sk)
  )
GROUP BY w.w_warehouse_id, w.w_city, w.w_state
HAVING SUM(ia.daily_qty) > 5000
ORDER BY total_qty DESC
LIMIT 10
