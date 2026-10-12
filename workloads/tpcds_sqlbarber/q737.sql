SELECT it.i_brand, SUM(inv.inv_quantity_on_hand) AS total_quantity
FROM inventory inv
JOIN item it ON inv.inv_item_sk = it.i_item_sk
WHERE inv.inv_date_sk = 2451004 AND it.i_current_price > 0.87
GROUP BY it.i_brand
ORDER BY total_quantity DESC
