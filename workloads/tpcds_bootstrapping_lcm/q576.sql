SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    floor(t_sold.t_hour / 6) AS hour_bucket,
    wp.wp_type,
    CASE WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(*) AS sales_transactions,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_ext_wholesale_cost) AS total_wholesale_cost,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0)) * 100 AS profit_margin_percent,
    AVG(cs.cs_quantity) AS avg_quantity_per_txn,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    AVG(CASE WHEN cs.cs_ext_sales_price > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_sales_price END) AS avg_discount_rate,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS coupon_usage_rate
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ship.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    floor(t_sold.t_hour / 6),
    wp.wp_type,
    CASE WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
