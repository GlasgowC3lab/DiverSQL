WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_date,
    p.p_promo_id,
    p.p_promo_name,
    sa.total_sales,
    sa.total_qty,
    sa.total_profit,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(ra.total_return_qty, 0) AS total_return_qty,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    d_returns.d_date AS return_date
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg ra
    ON sa.ss_sold_date_sk = ra.wr_returned_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_returns
    ON ra.wr_returned_date_sk = d_returns.d_date_sk
WHERE d_sales.d_year = 2022
ORDER BY sa.total_sales DESC
LIMIT 50
