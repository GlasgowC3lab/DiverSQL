WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_date_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE cs.cs_quantity > 0
        AND cr.cr_return_quantity >= 0
)
SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(s.cs_net_profit) - COALESCE(SUM(s.cr_return_amount), 0) AS adjusted_net_profit,
    CASE
        WHEN (SUM(s.cs_net_profit) - COALESCE(SUM(s.cr_return_amount), 0)) > 10000 THEN 'High'
        WHEN (SUM(s.cs_net_profit) - COALESCE(SUM(s.cr_return_amount), 0)) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (
        PARTITION BY d.d_year
        ORDER BY (SUM(s.cs_net_profit) - COALESCE(SUM(s.cr_return_amount), 0)) DESC
    ) AS profit_rank
FROM sales_data s
JOIN tpcds.date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.item i
    ON s.cs_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d.d_date_sk
JOIN tpcds.customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year BETWEEN 2001 AND 2002
  AND i.i_current_price > 50
  AND w.w_state = 'CA'
  AND cc.cc_country = 'United States'
  AND sm.sm_type = 'AIR'
  AND cd.cd_purchase_estimate >= 5000
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY d.d_year, i.i_item_id, i.i_product_name
ORDER BY d.d_year, profit_rank
LIMIT 100
