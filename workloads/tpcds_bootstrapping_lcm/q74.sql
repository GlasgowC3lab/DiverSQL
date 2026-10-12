SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_state,
    wp_create.wp_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wp_create.wp_web_page_sk) AS pages_created,
    COUNT(DISTINCT wp_access.wp_web_page_sk) AS pages_accessed,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 'No Sales'
        WHEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) >= 0.2 THEN 'High'
        WHEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) >= 0.1 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN inventory i
    ON i.inv_date_sk = d_sales.d_date_sk
JOIN web_page wp_create
    ON wp_create.wp_creation_date_sk = d_sales.d_date_sk
JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d_sales.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_state,
    wp_create.wp_type
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
    AND CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
            ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
        END > 0.1
ORDER BY total_sales DESC
LIMIT 100
