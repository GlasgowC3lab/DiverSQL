SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    s.s_store_name,
    cc.cc_name AS call_center_name,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_quantity) AS total_quantity_sold,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(sr.sr_return_amt) AS total_return_amount,
    sum(sr.sr_return_quantity) AS total_quantity_returned,
    sum(sr.sr_net_loss) AS total_return_loss,
    sum(ss.ss_ext_discount_amt) AS total_discount,
    avg(ss.ss_ext_discount_amt) AS avg_discount,
    sum(ss.ss_ext_sales_price) - sum(sr.sr_return_amt) AS net_sales_after_returns,
    (sum(sr.sr_return_quantity) * 100.0) / nullif(sum(ss.ss_quantity), 0) AS return_rate_percent
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
GROUP BY ROLLUP (d_sales.d_year, d_sales.d_month_seq, s.s_store_name, cc.cc_name)
ORDER BY d_sales.d_year, d_sales.d_month_seq, s.s_store_name, cc.cc_name
