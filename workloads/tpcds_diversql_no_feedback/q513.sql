WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        cr.cr_call_center_sk,
        cc.cc_name,
        cr.cr_returned_time_sk,
        td.t_hour,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_fee,
        cust_ref.c_customer_sk AS refunded_cust_sk,
        cust_ret.c_customer_sk AS returning_cust_sk,
        cd_ref.cd_education_status AS refunded_edu,
        cd_ret.cd_education_status AS returning_edu
    FROM catalog_returns cr
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    LEFT JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer cust_ret
        ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    LEFT JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE cc.cc_company IN (1, 3)
      AND cc.cc_county = 'Jackson County'
      AND td.t_hour BETWEEN 9 AND 17
      AND cust_ret.c_salutation = 'Mr.'
      AND cd_ret.cd_education_status = '4 yr Degree'
      AND cr.cr_return_amount > 100
),
agg AS (
    SELECT
        w.w_warehouse_name,
        cc.cc_name,
        SUM(cr_return_quantity) AS total_quantity,
        SUM(cr_return_amount)   AS total_return_amount,
        SUM(cr_net_loss)        AS total_net_loss
    FROM base
    JOIN call_center cc        ON base.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w           ON base.cr_warehouse_sk   = w.w_warehouse_sk
    GROUP BY ROLLUP (w.w_warehouse_name, cc.cc_name)
)
SELECT
    w_warehouse_name,
    cc_name,
    total_quantity,
    total_return_amount,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 100
