SELECT
    date_dim.d_year,
    item.i_category,
    store.s_state,
    web_page.wp_type,
    SUM(inventory.inv_quantity_on_hand) AS total_quantity,
    SUM(item.i_current_price * inventory.inv_quantity_on_hand) AS total_retail_value,
    AVG(item.i_current_price) AS avg_price,
    COUNT(DISTINCT item.i_item_sk) AS distinct_items,
    SUM(CASE WHEN web_page.wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS auto_generated_pages
FROM date_dim
JOIN inventory ON inventory.inv_date_sk = date_dim.d_date_sk
JOIN item ON inventory.inv_item_sk = item.i_item_sk
JOIN store ON store.s_closed_date_sk = date_dim.d_date_sk
JOIN web_page ON web_page.wp_creation_date_sk = date_dim.d_date_sk
WHERE web_page.wp_access_date_sk = date_dim.d_date_sk
  AND date_dim.d_year BETWEEN 2015 AND 2020
GROUP BY ROLLUP (date_dim.d_year, item.i_category, store.s_state, web_page.wp_type)
HAVING SUM(inventory.inv_quantity_on_hand) > 0
ORDER BY total_quantity DESC
LIMIT 100
