WITH cs_sample AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    cc.cc_name,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(ws.ws_net_paid) AS avg_ws_net_paid,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(ws.ws_coupon_amt) AS max_coupon
FROM cs_sample cs
JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'TX'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'F'
    AND hd.hd_buy_potential = '5001-10000'
    AND NOT EXISTS (
        SELECT 1
        FROM tpcds.call_center cc2
        WHERE cc2.cc_state = 'CA'
          AND cc2.cc_call_center_sk = cs.cs_call_center_sk
    )
GROUP BY
    d.d_year,
    cc.cc_name,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential
HAVING
    SUM(cs.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
