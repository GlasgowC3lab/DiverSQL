SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.wp_url,
    agg.sale_year,
    agg.sale_hour,
    agg.order_count,
    agg.total_net_paid,
    agg.avg_net_profit,
    agg.total_discount,
    agg.avg_days_to_ship,
    agg.avg_page_lifespan_days,
    agg.distinct_customers,
    RANK() OVER (PARTITION BY agg.sale_year ORDER BY agg.total_net_paid DESC) AS net_paid_rank_by_year
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        wp.wp_url,
        d_sold.d_year AS sale_year,
        t.t_hour AS sale_hour,
        COUNT(*) AS order_count,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        AVG(date_diff('day', d_sold.d_date, d_wp_access.d_date)) AS avg_page_lifespan_days,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
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
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_holiday = 'Y'
      AND s.s_market_id IS NOT NULL
      AND wp.wp_type = 'Home'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        wp.wp_url,
        d_sold.d_year,
        t.t_hour
    HAVING COUNT(*) > 5
) agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
