WITH
    /* Lateral aggregate of store returns per store */
    store_return_agg AS (
        SELECT
            s.s_store_sk,
            COUNT(*) AS returns_cnt,
            SUM(sr.sr_return_amt) AS returns_total
        FROM
            store s
            LEFT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        GROUP BY
            s.s_store_sk
    )
SELECT
    d1.d_year,
    s.s_store_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MIN(ss.ss_quantity) AS min_quantity,
    MAX(ss.ss_quantity) AS max_quantity,
    ra.returns_cnt,
    ra.returns_total
FROM
    store_sales ss
    /* join to promotion (fact to dim) */
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    /* join to date dimension for the sale date */
    LEFT JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    /* right outer join to retain all stores, even those with no sales */
    RIGHT OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    /* lateral join to bring back aggregated return info for each store */
    LEFT JOIN LATERAL (
        SELECT returns_cnt, returns_total
        FROM store_return_agg ra
        WHERE ra.s_store_sk = s.s_store_sk
    ) ra ON TRUE
    /* join to customer via the sales fact */
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    /* join to household demographics via current household of the customer */
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    /* join to store returns via ticket number (one‑to‑one with the sale) */
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    /* join to reason for the store return */
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    /* join to catalog returns using the same reason */
    LEFT JOIN catalog_returns cr ON r.r_reason_sk = cr.cr_reason_sk
    /* join to call centre that processed the catalog return */
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    /* join to a second copy of the date dimension for the call‑centre closed date */
    LEFT JOIN date_dim d2 ON cc.cc_closed_date_sk = d2.d_date_sk
    /* join to catalog page that the return originated from */
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    /* join to a third copy of the date dimension for the catalog page end date */
    LEFT JOIN date_dim d3 ON cp.cp_end_date_sk = d3.d_date_sk
    /* join to web page using the catalog page’s end‑date as a surrogate key */
    LEFT JOIN web_page wp ON d3.d_date_sk = wp.wp_creation_date_sk
    /* finally join to web returns that reference the same web page */
    LEFT JOIN web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    d1.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND cc.cc_market_manager = 'John Doe'
    AND cr.cr_return_quantity > 1
    AND wr.wr_return_amt > 100.00
GROUP BY
    d1.d_year,
    s.s_store_name,
    ra.returns_cnt,
    ra.returns_total
ORDER BY
    total_net_paid DESC
LIMIT 100
