WITH filtered_returns AS (
    SELECT cr.*, d.d_year, d.d_month_seq, d.d_quarter_seq
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
),

call_center_info AS (
    SELECT cc.cc_call_center_sk, cc.cc_city, cc.cc_state, cc.cc_gmt_offset
    FROM call_center cc
    WHERE cc.cc_gmt_offset = -6.00
),

warehouse_info AS (
    SELECT w.w_warehouse_sk, w.w_state, w.w_country
    FROM warehouse w
    WHERE w.w_country = 'United States'
)
SELECT
    ci.cc_city,
    wi.w_state,
    cp.cp_type,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    RANK() OVER (ORDER BY SUM(fr.cr_net_loss) DESC) AS net_loss_rank
FROM filtered_returns fr
JOIN call_center_info ci ON fr.cr_call_center_sk = ci.cc_call_center_sk
JOIN warehouse_info wi ON fr.cr_warehouse_sk = wi.w_warehouse_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY ci.cc_city, wi.w_state, cp.cp_type
HAVING SUM(fr.cr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 10
