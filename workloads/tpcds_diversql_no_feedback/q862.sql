WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        r.r_reason_desc
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    jd.c_customer_id,
    jd.cp_department,
    jd.i_brand,
    SUM(jd.sr_return_amt) AS total_return_amount,
    SUM(jd.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY jd.cp_department ORDER BY SUM(jd.sr_net_loss) DESC) AS dept_customer_rank,
    CASE
        WHEN jd.hd_buy_potential = '1001-5000' THEN 'Mid'
        WHEN jd.hd_buy_potential = '5001-10000' THEN 'High'
        ELSE 'Other'
    END AS buy_potential_segment
FROM joined_data jd
WHERE jd.sr_return_amt > 100
  AND jd.hd_buy_potential IN ('1001-5000', '5001-10000')
  AND jd.ib_lower_bound >= 50000
  AND jd.cp_department = 'Sports'
  AND jd.cs_sold_date_sk BETWEEN 2450815 AND 2451179
GROUP BY
    jd.c_customer_id,
    jd.cp_department,
    jd.i_brand,
    jd.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
