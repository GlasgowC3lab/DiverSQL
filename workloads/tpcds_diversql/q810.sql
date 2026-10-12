WITH all_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk,
        p.p_promo_name,
        p.p_discount_active,
        cp.cp_department,
        sm.sm_type AS ship_type,
        r.r_reason_desc,
        ws.ws_net_paid AS web_net_paid,
        ss.ss_net_paid AS store_net_paid,
        cs.cs_net_paid AS catalog_net_paid,
        cr.cr_net_loss AS return_net_loss,
        cs.cs_quantity,
        CASE WHEN cs.cs_quantity > 5 THEN 'High' ELSE 'Low' END AS qty_category
    FROM date_dim d
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
union_data AS (
    SELECT
        d_year,
        d_month_seq,
        p_promo_name,
        SUM(catalog_net_paid) AS catalog_sales,
        SUM(store_net_paid)   AS store_sales,
        SUM(web_net_paid)     AS web_sales,
        SUM(return_net_loss)  AS returns_loss,
        COUNT(*)              AS txn_count,
        SUM(CASE WHEN qty_category = 'High' THEN 1 ELSE 0 END) AS high_qty_txns
    FROM all_data
    WHERE d_year = 2001
      AND p_discount_active = 'Y'
      AND ca_state = 'CA'
    GROUP BY d_year, d_month_seq, p_promo_name

    UNION

    SELECT
        d_year,
        d_month_seq,
        p_promo_name,
        SUM(catalog_net_paid) AS catalog_sales,
        SUM(store_net_paid)   AS store_sales,
        SUM(web_net_paid)     AS web_sales,
        SUM(return_net_loss)  AS returns_loss,
        COUNT(*)              AS txn_count,
        SUM(CASE WHEN qty_category = 'High' THEN 1 ELSE 0 END) AS high_qty_txns
    FROM all_data
    WHERE d_year = 2000
      AND p_discount_active = 'N'
      AND ca_state = 'TX'
    GROUP BY d_year, d_month_seq, p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    p_promo_name,
    SUM(catalog_sales) AS total_catalog_sales,
    SUM(store_sales)   AS total_store_sales,
    SUM(web_sales)     AS total_web_sales,
    SUM(returns_loss)  AS total_returns_loss,
    SUM(txn_count)     AS total_txn,
    SUM(high_qty_txns) AS total_high_qty_txns,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(catalog_sales) DESC) AS rank_by_catalog_sales
FROM union_data
GROUP BY ROLLUP (d_year, d_month_seq, p_promo_name)
ORDER BY d_year, d_month_seq, p_promo_name
LIMIT 100
