WITH
    cp_arr AS (
        SELECT
            cp.cp_catalog_page_sk,
            ARRAY[cp.cp_type, cp.cp_department] AS attr_arr,
            cp.cp_catalog_page_id
        FROM catalog_page AS cp
    ),
    catalog_sales_filtered AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_promo_sk,
            cs.cs_warehouse_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cs.cs_catalog_page_sk
        FROM catalog_sales AS cs
        WHERE cs.cs_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    ),
    store_sales_sample AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            ss.ss_store_sk,
            ss.ss_promo_sk,
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_net_paid
        FROM store_sales AS ss
        TABLESAMPLE BERNOULLI (5)
    ),
    intersect_keys AS (
        SELECT cs.cs_order_number AS key_val FROM catalog_sales AS cs
        INTERSECT
        SELECT ss.ss_ticket_number FROM store_sales AS ss
    ),
    except_keys AS (
        SELECT cs.cs_order_number AS key_val FROM catalog_sales AS cs
        EXCEPT
        SELECT ss.ss_ticket_number FROM store_sales AS ss
    )
SELECT
    s.s_store_name,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT attr) AS total_page_attributes
FROM
    catalog_sales_filtered AS cs
    JOIN cp_arr AS cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN UNNEST(cp.attr_arr) AS t(attr)
    JOIN date_dim AS d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim AS td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion AS p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse AS w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item AS i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN household_demographics AS hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer AS c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address AS ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales_sample AS ss ON cs.cs_item_sk = ss.ss_item_sk
    RIGHT OUTER JOIN store AS s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim AS d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN store_returns AS sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns AS wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page AS wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    d.d_year = (SELECT MAX(d_year) FROM date_dim)
    AND d.d_year >= 2000
GROUP BY
    s.s_store_name,
    d.d_year
HAVING
    SUM(cs.cs_net_paid) > 10000
ORDER BY
    total_store_net_paid DESC
LIMIT 100
