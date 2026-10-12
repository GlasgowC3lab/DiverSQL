WITH
    full_ware_inv AS (
        SELECT
            w.w_warehouse_name,
            inv.inv_quantity_on_hand
        FROM warehouse w
        FULL OUTER JOIN inventory inv
            ON w.w_warehouse_sk = inv.inv_warehouse_sk
    ),
    base AS (
        SELECT
            cr.cr_returned_date_sk,
            i.i_item_id,
            i.i_product_name,
            cp.cp_department,
            w.w_warehouse_name,
            r.r_reason_desc,
            cd_ref.cd_gender         AS refunded_gender,
            cd_ret.cd_gender         AS returning_gender,
            ca_ref.ca_state          AS refunded_state,
            ca_ret.ca_state          AS returning_state,
            inv.inv_quantity_on_hand,
            sr.sr_return_amt,
            wr.wr_return_amt,
            cr.cr_return_amount,
            cr.cr_net_loss,
            CASE
                WHEN cr.cr_return_amount > 100 THEN 'High'
                ELSE 'Low'
            END                       AS return_amount_category
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
        LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    ),
    agg_base AS (
        SELECT
            return_amount_category,
            cp_department,
            COUNT(*)                                      AS cnt,
            SUM(cr_return_amount)                         AS total_return_amount,
            SUM(cr_net_loss)                              AS total_net_loss,
            ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cr_return_amount) DESC) AS dept_rank
        FROM base
        GROUP BY return_amount_category, cp_department
    ),
    union_set AS (
        SELECT
            return_amount_category,
            cp_department,
            cnt,
            total_return_amount,
            total_net_loss,
            dept_rank
        FROM agg_base
        UNION
        SELECT
            'All'                                          AS return_amount_category,
            cp_department,
            COUNT(*)                                      AS cnt,
            SUM(cr_return_amount)                         AS total_return_amount,
            SUM(cr_net_loss)                              AS total_net_loss,
            ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cr_return_amount) DESC) AS dept_rank
        FROM base
        GROUP BY cp_department
    ),
    final_set AS (
        SELECT *
        FROM union_set
        EXCEPT
        SELECT *
        FROM agg_base
        WHERE return_amount_category = 'Low'
    ),
    enriched AS (
        SELECT
            f.return_amount_category,
            f.cp_department,
            f.cnt,
            f.total_return_amount,
            f.total_net_loss,
            f.dept_rank,
            fw.inv_quantity_on_hand
        FROM final_set f
        LEFT JOIN full_ware_inv fw
            ON f.cp_department = fw.w_warehouse_name
    )
SELECT
    return_amount_category,
    cp_department,
    cnt,
    total_return_amount,
    total_net_loss,
    inv_quantity_on_hand
FROM enriched
WHERE dept_rank <= 5
ORDER BY total_return_amount DESC
LIMIT 100
