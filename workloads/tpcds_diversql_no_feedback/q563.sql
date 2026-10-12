WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state AS store_state,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        c.c_customer_id,
        cd.cd_education_status,
        ca.ca_state AS addr_state,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_ext_wholesale_cost,
        ss.ss_quantity,
        cs.cs_ext_sales_price,
        sr.sr_return_amt,
        wr.wr_return_amt AS web_return_amt,
        cp.cp_description,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        t.t_hour,
        t.t_am_pm,
        wp.wp_url
    FROM
        item i
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        cd.cd_education_status IN ('College', '4 yr Degree')
        AND cc.cc_state = 'CA'
        AND s.s_state = 'CA'
        AND cp.cp_department = 'DEPARTMENT'
        AND i.i_brand = 'BrandX'
)
SELECT
    base.s_store_id,
    base.s_store_name,
    base.i_item_id,
    base.i_brand,
    base.c_customer_id,
    base.cd_education_status,
    base.ss_ticket_number,
    base.ss_net_paid,
    base.ss_ext_wholesale_cost,
    (base.ss_net_paid - base.ss_ext_wholesale_cost) / NULLIF(base.ss_ext_wholesale_cost, 0) AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY base.s_store_id ORDER BY base.ss_net_paid DESC) AS store_sales_rank,
    LAG(base.ss_net_paid) OVER (PARTITION BY base.s_store_id ORDER BY base.ss_ticket_number) AS prev_net_paid,
    SUM(base.ss_net_paid) OVER (PARTITION BY base.s_store_id ORDER BY base.ss_ticket_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM base
ORDER BY base.s_store_id, store_sales_rank
LIMIT 100
