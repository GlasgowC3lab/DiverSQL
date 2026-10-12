WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cc.cc_name,
        p.p_promo_name,
        c.c_email_address,
        c.c_customer_sk,
        t.t_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
      AND p.p_promo_name LIKE 'Summer%'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
)
SELECT
    concat(fc.cc_name, ' - ', fc.p_promo_name) AS center_promo,
    CASE WHEN fc.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END AS revenue_category,
    substring(cast(fc.t_hour AS varchar), 1, 1) AS hour_first_digit,
    sum(fc.cs_net_paid) AS total_net_paid,
    avg(fc.cs_ext_discount_amt) AS avg_discount,
    count(DISTINCT fc.c_customer_sk) AS unique_customers,
    regexp_extract(fc.c_email_address, '@(.+)$', 1) AS email_domain
FROM filtered_sales fc
GROUP BY
    concat(fc.cc_name, ' - ', fc.p_promo_name),
    CASE WHEN fc.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END,
    substring(cast(fc.t_hour AS varchar), 1, 1),
    regexp_extract(fc.c_email_address, '@(.+)$', 1)
ORDER BY total_net_paid DESC
LIMIT 100
