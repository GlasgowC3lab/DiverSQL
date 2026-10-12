WITH daily_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity)               AS total_qty,
        SUM(ss.ss_ext_sales_price)        AS total_sales,
        SUM(ss.ss_ext_discount_amt)       AS total_discount,
        SUM(ss.ss_net_profit)             AS total_profit
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_sold_date_sk
)
SELECT
    c.cc_name,
    c.cc_manager,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    d_sold.d_date                 AS call_center_closed_date,
    d_cc_open.d_date              AS call_center_open_date,
    d_store_closed.d_date         AS store_closed_date,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    s.s_store_name,
    s.s_city,
    ds.total_qty,
    ds.total_sales,
    ds.total_discount,
    ds.total_profit,
    (ds.total_sales - ds.total_discount)           AS net_sales,
    ROUND(ds.total_profit / NULLIF(ds.total_sales, 0) * 100, 2) AS profit_margin_percent,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ds.total_sales DESC) AS sales_rank_within_store
FROM daily_sales ds
JOIN store s
    ON ds.ss_store_sk = s.s_store_sk
JOIN item i
    ON ds.ss_item_sk = i.i_item_sk
JOIN date_dim d_sold
    ON ds.ss_sold_date_sk = d_sold.d_date_sk
JOIN call_center c
    ON c.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON c.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2021
  AND s.s_state = 'TX'
ORDER BY ds.total_sales DESC
LIMIT 100
