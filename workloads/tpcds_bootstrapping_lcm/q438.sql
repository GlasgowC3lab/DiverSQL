WITH sales_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_floor_space,
        d_sales.d_year,
        d_sales.d_month_seq,
        d_sales.d_current_month,
        d_closed.d_current_month AS closed_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_units_sold,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MAX(ss.ss_sales_price) AS max_sales_price,
        MIN(ss.ss_sales_price) AS min_sales_price,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS return_txn_cnt,
        CASE
            WHEN s.s_floor_space > 20000 THEN 'Large'
            WHEN s.s_floor_space > 10000 THEN 'Medium'
            ELSE 'Small'
        END AS store_size_category
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_floor_space,
        d_sales.d_year,
        d_sales.d_month_seq,
        d_sales.d_current_month,
        d_closed.d_current_month
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    d_current_month,
    closed_month,
    total_sales,
    total_units_sold,
    total_profit,
    total_return_amount,
    total_return_qty,
    total_return_loss,
    avg_discount,
    max_sales_price,
    min_sales_price,
    sales_txn_cnt,
    return_txn_cnt,
    store_size_category,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank_month
FROM sales_returns
WHERE total_sales > 0
ORDER BY d_year DESC, d_month_seq DESC, total_sales DESC
LIMIT 200
