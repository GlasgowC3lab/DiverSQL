WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        cc.cc_name,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(sr.sr_refunded_cash) AS total_returns,
        i.i_brand,
        ib.ib_upper_bound,
        cc.cc_state,
        s.s_tax_percentage,
        MAX(i.i_item_sk) AS i_item_sk
    FROM
        tpcds.date_dim d
        JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN tpcds.catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
        JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
        LEFT JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                                      AND ss.ss_store_sk = s.s_store_sk
        LEFT JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_store_sk = s.s_store_sk
        LEFT JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                                      AND ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN tpcds.web_site web ON ws.ws_web_site_sk = web.web_site_sk
        LEFT JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_state = 'CA'
        AND s.s_tax_percentage > 0.05
        AND ib.ib_upper_bound <= 50000
        AND i.i_brand = 'Brand#45'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        cc.cc_name,
        i.i_category,
        i.i_brand,
        ib.ib_upper_bound,
        cc.cc_state,
        s.s_tax_percentage
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.d_year,
    b.cc_name,
    b.i_category,
    b.total_sales,
    b.total_returns,
    RANK() OVER (ORDER BY b.total_sales DESC) AS sales_rank,
    ps.promo_item_cnt,
    dim.dummy
FROM
    base b
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS promo_item_cnt
        FROM tpcds.promotion p2
        WHERE p2.p_item_sk = b.i_item_sk
    ) ps ON TRUE
    CROSS JOIN (VALUES (1), (2)) AS dim(dummy)
ORDER BY
    sales_rank,
    b.s_store_id
LIMIT 100
