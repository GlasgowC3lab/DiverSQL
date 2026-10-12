WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_returned_time_sk
)
SELECT
    d_sales.d_year,
    d_sales.d_quarter_name,
    s.s_store_name,
    s.s_city,
    t_sales.t_hour,
    t_sales.t_meal_time,
    sales_agg.total_net_paid,
    sales_agg.total_quantity,
    returns_agg.total_return_amt,
    returns_agg.total_return_qty,
    (sales_agg.total_net_paid - COALESCE(returns_agg.total_return_amt, 0)) AS net_sales_after_returns,
    CASE
        WHEN sales_agg.total_quantity > 0 THEN (COALESCE(returns_agg.total_return_qty, 0) / CAST(sales_agg.total_quantity AS double))
        ELSE 0
    END AS return_rate,
    d_closed.d_date AS store_closed_date,
    s.s_tax_percentage
FROM sales_agg
JOIN date_dim d_sales ON sales_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON sales_agg.ss_sold_time_sk = t_sales.t_time_sk
JOIN store s ON sales_agg.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ON sales_agg.ss_sold_date_sk = returns_agg.wr_returned_date_sk
    AND sales_agg.ss_sold_time_sk = returns_agg.wr_returned_time_sk
LEFT JOIN date_dim d_returns ON returns_agg.wr_returned_date_sk = d_returns.d_date_sk
LEFT JOIN time_dim t_returns ON returns_agg.wr_returned_time_sk = t_returns.t_time_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
ORDER BY net_sales_after_returns DESC
LIMIT 100
