WITH catalog_agg AS (
    SELECT
        c.c_customer_sk,
        cp.cp_department,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(cs.cs_order_number) AS sales_orders
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                              AND sr.sr_addr_sk = ca.ca_address_sk
    WHERE cp.cp_department IN ('Books', 'Electronics')
      AND ca.ca_state = 'CA'
      AND cs.cs_coupon_amt > 100
      AND sr.sr_return_amt > 0
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, cp.cp_department),
        (c.c_customer_sk)
    )
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_class = 'Unknown'
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
      AND ws.ws_net_paid > 50
      AND wsite.web_suite_number LIKE 'Suite %'
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, ws.ws_web_site_sk),
        (c.c_customer_sk)
    )
),
intersect_keys AS (
    SELECT c_customer_sk FROM catalog_agg WHERE total_sales > 5000
    INTERSECT
    SELECT c_customer_sk FROM web_agg WHERE total_web_sales > 3000
)
SELECT
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    ic.total_sales,
    ic.total_returns,
    iw.total_web_sales
FROM intersect_keys ik
JOIN customer c ON ik.c_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_agg ic ON ic.c_customer_sk = c.c_customer_sk AND ic.total_sales IS NOT NULL
LEFT JOIN web_agg iw ON iw.c_customer_sk = c.c_customer_sk AND iw.total_web_sales IS NOT NULL
ORDER BY ic.total_sales DESC NULLS LAST, iw.total_web_sales DESC NULLS LAST
LIMIT 100
