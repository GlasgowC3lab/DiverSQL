WITH city_inventory AS (
    SELECT
        cc.cc_city AS city,
        cc.cc_state AS state,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        AVG(i.inv_quantity_on_hand) AS avg_qty,
        COUNT(DISTINCT i.inv_warehouse_sk) AS wh_cnt,
        SUM(i.inv_quantity_on_hand * cc.cc_tax_percentage) AS tax_weighted_qty
    FROM call_center cc
    JOIN inventory i
        ON i.inv_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    WHERE cc.cc_state IN ('CA', 'TX', 'NY')
      AND cc.cc_mkt_id IN (2, 3, 5)
      AND i.inv_quantity_on_hand > 0
    GROUP BY cc.cc_city, cc.cc_state
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    city,
    state,
    total_qty,
    avg_qty,
    wh_cnt,
    tax_weighted_qty,
    RANK() OVER (ORDER BY total_qty DESC) AS city_rank
FROM city_inventory
ORDER BY total_qty DESC
LIMIT 50
