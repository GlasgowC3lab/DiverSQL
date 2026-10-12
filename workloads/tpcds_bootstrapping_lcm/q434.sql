WITH sales_agg AS (
    SELECT
        d_sale.d_date AS sale_date,
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        ca.ca_city AS customer_city,
        ca.ca_state AS customer_state,
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        d_store_close.d_date AS store_closed_date,
        d_cc_open.d_date AS call_center_open_date,
        d_cc_closed.d_date AS call_center_closed_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_store_close.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_sale.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        d_sale.d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_city,
        ca.ca_state,
        cc.cc_name,
        cc.cc_city,
        d_store_close.d_date,
        d_cc_open.d_date,
        d_cc_closed.d_date
)
SELECT
    sale_date,
    s_store_id,
    s_store_name,
    store_city,
    store_state,
    customer_city,
    customer_state,
    call_center_name,
    call_center_city,
    store_closed_date,
    call_center_open_date,
    call_center_closed_date,
    total_sales,
    total_quantity,
    avg_net_profit,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
