WITH
    -- Sample a fraction of the inventory table
    inventory_sample AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    -- Full outer join inventory (sampled) with warehouse to keep unmatched rows from both sides
    inv_wh AS (
        SELECT
            i.inv_date_sk,
            i.inv_item_sk,
            i.inv_warehouse_sk,
            i.inv_quantity_on_hand,
            w.w_warehouse_name,
            w.w_city    AS w_warehouse_city,
            w.w_state   AS w_warehouse_state
        FROM inventory_sample i
        FULL OUTER JOIN warehouse w
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    ),
    -- Core fact: catalog returns enriched with many dimension tables
    catalog_fact AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_refunded_customer_sk          AS refunded_customer_sk,
            cr.cr_refunded_cdemo_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_returning_customer_sk,
            cr.cr_returning_cdemo_sk,
            cr.cr_returning_addr_sk,
            cr.cr_call_center_sk,
            cr.cr_catalog_page_sk,
            cr.cr_ship_mode_sk,
            cr.cr_warehouse_sk,
            cr.cr_reason_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            r.r_reason_desc,
            td.t_hour,
            td.t_minute,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            ca.ca_city
        FROM catalog_returns cr
        LEFT JOIN call_center cc      ON cr.cr_call_center_sk   = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp     ON cr.cr_catalog_page_sk  = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm        ON cr.cr_ship_mode_sk     = sm.sm_ship_mode_sk
        LEFT JOIN reason r            ON cr.cr_reason_sk        = r.r_reason_sk
        LEFT JOIN time_dim td         ON cr.cr_returned_time_sk = td.t_time_sk
        LEFT JOIN customer c          ON cr.cr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    ),
    -- Aggregate store returns per customer (used later in a correlated subquery)
    store_ret_agg AS (
        SELECT
            sr.sr_customer_sk,
            SUM(sr.sr_return_amt) AS total_store_return_amount,
            COUNT(*)               AS store_return_cnt
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
    ),
    -- Aggregate web returns per customer
    web_ret_agg AS (
        SELECT
            wr.wr_refunded_customer_sk AS customer_sk,
            SUM(wr.wr_return_amt) AS total_web_return_amount,
            COUNT(*)               AS web_return_cnt
        FROM web_returns wr
        GROUP BY wr.wr_refunded_customer_sk
    ),
    -- Customers that appear only in one of the two return streams (EXCEPT example)
    common_customers AS (
        SELECT sr_customer_sk AS customer_sk FROM store_returns
        INTERSECT
        SELECT wr_refunded_customer_sk FROM web_returns
    ),
    exclusive_customers AS (
        SELECT customer_sk FROM (
            SELECT sr_customer_sk AS customer_sk FROM store_returns
            UNION ALL
            SELECT wr_refunded_customer_sk FROM web_returns
        )
        EXCEPT
        SELECT customer_sk FROM common_customers
    ),
    -- Enrich catalog fact with inventory/warehouse and return‑aggregates, plus web page info
    final_data AS (
        SELECT
            cf.cr_returned_date_sk,
            cf.cr_return_amount,
            cf.cr_net_loss,
            cf.cc_name,
            cf.cp_department,
            cf.sm_type,
            cf.r_reason_desc,
            cf.t_hour,
            cf.c_first_name,
            cf.c_last_name,
            cf.cd_gender,
            cf.ca_city,
            iw.w_warehouse_name,
            iw.w_warehouse_city,
            iw.w_warehouse_state,
            sr.total_store_return_amount,
            sr.store_return_cnt,
            wr.total_web_return_amount,
            wr.web_return_cnt,
            -- Correlated scalar subquery counting exclusive customers for the refunded customer
            (SELECT COUNT(*)
             FROM exclusive_customers ec
             WHERE ec.customer_sk = cf.refunded_customer_sk) AS exclusive_customer_cnt,
            -- Running total of return amount per warehouse
            SUM(cf.cr_return_amount) OVER (
                PARTITION BY iw.w_warehouse_name
                ORDER BY cf.cr_returned_date_sk
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_return_amount,
            -- Lag of net loss per warehouse
            LAG(cf.cr_net_loss) OVER (
                PARTITION BY iw.w_warehouse_name
                ORDER BY cf.cr_returned_date_sk
            ) AS lag_net_loss,
            -- Web page information linked via the refunded customer
            wp.wp_url
        FROM catalog_fact cf
        LEFT JOIN inv_wh iw   ON cf.cr_warehouse_sk = iw.inv_warehouse_sk
        LEFT JOIN store_ret_agg sr ON cf.refunded_customer_sk = sr.sr_customer_sk
        LEFT JOIN web_ret_agg   wr ON cf.refunded_customer_sk = wr.customer_sk
        LEFT JOIN web_page wp   ON cf.refunded_customer_sk = wp.wp_customer_sk
        WHERE cf.cr_returned_date_sk BETWEEN 2450000 AND 2452000
          AND cf.cr_return_amount > 100
          AND cf.cr_net_loss < 0
          AND cf.cd_gender = 'M'
          AND cf.ca_city = 'Seattle'
    )
SELECT *
FROM (
    SELECT
        fd.*, 
        ROW_NUMBER() OVER (PARTITION BY fd.w_warehouse_name ORDER BY fd.cr_return_amount DESC) AS rn
    FROM final_data fd
) ranked
WHERE rn <= 3
ORDER BY w_warehouse_name, rn
LIMIT 100
