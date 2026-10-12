SELECT sub.d_year,
       sub.i_category,
       sub.total_quantity,
       sub.avg_price
FROM (
    SELECT d.d_year,
           i.i_category,
           SUM(inv.inv_quantity_on_hand) AS total_quantity,
           AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1933
      AND w.w_state = 'IN'
    GROUP BY d.d_year, i.i_category
    HAVING SUM(inv.inv_quantity_on_hand) > 83
) sub
WHERE sub.avg_price < 2.77
