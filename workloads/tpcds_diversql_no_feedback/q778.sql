WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS city_state,
        SUBSTRING(cc.cc_zip, 1, 5) AS zip_prefix,
        REGEXP_EXTRACT(cc.cc_zip, '(\\d+)', 1) AS zip_digits,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(cc.cc_city, 'County$')
      AND cc.cc_state LIKE 'A%'
      AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_cdemo_sk = cd.cd_demo_sk
            AND sr.sr_return_amt > 500
      )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        sm.sm_type,
        cc.cc_zip
)
SELECT
    cc_call_center_id,
    city_state,
    zip_prefix,
    zip_digits,
    sm_type,
    total_profit,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
