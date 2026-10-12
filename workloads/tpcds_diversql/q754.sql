WITH joined AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cc.cc_state,
        wp.wp_autogen_flag,
        inv.inv_quantity_on_hand,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        SUM(wr.wr_return_amt) AS total_wr_return,
        SUM(sr.sr_return_amt) AS total_sr_return,
        SUM(cr.cr_return_amount) AS total_cr_return,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt,
        CASE
            WHEN SUM(ws.ws_ext_sales_price) > 0 THEN
                SUM(ws.ws_ext_sales_price) - (SUM(wr.wr_return_amt) + SUM(sr.sr_return_amt) + SUM(cr.cr_return_amount))
            ELSE 0
        END AS net_contribution
    FROM tpcds.item i
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE wp.wp_autogen_flag = 'N'
      AND inv.inv_quantity_on_hand > 600
      AND cc.cc_state = 'GA'
      AND wr.wr_account_credit > 100
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cc.cc_state,
        wp.wp_autogen_flag,
        inv.inv_quantity_on_hand
),
brand_category AS (
    SELECT
        i_brand,
        i_category,
        AVG(net_contribution) AS avg_net_contribution,
        SUM(total_ws_sales) AS sum_sales
    FROM joined
    GROUP BY i_brand, i_category
)
SELECT
    bc.i_brand,
    bc.i_category,
    bc.avg_net_contribution,
    bc.sum_sales,
    dim.rating,
    CASE WHEN bc.avg_net_contribution > 0 THEN 'POS' ELSE 'NEG' END AS contribution_sign
FROM brand_category bc
CROSS JOIN (
    SELECT 'High' AS rating UNION ALL SELECT 'Low' AS rating
) dim
WHERE bc.i_brand NOT IN (
    SELECT i_brand FROM tpcds.item WHERE i_current_price > 500
)
ORDER BY bc.avg_net_contribution DESC, dim.rating
LIMIT 100
