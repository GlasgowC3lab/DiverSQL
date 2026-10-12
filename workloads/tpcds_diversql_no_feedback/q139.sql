WITH joined AS (
    SELECT
        i.i_category,
        i.i_brand,
        hd1.hd_demo_sk AS hd_store_demo,
        t1.t_hour AS ss_hour,
        cs.cs_ext_sales_price AS cs_sales,
        ss.ss_ext_sales_price AS ss_sales,
        ws.ws_ext_sales_price AS ws_sales,
        cr.cr_return_amount AS cr_return,
        wr.wr_return_amt AS wr_return,
        cs.cs_net_profit AS cs_profit,
        ss.ss_net_profit AS ss_profit,
        ws.ws_net_profit AS ws_profit,
        inv.inv_quantity_on_hand AS inventory_qty,
        cs.cs_order_number AS cs_order_number
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN time_dim t1
        ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN time_dim t2
        ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN time_dim t3
        ON cr.cr_returned_time_sk = t3.t_time_sk
    JOIN time_dim t4
        ON ws.ws_sold_time_sk = t4.t_time_sk
    JOIN time_dim t5
        ON wr.wr_returned_time_sk = t5.t_time_sk
    JOIN household_demographics hd1
        ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN household_demographics hd2
        ON cs.cs_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN household_demographics hd3
        ON cs.cs_ship_hdemo_sk = hd3.hd_demo_sk
    JOIN household_demographics hd4
        ON cr.cr_refunded_hdemo_sk = hd4.hd_demo_sk
    JOIN household_demographics hd5
        ON cr.cr_returning_hdemo_sk = hd5.hd_demo_sk
    JOIN household_demographics hd6
        ON ws.ws_bill_hdemo_sk = hd6.hd_demo_sk
    JOIN household_demographics hd7
        ON ws.ws_ship_hdemo_sk = hd7.hd_demo_sk
    JOIN household_demographics hd8
        ON wr.wr_refunded_hdemo_sk = hd8.hd_demo_sk
    JOIN household_demographics hd9
        ON wr.wr_returning_hdemo_sk = hd9.hd_demo_sk
    WHERE
        cs.cs_ext_wholesale_cost > 1500
        AND cr.cr_store_credit < 100
        AND ss.ss_ext_tax BETWEEN 0.5 AND 5
        AND ws.ws_net_paid_inc_tax > 2000
        AND i.i_brand_id IN (1, 2)
        AND inv.inv_quantity_on_hand > 0
)
SELECT
    i_category,
    i_brand,
    hd_store_demo,
    ss_hour,
    SUM(cs_sales) AS total_catalog_sales,
    SUM(ss_sales) AS total_store_sales,
    SUM(ws_sales) AS total_web_sales,
    SUM(cr_return) AS total_catalog_returns,
    SUM(wr_return) AS total_web_returns,
    SUM(cs_profit + ss_profit + ws_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined
GROUP BY GROUPING SETS (
    (i_category, i_brand, hd_store_demo, ss_hour),
    (i_category, i_brand),
    (hd_store_demo),
    ()
)
ORDER BY total_catalog_sales DESC
LIMIT 100
