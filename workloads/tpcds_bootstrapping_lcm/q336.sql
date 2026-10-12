WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_division_name,
        d_sold.d_year AS sold_year,
        d_ship.d_month_seq AS ship_month_seq,
        wp.wp_type,
        d_wc.d_year AS page_creation_year,
        d_wa.d_year AS page_access_year,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        AVG(DATE_DIFF('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        AVG(DATE_DIFF('day', d_wc.d_date, d_wa.d_date)) AS avg_page_access_delay
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_wc ON wp.wp_creation_date_sk = d_wc.d_date_sk
    JOIN date_dim d_wa ON wp.wp_access_date_sk = d_wa.d_date_sk
    WHERE d_sold.d_year BETWEEN 2020 AND 2022
    GROUP BY s.s_store_id, s.s_division_name,
        d_sold.d_year, d_ship.d_month_seq, wp.wp_type,
        d_wc.d_year, d_wa.d_year
)
SELECT
    s_store_id,
    s_division_name,
    sold_year,
    ship_month_seq,
    wp_type,
    page_creation_year,
    page_access_year,
    num_orders,
    total_net_paid,
    avg_net_profit,
    avg_days_to_ship,
    avg_page_access_delay,
    ROW_NUMBER() OVER (PARTITION BY s_division_name ORDER BY total_net_paid DESC) AS division_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
