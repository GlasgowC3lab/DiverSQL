WITH
    inventory_warehouse AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_quantity_on_hand,
            w.w_warehouse_name,
            w.w_gmt_offset
        FROM inventory inv
        FULL OUTER JOIN warehouse w
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_country = 'United States'                -- predicate 1
          AND w.w_gmt_offset = -5.00                      -- predicate 2
    ),
    unified AS (
        /* Store sales side */
        SELECT
            ss.ss_sold_date_sk         AS date_sk,
            ss.ss_item_sk               AS item_sk,
            ss.ss_net_paid              AS amount,
            td.t_hour                   AS hour,
            ca.ca_state                 AS state,
            CAST('store' AS VARCHAR)    AS source,
            COALESCE(r.r_reason_desc, 'No Return') AS reason,
            NULL                        AS warehouse_name
        FROM store_sales ss
        JOIN time_dim td          ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
        WHERE c.c_birth_year > 1970                     -- predicate 3
          AND p.p_discount_active = 'Y'                -- predicate 4
          AND ss.ss_net_paid > 100                     -- predicate 5
          AND EXISTS (SELECT 1 FROM promotion p2
                      WHERE p2.p_promo_id = p.p_promo_id
                        AND p2.p_discount_active = 'Y')
        
        UNION
        
        /* Catalog returns side */
        SELECT
            cr.cr_returned_date_sk      AS date_sk,
            cr.cr_item_sk                AS item_sk,
            cr.cr_return_amount          AS amount,
            td.t_hour                   AS hour,
            ca.ca_state                 AS state,
            CAST('catalog' AS VARCHAR)   AS source,
            r.r_reason_desc              AS reason,
            w.w_warehouse_name           AS warehouse_name
        FROM catalog_returns cr
        JOIN time_dim td          ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c           ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > 50                -- predicate 6
          AND w.w_gmt_offset = -5.00                 -- predicate 7
        
        UNION
        
        /* Web returns side */
        SELECT
            wr.wr_returned_date_sk      AS date_sk,
            wr.wr_item_sk               AS item_sk,
            wr.wr_return_amt            AS amount,
            td.t_hour                   AS hour,
            ca.ca_state                 AS state,
            CAST('web' AS VARCHAR)      AS source,
            r.r_reason_desc              AS reason,
            NULL                         AS warehouse_name
        FROM web_returns wr
        JOIN time_dim td          ON wr.wr_returned_time_sk = td.t_time_sk
        JOIN customer c           ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN reason r             ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_return_ship_cost > 200            -- predicate 8
          AND c.c_preferred_cust_flag = 'Y'          -- predicate 9
    ),
    aggregated AS (
        SELECT
            u.state,
            u.source,
            u.reason,
            SUM(u.amount) AS total_amount,
            AVG(u.amount) AS avg_amount,
            inv_q.total_qty AS total_inventory_qty
        FROM unified u
        LEFT JOIN LATERAL (
            SELECT COALESCE(SUM(i.inv_quantity_on_hand),0) AS total_qty
            FROM inventory_warehouse i
            WHERE i.inv_item_sk = u.item_sk
        ) inv_q ON TRUE
        GROUP BY u.state, u.source, u.reason, inv_q.total_qty
        HAVING SUM(u.amount) > 500                     -- predicate 10
    ),
    low_amount AS (
        SELECT *
        FROM aggregated
        WHERE total_amount < 800                     -- predicate 11
    )
SELECT *
FROM aggregated
EXCEPT
SELECT *
FROM low_amount
ORDER BY total_amount DESC
LIMIT 100
