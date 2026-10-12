WITH joined AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_zip,
        s.s_company_id,
        s.s_rec_start_date,
        s.s_rec_end_date,
        p.p_promo_id,
        p.p_response_target,
        p.p_channel_radio,
        cc.cc_name,
        cc.cc_gmt_offset,
        ss.ss_net_paid,
        cs.cs_net_paid,
        ca.ca_state AS cust_state,
        hd.hd_income_band_sk,
        wp.wp_type,
        ss.ss_quantity,
        cs.cs_quantity,
        ss.ss_net_profit,
        cs.cs_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE s.s_zip = '55752'
      AND s.s_company_id = 1
      AND p.p_response_target = 1
      AND p.p_channel_radio = 'N'
      AND cc.cc_gmt_offset >= 0
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_end_date <= DATE '2025-12-31'
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        p_promo_id,
        SUM(ss_net_paid) AS total_store_promo_sales
    FROM joined
    GROUP BY
        s_store_id,
        s_store_name,
        s_state,
        p_promo_id
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    p_promo_id,
    total_store_promo_sales,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_store_promo_sales DESC) AS state_sales_rank,
    RANK() OVER (PARTITION BY s_state ORDER BY total_store_promo_sales DESC) AS state_sales_dense_rank
FROM agg
ORDER BY total_store_promo_sales DESC
LIMIT 100
