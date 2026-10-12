WITH item_pairs AS (
    SELECT
        i1.inv_item_sk,
        i1.inv_warehouse_sk AS warehouse_a,
        i2.inv_warehouse_sk AS warehouse_b,
        i1.inv_quantity_on_hand AS qty_a,
        i2.inv_quantity_on_hand AS qty_b
    FROM inventory i1
    JOIN inventory i2
      ON i1.inv_item_sk = i2.inv_item_sk
      AND i1.inv_warehouse_sk < i2.inv_warehouse_sk
    WHERE i1.inv_date_sk BETWEEN 2450815 AND 2451053
      AND i2.inv_date_sk BETWEEN 2450815 AND 2451053
)
SELECT *
FROM (
    SELECT
        ip.inv_item_sk,
        sm.sm_carrier,
        COUNT(*) AS pair_count,
        SUM(ip.qty_a) AS total_qty_a,
        SUM(ip.qty_b) AS total_qty_b,
        AVG(ip.qty_a) AS avg_qty_a,
        AVG(ip.qty_b) AS avg_qty_b,
        approx_percentile(ip.qty_a, 0.5) AS median_qty_a,
        approx_percentile(ip.qty_b, 0.5) AS median_qty_b,
        SUM(ip.qty_a) - SUM(ip.qty_b) AS qty_diff,
        ROW_NUMBER() OVER (PARTITION BY ip.inv_item_sk ORDER BY SUM(ip.qty_a) DESC) AS rank_by_qty_a
    FROM item_pairs ip
    JOIN ship_mode sm
      ON (ip.warehouse_a % 4) = CASE sm.sm_code
                                  WHEN 'AIR' THEN 0
                                  WHEN 'SURFACE' THEN 1
                                  WHEN 'SEA' THEN 2
                                  WHEN 'BIKE' THEN 3
                                  ELSE -1
                               END
    WHERE sm.sm_carrier IN ('UPS', 'FEDEX', 'USPS')
    GROUP BY ip.inv_item_sk, sm.sm_carrier
    HAVING COUNT(*) >= 2
) t
WHERE t.rank_by_qty_a <= 5
ORDER BY t.total_qty_a DESC
LIMIT 50
