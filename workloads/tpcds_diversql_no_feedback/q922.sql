WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        COUNT(*) AS inv_rows,
        SUM(inv_quantity_on_hand) AS total_quantity,
        AVG(inv_quantity_on_hand) AS avg_quantity,
        MIN(inv_quantity_on_hand) AS min_quantity,
        MAX(inv_quantity_on_hand) AS max_quantity
    FROM tpcds.inventory
    WHERE inv_item_sk IN (101440, 101446, 101425)
      AND inv_quantity_on_hand > 0
      AND inv_date_sk = 2451067
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_city,
    w.w_county,
    w.w_gmt_offset,
    SUM(iagg.total_quantity) AS sum_total_quantity,
    AVG(iagg.avg_quantity) AS avg_quantity_per_item,
    COUNT(DISTINCT iagg.inv_warehouse_sk) AS warehouse_cnt,
    MIN(iagg.min_quantity) AS overall_min_quantity,
    MAX(iagg.max_quantity) AS overall_max_quantity
FROM tpcds.warehouse w
JOIN inventory_agg iagg
      ON iagg.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_gmt_offset = -6.00
  AND w.w_street_name = 'Ash Laurel'
  AND w.w_county = 'Walker County'
  AND w.w_state = 'TX'
  AND w.w_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM tpcds.inventory i2
        WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
          AND i2.inv_quantity_on_hand > 0
    )
GROUP BY CUBE (w.w_city, w.w_county, w.w_gmt_offset)
HAVING SUM(iagg.total_quantity) > 0
ORDER BY sum_total_quantity DESC
LIMIT 100
