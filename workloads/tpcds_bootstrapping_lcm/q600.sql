SELECT
    s.s_state,
    ds.d_current_year,
    ds.d_month_seq,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 6 THEN 'Jan-Jun'
        ELSE 'Jul-Dec'
    END AS birth_month_range,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(wr.wr_net_loss) AS total_return_loss,
    AVG(ss.ss_quantity) AS avg_quantity_sold,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > COALESCE(SUM(wr.wr_return_amt), 0) THEN 'Net Gain'
        ELSE 'Net Loss'
    END AS net_status
FROM store_sales ss
JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_returned_date_sk = ds.d_date_sk
LEFT JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
LEFT JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk
LEFT JOIN date_dim df ON c.c_first_shipto_date_sk = df.d_date_sk
LEFT JOIN date_dim dsf ON c.c_first_sales_date_sk = dsf.d_date_sk
WHERE ds.d_year = 2022
GROUP BY
    s.s_state,
    ds.d_current_year,
    ds.d_month_seq,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 6 THEN 'Jan-Jun'
        ELSE 'Jul-Dec'
    END
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 0
ORDER BY total_sales DESC
LIMIT 100
