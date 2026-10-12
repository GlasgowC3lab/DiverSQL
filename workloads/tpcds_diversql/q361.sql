WITH
    -- Sales from catalog and web channels (inner joins, many dimensions)
    sales_union AS (
        SELECT
            cs.cs_order_number            AS order_id,
            cs.cs_sold_date_sk            AS date_sk,
            i.i_item_id,
            i.i_manufact_id,
            i.i_category,
            i.i_brand,
            cs.cs_quantity               AS quantity,
            cs.cs_ext_sales_price        AS sales_amount,
            cs.cs_net_profit             AS profit,
            cc.cc_name                    AS call_center_name,
            sm.sm_type                    AS ship_mode_type,
            w.w_warehouse_name           AS warehouse_name,
            p.p_promo_name                AS promo_name,
            c.c_customer_id,
            cd.cd_gender,
            ca.ca_state,
            NULL                         AS return_quantity,
            NULL                         AS return_amount,
            NULL                         AS net_loss,
            'sale'                       AS record_type
        FROM catalog_sales cs
        JOIN item i                     ON cs.cs_item_sk       = i.i_item_sk
        JOIN customer c                 ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd   ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca        ON cs.cs_bill_addr_sk  = ca.ca_address_sk
        JOIN call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm               ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
        JOIN warehouse w                ON cs.cs_warehouse_sk  = w.w_warehouse_sk
        JOIN promotion p                ON cs.cs_promo_sk      = p.p_promo_sk
        WHERE i.i_manufact_id IN (264, 460, 260)
          AND cs.cs_ext_sales_price > 100
          AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
        UNION DISTINCT
        SELECT
            ws.ws_order_number            AS order_id,
            ws.ws_sold_date_sk            AS date_sk,
            i.i_item_id,
            i.i_manufact_id,
            i.i_category,
            i.i_brand,
            ws.ws_quantity               AS quantity,
            ws.ws_ext_sales_price        AS sales_amount,
            ws.ws_net_profit             AS profit,
            NULL                         AS call_center_name,
            sm.sm_type                    AS ship_mode_type,
            w.w_warehouse_name           AS warehouse_name,
            p.p_promo_name                AS promo_name,
            c.c_customer_id,
            cd.cd_gender,
            ca.ca_state,
            NULL                         AS return_quantity,
            NULL                         AS return_amount,
            NULL                         AS net_loss,
            'sale'                       AS record_type
        FROM web_sales ws
        JOIN item i                     ON ws.ws_item_sk       = i.i_item_sk
        JOIN customer c                 ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd   ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca        ON ws.ws_bill_addr_sk  = ca.ca_address_sk
        JOIN ship_mode sm               ON ws.ws_ship_mode_sk  = sm.sm_ship_mode_sk
        JOIN warehouse w                ON ws.ws_warehouse_sk  = w.w_warehouse_sk
        JOIN promotion p                ON ws.ws_promo_sk      = p.p_promo_sk
        WHERE i.i_category = 'Electronics'
          AND ws.ws_ext_sales_price > 50
          AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    ),

    -- Store returns with a FULL OUTER JOIN to the item dimension (keeps unmatched rows on both sides)
    returns_full AS (
        SELECT
            sr.sr_ticket_number          AS order_id,
            sr.sr_returned_date_sk       AS date_sk,
            i.i_item_id,
            i.i_manufact_id,
            i.i_category,
            i.i_brand,
            sr.sr_return_quantity       AS return_quantity,
            sr.sr_return_amt            AS return_amount,
            sr.sr_net_loss              AS net_loss,
            c.c_customer_id,
            cd.cd_gender,
            ca.ca_state
        FROM store_returns sr
        FULL OUTER JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN customer c
            ON sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE (i.i_size = 'large' OR i.i_size IS NULL)
          AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
    ),

    -- Combine sales and returns, eliminating duplicates via UNION DISTINCT
    combined AS (
        SELECT * FROM sales_union
        UNION DISTINCT
        SELECT
            order_id,
            date_sk,
            i_item_id,
            i_manufact_id,
            i_category,
            i_brand,
            NULL           AS quantity,
            NULL           AS sales_amount,
            NULL           AS profit,
            NULL           AS call_center_name,
            NULL           AS ship_mode_type,
            NULL           AS warehouse_name,
            NULL           AS promo_name,
            c_customer_id,
            cd_gender,
            ca_state,
            return_quantity,
            return_amount,
            net_loss,
            'return'       AS record_type
        FROM returns_full
        WHERE net_loss > 0
    ),

    -- Apply window functions for ranking and cumulative calculations
    ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY COALESCE(sales_amount, 0) DESC NULLS LAST) AS sales_rank,
            CASE
                WHEN record_type = 'sale' AND sales_amount IS NOT NULL THEN 'High'
                WHEN record_type = 'return' AND net_loss IS NOT NULL THEN 'Loss'
                ELSE 'Other'
            END AS classification,
            SUM(COALESCE(sales_amount, 0) - COALESCE(return_amount, 0))
                OVER (PARTITION BY i_category ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net
        FROM combined
    )
SELECT *
FROM ranked
WHERE sales_rank <= 10
ORDER BY i_category, sales_rank
