WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_email_address,
        c.c_current_hdemo_sk
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1960 AND 1990
)
,
sales_metrics AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid_inc_ship) AS metric_value
    FROM catalog_sales cs
    JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY cc.cc_call_center_id
)
,
web_metrics AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        'web_visits' AS metric_type,
        COUNT(wp.wp_web_page_sk) AS metric_value
    FROM web_page wp
    JOIN filtered_customers fc ON wp.wp_customer_sk = fc.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = fc.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE wp.wp_type = 'customer'
    GROUP BY cc.cc_call_center_id
)
SELECT call_center_id, metric_type, metric_value
FROM sales_metrics
UNION ALL
SELECT call_center_id, metric_type, metric_value
FROM web_metrics
ORDER BY call_center_id, metric_type
LIMIT 100
