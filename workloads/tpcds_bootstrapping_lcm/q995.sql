SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    CASE
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 0 THEN 'OnTime'
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 2 THEN '1-2 Days'
        ELSE '3+ Days'
    END AS shipping_delay_bucket,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_list_price, 0)) AS avg_discount_rate,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND wp.wp_autogen_flag = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    CASE
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 0 THEN 'OnTime'
        WHEN date_diff('day', d_sold.d_date, d_ship.d_date) <= 2 THEN '1-2 Days'
        ELSE '3+ Days'
    END
HAVING SUM(cs.cs_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
