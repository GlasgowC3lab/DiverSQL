/*
Goal: Combine catalog_sales and store_sales information with their related dimensions, filter on call center name, active promotions, and California stores, then compute sales and profit aggregates across all dimension combinations using CUBE. Rank the rows by total profit and return the top 100.
*/
WITH cs_data AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        p.p_promo_id,
        ca.ca_state AS address_state,
        cd.cd_gender,
        cs.cs_ext_sales_price      AS cs_sales,
        cs.cs_net_profit           AS cs_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_name LIKE '%Center%'
      AND p.p_discount_active = 'Y'
),
store_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_rec_end_date,
        p.p_promo_id,
        ca.ca_state AS address_state,
        cd.cd_gender,
        r.r_reason_id,
        ss.ss_ext_sales_price      AS ss_sales,
        ss.ss_net_profit           AS ss_profit,
        sr.sr_net_loss             AS sr_loss
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND s.s_rec_end_date > DATE '2000-01-01'
),
combined AS (
    /* Join the two fact‑level CTEs on the common promotion key to keep the row set manageable */
    SELECT
        cs.cc_call_center_id,
        cs.cp_catalog_page_id,
        st.s_store_id,
        cs.p_promo_id,
        st.r_reason_id,
        cs.cd_gender,
        cs.cs_sales,
        st.ss_sales,
        st.sr_loss,
        cs.cs_profit,
        st.ss_profit
    FROM cs_data cs
    JOIN store_data st
        ON cs.p_promo_id = st.p_promo_id
)
SELECT
    cc_call_center_id,
    cp_catalog_page_id,
    s_store_id,
    p_promo_id,
    r_reason_id,
    cd_gender,
    SUM(cs_sales)               AS total_catalog_sales,
    SUM(ss_sales)               AS total_store_sales,
    SUM(sr_loss)                AS total_return_loss,
    SUM(cs_profit + ss_profit)  AS total_profit,
    RANK() OVER (ORDER BY SUM(cs_profit + ss_profit) DESC) AS profit_rank
FROM combined
GROUP BY CUBE (
    cc_call_center_id,
    cp_catalog_page_id,
    s_store_id,
    p_promo_id,
    r_reason_id,
    cd_gender
)
HAVING SUM(cs_sales) > 0
ORDER BY profit_rank
LIMIT 100
