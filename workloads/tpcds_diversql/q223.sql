WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_id,
        s.s_state,
        p.p_promo_name,
        hd.hd_buy_potential,
        r.r_reason_desc,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cr.cr_net_loss,
        cc.cc_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%gift%'
)
SELECT
    d_year,
    s_state,
    CASE WHEN s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category,
    COUNT(DISTINCT s_store_id) AS distinct_stores,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(cs_ext_sales_price) AS avg_ext_sales_price,
    MIN(cr_net_loss) AS min_net_loss,
    MAX(cr_net_loss) AS max_net_loss,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS revenue_rank
FROM base
GROUP BY
    d_year,
    s_state,
    CASE WHEN s_state = 'CA' THEN 'West' ELSE 'Other' END
ORDER BY total_net_paid DESC
LIMIT 100
