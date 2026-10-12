WITH unified_sales AS (
    SELECT
        td.t_hour,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        'store' AS sales_channel,
        CAST(NULL AS varchar) AS call_center_name,
        CAST(NULL AS integer) AS catalog_page_number,
        CAST(NULL AS decimal(7,2)) AS discount_amt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT
        td.t_hour,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        'catalog' AS sales_channel,
        cc.cc_name AS call_center_name,
        cp.cp_catalog_page_number AS catalog_page_number,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'Promotion'
),
aggregated AS (
    SELECT
        t_hour,
        sales_channel,
        call_center_name,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        AVG(quantity) AS avg_quantity,
        CASE WHEN sales_channel = 'catalog' THEN AVG(discount_amt) END AS avg_discount
    FROM unified_sales
    GROUP BY t_hour, sales_channel, call_center_name
)
SELECT
    t_hour,
    sales_channel,
    call_center_name,
    distinct_customers,
    total_net_paid,
    total_net_profit,
    avg_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY sales_channel ORDER BY total_net_paid DESC) AS net_paid_rank
FROM aggregated
ORDER BY t_hour, sales_channel
