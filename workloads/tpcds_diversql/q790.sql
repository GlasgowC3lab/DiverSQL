WITH full_cc_cr AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        cc.cc_call_center_id,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_call_center_sk AS cr_cc_sk,
        cr.cr_order_number,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk
    FROM call_center cc
    FULL OUTER JOIN (
        SELECT * FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    ) cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
),
joined_all AS (
    SELECT
        fc.cc_state,
        fc.cc_call_center_id,
        cp.cp_type,
        r.r_reason_desc,
        cd.cd_gender,
        hd.hd_buy_potential,
        t.t_hour,
        t.t_shift,
        fc.cr_order_number,
        fc.cr_return_amount,
        fc.cr_return_tax,
        fc.cr_return_amt_inc_tax,
        fc.cr_fee,
        fc.cr_net_loss,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_net_loss,
        c.c_preferred_cust_flag
    FROM full_cc_cr fc
    LEFT JOIN catalog_page cp
        ON fc.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
        ON fc.cr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim t
        ON fc.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer c
        ON fc.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON fc.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON fc.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
           AND sr.sr_reason_sk = r.r_reason_sk
    WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
      AND (fc.cc_state = 'CA' OR fc.cc_state IS NULL)
      AND (cp.cp_type = 'monthly' OR cp.cp_type IS NULL)
),
order_diff AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
)
SELECT
    cc_state,
    cp_type,
    cd_gender,
    hd_buy_potential,
    r_reason_desc,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) DESC) AS loss_rank_in_state,
    (SELECT COUNT(*) FROM order_diff) AS missing_order_count
FROM joined_all
GROUP BY CUBE (cc_state, cp_type, cd_gender, hd_buy_potential, r_reason_desc)
HAVING SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
