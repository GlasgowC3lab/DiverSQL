WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
        i.i_brand,
        i.i_manufact_id
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)hard|private')
      AND i.i_brand LIKE 'Brand%'
)
SELECT
    cc.cc_state,
    w.w_city,
    fi.first_word,
    concat(cc.cc_name, ' (', cc.cc_state, ')') AS call_center_full,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COUNT(DISTINCT sr.sr_store_sk) AS distinct_stores,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(DISTINCT sr.sr_return_amt) AS total_distinct_return_amt
FROM filtered_items fi
JOIN store_sales ss
    ON ss.ss_item_sk = fi.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr
    ON cr.cr_item_sk = fi.i_item_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
GROUP BY
    cc.cc_state,
    w.w_city,
    fi.first_word,
    cc.cc_name,
    cc.cc_state
ORDER BY total_sales DESC
LIMIT 100
