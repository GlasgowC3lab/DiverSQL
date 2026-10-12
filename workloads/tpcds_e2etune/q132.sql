SELECT
    td.t_hour,
    cd_ret.cd_education_status,
    wp.wp_type,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE cd_ret.cd_gender = 'F'
  AND cd_ret.cd_credit_rating = 'Good'
  AND cd_ret.cd_education_status IN ('College', '4 yr Degree')
  AND cd_ref.cd_marital_status = 'M'
  AND td.t_hour BETWEEN 9 AND 17
  AND wp.wp_type = 'product'
GROUP BY td.t_hour, cd_ret.cd_education_status, wp.wp_type
ORDER BY total_net_loss DESC
LIMIT 10
