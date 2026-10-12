WITH inv_detail AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        d.d_date,
        d.d_quarter_seq,
        i.inv_quantity_on_hand,
        regexp_extract(d.d_date_id, '([A-Z]{2})$', 1) AS date_suffix,
        CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_label,
        SUBSTR(w.w_warehouse_name, 1, 3) AS warehouse_prefix
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_quarter_seq = 7
      AND w.w_warehouse_name LIKE '%WARE%'
      AND regexp_like(w.w_warehouse_name, '^.*[A-Z]{3}.*$')
      AND w.w_city LIKE '%Ville%'
)
SELECT
    w_state,
    warehouse_label,
    warehouse_prefix,
    date_suffix,
    SUM(inv_quantity_on_hand) AS total_qty,
    AVG(inv_quantity_on_hand) AS avg_qty,
    COUNT(DISTINCT d_date) AS distinct_days,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY SUM(inv_quantity_on_hand) DESC) AS state_qty_rank
FROM inv_detail
GROUP BY w_state, warehouse_label, warehouse_prefix, date_suffix
HAVING SUM(inv_quantity_on_hand) > 500
ORDER BY w_state, total_qty DESC
LIMIT 20
