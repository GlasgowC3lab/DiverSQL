WITH rtn_agg AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns,
        MAX(cr_returned_date_sk) AS max_return_date_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 0
      AND cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr_fee < 200
      AND cr_reversed_charge <> 0
      AND cr_store_credit IS NOT NULL
    GROUP BY cr_item_sk, cr_warehouse_sk, cr_call_center_sk, cr_catalog_page_sk
),
profit_flag AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        sum_return_amount,
        sum_net_loss,
        cnt_returns,
        max_return_date_sk,
        CASE WHEN sum_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_status
    FROM rtn_agg
    WHERE cnt_returns >= 5
)
SELECT
    item_id,
    product_name,
    warehouse_name,
    call_center_name,
    category,
    profit_status,
    sum_return_amount,
    sum_net_loss,
    cnt_returns,
    price_vs_avg,
    running_sum_by_category
FROM (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        w.w_warehouse_name AS warehouse_name,
        cc.cc_name AS call_center_name,
        i.i_category AS category,
        pf.profit_status,
        pf.sum_return_amount,
        pf.sum_net_loss,
        pf.cnt_returns,
        CASE
            WHEN pf.sum_return_amount > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_units = 'Ounce')
            THEN 'ABOVE_AVG'
            ELSE 'BELOW_AVG'
        END AS price_vs_avg,
        SUM(pf.sum_return_amount) OVER (PARTITION BY i.i_category ORDER BY pf.sum_return_amount DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum_by_category
    FROM profit_flag pf
    JOIN item i ON pf.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON pf.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON pf.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON pf.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_units = 'Ounce'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'NY'
      AND cc.cc_county = 'Bronx County'
      AND cp.cp_department = 'Electronics'
      AND i.i_manager_id IN (6, 18, 25)
      AND EXISTS (SELECT 1 FROM call_center cc2 WHERE cc2.cc_state = cc.cc_state AND cc2.cc_gmt_offset > 0)
) q1
UNION
SELECT
    item_id,
    product_name,
    warehouse_name,
    call_center_name,
    category,
    profit_status,
    sum_return_amount,
    sum_net_loss,
    cnt_returns,
    price_vs_avg,
    running_sum_by_category
FROM (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        w.w_warehouse_name AS warehouse_name,
        cc.cc_name AS call_center_name,
        i.i_category AS category,
        pf.profit_status,
        pf.sum_return_amount,
        pf.sum_net_loss,
        pf.cnt_returns,
        CASE
            WHEN pf.sum_return_amount > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_units = 'Ounce')
            THEN 'ABOVE_AVG'
            ELSE 'BELOW_AVG'
        END AS price_vs_avg,
        SUM(pf.sum_return_amount) OVER (PARTITION BY i.i_category ORDER BY pf.sum_return_amount DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum_by_category
    FROM profit_flag pf
    JOIN item i ON pf.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON pf.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON pf.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON pf.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_units = 'Box'
      AND w.w_state = 'TX'
      AND cc.cc_state = 'FL'
      AND cc.cc_county = 'Maverick County'
      AND cp.cp_department = 'Home'
      AND i.i_manager_id NOT IN (6, 18, 25)
      AND EXISTS (SELECT 1 FROM catalog_page cp2 WHERE cp2.cp_type = cp.cp_type AND cp2.cp_department = 'Home')
) q2
ORDER BY sum_return_amount DESC
OFFSET 0 LIMIT 100
