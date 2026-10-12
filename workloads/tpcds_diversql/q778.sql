WITH
store_part AS (
    SELECT
        CASE 
            WHEN s.s_state = 'CA' THEN 'West'
            WHEN s.s_state = 'NY' THEN 'East'
            ELSE 'Other'
        END AS region_flag,
        p.p_promo_id,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity,
        s.s_country,
        p.p_channel_dmail,
        s.s_gmt_offset,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_quantity > 1
      AND s.s_country = 'United States'
      AND s.s_state IN ('CA','NY')
      AND p.p_channel_dmail = 'Y'
      AND s.s_gmt_offset > -5
      AND cd.cd_gender = 'M'
),
catalog_part AS (
    SELECT
        CASE 
            WHEN cp.cp_type = 'monthly' THEN 'Monthly'
            WHEN cp.cp_type = 'quarterly' THEN 'Quarterly'
            ELSE 'Other'
        END AS region_flag,
        p.p_promo_id,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity,
        cp.cp_start_date_sk,
        cc.cc_hours,
        cc.cc_gmt_offset,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 2
      AND cp.cp_type IN ('monthly','quarterly')
      AND cc.cc_gmt_offset > -5
      AND p.p_channel_dmail = 'Y'
      AND cd.cd_gender = 'F'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
),
web_part AS (
    SELECT
        CASE 
            WHEN wp.wp_type = 'article' THEN 'Article'
            WHEN wp.wp_type = 'video' THEN 'Video'
            ELSE 'Other'
        END AS region_flag,
        p.p_promo_id,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity,
        wp.wp_char_count,
        p.p_channel_email,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_quantity > 3
      AND wp.wp_type = 'article'
      AND p.p_channel_email = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 1 AND 5
),
union_part AS (
    SELECT region_flag, p_promo_id, net_profit
    FROM store_part
    UNION
    SELECT region_flag, p_promo_id, net_profit
    FROM catalog_part
),
intersect_part AS (
    SELECT region_flag, p_promo_id
    FROM union_part
    INTERSECT
    SELECT region_flag, p_promo_id
    FROM web_part
),
final_agg AS (
    SELECT
        ip.region_flag,
        ip.p_promo_id,
        SUM(up.net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        CASE 
            WHEN SUM(up.net_profit) > 0 THEN 'POS'
            ELSE 'NEG'
        END AS profit_sign
    FROM intersect_part ip
    JOIN union_part up
        ON ip.region_flag = up.region_flag
        AND ip.p_promo_id = up.p_promo_id
    GROUP BY CUBE(ip.region_flag, ip.p_promo_id)
    HAVING SUM(up.net_profit) > 1000
)
SELECT *
FROM final_agg
ORDER BY total_profit DESC
LIMIT 100
