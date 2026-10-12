WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_ext_discount_amt,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2020
      AND d.d_qoy = 2  -- second quarter
      AND t.t_hour BETWEEN 9 AND 17  -- business hours
      AND cs.cs_ext_tax > 20
      AND cs.cs_ext_discount_amt < 100
)
SELECT
    w.w_warehouse_name,
    fs.d_year,
    fs.d_month_seq,
    COUNT(DISTINCT fs.cs_bill_customer_sk) AS distinct_customers,
    SUM(fs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    AVG(fs.cs_net_profit) AS avg_net_profit,
    SUM(CASE WHEN hd.hd_income_band_sk >= 5 THEN fs.cs_net_paid_inc_ship_tax ELSE 0 END) /
        NULLIF(SUM(CASE WHEN hd.hd_income_band_sk >= 5 THEN 1 ELSE 0 END), 0) AS avg_net_paid_high_income,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages_accessed,
    RANK() OVER (PARTITION BY fs.d_month_seq ORDER BY SUM(fs.cs_net_paid_inc_ship_tax) DESC) AS warehouse_month_rank
FROM filtered_sales fs
JOIN warehouse w ON fs.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = fs.cs_bill_customer_sk
    AND wp.wp_creation_date_sk = fs.cs_sold_date_sk
GROUP BY w.w_warehouse_name, fs.d_year, fs.d_month_seq
ORDER BY fs.d_year, fs.d_month_seq, total_net_paid_inc_ship_tax DESC
LIMIT 50
