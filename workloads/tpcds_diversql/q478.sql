WITH c_not_return AS (
        SELECT c_customer_sk
        FROM customer
        EXCEPT
        SELECT sr_customer_sk
        FROM store_returns
    )
SELECT
    sr.sr_ticket_number,
    d_ret.d_date AS return_date,
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    w.w_warehouse_name,
    cr.cr_return_amount,
    ws.ws_net_paid,
    LAG(sr.sr_return_amt) OVER (PARTITION BY sr.sr_customer_sk ORDER BY d_ret.d_date) AS prev_return_amount,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = sr.sr_customer_sk
    ) AS total_customer_web_sales,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr.sr_customer_sk
    ) AS customer_return_count,
    (
        SELECT COUNT(*)
        FROM (
            SELECT c_customer_sk FROM customer EXCEPT SELECT sr_customer_sk FROM store_returns
        ) AS diff
        WHERE diff.c_customer_sk = c.c_customer_sk
    ) AS missing_return_flag
FROM store_returns sr
INNER JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
INNER JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
INNER JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
INNER JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_returned_date_sk = d_ret.d_date_sk
INNER JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE c.c_customer_sk NOT IN (SELECT cr_refunded_customer_sk FROM catalog_returns)
ORDER BY d_ret.d_date DESC
LIMIT 100
