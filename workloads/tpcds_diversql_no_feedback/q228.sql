WITH unified AS (
    SELECT
        d.d_year,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        p.p_promo_id,
        r.r_reason_desc,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(cr.cr_return_amount) AS avg_catalog_return,
        SUM(sr.sr_return_amt) AS total_store_return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY d.d_year, c.c_current_hdemo_sk, hd.hd_income_band_sk, p.p_promo_id, r.r_reason_desc

    UNION DISTINCT

    SELECT
        d.d_year,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        p.p_promo_id,
        r.r_reason_desc,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(cr.cr_return_amount) AS avg_catalog_return,
        SUM(sr.sr_return_amt) AS total_store_return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND p.p_discount_active = 'N'
      AND r.r_reason_desc LIKE '%late%'
    GROUP BY d.d_year, c.c_current_hdemo_sk, hd.hd_income_band_sk, p.p_promo_id, r.r_reason_desc
)
SELECT
    d_year,
    c_current_hdemo_sk,
    hd_income_band_sk,
    p_promo_id,
    r_reason_desc,
    SUM(total_net_profit) AS total_net_profit,
    SUM(unique_customers) AS total_unique_customers,
    AVG(avg_catalog_return) AS avg_catalog_return,
    SUM(total_store_return_amt) AS total_store_return_amt
FROM unified
GROUP BY d_year, c_current_hdemo_sk, hd_income_band_sk, p_promo_id, r_reason_desc
ORDER BY total_net_profit DESC
LIMIT 100
