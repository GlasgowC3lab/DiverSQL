WITH
store_sales_agg AS (
    SELECT
        s.s_store_sk AS entity_id,
        s.s_store_name AS entity_name,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS uniq_transactions,
        'STORE' AS entity_type
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS
        ((s.s_store_sk, s.s_store_name, d.d_year),
         (s.s_store_sk, s.s_store_name))
),
web_sales_agg AS (
    SELECT
        wp.wp_web_page_sk AS entity_id,
        wp.wp_url AS entity_name,
        d.d_year AS year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS uniq_transactions,
        'WEB' AS entity_type
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS
        ((wp.wp_web_page_sk, wp.wp_url, d.d_year),
         (wp.wp_web_page_sk, wp.wp_url))
),
catalog_sales_agg AS (
    SELECT
        c.cc_call_center_sk AS entity_id,
        c.cc_name AS entity_name,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS uniq_transactions,
        'CATALOG' AS entity_type
    FROM catalog_sales cs
    JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS
        ((c.cc_call_center_sk, c.cc_name, d.d_year),
         (c.cc_call_center_sk, c.cc_name))
),
combined_agg AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
store_ids_from_sales AS (
    SELECT DISTINCT ss.ss_store_sk AS entity_id, 'STORE' AS entity_type
    FROM store_sales ss
    WHERE ss.ss_quantity > 1
),
store_agg_ids AS (
    SELECT DISTINCT entity_id, entity_type
    FROM combined_agg
    WHERE entity_type = 'STORE'
),
store_common AS (
    SELECT * FROM store_agg_ids
    INTERSECT
    SELECT * FROM store_ids_from_sales
),
customer_latest AS (
    SELECT
        customer_sk,
        latest_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY latest_sold_date_sk DESC) AS rn
    FROM (
        SELECT ss.ss_customer_sk AS customer_sk,
               MAX(ss.ss_sold_date_sk) AS latest_sold_date_sk
        FROM store_sales ss
        GROUP BY ss.ss_customer_sk
    ) sub
),
top_customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_email_address, '') AS email,
        LENGTH(TRIM(COALESCE(c.c_email_address, ''))) AS email_len,
        cl.latest_sold_date_sk
    FROM customer c
    LEFT JOIN customer_latest cl ON c.c_customer_sk = cl.customer_sk AND cl.rn = 1
    WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT
    ca.entity_type,
    ca.entity_id,
    ca.entity_name,
    ca.year,
    ca.total_net_paid,
    ca.total_net_profit,
    ca.avg_quantity,
    ca.uniq_transactions,
    CASE
        WHEN ca.total_net_paid = 0 THEN NULL
        ELSE ca.total_net_profit / ca.total_net_paid
    END AS profit_margin,
    CASE 
        WHEN ca.year IS NOT NULL 
             AND (ca.year % 4 = 0 AND (ca.year % 100 <> 0 OR ca.year % 400 = 0))
        THEN 'LEAP' 
        ELSE COALESCE(CAST(ca.year AS VARCHAR), 'UNKNOWN')
    END AS year_category,
    CONCAT(ca.entity_type, ':', COALESCE(ca.entity_name, 'N/A')) AS entity_label,
    ROW_NUMBER() OVER (PARTITION BY ca.entity_type ORDER BY ca.total_net_paid DESC) AS rn_entity,
    COUNT(*) OVER (PARTITION BY ca.entity_type) AS cnt_by_type,
    (SELECT MAX(total_net_paid) FROM combined_agg ca2 WHERE ca2.entity_type = ca.entity_type) AS max_total_net_paid_same_type,
    (SELECT COUNT(*) FROM top_customer_info tci WHERE tci.email_len > 10) AS top_customers_long_email,
    CASE 
        WHEN ca.entity_type = 'STORE' THEN 
            (SELECT COUNT(DISTINCT ss_customer_sk) FROM store_sales ss WHERE ss.ss_store_sk = ca.entity_id)
        WHEN ca.entity_type = 'WEB' THEN 
            (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_web_page_sk = ca.entity_id)
        WHEN ca.entity_type = 'CATALOG' THEN 
            (SELECT COUNT(DISTINCT cs_bill_customer_sk) FROM catalog_sales cs WHERE cs.cs_call_center_sk = ca.entity_id)
        ELSE NULL
    END AS unique_customer_count,
    COALESCE(
        (SELECT d.d_date FROM date_dim d WHERE d.d_year = ca.year ORDER BY d.d_date DESC LIMIT 1),
        DATE '1970-01-01'
    ) AS latest_date_in_year,
    CASE 
        WHEN ca.entity_name IS NULL THEN 'MISSING'
        WHEN LENGTH(ca.entity_name) > 20 THEN 'LONG'
        ELSE 'SHORT'
    END AS name_length_category,
    (SELECT SUM(cr.cr_return_quantity) FROM catalog_returns cr WHERE cr.cr_call_center_sk = ca.entity_id AND cr.cr_return_amount > 0) AS total_return_quantity
FROM combined_agg ca
LEFT JOIN store_common sc ON ca.entity_id = sc.entity_id AND ca.entity_type = sc.entity_type
WHERE (ca.entity_name IS NOT NULL OR ca.entity_type = 'CATALOG')
  AND (ca.total_net_paid > 1000 OR ca.total_net_profit < 0)
ORDER BY ca.entity_type, rn_entity
LIMIT 200
