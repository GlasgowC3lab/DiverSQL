/*
Goal: Analyze sales performance per item, warehouse and call center while incorporating related returns from catalog, store and web channels. The query joins all 12 selected TPC‑DS tables using the allowed foreign‑key relationships, aggregates sales and return amounts, flags items with any catalog returns, excludes orders with large catalog refunds via an anti‑semi‑join, orders by total sales and limits the output.
*/
SELECT
    cs.cs_sold_date_sk               AS sold_date_sk,
    i.i_item_id                      AS item_id,
    i.i_brand                        AS brand,
    w.w_warehouse_name               AS warehouse_name,
    cc.cc_name                       AS call_center_name,
    SUM(cs.cs_ext_sales_price)       AS total_sales,
    SUM(cr.cr_return_amount)         AS total_catalog_return,
    SUM(sr.sr_return_amt)            AS total_store_return,
    SUM(wr.wr_return_amt)            AS total_web_return,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'Returned' ELSE 'No Return' END AS catalog_return_flag
FROM
    catalog_sales cs
    -- dimensions for sales
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN time_dim td_sold               ON cs.cs_sold_time_sk = td_sold.t_time_sk

    -- catalog returns linked to the same order/item
    JOIN catalog_returns cr            ON cs.cs_order_number = cr.cr_order_number
                                        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN time_dim td_cr                ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN reason r_cr                   ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN warehouse w_cr               ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN call_center cc_cr            ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
    JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk

    -- store returns for the same item
    JOIN store_returns sr              ON cs.cs_item_sk = sr.sr_item_sk
    JOIN time_dim td_sr                ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN store s                       ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr                  ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk

    -- web returns for the same item
    JOIN web_returns wr                ON cs.cs_item_sk = wr.wr_item_sk
    JOIN time_dim td_wr                ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN reason r_wr                  ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk

    -- inventory snapshot for the item/warehouse pair
    JOIN inventory inv                 ON cs.cs_item_sk = inv.inv_item_sk
                                        AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
WHERE
    cs.cs_order_number NOT IN (
        SELECT cr2.cr_order_number
        FROM catalog_returns cr2
        WHERE cr2.cr_return_amount > 1000
    )
GROUP BY
    cs.cs_sold_date_sk,
    i.i_item_id,
    i.i_brand,
    w.w_warehouse_name,
    cc.cc_name
ORDER BY
    total_sales DESC
LIMIT 100
