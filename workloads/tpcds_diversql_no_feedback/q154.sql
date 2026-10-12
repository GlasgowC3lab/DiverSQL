WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cc.cc_name,
        cp.cp_type,
        cp.cp_description,
        ca_ref.ca_suite_number
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE ca_ref.ca_suite_number LIKE 'Suite %'
      AND regexp_like(ca_ref.ca_suite_number, '^Suite [0-9]+')
      AND cp.cp_description LIKE '%special%'
)
SELECT
    cc_name,
    cp_type,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_net_loss) AS total_net_loss,
    count(*) AS return_cnt,
    avg(CAST(regexp_extract(ca_suite_number, '([0-9]+)') AS integer)) AS avg_suite_num,
    min(substring(cc_name, 1, 5)) AS cc_prefix_min
FROM filtered
GROUP BY GROUPING SETS (
    (cc_name, cp_type),
    (cc_name),
    (cp_type),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
