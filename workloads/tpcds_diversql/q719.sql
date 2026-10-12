/*
Goal: Identify high‑loss returns from store and web channels (excluding any return that also appears in the catalog channel), focusing on reasons that mention price or warranty. The query demonstrates string processing (REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT, SUBSTRING), uses CTEs, UNION, EXCEPT, a scalar subquery for average loss comparison, CASE expressions, ordering and a limit.
*/
WITH
store_ret AS (
    SELECT
        sr.sr_returned_date_sk            AS date_sk,
        sr.sr_item_sk                     AS item_sk,
        sr.sr_customer_sk                 AS customer_sk,
        sr.sr_net_loss                    AS net_loss,
        r.r_reason_desc                   AS reason_desc,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        d.d_date,
        'store'                           AS channel,
        NULL                              AS wp_url
    FROM store_returns sr
    JOIN date_dim d   ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c   ON sr.sr_customer_sk     = c.c_customer_sk
    JOIN item i       ON sr.sr_item_sk         = i.i_item_sk
    JOIN reason r     ON sr.sr_reason_sk       = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price|warranty')
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk            AS date_sk,
        wr.wr_item_sk                     AS item_sk,
        wr.wr_refunded_customer_sk        AS customer_sk,
        wr.wr_net_loss                    AS net_loss,
        r.r_reason_desc                   AS reason_desc,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        d.d_date,
        'web'                             AS channel,
        wp.wp_url                         AS wp_url
    FROM web_returns wr
    JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c   ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i       ON wr.wr_item_sk           = i.i_item_sk
    JOIN reason r     ON wr.wr_reason_sk         = r.r_reason_sk
    JOIN web_page wp  ON wr.wr_web_page_sk       = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE 'http://%'
),
union_ret AS (
    SELECT * FROM store_ret
    UNION
    SELECT * FROM web_ret
),
catalog_keys AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk          AS item_sk,
        cr.cr_returning_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)find')
),
filtered_ret AS (
    SELECT *
    FROM union_ret ur
    WHERE ur.net_loss > (SELECT avg(net_loss) FROM union_ret)
)
SELECT
    CONCAT(fr.c_first_name, ' ', fr.c_last_name)                     AS customer_name,
    fr.i_item_id,
    DATE_FORMAT(fr.d_date, '%Y-%m-%d')                               AS return_date,
    fr.channel,
    CASE WHEN fr.net_loss > 100 THEN 'High' ELSE 'Low' END          AS loss_category,
    SUBSTRING(fr.reason_desc, 1, 30)                                 AS reason_snippet,
    REGEXP_EXTRACT(fr.reason_desc, '(\\w+)', 1)                     AS first_word,
    CASE
        WHEN fr.channel = 'web' AND fr.wp_url IS NOT NULL THEN CONCAT('URL:', SUBSTRING(fr.wp_url, 1, 20))
        ELSE NULL
    END                                                               AS url_prefix
FROM filtered_ret fr
EXCEPT
SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_item_id,
    DATE_FORMAT(d.d_date, '%Y-%m-%d') AS return_date,
    'catalog'                         AS channel,
    NULL                              AS loss_category,
    NULL                              AS reason_snippet,
    NULL                              AS first_word,
    NULL                              AS url_prefix
FROM catalog_keys ck
JOIN customer c ON ck.customer_sk = c.c_customer_sk
JOIN item i      ON ck.item_sk     = i.i_item_sk
JOIN date_dim d   ON ck.date_sk    = d.d_date_sk
ORDER BY loss_category DESC, return_date
LIMIT 100
