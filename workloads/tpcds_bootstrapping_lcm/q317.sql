WITH agg_sales AS (
    SELECT
        s.s_store_id,
        s.s_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        sm.sm_type,
        sm.sm_carrier,
        wp.wp_type,
        wp.wp_url,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        sm.sm_type,
        sm.sm_carrier,
        wp.wp_type,
        wp.wp_url
    HAVING SUM(cs.cs_net_paid) > 500
)
SELECT
    s_store_id,
    s_city,
    d_year,
    d_month_seq,
    sm_type,
    sm_carrier,
    wp_type,
    wp_url,
    total_net_paid,
    total_discount,
    avg_quantity,
    distinct_items,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_rank
FROM agg_sales
ORDER BY d_year, yearly_rank
LIMIT 200
