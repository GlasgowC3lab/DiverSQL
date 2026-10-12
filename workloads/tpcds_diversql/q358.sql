WITH cr_sample AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    store_item_keys AS (
        SELECT DISTINCT ss.ss_item_sk AS item_sk
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 9 AND 17
    ),
    web_return_item_keys AS (
        SELECT DISTINCT wr.wr_item_sk AS item_sk
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        WHERE ws.ws_sold_date_sk = wr.wr_returned_date_sk
    ),
    common_items AS (
        SELECT item_sk FROM store_item_keys
        INTERSECT
        SELECT item_sk FROM web_return_item_keys
    ),
    joined_data AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            ca_returning.ca_state           AS returning_state,
            cd_returning.cd_gender          AS returning_gender,
            hd_returning.hd_income_band_sk  AS returning_income_band,
            sm.sm_type                      AS ship_type,
            r.r_reason_desc                 AS reason_desc,
            i.i_brand,
            i.i_category,
            p.p_promo_name,
            lc.return_cnt,
            CASE WHEN cr.cr_net_loss > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_flag
        FROM cr_sample cr
        JOIN customer_address ca_returning
            ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN customer_demographics cd_returning
            ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN household_demographics hd_returning
            ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
        JOIN customer c_refunded
            ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
        JOIN customer c_returning
            ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS return_cnt
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
        ) lc ON true
        WHERE cr.cr_item_sk IN (SELECT item_sk FROM common_items)
    ),
    agg AS (
        SELECT
            returning_state,
            loss_flag,
            ship_type,
            COUNT(*)                                    AS total_returns,
            SUM(cr_return_amount)                       AS total_return_amount,
            COUNT(DISTINCT i_brand)                     AS distinct_brands_returned,
            COUNT(DISTINCT i_category)                 AS distinct_categories_returned,
            SUM(CASE WHEN loss_flag = 'LOSS' THEN cr_net_loss ELSE 0 END) AS total_net_loss,
            AVG(return_cnt)                             AS avg_customer_prior_returns
        FROM joined_data
        GROUP BY returning_state, loss_flag, ship_type
    ),
    inventory_sales AS (
        SELECT
            i.i_item_sk,
            inv.inv_quantity_on_hand,
            ss.ss_quantity,
            i.i_product_name
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        FULL OUTER JOIN (
            SELECT ss_item_sk, ss_quantity
            FROM store_sales
        ) ss ON ss.ss_item_sk = i.i_item_sk
    )
SELECT *
FROM agg
FULL OUTER JOIN inventory_sales ON true
ORDER BY total_returns DESC, returning_state
LIMIT 100
