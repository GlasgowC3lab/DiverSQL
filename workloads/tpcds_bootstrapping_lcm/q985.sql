WITH aggregated AS (
    SELECT
        cc.cc_company_name,
        cc.cc_state,
        d_closed.d_year AS closed_year,
        d_open.d_year AS open_year,
        s.s_store_name,
        s.s_state,
        d_sold.d_year AS sold_year,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        s.s_store_id
    FROM call_center cc
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d_sold.d_year = 2020
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        cc.cc_company_name,
        cc.cc_state,
        d_closed.d_year,
        d_open.d_year,
        s.s_store_name,
        s.s_state,
        d_sold.d_year,
        t.t_hour,
        s.s_store_id
)
SELECT
    a.cc_company_name,
    a.cc_state,
    a.closed_year,
    a.open_year,
    a.s_store_name,
    a.s_state,
    a.sold_year,
    a.t_hour,
    a.total_sales,
    a.total_profit,
    a.avg_sales_price,
    a.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
