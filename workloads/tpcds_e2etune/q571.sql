WITH billing AS (
    SELECT
        ws_order_number,
        ws_net_profit,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_quantity,
        ws_bill_customer_sk,
        ws_bill_addr_sk,
        ws_web_page_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458840 AND 2459200
)
SELECT
    billing_zip,
    page_type,
    distinct_customers,
    total_quantity,
    total_sales,
    total_profit,
    avg_discount,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        ca.ca_zip AS billing_zip,
        wp.wp_type AS page_type,
        COUNT(DISTINCT b.ws_bill_customer_sk) AS distinct_customers,
        SUM(b.ws_quantity) AS total_quantity,
        SUM(b.ws_ext_sales_price) AS total_sales,
        SUM(b.ws_net_profit) AS total_profit,
        AVG(b.ws_ext_discount_amt) AS avg_discount
    FROM billing b
    JOIN customer_address ca
        ON b.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON b.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND wp.wp_type IN ('Home', 'Product', 'Search')
    GROUP BY ca.ca_zip, wp.wp_type
    HAVING SUM(b.ws_ext_sales_price) > 10000
) t
ORDER BY total_profit DESC
LIMIT 50
