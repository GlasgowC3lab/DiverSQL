WITH date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    d.d_year,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    p.p_promo_name,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_net_paid,
    AVG(COALESCE(ss.ss_ext_discount_amt, 0)) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    ss_l.store_sales_total,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank
FROM date_filtered d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = s.s_store_sk
JOIN customer c
    ON COALESCE(ss.ss_customer_sk, sr.sr_customer_sk) = c.c_customer_sk
JOIN household_demographics hd
    ON COALESCE(ss.ss_hdemo_sk, sr.sr_hdemo_sk) = hd.hd_demo_sk
JOIN customer_address ca
    ON COALESCE(ss.ss_addr_sk, sr.sr_addr_sk) = ca.ca_address_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT SUM(ss2.ss_net_paid) AS store_sales_total
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND ss2.ss_sold_date_sk = d.d_date_sk
) ss_l ON TRUE
WHERE s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count > 1
GROUP BY
    d.d_year,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    p.p_promo_name,
    ss_l.store_sales_total
ORDER BY total_net_paid DESC
LIMIT 100
