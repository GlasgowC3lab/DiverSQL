SELECT
    d.d_year,
    d.d_month_seq,
    cd_ref.cd_gender,
    cd_ref.cd_marital_status,
    cd_ret.cd_education_status,
    s.s_city,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr.wr_return_amt) AS avg_web_return_amount,
    SUM(CASE WHEN cr.cr_return_quantity > 1 THEN cr.cr_return_quantity * cr.cr_return_amount ELSE 0 END) AS catalog_multi_item_loss,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_quantity * wr.wr_return_amt ELSE 0 END) AS web_multi_item_loss
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref_wr
    ON wr.wr_refunded_cdemo_sk = cd_ref_wr.cd_demo_sk
JOIN customer_demographics cd_ret_wr
    ON wr.wr_returning_cdemo_sk = cd_ret_wr.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND cd_ref.cd_gender = 'M'
  AND cd_ret.cd_education_status = 'College'
GROUP BY
    d.d_year,
    d.d_month_seq,
    cd_ref.cd_gender,
    cd_ref.cd_marital_status,
    cd_ret.cd_education_status,
    s.s_city
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY d.d_year, d.d_month_seq, s.s_city
LIMIT 100
