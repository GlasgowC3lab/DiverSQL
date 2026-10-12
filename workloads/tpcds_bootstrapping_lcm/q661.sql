SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    dd.d_year,
    dd.d_moy AS month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_per_item,
    MAX(dd_ship.d_date) AS latest_ship_date,
    AVG(date_diff('day', dd.d_date, dd_ship.d_date)) AS avg_shipping_delay_days
FROM
    catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN date_dim dd_ship ON cs.cs_ship_date_sk = dd_ship.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
                 AND s.s_closed_date_sk = dd.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dd.d_date_sk
                     AND wp.wp_access_date_sk = dd.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    dd.d_year,
    dd.d_moy
