SELECT
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_moy AS ship_month,
    wp.wp_type,
    d_create.d_date AS page_creation_date,
    d_access.d_date AS page_access_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_create
    ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_moy,
    wp.wp_type,
    d_create.d_date,
    d_access.d_date
ORDER BY total_net_paid DESC
LIMIT 100
