WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        sm.sm_type,
        cr.cr_return_amount,
        wr.wr_return_amt,
        ib.ib_upper_bound,
        p.p_cost,
        cc.cc_division,
        r.r_reason_id,
        sm.sm_code
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    -- refunded customer
    JOIN tpcds.customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    -- returning customer
    JOIN tpcds.customer cust_ret
        ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    -- refunded household demographics
    JOIN tpcds.household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    -- returning household demographics
    JOIN tpcds.household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    -- income band via refunded household demographics
    JOIN tpcds.income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    -- promotion linked to the same date (using start date)
    LEFT JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    -- web returns that happened on the same date
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND r.r_reason_id IN ('AAAAAAAACAAAAAAA','AAAAAAAADBAAAAAA')
      AND sm.sm_code = 'AIR'
      AND ib.ib_upper_bound < 100000
      AND p.p_cost > 1000
      AND cc.cc_division = 2
      AND cr.cr_return_amount > 0
),
aggregated AS (
    SELECT
        cc_call_center_id,
        cc_name,
        d_year,
        d_month_seq,
        r_reason_desc,
        sm_type,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amount,
        SUM(cr_return_amount + COALESCE(wr_return_amt, 0)) AS total_return_amount
    FROM base
    GROUP BY
        cc_call_center_id,
        cc_name,
        d_year,
        d_month_seq,
        r_reason_desc,
        sm_type
)
SELECT
    cc_call_center_id,
    cc_name,
    d_year,
    d_month_seq,
    r_reason_desc,
    sm_type,
    total_catalog_return_amount,
    total_web_return_amount,
    total_return_amount,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amount DESC) AS month_return_rank
FROM aggregated
ORDER BY month_return_rank, total_return_amount DESC
OFFSET 0 LIMIT 100
