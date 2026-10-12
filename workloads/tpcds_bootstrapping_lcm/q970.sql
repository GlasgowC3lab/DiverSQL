WITH aggregated_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd_sales.d_year,
        dd_sales.d_month_seq,
        cd.cd_credit_rating,
        cd.cd_education_status,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim dd_sales
        ON ss.ss_sold_date_sk = dd_sales.d_date_sk
    JOIN date_dim dd_store
        ON s.s_closed_date_sk = dd_store.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = dd_sales.d_date_sk
    WHERE dd_store.d_year >= 2000
      AND dd_sales.d_year BETWEEN 2015 AND 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd_sales.d_year,
        dd_sales.d_month_seq,
        cd.cd_credit_rating,
        cd.cd_education_status
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_month_seq,
    cd_credit_rating,
    cd_education_status,
    total_sales,
    total_profit,
    avg_discount,
    distinct_web_pages_created,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS store_year_sales_rank,
    SUM(total_sales) OVER (
        PARTITION BY s_store_id
        ORDER BY d_year, d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_to_date
FROM aggregated_sales
ORDER BY total_sales DESC
LIMIT 100
