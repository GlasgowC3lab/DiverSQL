WITH sampled_returns AS (
    SELECT *
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)
),

high_returns AS (
    SELECT *
    FROM sampled_returns
    WHERE cr_return_amount > 100
      AND cr_return_quantity >= 1
),

low_returns AS (
    SELECT *
    FROM sampled_returns
    WHERE cr_return_amount <= 100
),

order_numbers_excluding_low AS (
    SELECT cr_order_number
    FROM high_returns
    EXCEPT
    SELECT cr_order_number
    FROM low_returns
),

joined_base AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        cr.cr_call_center_sk,
        cc.cc_name,
        cr.cr_catalog_page_sk,
        cp.cp_department,
        cr.cr_refunded_customer_sk,
        c.c_customer_id,
        cr.cr_refunded_addr_sk,
        ca.ca_state,
        s.s_store_name,
        ws.web_name,
        inv.inv_quantity_on_hand
    FROM high_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_order_number IN (SELECT cr_order_number FROM order_numbers_excluding_low)
      AND d.d_year = 2002
      AND ca.ca_state = 'TX'
      AND ws.web_name LIKE '%Shop%'
      AND inv.inv_quantity_on_hand > 0
),

aggregated AS (
    SELECT
        d_year,
        w_warehouse_name,
        cc_name,
        cp_department,
        COUNT(DISTINCT cr_return_quantity) AS distinct_qty_cnt,
        SUM(DISTINCT cr_return_amount) AS distinct_amount_sum,
        CASE WHEN SUM(cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM joined_base
    GROUP BY GROUPING SETS (
        (d_year, w_warehouse_name),
        (cc_name, cp_department),
        ()
    )
)

SELECT
    d_year,
    w_warehouse_name,
    cc_name,
    cp_department,
    distinct_qty_cnt,
    distinct_amount_sum,
    amount_category,
    warehouse_rank
FROM (
    SELECT
        d_year,
        w_warehouse_name,
        cc_name,
        cp_department,
        distinct_qty_cnt,
        distinct_amount_sum,
        amount_category,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY distinct_amount_sum DESC) AS warehouse_rank
    FROM aggregated
) t
WHERE warehouse_rank <= 5
ORDER BY w_warehouse_name, warehouse_rank
LIMIT 100
