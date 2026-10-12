WITH returns AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_moy AS return_month,
        cc.cc_division AS cc_division,
        cc.cc_city AS cc_city,
        sm.sm_type AS ship_mode_type,
        i.i_category AS item_category,
        cp.cp_type AS catalog_page_type,
        r.r_reason_desc AS reason_desc,
        ws.web_site_id AS web_site_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items,
        SUM(cr.cr_store_credit) AS total_store_credit,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE cc.cc_division IN (2, 3)
      AND d_ret.d_year BETWEEN 2000 AND 2005
      AND i.i_category = 'Electronics'
      AND cp.cp_type = 'Return'
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY
        d_ret.d_year,
        d_ret.d_moy,
        cc.cc_division,
        cc.cc_city,
        sm.sm_type,
        i.i_category,
        cp.cp_type,
        r.r_reason_desc,
        ws.web_site_id
)
SELECT
    return_year,
    return_month,
    cc_division,
    ship_mode_type,
    total_return_amount,
    total_net_loss,
    total_quantity,
    distinct_items,
    total_store_credit,
    avg_quantity,
    (total_return_amount / NULLIF(total_store_credit, 0)) AS return_to_credit_ratio,
    RANK() OVER (PARTITION BY return_year, return_month, cc_division ORDER BY total_return_amount DESC) AS ship_mode_rank
FROM returns
ORDER BY return_year, return_month, cc_division, ship_mode_rank
