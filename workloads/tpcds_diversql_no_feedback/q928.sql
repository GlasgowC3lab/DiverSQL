WITH base AS (
    SELECT
        s.s_store_name,
        r.r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
        SUM(cr.cr_return_amount) AS catalog_return_total,
        (SUM(sr.sr_return_amt_inc_tax) + SUM(wr.wr_return_amt_inc_tax) + SUM(cr.cr_return_amount)) AS total_return_amount
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsp ON ws.ws_web_site_sk = wsp.web_site_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        sm.sm_carrier IN ('USPS', 'ZOUROS', 'GREAT EASTERN')
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND ib.ib_upper_bound > 50000
        AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
        AND wsp.web_country = 'United States'
    GROUP BY
        s.s_store_name,
        r.r_reason_desc
), carriers AS (
    SELECT sm_carrier FROM (VALUES 'USPS', 'ZOUROS', 'GREAT EASTERN') AS t(sm_carrier)
)
SELECT
    base.s_store_name,
    base.r_reason_desc,
    base.total_return_amount,
    carriers.sm_carrier
FROM base
CROSS JOIN carriers
ORDER BY base.total_return_amount DESC
LIMIT 100
