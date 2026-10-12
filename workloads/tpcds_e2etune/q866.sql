WITH inv_wp_agg AS (
    SELECT i.inv_warehouse_sk,
           wp.wp_type,
           i.inv_date_sk,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
           AVG(i.inv_quantity_on_hand) AS avg_qty
    FROM inventory i
    JOIN web_page wp
      ON i.inv_date_sk = wp.wp_creation_date_sk
    WHERE i.inv_quantity_on_hand BETWEEN 200 AND 900
      AND wp.wp_type IS NOT NULL
    GROUP BY i.inv_warehouse_sk, wp.wp_type, i.inv_date_sk
)
SELECT a.inv_warehouse_sk,
       a.wp_type,
       a.inv_date_sk,
       a.total_qty,
       a.page_cnt,
       a.avg_qty,
       (a.total_qty * 1.0 / a.page_cnt) AS qty_per_page,
       RANK() OVER (PARTITION BY a.wp_type ORDER BY (a.total_qty * 1.0 / a.page_cnt) DESC) AS rank_by_type,
       (SELECT r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_desc LIKE '%product%'
        ORDER BY r.r_reason_id
        LIMIT 1) AS example_reason
FROM inv_wp_agg a
WHERE a.total_qty > 500
ORDER BY qty_per_page DESC
LIMIT 50
