WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
joined_data AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        d_sold.d_date AS sale_date,
        cp.cp_department AS cp_department,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        wr.wr_return_amt AS wr_return_amt,
        inv_agg.total_on_hand AS total_on_hand,
        d_sold.d_year AS d_year
    FROM (
        SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ) cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
        AND sr.sr_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
        AND wr.wr_refunded_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN inventory_agg inv_agg
        ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        AND inv_agg.inv_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND cp.cp_department = 'Electronics'
        AND cs.cs_quantity > 5
        AND cs.cs_ext_sales_price > 1000
        AND w.w_warehouse_sq_ft > 500000
)
SELECT
    w_warehouse_name,
    sale_date,
    SUM(cs_net_profit) AS total_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    total_on_hand,
    LAG(SUM(cs_net_profit)) OVER (PARTITION BY w_warehouse_name ORDER BY sale_date) AS prev_day_profit,
    SUM(SUM(cs_net_profit)) OVER (PARTITION BY w_warehouse_name ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit
FROM joined_data
GROUP BY
    w_warehouse_name,
    sale_date,
    total_on_hand
HAVING
    SUM(cs_net_profit) > 0
ORDER BY
    w_warehouse_name,
    sale_date DESC
LIMIT 100
