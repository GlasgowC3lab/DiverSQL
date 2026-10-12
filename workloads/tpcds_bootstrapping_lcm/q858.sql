WITH raw_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_ticket_number
    FROM store_sales ss
),
joined AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        c.c_customer_id AS customer_id,
        wp.wp_web_page_id AS web_page_id,
        d_ship.d_date AS ship_date,
        d_closed.d_date AS closed_date,
        d_first_sales.d_date AS first_sales_date,
        d_access.d_day_name AS access_day_name
    FROM raw_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_first_sales ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
),
agg AS (
    SELECT
        store_id,
        store_name,
        sale_year,
        sale_month_seq,
        SUM(net_profit) AS total_net_profit,
        SUM(ext_sales_price) AS total_sales,
        AVG(ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT web_page_id) AS distinct_web_pages,
        MIN(ship_date) AS first_ship_date,
        MAX(closed_date) AS store_closed_date,
        MIN(first_sales_date) AS first_sales_date,
        MAX(access_day_name) AS last_access_day_name
    FROM joined
    GROUP BY store_id, store_name, sale_year, sale_month_seq
)
SELECT
    store_id,
    store_name,
    sale_year,
    sale_month_seq,
    total_net_profit,
    total_sales,
    avg_discount,
    distinct_customers,
    distinct_web_pages,
    first_ship_date,
    store_closed_date,
    first_sales_date,
    last_access_day_name,
    RANK() OVER (PARTITION BY sale_year ORDER BY total_net_profit DESC) AS profit_rank_year
FROM agg
ORDER BY profit_rank_year, total_net_profit DESC
LIMIT 100
