SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COALESCE(SUM(sr.sr_net_loss), 0) AS store_return_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_return_net_loss,
    COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_loss,
    COUNT(DISTINCT s.s_store_sk) FILTER (WHERE s.s_closed_date_sk IS NOT NULL) AS stores_closed,
    COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
    COUNT(DISTINCT wp_access.wp_web_page_sk) AS pages_accessed,
    AVG(CASE WHEN cr.cr_return_amt_inc_tax IS NOT NULL THEN cr.cr_return_amt_inc_tax END) AS avg_catalog_return_amt_inc_tax,
    AVG(CASE WHEN sr.sr_return_amt_inc_tax IS NOT NULL THEN sr.sr_return_amt_inc_tax END) AS avg_store_return_amt_inc_tax
FROM
    date_dim d
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    s.s_state
HAVING
    COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(cr.cr_net_loss), 0) > 0
ORDER BY
    d.d_year,
    s.s_state
