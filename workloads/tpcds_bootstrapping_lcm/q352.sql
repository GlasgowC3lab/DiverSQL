SELECT
    d.d_date,
    d.d_year,
    s.s_store_id,
    s.s_store_name,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(wr.wr_return_amt_inc_tax) AS web_return_amt_inc_tax,
    (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid_inc_tax) - SUM(wr.wr_return_amt_inc_tax)) AS total_net_flow,
    CASE
        WHEN (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid_inc_tax) - SUM(wr.wr_return_amt_inc_tax)) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS net_flow_category
FROM
    date_dim d
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk AND ss.ss_sold_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_date,
    d.d_year,
    s.s_store_id,
    s.s_store_name
ORDER BY
    total_net_flow DESC
LIMIT 100
