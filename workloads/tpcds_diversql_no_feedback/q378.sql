WITH joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_type,
        c.c_first_name,
        c.c_last_name,
        d_sold.d_date,
        d_sold.d_year,
        t.t_hour,
        sm.sm_type AS ship_type,
        w.w_warehouse_name,
        w.w_city
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 5
),
agg AS (
    SELECT
        cp_department,
        cp_type,
        d_year,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(DISTINCT cs_ext_discount_amt) AS distinct_discount_sum,
        SUM(cs_net_profit) AS total_profit
    FROM joined
    GROUP BY GROUPING SETS (
        (cp_department, cp_type, d_year),
        (cp_type, d_year),
        (d_year)
    )
)
SELECT
    cp_department,
    cp_type,
    d_year,
    distinct_orders,
    distinct_discount_sum,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY d_year ORDER BY distinct_orders DESC) AS order_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
