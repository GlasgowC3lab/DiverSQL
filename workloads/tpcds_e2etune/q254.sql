SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT i.i_item_sk) AS num_items,
    SUM(i.i_wholesale_cost) AS total_wholesale_cost,
    AVG(i.i_current_price) AS avg_current_price,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_product_pages,
    ROW_NUMBER() OVER (ORDER BY SUM(i.i_wholesale_cost) DESC) AS wholesale_cost_rank
FROM
    income_band ib
JOIN
    item i
      ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN
    web_page wp
      ON i.i_item_sk = wp.wp_web_page_sk
      AND wp.wp_type = 'product'
WHERE
    i.i_brand_id IN (5003002, 1001001, 3002001)
    AND i.i_size IN ('large', 'medium')
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING
    COUNT(DISTINCT i.i_item_sk) >= 10
ORDER BY
    total_wholesale_cost DESC
LIMIT 50
