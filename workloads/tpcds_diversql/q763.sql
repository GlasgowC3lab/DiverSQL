WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        ws.ws_net_profit,
        ws.ws_ship_addr_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        wp.wp_type,
        wp.wp_url,
        wp.wp_link_count,
        wsit.web_company_id,
        wsit.web_name
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_ship_addr_sk IN (
            SELECT ca_address_sk FROM customer_address WHERE ca_country = 'United States'
        )
      AND ws.ws_ship_date_sk BETWEEN 2451900 AND 2452500
      AND ws.ws_coupon_amt > 500
      AND wsit.web_company_id IN (1, 2, 3)
      AND wp.wp_link_count >= 5
      AND ca.ca_state = 'TX'
)
SELECT *
FROM (
    -- Detailed rows with window rank and correlated sub‑query
    SELECT
        fs.ws_order_number,
        fs.ws_sold_date_sk,
        fs.ws_ext_sales_price AS metric_sales_price,
        fs.ws_coupon_amt,
        fs.ws_net_profit,
        fs.ca_city,
        fs.wp_url,
        fs.web_name,
        CASE WHEN fs.ws_coupon_amt > 1000 THEN 'High' ELSE 'Low' END AS coupon_level,
        ROW_NUMBER() OVER (PARTITION BY fs.web_company_id ORDER BY fs.ws_ext_sales_price DESC) AS sales_rank_company,
        (
            SELECT SUM(ws3.ws_ext_sales_price)
            FROM web_sales ws3
            WHERE ws3.ws_bill_addr_sk = fs.ws_bill_addr_sk
        ) AS total_sales_by_bill_addr,
        fs.web_company_id,
        fs.wp_type,
        NULL AS size_category
    FROM filtered_sales fs
    WHERE fs.ws_ext_sales_price > 0

    UNION DISTINCT

    -- Subtotals and grand total using ROLLUP
    SELECT
        NULL AS ws_order_number,
        NULL AS ws_sold_date_sk,
        SUM(fs.ws_ext_sales_price) AS metric_sales_price,
        NULL AS ws_coupon_amt,
        SUM(fs.ws_net_profit) AS ws_net_profit,
        NULL AS ca_city,
        NULL AS wp_url,
        NULL AS web_name,
        NULL AS coupon_level,
        NULL AS sales_rank_company,
        NULL AS total_sales_by_bill_addr,
        fs.web_company_id,
        fs.wp_type,
        CASE WHEN SUM(fs.ws_ext_sales_price) > 100000 THEN 'Big' ELSE 'Small' END AS size_category
    FROM filtered_sales fs
    GROUP BY ROLLUP (fs.web_company_id, fs.wp_type)
) AS u
ORDER BY metric_sales_price DESC NULLS LAST, ws_order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
