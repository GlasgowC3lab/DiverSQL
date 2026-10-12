WITH inv_agg AS (
    SELECT
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    GROUP BY i.inv_date_sk
),
cust_agg AS (
    SELECT
        c.c_first_shipto_date_sk AS date_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
        COUNT(DISTINCT c.c_login) AS distinct_logins
    FROM customer c
    GROUP BY c.c_first_shipto_date_sk
),
cust_sales_diff AS (
    SELECT
        c.c_first_shipto_date_sk AS date_sk,
        AVG(date_diff('day', ds.d_date, ds2.d_date)) AS avg_days_between_shipto_and_sales
    FROM customer c
    JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN date_dim ds2 ON c.c_first_sales_date_sk = ds2.d_date_sk
    GROUP BY c.c_first_shipto_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_year.d_year AS calendar_year,
    d_year.d_month_seq AS month_seq,
    inv_agg.total_quantity,
    inv_agg.distinct_items,
    cust_agg.customer_cnt,
    cust_agg.distinct_logins,
    csd.avg_days_between_shipto_and_sales,
    cc.cc_tax_percentage * s.s_tax_percentage AS combined_tax_factor,
    CASE
        WHEN cc.cc_tax_percentage > s.s_tax_percentage THEN 'CC_Higher_Tax'
        WHEN cc.cc_tax_percentage < s.s_tax_percentage THEN 'Store_Higher_Tax'
        ELSE 'Equal_Tax'
    END AS tax_comparison,
    CONCAT(cc.cc_name, ' - ', s.s_store_name) AS cc_store_concat
FROM call_center cc
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_close.d_date_sk
JOIN date_dim d_year ON s.s_closed_date_sk = d_year.d_date_sk
JOIN inv_agg ON inv_agg.inv_date_sk = d_year.d_date_sk
JOIN cust_agg ON cust_agg.date_sk = d_year.d_date_sk
JOIN cust_sales_diff csd ON csd.date_sk = d_year.d_date_sk
WHERE d_year.d_year BETWEEN 1995 AND 2000
ORDER BY inv_agg.total_quantity DESC
LIMIT 100
