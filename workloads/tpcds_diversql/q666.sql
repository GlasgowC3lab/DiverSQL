WITH
    agg_ws AS (
        SELECT
            ws_bill_customer_sk,
            ws_ship_customer_sk,
            ws_bill_addr_sk,
            ws_ship_addr_sk,
            ws_bill_cdemo_sk,
            ws_ship_cdemo_sk,
            ws_web_page_sk,
            ws_web_site_sk,
            ws_order_number,
            SUM(ws_ext_sales_price) AS total_sales,
            COUNT(*) AS order_cnt
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2451910 AND 2452000
        GROUP BY
            ws_bill_customer_sk,
            ws_ship_customer_sk,
            ws_bill_addr_sk,
            ws_ship_addr_sk,
            ws_bill_cdemo_sk,
            ws_ship_cdemo_sk,
            ws_web_page_sk,
            ws_web_site_sk,
            ws_order_number
    ),
    base1 AS (
        SELECT
            a.ws_bill_customer_sk AS customer_sk,
            ws1.web_name,
            ca_bill.ca_city AS bill_city,
            ca_ship.ca_city AS ship_city,
            cd_bill.cd_gender,
            CASE WHEN cd_bill.cd_purchase_estimate > 5000 THEN 'High' ELSE 'Low' END AS purchase_category,
            a.total_sales,
            l.avg_sales_by_cust
        FROM agg_ws a
        JOIN customer_address ca_bill
            ON a.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON a.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_demographics cd_bill
            ON a.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship
            ON a.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN web_site ws1
            ON a.ws_web_site_sk = ws1.web_site_sk
        JOIN web_page wp1
            ON a.ws_web_page_sk = wp1.wp_web_page_sk
        JOIN web_sales ws_raw
            ON a.ws_order_number = ws_raw.ws_order_number
        JOIN customer_address ca_extra
            ON ws_raw.ws_ship_addr_sk = ca_extra.ca_address_sk
        JOIN customer_demographics cd_extra
            ON ws_raw.ws_ship_cdemo_sk = cd_extra.cd_demo_sk
        LEFT JOIN LATERAL (
            SELECT AVG(ws_ext_sales_price) AS avg_sales_by_cust
            FROM web_sales
            WHERE ws_bill_customer_sk = a.ws_bill_customer_sk
        ) l ON TRUE
        WHERE a.total_sales > (SELECT MAX(total_sales) FROM agg_ws)
          AND ws1.web_zip = '93511'
    ),
    base2 AS (
        SELECT
            a.ws_bill_customer_sk AS customer_sk,
            ws1.web_name,
            ca_bill.ca_city AS bill_city,
            ca_ship.ca_city AS ship_city,
            cd_bill.cd_gender,
            CASE WHEN cd_bill.cd_purchase_estimate > 5000 THEN 'High' ELSE 'Low' END AS purchase_category,
            a.total_sales,
            l.avg_sales_by_cust
        FROM agg_ws a
        JOIN customer_address ca_bill
            ON a.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship
            ON a.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_demographics cd_bill
            ON a.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship
            ON a.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN web_site ws1
            ON a.ws_web_site_sk = ws1.web_site_sk
        JOIN web_page wp2
            ON a.ws_web_page_sk = wp2.wp_web_page_sk
        JOIN web_sales ws_raw2
            ON a.ws_order_number = ws_raw2.ws_order_number
        JOIN customer_address ca_extra2
            ON ws_raw2.ws_bill_addr_sk = ca_extra2.ca_address_sk
        JOIN customer_demographics cd_extra2
            ON ws_raw2.ws_bill_cdemo_sk = cd_extra2.cd_demo_sk
        LEFT JOIN LATERAL (
            SELECT AVG(ws_ext_sales_price) AS avg_sales_by_cust
            FROM web_sales
            WHERE ws_bill_customer_sk = a.ws_bill_customer_sk
        ) l ON TRUE
        WHERE a.total_sales > (SELECT MAX(total_sales) FROM agg_ws)
          AND ws1.web_zip = '86787'
    ),
    unioned AS (
        SELECT * FROM base1
        UNION
        SELECT * FROM base2
    ),
    final_set AS (
        SELECT * FROM unioned
        EXCEPT
        SELECT * FROM unioned WHERE total_sales < 2000
    )
SELECT
    customer_sk,
    web_name,
    bill_city,
    ship_city,
    cd_gender,
    purchase_category,
    total_sales,
    avg_sales_by_cust
FROM final_set
LIMIT 100
