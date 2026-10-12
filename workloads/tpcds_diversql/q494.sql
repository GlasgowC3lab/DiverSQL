WITH
    sales_dates AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_quantity,
            cs.cs_ext_ship_cost,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            d.d_year,
            d.d_quarter_seq,
            d.d_weekend
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_quantity > 5
          AND cs.cs_ext_ship_cost > 0
          AND d.d_year = 1999
          AND d.d_weekend = 'N'
    ),
    agg_by_quarter AS (
        SELECT
            d_year,
            d_quarter_seq,
            SUM(cs_ext_sales_price) AS sum_sales,
            AVG(cs_net_profit) AS avg_profit,
            COUNT(*) AS cnt_orders
        FROM sales_dates
        GROUP BY d_year, d_quarter_seq
    ),
    scalar_profit AS (
        SELECT AVG(cs_net_profit) AS overall_avg_profit
        FROM catalog_sales
        WHERE cs_net_profit IS NOT NULL
    ),
    key_exceptions AS (
        SELECT cs_sold_date_sk FROM catalog_sales WHERE cs_quantity > 10
        EXCEPT
        SELECT cs_ship_date_sk FROM catalog_sales WHERE cs_quantity > 10
    )
SELECT
    a.d_year,
    a.d_quarter_seq,
    a.sum_sales,
    a.avg_profit,
    a.cnt_orders,
    (a.sum_sales / a.cnt_orders) AS avg_sales_per_order,
    LAG(a.sum_sales) OVER (PARTITION BY a.d_year ORDER BY a.d_quarter_seq) AS prev_quarter_sales,
    CASE WHEN a.avg_profit > (SELECT overall_avg_profit FROM scalar_profit) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM agg_by_quarter a
WHERE a.sum_sales > (
        SELECT SUM(cs_ext_sales_price) * 0.5
        FROM catalog_sales
        WHERE cs_sold_date_sk IN (SELECT cs_sold_date_sk FROM key_exceptions)
    )
ORDER BY a.d_year DESC, a.d_quarter_seq
LIMIT 100
