WITH dim_promo AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_dmail,
        p.p_discount_active
    FROM tpcds.date_dim d
    FULL OUTER JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
)
SELECT
    dpp.d_date,
    dpp.d_year,
    c.c_customer_id,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    CASE
        WHEN dpp.p_discount_active = 'Y' THEN ss.ss_net_paid * 0.9
        ELSE ss.ss_net_paid
    END AS adjusted_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_net_paid DESC) AS rn_customer,
    RANK() OVER (ORDER BY ss.ss_net_paid DESC) AS rank_overall,
    SUM(ss.ss_net_paid) OVER (PARTITION BY dpp.d_year) AS yearly_sales_total
FROM dim_promo dpp
RIGHT JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = dpp.d_date_sk
LEFT JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = dpp.d_date_sk
LEFT JOIN tpcds.inventory i
    ON i.inv_date_sk = dpp.d_date_sk
LEFT JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = dpp.d_date_sk
LEFT JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = dpp.d_date_sk
LEFT JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = dpp.d_date_sk
WHERE
    dpp.d_year = 2001
    AND (dpp.p_channel_dmail = 'Y' OR dpp.p_channel_dmail IS NULL)
    AND (cp.cp_catalog_number IN (15, 19) OR cp.cp_catalog_number IS NULL)
    AND i.inv_quantity_on_hand > 0
    AND (cc.cc_state = 'GA' OR cc.cc_state IS NULL)
ORDER BY
    rank_overall,
    adjusted_net_paid DESC
LIMIT 100
