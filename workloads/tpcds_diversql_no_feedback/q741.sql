WITH page_year_agg AS (
  SELECT
    cp.cp_catalog_page_id,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND t.t_meal_time = 'dinner'
    AND i.i_units = 'Each'
    AND i.i_color = 'red'
    AND cp.cp_type = 'Catalog'
    AND ca.ca_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
    AND cr.cr_return_amount > 100
  GROUP BY cp.cp_catalog_page_id, d.d_year
),
year_summary AS (
  SELECT
    d_year,
    SUM(total_return_amount) AS year_total_return,
    AVG(total_return_amount) AS year_avg_return,
    SUM(total_inventory_qty) AS year_total_inventory
  FROM page_year_agg
  GROUP BY d_year
  HAVING SUM(total_return_amount) > 5000
)
SELECT
  p.cp_catalog_page_id,
  p.d_year,
  p.total_return_amount,
  p.return_cnt,
  p.total_inventory_qty,
  y.year_total_return,
  y.year_avg_return,
  p.total_return_amount / NULLIF(p.total_inventory_qty, 0) AS return_per_inventory
FROM page_year_agg p
JOIN year_summary y ON p.d_year = y.d_year
ORDER BY p.total_return_amount DESC
LIMIT 100
