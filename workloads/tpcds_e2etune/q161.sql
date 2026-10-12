WITH cp_inventory AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_catalog_number,
           cp.cp_type,
           cp.cp_start_date_sk,
           cp.cp_end_date_sk,
           r.r_reason_desc,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           COUNT(*) AS inv_cnt,
           AVG(i.inv_quantity_on_hand) AS avg_qty
    FROM catalog_page cp
    JOIN inventory i
      ON i.inv_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    JOIN reason r
      ON i.inv_item_sk = r.r_reason_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND i.inv_quantity_on_hand > 0
    GROUP BY cp.cp_catalog_page_id,
             cp.cp_catalog_number,
             cp.cp_type,
             cp.cp_start_date_sk,
             cp.cp_end_date_sk,
             r.r_reason_desc
    HAVING SUM(i.inv_quantity_on_hand) > 500
)
SELECT cp_inventory.*, 
       date_add('day', cp_inventory.cp_start_date_sk, DATE '1970-01-01') AS start_date,
       date_add('day', cp_inventory.cp_end_date_sk, DATE '1970-01-01') AS end_date,
       cp_inventory.total_qty / type_total.total_qty AS pct_of_type_total,
       RANK() OVER (PARTITION BY cp_inventory.cp_type ORDER BY cp_inventory.total_qty DESC) AS type_rank
FROM cp_inventory
JOIN (
    SELECT cp_type, SUM(total_qty) AS total_qty
    FROM cp_inventory
    GROUP BY cp_type
) AS type_total
  ON cp_inventory.cp_type = type_total.cp_type
ORDER BY cp_inventory.cp_type, type_rank
LIMIT 100
