WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_class,
        cc_mkt_desc,
        cc_city,
        cc_state,
        regexp_extract(cc_mkt_desc, '(\\w+)', 1) AS mkt_first_word,
        CONCAT(cc_name, ' - ', cc_state) AS cc_full_name
    FROM tpcds.call_center
    WHERE regexp_like(cc_mkt_desc, '(?i)rich|future|young')
      AND cc_city LIKE 'S%'
),
agg AS (
    SELECT
        fc.cc_mkt_desc,
        fc.cc_class,
        fc.mkt_first_word,
        arbitrary(fc.cc_full_name) AS cc_full_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt
    FROM filtered_cc fc
    JOIN tpcds.catalog_returns cr
      ON cr.cr_call_center_sk = fc.cc_call_center_sk
    WHERE cr.cr_return_quantity > 10
    GROUP BY ROLLUP (fc.cc_mkt_desc, fc.cc_class, fc.mkt_first_word)
)
SELECT
    cc_mkt_desc,
    cc_class,
    mkt_first_word,
    cc_full_name,
    total_return_amount,
    total_return_inc_tax,
    return_cnt,
    RANK() OVER (PARTITION BY cc_mkt_desc ORDER BY total_return_inc_tax DESC) AS market_rank,
    SUM(total_return_inc_tax) OVER () AS grand_total_inc_tax
FROM agg
ORDER BY cc_mkt_desc NULLS LAST,
         cc_class NULLS LAST,
         total_return_inc_tax DESC
LIMIT 100
