WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),

joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        dd.d_year,
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        sr.sr_store_credit,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        cc.cc_name,
        cp.cp_catalog_page_number,
        sm.sm_type,
        w.w_warehouse_name,
        ti.t_hour,
        inv.inv_quantity_on_hand,
        cr.cr_item_sk
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN time_dim ti ON sr.sr_return_time_sk = ti.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = dd.d_date_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
        AND wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN sampled_inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_item_sk = cr.cr_item_sk
    WHERE dd.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND sr.sr_store_credit > 100
),

per_customer_agg AS (
    SELECT
        sr_customer_sk,
        ca_state,
        SUM(sr_store_credit) AS total_store_credit,
        AVG(inv_quantity_on_hand) AS avg_inventory_qty
    FROM joined_data
    GROUP BY sr_customer_sk, ca_state
),

key_set1 AS (
    SELECT sr_customer_sk FROM store_returns
    WHERE sr_returned_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001
    )
),

key_set2 AS (
    SELECT cr_returning_customer_sk FROM catalog_returns
    WHERE cr_returned_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001
    )
),

key_set3 AS (
    SELECT wr_returning_customer_sk FROM web_returns
    WHERE wr_returned_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001
    )
),

excluded_customers AS (
    SELECT ks1.sr_customer_sk FROM key_set1 ks1
    EXCEPT
    SELECT ks2.cr_returning_customer_sk FROM key_set2 ks2
),

common_customers AS (
    SELECT ks2.cr_returning_customer_sk FROM key_set2 ks2
    INTERSECT
    SELECT ks3.wr_returning_customer_sk FROM key_set3 ks3
),

final_agg AS (
    SELECT
        ca_state,
        COUNT(*) AS num_customers,
        SUM(total_store_credit) AS sum_store_credit,
        AVG(avg_inventory_qty) AS avg_inventory_qty_over_customers
    FROM per_customer_agg pca
    WHERE pca.sr_customer_sk NOT IN (SELECT sr_customer_sk FROM excluded_customers)
      AND pca.sr_customer_sk IN (SELECT cr_returning_customer_sk FROM common_customers)
    GROUP BY ca_state
    HAVING SUM(total_store_credit) > 5000
)

SELECT *
FROM final_agg
ORDER BY sum_store_credit DESC
LIMIT 100
