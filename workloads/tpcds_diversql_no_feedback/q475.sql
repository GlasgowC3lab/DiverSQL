SELECT
    d.d_year,
    s.s_store_id,
    s.s_state,
    cd.cd_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MIN(i.inv_quantity_on_hand) AS min_inventory_qty
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 1998
  AND t.t_hour BETWEEN 9 AND 17
  AND s.s_state = 'TX'
  AND cd.cd_gender = 'M'
  AND cs.cs_wholesale_cost > 50
  AND i.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_item_sk = ss.ss_item_sk
          AND i2.inv_date_sk = d.d_date_sk
          AND i2.inv_quantity_on_hand > 0
      )
GROUP BY d.d_year, s.s_store_id, s.s_state, cd.cd_gender
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_paid DESC
LIMIT 100
