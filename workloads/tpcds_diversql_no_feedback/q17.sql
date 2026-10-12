WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amount
    FROM tpcds.catalog_returns
)
SELECT
    d.d_date AS return_date,
    w.w_warehouse_name,
    rc.c_last_name AS refunded_last_name,
    rc.c_first_name,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    inv.inv_quantity_on_hand,
    hd.hd_income_band_sk,
    CASE
        WHEN cr.cr_return_amount > (SELECT avg_amount FROM avg_return) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_vs_avg,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS warehouse_return_rank
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer rc
    ON cr.cr_refunded_customer_sk = rc.c_customer_sk
JOIN tpcds.household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND rc.c_last_name IN ('Wilder', 'Bernstein', 'Rubio')
  AND inv.inv_quantity_on_hand > 500
ORDER BY w.w_warehouse_name, cr.cr_return_amount DESC
LIMIT 100
