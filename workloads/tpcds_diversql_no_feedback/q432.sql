WITH sales_agg AS (
    SELECT
        cs_catalog_page_sk,
        SUM(cs_ext_sales_price) AS total_sales_price,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales
    WHERE
        cs_net_profit > 0
        AND cs_ext_list_price > 1000
        AND cs_quantity BETWEEN 1 AND 5
        AND cs_ext_discount_amt < 500
        AND cs_ship_mode_sk IS NOT NULL
        AND cs_wholesale_cost > 20
    GROUP BY cs_catalog_page_sk
    HAVING SUM(cs_ext_sales_price) > 5000
),
joined AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_end_date_sk,
        sa.total_sales_price,
        sa.avg_profit,
        sa.sales_cnt
    FROM tpcds.catalog_page cp
    JOIN sales_agg sa
        ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cp.cp_department IN ('Sports', 'Books', 'Home')
        AND cp.cp_catalog_number IN (4, 12, 16)
        AND cp.cp_end_date_sk BETWEEN 2450844 AND 2450996
        AND cp.cp_catalog_page_number >= 9
        AND cp.cp_type = 'Standard'
        AND cp.cp_description IS NOT NULL
),
dept_agg AS (
    SELECT
        cp_department,
        SUM(total_sales_price) AS dept_total_sales,
        AVG(avg_profit) AS dept_avg_profit
    FROM joined
    GROUP BY cp_department
    HAVING SUM(total_sales_price) > 20000
)
SELECT
    j.cp_department,
    j.cp_catalog_page_id,
    j.cp_catalog_number,
    j.total_sales_price,
    j.avg_profit,
    j.sales_cnt,
    d.dept_total_sales,
    d.dept_avg_profit,
    ROW_NUMBER() OVER (PARTITION BY j.cp_department ORDER BY j.total_sales_price DESC) AS rank_within_dept
FROM joined j
JOIN dept_agg d
    ON j.cp_department = d.cp_department
ORDER BY j.cp_department, rank_within_dept
LIMIT 100
