/*
 Goal: Analyze the combined performance of catalog, store, and web sales for each call centre in 2001, including return amounts and the diversity of operating hours, while applying several realistic filters.
*/
WITH catalog_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid)        AS total_sales,
        SUM(cs.cs_quantity)        AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk, cs.cs_order_number, cs.cs_sold_date_sk
),
store_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_paid)   AS total_store_sales,
        SUM(ss.ss_quantity)   AS total_store_qty
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
),
hours AS (
    SELECT
        cc.cc_call_center_id,
        TRIM(hour_elem) AS hour_part
    FROM call_center cc
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_elem)
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_year.d_year,
    d_year.d_month_seq,
    COUNT(DISTINCT ca.cs_order_number)          AS order_cnt,
    SUM(ca.total_sales)                         AS catalog_sales_total,
    SUM(cr.cr_return_amount)                    AS total_return_amount,
    SUM(sa.total_store_sales)                   AS store_sales_total,
    SUM(ws.ws_net_paid)                         AS web_sales_total,
    COUNT(DISTINCT h.hour_part)                 AS distinct_hours_cnt
FROM catalog_agg ca
JOIN catalog_returns cr
    ON ca.cs_item_sk = cr.cr_item_sk
   AND ca.cs_order_number = cr.cr_order_number
JOIN call_center cc
    ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_year
    ON ca.cs_sold_date_sk = d_year.d_date_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store_agg sa
    ON sa.ss_sold_date_sk = d_year.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_year.d_date_sk
LEFT JOIN hours h
    ON cc.cc_call_center_id = h.cc_call_center_id
WHERE
    cc.cc_state = 'CA'
    AND cc.cc_zip = '28482'
    AND d_year.d_year = 2001
    AND d_ret.d_month_seq BETWEEN 1 AND 12
    AND cr.cr_fee > 20
    AND sa.total_store_sales < 0
    AND ws.ws_net_paid > 1000
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    d_year.d_year,
    d_year.d_month_seq
ORDER BY
    catalog_sales_total DESC,
    cc.cc_call_center_id
LIMIT 100
