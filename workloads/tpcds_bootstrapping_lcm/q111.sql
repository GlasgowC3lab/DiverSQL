WITH
    -- Alias for the sold date dimension
    d_sold AS (
        SELECT *
        FROM date_dim
    ),
    -- Alias for the ship date dimension
    d_ship AS (
        SELECT *
        FROM date_dim
    )
SELECT
    d_sold.d_year                                   AS sold_year,
    d_sold.d_month_seq                              AS sold_month,
    s.s_state                                       AS store_state,
    s.s_market_desc                                 AS market_description,
    COUNT(DISTINCT cs.cs_order_number)              AS distinct_orders,
    SUM(cs.cs_net_paid)                             AS total_net_paid,
    SUM(cs.cs_net_profit)                           AS total_net_profit,
    AVG(cs.cs_sales_price)                          AS avg_sales_price,
    SUM(cs.cs_ext_discount_amt)                     AS total_discount_amount,
    COUNT(DISTINCT cd.cd_demo_sk)                   AS distinct_customer_demographics,
    AVG(CASE WHEN wp.wp_type = 'home' THEN wp.wp_char_count END)          AS avg_home_page_char_count,
    SUM(CASE WHEN wp.wp_type = 'product' THEN cs.cs_ext_sales_price ELSE 0 END) AS product_page_sales
FROM catalog_sales cs
JOIN d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND wp.wp_type IN ('home', 'product')
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    s.s_market_desc
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
