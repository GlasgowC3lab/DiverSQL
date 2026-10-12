WITH inventory_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d.d_year,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    iag.total_on_hand,
    CASE WHEN iag.total_on_hand > 0 THEN 'InStock' ELSE 'OutOfStock' END AS stock_status,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    COUNT(DISTINCT t.channel_word) AS distinct_token_cnt,
    cr_refunded.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
-- expand the free‑form promotion channel description into words
CROSS JOIN UNNEST(split(p.p_channel_details, ' ')) AS t (channel_word)
JOIN inventory_agg iag ON d.d_date_sk = iag.inv_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr_refunded
       ON cr_refunded.cr_refunded_customer_sk = c.c_customer_sk
      AND cr_refunded.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr_returning
       ON cr_returning.cr_returning_customer_sk = c.c_customer_sk
      AND cr_returning.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr_refunded.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr_refunded.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason cr_refunded ON cr_refunded.cr_reason_sk = cr_refunded.r_reason_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
GROUP BY
    d.d_year,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    iag.total_on_hand,
    cr_refunded.r_reason_desc,
    r_wr.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
