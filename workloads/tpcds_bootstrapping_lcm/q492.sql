WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        s.s_store_name AS store_name,
        d_sales.d_year AS sales_year,
        d_sales.d_quarter_name AS sales_quarter,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
        COUNT(DISTINCT ss.ss_customer_sk) AS customer_count,
        COUNT(DISTINCT ss.ss_item_sk) AS item_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MIN(d_sales.d_date) AS first_sale_date,
        MAX(d_sales.d_date) AS last_sale_date,
        AVG(date_diff('day', d_sales.d_date, d_store_close.d_date)) AS avg_days_to_store_closure,
        AVG(date_diff('day', d_sales.d_date, d_cc_close.d_date)) AS avg_days_to_cc_closure
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY cc.cc_name, s.s_store_name, d_sales.d_year, d_sales.d_quarter_name
)
SELECT
    call_center_name,
    store_name,
    sales_year,
    sales_quarter,
    total_sales,
    total_discount,
    total_profit,
    ticket_count,
    customer_count,
    item_count,
    avg_sales_price,
    first_sale_date,
    last_sale_date,
    avg_days_to_store_closure,
    avg_days_to_cc_closure,
    RANK() OVER (PARTITION BY call_center_name, sales_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
