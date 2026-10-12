WITH
    inventory_agg AS (
        SELECT
            inv_warehouse_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory
        GROUP BY inv_warehouse_sk, inv_date_sk
    ),
    orders_without_returns AS (
        SELECT ws_order_number
        FROM web_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    base_data AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            cp.cp_catalog_page_id,
            w.w_warehouse_name,
            cd_s.cd_gender,
            cd_s.cd_marital_status,
            ws.ws_sales_price,
            ss.ss_quantity,
            i.total_quantity_on_hand,
            COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS row_profit,
            cd_s.cd_demo_sk
        FROM ss_sample ss
        INNER JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN customer_demographics cd_s
            ON ss.ss_cdemo_sk = cd_s.cd_demo_sk
        INNER JOIN inventory_agg i
            ON i.inv_date_sk = d.d_date_sk
        INNER JOIN warehouse w
            ON i.inv_warehouse_sk = w.w_warehouse_sk
        INNER JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
        INNER JOIN time_dim t_cr
            ON cr.cr_returned_time_sk = t_cr.t_time_sk
        INNER JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        INNER JOIN customer_demographics cd_ret
            ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        INNER JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t_ws
            ON ws.ws_sold_time_sk = t_ws.t_time_sk
        INNER JOIN customer_demographics cd_b
            ON ws.ws_bill_cdemo_sk = cd_b.cd_demo_sk
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN orders_without_returns od
            ON ws.ws_order_number = od.ws_order_number
        WHERE
            d.d_year = 2001
            AND t.t_hour BETWEEN 9 AND 17
            AND cd_s.cd_gender = 'F'
            AND cp.cp_type = 'monthly'
            AND w.w_country = 'United States'
            AND ws.ws_sales_price > 100
            AND i.total_quantity_on_hand > 0
    ),
    profit_ranked AS (
        SELECT
            d_year,
            d_month_seq,
            cp_catalog_page_id,
            w_warehouse_name,
            cd_gender,
            cd_marital_status,
            ws_sales_price,
            ss_quantity,
            total_quantity_on_hand,
            SUM(row_profit) OVER (PARTITION BY cd_demo_sk) AS demo_total_profit
        FROM base_data
    )
SELECT
    d_year,
    d_month_seq,
    cp_catalog_page_id,
    w_warehouse_name,
    cd_gender,
    cd_marital_status,
    ws_sales_price,
    ss_quantity,
    total_quantity_on_hand,
    demo_total_profit,
    RANK() OVER (ORDER BY demo_total_profit DESC) AS profit_rank
FROM profit_ranked
ORDER BY profit_rank ASC, d_year ASC
LIMIT 100
