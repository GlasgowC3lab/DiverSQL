WITH inv_band AS (
    SELECT i.inv_item_sk,
           i.inv_warehouse_sk,
           i.inv_date_sk,
           i.inv_quantity_on_hand,
           ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM inventory i
    JOIN income_band ib
      ON i.inv_quantity_on_hand >= ib.ib_lower_bound
     AND i.inv_quantity_on_hand < ib.ib_upper_bound
)
SELECT ca.ca_state,
       inv_band.ib_income_band_sk,
       COUNT(DISTINCT ca.ca_address_sk) AS address_cnt,
       SUM(inv_band.inv_quantity_on_hand) AS total_qty,
       AVG(inv_band.inv_quantity_on_hand) AS avg_qty,
       RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(inv_band.inv_quantity_on_hand) DESC) AS qty_rank
FROM inv_band
JOIN customer_address ca
  ON 1 = 1
WHERE ca.ca_country = 'United States'
  AND ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
GROUP BY ca.ca_state, inv_band.ib_income_band_sk
ORDER BY ca.ca_state, qty_rank
LIMIT 100
