WITH inventory_by_warehouse AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS warehouse_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
),
state_customer AS (
    SELECT ca_state,
           COUNT(DISTINCT ca_address_sk) AS cust_cnt
    FROM customer_address
    WHERE ca_country = 'United States'
      AND ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    GROUP BY ca_state
)
SELECT sc.ca_state,
       sc.cust_cnt,
       SUM(iw.warehouse_qty) AS total_inventory_qty,
       AVG(iw.warehouse_qty) AS avg_inventory_per_warehouse,
       RANK() OVER (ORDER BY SUM(iw.warehouse_qty) DESC) AS inventory_rank
FROM state_customer sc
JOIN inventory_by_warehouse iw ON TRUE
GROUP BY sc.ca_state, sc.cust_cnt
HAVING SUM(iw.warehouse_qty) > 10000
ORDER BY inventory_rank
LIMIT 10
