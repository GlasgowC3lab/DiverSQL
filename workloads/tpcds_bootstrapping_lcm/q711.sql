WITH daily_metrics AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_ext_sales_price) AS daily_sales,
        SUM(ss.ss_net_profit) AS daily_profit,
        SUM(ss.ss_quantity) AS daily_qty_sold
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
daily_returns AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_return_quantity) AS daily_return_qty,
        SUM(wr.wr_net_loss) AS daily_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
daily_inventory AS (
    SELECT
        i.inv_date_sk AS date_sk,
        SUM(i.inv_quantity_on_hand) AS daily_inventory_qty
    FROM inventory i
    GROUP BY i.inv_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    COALESCE(dm.daily_sales, 0) AS total_sales,
    COALESCE(dm.daily_profit, 0) AS total_profit,
    COALESCE(dm.daily_qty_sold, 0) AS total_qty_sold,
    COALESCE(dr.daily_return_qty, 0) AS total_return_qty,
    COALESCE(dr.daily_return_loss, 0) AS total_return_loss,
    COALESCE(di.daily_inventory_qty, 0) AS total_inventory_qty,
    CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 1 ELSE 0 END AS store_closed_flag,
    MAX(d_closed.d_date) AS store_closed_date,
    SUM(COALESCE(dm.daily_sales, 0)) OVER (
        PARTITION BY s.s_store_id
        ORDER BY d.d_year, d.d_month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sales_3_month_sum
FROM store s
LEFT JOIN daily_metrics dm ON dm.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d ON dm.date_sk = d.d_date_sk
LEFT JOIN daily_returns dr ON dr.date_sk = d.d_date_sk
LEFT JOIN daily_inventory di ON di.date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year BETWEEN 2010 AND 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    s.s_closed_date_sk,
    d_closed.d_date,
    dm.daily_sales,
    dm.daily_profit,
    dm.daily_qty_sold,
    dr.daily_return_qty,
    dr.daily_return_loss,
    di.daily_inventory_qty
HAVING SUM(COALESCE(dm.daily_sales, 0)) > 1000
ORDER BY total_sales DESC
LIMIT 100
