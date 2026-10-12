WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        p.p_promo_id,
        p.p_promo_name,
        s.s_store_name,
        ws.web_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND ws.web_class = 'Unknown'
      AND p.p_discount_active = 'Y'
)
SELECT
    p_promo_id,
    p_promo_name,
    s_store_name,
    web_name,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(cr_net_loss + sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr_net_loss + sr_net_loss) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY SUM(cr_net_loss + sr_net_loss) DESC) AS rn
FROM base
GROUP BY
    p_promo_id,
    p_promo_name,
    s_store_name,
    web_name
ORDER BY rn
LIMIT 100
