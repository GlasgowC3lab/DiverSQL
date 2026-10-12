WITH site_month_sales AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS month_net_paid,
        SUM(cs.cs_net_profit) AS month_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_discount_amt) AS month_discount_total,
        AVG(t.t_hour) AS avg_sale_hour
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY ws.web_site_sk, ws.web_name, d.d_year, d.d_month_seq
), site_total AS (
    SELECT
        web_site_sk,
        web_name,
        SUM(month_net_paid) AS total_net_paid,
        SUM(month_net_profit) AS total_net_profit,
        SUM(month_discount_total) AS total_discount,
        SUM(month_net_profit) / NULLIF(SUM(month_net_paid), 0) AS overall_profit_margin,
        SUM(distinct_customers) AS total_distinct_customers,
        AVG(avg_sale_hour) AS overall_avg_sale_hour
    FROM site_month_sales
    GROUP BY web_site_sk, web_name
), site_month_lag AS (
    SELECT
        sm.web_site_sk,
        sm.web_name,
        sm.d_year,
        sm.d_month_seq,
        sm.month_net_paid,
        LAG(sm.month_net_paid) OVER (PARTITION BY sm.web_site_sk ORDER BY sm.d_year, sm.d_month_seq) AS prev_month_net_paid
    FROM site_month_sales sm
), site_last_month AS (
    SELECT
        sm.web_site_sk,
        sm.prev_month_net_paid,
        ROW_NUMBER() OVER (PARTITION BY sm.web_site_sk ORDER BY sm.d_year DESC, sm.d_month_seq DESC) AS rn
    FROM site_month_lag sm
)
SELECT
    st.web_name,
    st.total_net_paid,
    st.total_net_profit,
    st.overall_profit_margin,
    st.total_distinct_customers,
    st.overall_avg_sale_hour,
    CASE 
        WHEN st.overall_profit_margin >= 0.30 THEN 'High Margin'
        WHEN st.overall_profit_margin >= 0.15 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS margin_category,
    DENSE_RANK() OVER (ORDER BY st.total_net_paid DESC) AS sales_rank,
    slm.prev_month_net_paid,
    (st.total_net_paid - COALESCE(slm.prev_month_net_paid, 0)) AS net_paid_change_from_last_month
FROM site_total st
LEFT JOIN site_last_month slm
  ON st.web_site_sk = slm.web_site_sk AND slm.rn = 1
ORDER BY st.total_net_paid DESC
LIMIT 20
