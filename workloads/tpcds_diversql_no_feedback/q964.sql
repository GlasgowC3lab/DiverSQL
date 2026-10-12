WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        d.d_year,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_country,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        wp.wp_type,
        td.t_hour
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND ca.ca_country = 'United States'
      AND td.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'content'
)
SELECT
    cc_name,
    d_year,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM base
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = base.cc_call_center_sk
      AND cr2.cr_return_amount > 0
)
GROUP BY cc_name, d_year
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
