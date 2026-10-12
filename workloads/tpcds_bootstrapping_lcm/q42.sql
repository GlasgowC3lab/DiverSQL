SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    dd_sales.d_year AS sales_year,
    dd_sales.d_month_seq AS sales_month,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_refunded_cash), 0) AS total_refunded_cash,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_paid) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_sales_minus_returns,
    SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    CASE WHEN dd_store.d_date IS NULL THEN 'Open' ELSE 'Closed' END AS store_status_at_sales_date
FROM store_sales ss
JOIN date_dim dd_sales
    ON ss.ss_sold_date_sk = dd_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim dd_store
    ON s.s_closed_date_sk = dd_store.d_date_sk
LEFT JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
LEFT JOIN date_dim dd_returns
    ON wr.wr_returned_date_sk = dd_returns.d_date_sk
WHERE dd_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    dd_sales.d_year,
    dd_sales.d_month_seq,
    dd_store.d_date
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY net_sales_minus_returns DESC
LIMIT 100
