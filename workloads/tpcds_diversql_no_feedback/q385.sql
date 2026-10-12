/*
Goal: Analyze sales performance and return impact by hour and call center, classify sales volume, and rank hours by total sales.
*/
WITH filtered AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_list_price,
        cs.cs_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number,
        t.t_hour
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE
        t.t_hour IN (6, 7, 9, 18)
        AND cs.cs_call_center_sk IN (2, 31)
        AND cs.cs_ship_cdemo_sk > 400000
        AND cs.cs_ext_list_price BETWEEN 1500 AND 2500
        AND cs.cs_quantity > 1
        AND wr.wr_return_ship_cost > 500
        AND wr.wr_returning_customer_sk = 5712123
),
agg AS (
    SELECT
        t_hour,
        cs_call_center_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(wr_return_amt) AS total_returns,
        SUM(cs_net_profit) - SUM(wr_net_loss) AS net_profit,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs_order_number) AS cnt_sales_orders,
        COUNT(DISTINCT wr_order_number) AS cnt_return_orders,
        CASE WHEN SUM(cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_category
    FROM filtered
    GROUP BY t_hour, cs_call_center_sk
)
SELECT
    t_hour,
    cs_call_center_sk,
    total_sales,
    total_returns,
    net_profit,
    avg_sales_price,
    cnt_sales_orders,
    cnt_return_orders,
    sales_volume_category,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY t_hour, total_sales DESC
LIMIT 100
