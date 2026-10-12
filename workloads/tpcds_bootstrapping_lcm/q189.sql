WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sale.d_date AS sale_date,
        d_sale.d_date_sk,
        t.t_hour,
        t.t_meal_time,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status,
        d_store_closed.d_date AS store_closed_date
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sale.d_date,
        d_sale.d_date_sk,
        t.t_hour,
        t.t_meal_time,
        s.s_closed_date_sk,
        d_store_closed.d_date
),
wp_creation_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        AVG(wp.wp_char_count) AS avg_chars_created
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),
wp_access_agg AS (
    SELECT
        d.d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed,
        AVG(wp.wp_char_count) AS avg_chars_accessed
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.sale_date,
    sa.t_hour,
    sa.t_meal_time,
    sa.total_sales,
    sa.total_profit,
    sa.avg_discount,
    sa.distinct_tickets,
    COALESCE(wc.pages_created, 0) AS pages_created,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed,
    COALESCE(wc.avg_chars_created, 0) AS avg_chars_created,
    COALESCE(wa.avg_chars_accessed, 0) AS avg_chars_accessed,
    sa.store_status,
    sa.store_closed_date,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_id ORDER BY sa.total_sales DESC) AS sales_rank
FROM sales_agg sa
LEFT JOIN wp_creation_agg wc
    ON sa.d_date_sk = wc.d_date_sk
LEFT JOIN wp_access_agg wa
    ON sa.d_date_sk = wa.d_date_sk
ORDER BY sa.total_sales DESC
LIMIT 100
