WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_customer_sk,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_ext_list_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_quantity
    FROM store_sales ss
),
joined AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_type,
        t.t_shift,
        bs.ss_net_profit,
        bs.ss_ext_discount_amt,
        bs.ss_customer_sk,
        bs.ss_quantity,
        bs.ss_ext_sales_price
    FROM base_sales bs
    JOIN time_dim t
        ON bs.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON bs.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND t.t_shift = 'Evening'
),
aggregated AS (
    SELECT
        cp_catalog_page_number,
        cp_type,
        t_shift,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers
    FROM joined
    GROUP BY cp_catalog_page_number, cp_type, t_shift
    HAVING SUM(ss_net_profit) > 1000
)
SELECT
    cp_catalog_page_number,
    cp_type,
    t_shift,
    total_net_profit,
    total_sales,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY t_shift ORDER BY total_net_profit DESC) AS profit_rank_within_shift
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 20
