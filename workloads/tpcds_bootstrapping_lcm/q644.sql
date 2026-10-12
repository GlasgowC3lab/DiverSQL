SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_moy,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_sales_after_returns,
    SUM(ss.ss_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_sales_customers,
    AVG(cd_sales.cd_purchase_estimate) AS avg_sales_purchase_estimate,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_refunded_customers,
    AVG(CASE WHEN cd_refunded.cd_demo_sk IS NOT NULL THEN cd_refunded.cd_purchase_estimate END) AS avg_refunded_purchase_estimate,
    AVG(CASE WHEN cd_returning.cd_demo_sk IS NOT NULL THEN cd_returning.cd_purchase_estimate END) AS avg_returning_purchase_estimate,
    d_closure.d_year AS store_closed_year,
    d_closure.d_moy AS store_closed_month
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_moy,
    d_closure.d_year,
    d_closure.d_moy
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY net_sales_after_returns DESC
LIMIT 50
