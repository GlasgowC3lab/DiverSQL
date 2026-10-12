WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_wholesale_cost) AS total_wholesale,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk
),
wp_creation_counts AS (
    SELECT
        wp_creation_date_sk AS date_sk,
        COUNT(DISTINCT wp_web_page_sk) AS creation_pages
    FROM web_page
    GROUP BY wp_creation_date_sk
),
wp_access_counts AS (
    SELECT
        wp_access_date_sk AS date_sk,
        COUNT(DISTINCT wp_web_page_sk) AS access_pages
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d_sale.d_date,
    d_sale.d_year,
    d_sale.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_category,
    i.i_brand,
    agg.total_sales,
    agg.total_quantity,
    agg.avg_sales_price,
    agg.total_profit,
    COALESCE(cr.creation_pages, 0) AS creation_pages,
    COALESCE(ac.access_pages, 0) AS access_pages,
    CASE WHEN agg.total_sales = 0 THEN NULL ELSE agg.total_wholesale / agg.total_sales END AS wholesale_to_sales_ratio,
    RANK() OVER (PARTITION BY d_sale.d_year ORDER BY agg.total_sales DESC) AS yearly_sales_rank
FROM sales_agg agg
JOIN date_dim d_sale
    ON agg.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s
    ON agg.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN item i
    ON agg.ss_item_sk = i.i_item_sk
LEFT JOIN wp_creation_counts cr
    ON d_sale.d_date_sk = cr.date_sk
LEFT JOIN wp_access_counts ac
    ON d_sale.d_date_sk = ac.date_sk
WHERE (s.s_closed_date_sk IS NULL OR d_sale.d_date <= d_closed.d_date)
  AND d_sale.d_year = 2022
  AND s.s_state = 'CA'
ORDER BY agg.total_sales DESC
LIMIT 100
