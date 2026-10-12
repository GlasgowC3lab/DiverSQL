WITH cs_aggs AS (
    SELECT
        cs.cs_call_center_sk AS cs_call_center_sk,
        cs.cs_item_sk AS cs_item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'                                   -- predicate 1
      AND i.i_category_id IN (1, 5, 9)                         -- predicate 2
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910       -- predicate 3 (surrogate date range)
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
cr_aggs AS (
    SELECT
        cr.cr_call_center_sk AS cr_call_center_sk,
        cr.cr_item_sk AS cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'                                   -- predicate 1 (re‑used)
      AND i.i_category_id IN (1, 5, 9)                         -- predicate 2 (re‑used)
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910  -- predicate 3 (surrogate date range)
    GROUP BY cr.cr_call_center_sk, cr.cr_item_sk
),
ws_aggs AS (
    SELECT
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_web_page_sk AS ws_web_page_sk,
        wp.wp_image_count AS wp_image_count,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        COUNT(*) AS ws_cnt
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE wp.wp_image_count >= 3                              -- predicate 4
      AND i.i_category_id IN (1, 5, 9)                         -- predicate 2 (re‑used)
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910      -- predicate 3 (surrogate date range)
    GROUP BY ws.ws_item_sk, ws.ws_web_page_sk, wp.wp_image_count
),
intersect_keys AS (
    SELECT cs_call_center_sk AS cc_sk, cs_item_sk AS item_sk FROM cs_aggs
    INTERSECT
    SELECT cr_call_center_sk AS cc_sk, cr_item_sk AS item_sk FROM cr_aggs
)
SELECT
    cc_dim.cc_name,
    i.i_product_name,
    COALESCE(cs.total_net_paid, 0)      AS total_net_paid,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ws.total_ws_net_paid, 0)   AS total_ws_net_paid
FROM intersect_keys ik
LEFT JOIN cs_aggs cs
    ON ik.cc_sk = cs.cs_call_center_sk AND ik.item_sk = cs.cs_item_sk
LEFT JOIN cr_aggs cr
    ON ik.cc_sk = cr.cr_call_center_sk AND ik.item_sk = cr.cr_item_sk
LEFT JOIN ws_aggs ws
    ON ik.item_sk = ws.ws_item_sk
RIGHT OUTER JOIN call_center cc_dim
    ON ik.cc_sk = cc_dim.cc_call_center_sk
LEFT JOIN item i
    ON ik.item_sk = i.i_item_sk
WHERE cc_dim.cc_state = 'CA'
ORDER BY total_net_paid DESC
LIMIT 100
