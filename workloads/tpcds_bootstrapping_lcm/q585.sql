SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    dr_ret.d_year AS return_year,
    dr_ret.d_moy AS return_month,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MAX(cr.cr_net_loss) AS max_net_loss,
    COUNT(DISTINCT cd_ret.cd_demo_sk) AS distinct_returning_customers,
    COUNT(DISTINCT cd_ref.cd_demo_sk) AS distinct_refunded_customers,
    CASE
        WHEN cc.cc_tax_percentage > 5.00 THEN 'HighTax'
        ELSE 'LowTax'
    END AS tax_bracket,
    dr_cc_closed.d_date AS call_center_closed_date,
    dr_cc_open.d_date AS call_center_open_date
FROM catalog_returns cr
INNER JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN date_dim dr_ret
    ON cr.cr_returned_date_sk = dr_ret.d_date_sk
INNER JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
INNER JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
INNER JOIN store s
    ON s.s_closed_date_sk = dr_ret.d_date_sk
INNER JOIN date_dim dr_cc_closed
    ON cc.cc_closed_date_sk = dr_cc_closed.d_date_sk
INNER JOIN date_dim dr_cc_open
    ON cc.cc_open_date_sk = dr_cc_open.d_date_sk
WHERE cr.cr_return_amount > 0
GROUP BY
    cc.cc_name,
    s.s_store_name,
    dr_ret.d_year,
    dr_ret.d_moy,
    dr_cc_closed.d_date,
    dr_cc_open.d_date,
    cc.cc_tax_percentage
ORDER BY total_return_amount DESC
LIMIT 100
