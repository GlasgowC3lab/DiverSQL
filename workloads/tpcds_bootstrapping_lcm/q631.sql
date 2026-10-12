WITH wp_creation AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           SUM(wp_image_count) AS total_image_count
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access AS (
    SELECT wp_access_date_sk AS d_date_sk,
           SUM(wp_link_count) AS total_link_count
    FROM web_page
    GROUP BY wp_access_date_sk
),
sales_agg AS (
    SELECT
        d_sales.d_current_year,
        d_sales.d_current_month,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_wholesale_cost) AS total_wholesale_cost,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(wc.total_image_count, 0)) AS total_image_count_creation,
        SUM(COALESCE(wa.total_link_count, 0)) AS total_link_count_access,
        MAX(CASE WHEN d_closed.d_date_sk = d_sales.d_date_sk THEN 1 ELSE 0 END) AS store_closed_on_sale_date
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN wp_creation wc ON wc.d_date_sk = d_sales.d_date_sk
    LEFT JOIN wp_access wa ON wa.d_date_sk = d_sales.d_date_sk
    GROUP BY
        d_sales.d_current_year,
        d_sales.d_current_month,
        s.s_store_sk,
        s.s_store_name,
        s.s_city
)
SELECT
    sagg.d_current_year,
    sagg.d_current_month,
    sagg.s_store_name,
    sagg.s_city,
    sagg.distinct_items_sold,
    sagg.total_sales,
    sagg.avg_discount,
    sagg.total_wholesale_cost,
    sagg.total_net_profit,
    sagg.total_image_count_creation,
    sagg.total_link_count_access,
    sagg.store_closed_on_sale_date,
    RANK() OVER (PARTITION BY sagg.d_current_year, sagg.d_current_month ORDER BY sagg.total_sales DESC) AS sales_rank
FROM sales_agg sagg
ORDER BY sagg.d_current_year, sagg.d_current_month, sales_rank
LIMIT 100
