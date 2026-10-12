SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month_seq,
    s.s_city AS store_city,
    cc.cc_city AS call_center_city,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    CASE
        WHEN cd.cd_credit_rating = 'Excellent' THEN 'Top'
        ELSE 'Other'
    END AS credit_bucket,
    COUNT(*) AS transaction_count,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0)) AS profit_margin,
    AVG(d_cc_open.d_year) AS avg_call_center_open_year
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND cc.cc_country = 'USA'
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_city,
    cc.cc_city,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE
        WHEN cd.cd_credit_rating = 'Excellent' THEN 'Top'
        ELSE 'Other'
    END
HAVING (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0)) > 0.01
ORDER BY profit_margin DESC
LIMIT 100
