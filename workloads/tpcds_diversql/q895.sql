/*
Goal: Analyze catalog sales that were billed to customers in California, shipped from warehouses in GMT offset -6, and belong to households with buying potential 1001-5000. The query joins all six TPC‑DS tables using only the permitted keys, applies selective filters, removes rows that have a matching high‑quantity store sale (anti‑join), samples catalog_sales, aggregates sales metrics, classifies households with a CASE expression, and computes lag and running total window functions per division.
*/
WITH filtered_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid_inc_ship_tax > 1000
      AND cs_wholesale_cost >= 20
      AND cs_ext_tax <= 150
),
joined_data AS (
    SELECT
        fs.cs_order_number,
        fs.cs_sold_date_sk,
        fs.cs_net_paid_inc_ship_tax,
        fs.cs_wholesale_cost,
        fs.cs_ext_tax,
        cc.cc_name,
        cc.cc_state,
        cc.cc_division,
        w.w_city,
        w.w_gmt_offset,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        CASE WHEN hd.hd_dep_count = 0 THEN 'NoDependents' ELSE 'HasDependents' END AS dependent_status,
        c.c_customer_sk
    FROM filtered_sales fs
    JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON fs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON fs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_gmt_offset = -6.00
      AND hd.hd_buy_potential = '1001-5000'
      AND NOT EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_ticket_number = fs.cs_order_number
              AND ss2.ss_quantity > 5
        )
),
aggregated_data AS (
    SELECT
        cc_name,
        w_city,
        hd_buy_potential,
        dependent_status,
        cc_division,
        cs_sold_date_sk,
        COUNT(DISTINCT cs_order_number) AS num_orders,
        SUM(cs_net_paid_inc_ship_tax) AS total_sales,
        AVG(cs_wholesale_cost) AS avg_wholesale_cost,
        MIN(cs_ext_tax) AS min_tax,
        MAX(cs_ext_tax) AS max_tax
    FROM joined_data
    GROUP BY
        cc_name,
        w_city,
        hd_buy_potential,
        dependent_status,
        cc_division,
        cs_sold_date_sk
)
SELECT
    cc_name,
    w_city,
    hd_buy_potential,
    dependent_status,
    num_orders,
    total_sales,
    avg_wholesale_cost,
    min_tax,
    max_tax,
    LAG(total_sales) OVER (PARTITION BY cc_division ORDER BY cs_sold_date_sk) AS prev_total_sales,
    SUM(total_sales) OVER (PARTITION BY cc_division ORDER BY cs_sold_date_sk
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM aggregated_data
ORDER BY total_sales DESC
LIMIT 100
