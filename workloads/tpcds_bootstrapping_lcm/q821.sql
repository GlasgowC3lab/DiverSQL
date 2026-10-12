WITH cs_sold_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid_sold,
        SUM(cs.cs_net_profit) AS total_net_profit_sold,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders_sold
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
cs_ship_agg AS (
    SELECT
        cs.cs_ship_date_sk AS date_sk,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        SUM(cs.cs_ext_tax) AS total_ship_tax,
        COUNT(*) AS ship_rows
    FROM catalog_sales cs
    GROUP BY cs.cs_ship_date_sk
),
cr_cs_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders_with_returns
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    GROUP BY cr.cr_returned_date_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_net_loss) AS total_web_return_net_loss,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS web_return_rows
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk AS date_sk,
        COUNT(*) AS closed_store_count,
        MIN(s.s_store_name) AS example_store_name
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT
    dd.d_date,
    dd.d_year,
    cs_sold.total_net_paid_sold,
    cs_sold.total_net_profit_sold,
    cs_ship.total_ship_cost,
    cs_ship.total_ship_tax,
    cr_cs.total_return_net_loss,
    cr_cs.total_return_amount,
    cr_cs.total_sales_net_paid,
    cr_cs.total_sales_net_profit,
    wr.total_web_return_net_loss,
    wr.total_web_return_amount,
    st.closed_store_count,
    st.example_store_name
FROM date_dim dd
LEFT JOIN cs_sold_agg cs_sold ON cs_sold.date_sk = dd.d_date_sk
LEFT JOIN cs_ship_agg cs_ship ON cs_ship.date_sk = dd.d_date_sk
LEFT JOIN cr_cs_agg cr_cs ON cr_cs.date_sk = dd.d_date_sk
LEFT JOIN wr_agg wr ON wr.date_sk = dd.d_date_sk
LEFT JOIN store_agg st ON st.date_sk = dd.d_date_sk
WHERE dd.d_year = 2001
ORDER BY cs_sold.total_net_paid_sold DESC
LIMIT 100
