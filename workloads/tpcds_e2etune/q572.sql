WITH cust_demo AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           COUNT(DISTINCT c_customer_sk) AS num_customers
    FROM customer
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE cd_gender = 'F' AND cd_marital_status = 'M' AND c_birth_year >= 1980
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
warehouse_inventory AS (
    SELECT w.w_warehouse_id,
           w.w_city,
           w.w_state,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           AVG(i.inv_quantity_on_hand) AS avg_qty,
           COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state
)
SELECT ranked.w_warehouse_id,
       ranked.w_city,
       ranked.w_state,
       ranked.total_qty,
       ranked.avg_qty,
       ranked.distinct_items,
       (SELECT SUM(num_customers) FROM cust_demo) AS total_female_married_customers,
       ranked.warehouse_rank
FROM (
    SELECT wi.*,
           ROW_NUMBER() OVER (ORDER BY wi.total_qty DESC) AS warehouse_rank
    FROM warehouse_inventory wi
) ranked
WHERE ranked.warehouse_rank <= 10
ORDER BY ranked.total_qty DESC
