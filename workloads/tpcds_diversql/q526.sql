WITH filtered_returns AS (
    SELECT
        cr.cr_returning_customer_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_name,
        cc.cc_tax_percentage,
        sm.sm_ship_mode_id,
        cust.c_customer_id,
        cust.c_email_address,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_tax_percentage > 0.05
      AND cc.cc_mkt_class LIKE '%Written%'
      AND sm.sm_type = 'AIR'
      AND hd.hd_buy_potential = '0-500'
      AND cd.cd_gender = 'F'
),
intersect_customers AS (
    SELECT cr_returning_customer_sk AS cust_sk
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 500
    INTERSECT
    SELECT cr_refunded_customer_sk
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 500
),
high_tax_cc AS (
    SELECT cc_call_center_sk AS cc_sk
    FROM tpcds.call_center
    WHERE cc_tax_percentage >= 0.08
    EXCEPT
    SELECT cc_call_center_sk
    FROM tpcds.call_center
    WHERE cc_tax_percentage < 0.08
)
SELECT
    fr.cc_name,
    fr.c_customer_id,
    fr.c_email_address,
    fr.cr_return_amount,
    fr.cr_return_quantity,
    fr.sm_ship_mode_id,
    fr.hd_buy_potential,
    RANK() OVER (PARTITION BY fr.cc_name ORDER BY fr.cr_return_amount DESC) AS return_rank
FROM filtered_returns fr
JOIN intersect_customers ic
    ON fr.cr_returning_customer_sk = ic.cust_sk
JOIN high_tax_cc htc
    ON fr.cr_call_center_sk = htc.cc_sk
ORDER BY return_rank,
         fr.cr_return_amount DESC
OFFSET 0 LIMIT 100
