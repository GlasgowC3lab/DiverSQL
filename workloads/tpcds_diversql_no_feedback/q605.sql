WITH cr_join AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id AS cc_id,
        cc.cc_name,
        cc.cc_city,
        cr.cr_return_amount,
        r.r_reason_desc,
        d.d_year
    FROM call_center cc
    JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_city, '^A')
      AND d.d_year = 2000
      AND regexp_like(r.r_reason_desc, '(?i)damage|defect')
)
SELECT
    cc_id,
    cc_name,
    cc_city,
    concat(cc_name, ' - ', cc_city) AS call_center_label,
    sum(cr_return_amount) AS total_return_amount,
    count(*) AS return_cnt
FROM cr_join
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE regexp_like(wp.wp_url, concat('.*', cc_name, '.*'))
)
GROUP BY cc_id, cc_name, cc_city
ORDER BY total_return_amount DESC
LIMIT 100
