SELECT ws.web_name,
       d.d_year,
       SUM(i.inv_quantity_on_hand) AS total_quantity,
       COUNT(DISTINCT i.inv_item_sk) AS distinct_items
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 1936 AND ws.web_state = 'LA'
GROUP BY ws.web_name, d.d_year
