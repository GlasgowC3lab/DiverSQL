WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
),
date_sold AS (
    SELECT
        d_date_sk,
        d_quarter_seq,
        d_year
    FROM date_dim
),
date_ship AS (
    SELECT
        d_date_sk,
        d_year
    FROM date_dim
),
store_join AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_closed_date_sk
    FROM store s
),
web_page_join AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_creation_date_sk
    FROM web_page wp
)
SELECT
    s.s_state,
    ds.d_quarter_seq,
    t.t_shift,
    COUNT(DISTINCT sa.cs_order_number) AS orders,
    SUM(sa.cs_net_profit) AS total_profit,
    SUM(sa.cs_net_paid) AS total_paid,
    AVG(sa.cs_ext_discount_amt) AS avg_discount,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_link_count) AS avg_links,
    AVG(t.t_hour) AS avg_hour,
    RANK() OVER (PARTITION BY ds.d_quarter_seq ORDER BY SUM(sa.cs_net_profit) DESC) AS profit_rank
FROM sales_agg sa
JOIN date_sold ds
    ON sa.cs_sold_date_sk = ds.d_date_sk
JOIN time_dim t
    ON sa.cs_sold_time_sk = t.t_time_sk
JOIN date_ship dsh
    ON sa.cs_ship_date_sk = dsh.d_date_sk
JOIN store_join s
    ON s.s_closed_date_sk = dsh.d_date_sk
JOIN web_page_join wp
    ON wp.wp_creation_date_sk = dsh.d_date_sk
WHERE ds.d_year = 2022
GROUP BY s.s_state, ds.d_quarter_seq, t.t_shift
HAVING SUM(sa.cs_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
