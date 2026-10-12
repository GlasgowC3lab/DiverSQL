WITH sr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
)
SELECT
    s.s_store_id,
    s.s_state,
    wp.wp_url,
    dd_ret.d_year AS return_year,
    dd_sold.d_year AS sold_year,
    dd_ship.d_year AS ship_year,
    SUM(sr.cs_net_paid) AS total_sales_net_paid,
    SUM(sr.cs_net_profit) AS total_sales_net_profit,
    SUM(sr.cr_net_loss) AS total_return_net_loss,
    COUNT(DISTINCT sr.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.cr_order_number) AS distinct_returns,
    AVG(sr.cs_quantity) AS avg_quantity,
    MAX(sr.cs_sales_price) AS max_sales_price,
    MIN(sr.cs_sales_price) AS min_sales_price,
    SUM(CASE WHEN dd_ret.d_quarter_seq = dd_sold.d_quarter_seq THEN sr.cs_ext_sales_price ELSE 0 END) AS same_quarter_sales,
    SUM(CASE WHEN dd_ret.d_year = dd_sold.d_year THEN sr.cs_ext_sales_price ELSE 0 END) AS same_year_sales,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sr.cs_net_paid) DESC) AS rn_store
FROM sr
JOIN date_dim dd_ret
    ON sr.cr_returned_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_sold
    ON sr.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON sr.cs_ship_date_sk = dd_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_wp_access
    ON wp.wp_access_date_sk = dd_wp_access.d_date_sk
WHERE dd_ret.d_year = 2020
  AND s.s_state = 'CA'
  AND wp.wp_type = 'home'
GROUP BY
    s.s_store_id,
    s.s_state,
    wp.wp_url,
    dd_ret.d_year,
    dd_sold.d_year,
    dd_ship.d_year
HAVING SUM(sr.cs_net_paid) > 10000
ORDER BY total_sales_net_paid DESC
LIMIT 100
