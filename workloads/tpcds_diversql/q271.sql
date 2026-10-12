WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_catalog_number BETWEEN 1 AND 100
      AND cd.cd_purchase_estimate >= 2000
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_ext_sales_price > 100
      AND sm.sm_type = 'AIR'
),

returns_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        s.s_store_name,
        r.r_reason_desc,
        td.t_hour AS return_hour,
        CASE WHEN sr.sr_return_quantity > 3 THEN 'HighReturn' ELSE 'LowReturn' END AS return_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%defect%'
      AND cd.cd_dep_employed_count >= 1
      AND td.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_amt > 50
      AND s.s_market_desc LIKE '%Local%'
)

SELECT
    COALESCE(sa.cs_sold_date_sk, ra.sr_returned_date_sk) AS activity_date_sk,
    COALESCE(sa.cc_name, ra.s_store_name) AS location_name,
    SUM(COALESCE(sa.cs_ext_sales_price, 0)) AS total_sales,
    SUM(COALESCE(ra.sr_return_amt, 0)) AS total_returns,
    AVG(COALESCE(sa.cs_net_profit, 0) - COALESCE(ra.sr_net_loss, 0)) AS avg_profit_loss,
    COUNT(*) AS activity_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sa.cs_sold_date_sk, ra.sr_returned_date_sk) DESC) AS rn
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.cs_sold_date_sk = ra.sr_returned_date_sk
   AND sa.cs_sold_time_sk = ra.sr_return_time_sk
WHERE (COALESCE(sa.cs_ext_sales_price, 0) - COALESCE(ra.sr_return_amt, 0)) > 0
GROUP BY
    COALESCE(sa.cs_sold_date_sk, ra.sr_returned_date_sk),
    COALESCE(sa.cc_name, ra.s_store_name)
HAVING SUM(COALESCE(sa.cs_ext_sales_price, 0)) > 1000
ORDER BY total_sales DESC
LIMIT 100
