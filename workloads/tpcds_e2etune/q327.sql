WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_quantity
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND w.w_gmt_offset BETWEEN -5 AND -3
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state
)
SELECT
    wi.w_warehouse_id,
    wi.w_city,
    wi.w_state,
    wi.total_quantity,
    wi.distinct_items,
    wi.avg_quantity,
    (
        SELECT COUNT(*)
        FROM customer c
        JOIN customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND cd.cd_credit_rating = 'A'
          AND cd.cd_gender = CASE WHEN wi.w_state = 'CA' THEN 'M' ELSE 'F' END
    ) AS preferred_customers_by_gender
FROM warehouse_inventory wi
ORDER BY wi.total_quantity DESC
LIMIT 10
