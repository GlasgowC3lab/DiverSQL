WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        t.t_hour,
        cs.cs_order_number,
        cs.cs_sales_price AS catalog_sales_price,
        cs.cs_ext_discount_amt AS catalog_discount,
        ss.ss_sales_price AS store_sales_price,
        ss.ss_quantity,
        i.inv_quantity_on_hand,
        ws.web_name
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.web_name LIKE '%Shop%'
),
set_a AS (
    SELECT DISTINCT s_store_sk FROM base WHERE cd_gender = 'M'
),
set_b AS (
    SELECT DISTINCT s_store_sk FROM base WHERE cd_gender = 'F'
),
union_set AS (
    SELECT
        s_store_sk,
        s_store_name,
        cs_order_number,
        catalog_sales_price,
        store_sales_price,
        ss_quantity
    FROM base
    WHERE s_state = 'CA'
    UNION
    SELECT
        s_store_sk,
        s_store_name,
        cs_order_number,
        catalog_sales_price,
        store_sales_price,
        ss_quantity
    FROM base
    WHERE s_state = 'NY'
),
avg_price AS (
    SELECT AVG(catalog_sales_price) AS overall_avg_price FROM base
)
SELECT
    u.s_store_name,
    u.s_store_sk,
    SUM(u.catalog_sales_price) AS total_catalog_sales,
    AVG(u.store_sales_price) AS avg_store_sales,
    COUNT(DISTINCT u.cs_order_number) AS distinct_orders,
    MIN(u.catalog_sales_price) AS min_catalog_sales,
    MAX(u.catalog_sales_price) AS max_catalog_sales,
    CASE WHEN SUM(u.catalog_sales_price) > (SELECT overall_avg_price FROM avg_price)
         THEN 'Above Avg'
         ELSE 'Below Avg'
    END AS sales_category,
    (SELECT COUNT(*) FROM set_a) AS male_store_count,
    (SELECT COUNT(*) FROM set_b) AS female_store_count
FROM union_set u
WHERE u.s_store_sk IN (
    SELECT s_store_sk FROM store WHERE s_state = 'CA'
    EXCEPT
    SELECT s_store_sk FROM store WHERE s_number_employees > 500
)
GROUP BY u.s_store_name, u.s_store_sk
ORDER BY total_catalog_sales DESC
LIMIT 100
