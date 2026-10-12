SELECT
    d_year,
    d_quarter_name,
    ship_month_seq,
    s_division_name,
    s_city,
    s_state,
    t_shift,
    t_meal_time,
    num_orders,
    total_net_paid,
    avg_discount_amt,
    total_quantity,
    total_sales_price,
    total_tax,
    distinct_pages_created,
    distinct_pages_accessed,
    ROW_NUMBER() OVER (PARTITION BY d_year, s_division_name ORDER BY total_net_paid DESC) AS division_year_rank
FROM (
    SELECT
        d_sold.d_year AS d_year,
        d_sold.d_quarter_name AS d_quarter_name,
        d_ship.d_month_seq AS ship_month_seq,
        s.s_division_name AS s_division_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        t.t_shift AS t_shift,
        t.t_meal_time AS t_meal_time,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_ext_tax) AS total_tax,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
        COUNT(DISTINCT CASE WHEN d_wp_access.d_date_sk IS NOT NULL THEN wp.wp_web_page_id END) AS distinct_pages_accessed
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_wp_access
      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
      AND t.t_meal_time = 'Evening'
    GROUP BY
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_ship.d_month_seq,
        s.s_division_name,
        s.s_city,
        s.s_state,
        t.t_shift,
        t.t_meal_time
    HAVING SUM(cs.cs_net_paid) > 10000
) AS agg
ORDER BY total_net_paid DESC
LIMIT 100
