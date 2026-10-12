WITH sales_agg AS (
    SELECT
        ca_state,
        ca_city,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        AVG(ss_quantity) AS avg_quantity
    FROM store_sales
    JOIN customer_address ON store_sales.ss_addr_sk = customer_address.ca_address_sk
    WHERE ca_gmt_offset = -5.00
      AND ss_net_profit > 0
    GROUP BY ca_state, ca_city
),
inventory_agg AS (
    SELECT
        w_state,
        w_city,
        SUM(inv_quantity_on_hand) AS total_inventory,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    JOIN warehouse ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE w_country = 'United States'
    GROUP BY w_state, w_city
)
SELECT
    'sales' AS source,
    ca_state AS state,
    ca_city AS city,
    total_net_profit,
    total_net_paid,
    distinct_customers,
    avg_quantity,
    NULL AS total_inventory,
    NULL AS avg_inventory,
    NULL AS distinct_items
FROM sales_agg
UNION ALL
SELECT
    'inventory' AS source,
    w_state AS state,
    w_city AS city,
    NULL,
    NULL,
    NULL,
    NULL,
    total_inventory,
    avg_inventory,
    distinct_items
FROM inventory_agg
ORDER BY source, state, city
