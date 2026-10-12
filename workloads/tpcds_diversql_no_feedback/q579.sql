WITH joined_data AS (
    SELECT
        i.i_item_id               AS item_id,
        td.t_hour                 AS hour,
        ss.ss_ext_sales_price     AS store_sales_amount,
        sr.sr_return_amt          AS store_return_amount,
        cs.cs_ext_sales_price     AS catalog_sales_amount,
        cr.cr_return_amount       AS catalog_return_amount,
        wr.wr_return_amt          AS web_return_amount
    FROM store_sales ss
    RIGHT OUTER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    INNER JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
       AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r_catalog
        ON cr.cr_reason_sk = r_catalog.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE td.t_hour BETWEEN 8 AND 16
      AND w.w_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_class = 'C'
      AND r_store.r_reason_desc LIKE '%Customer%'
      AND cs.cs_ext_sales_price > 500
)
SELECT
    COALESCE(item_id, 'ALL_ITEMS') AS item_id,
    hour,
    SUM(store_sales_amount)   AS total_store_sales,
    SUM(store_return_amount)  AS total_store_returns,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(catalog_return_amount) AS total_catalog_returns,
    SUM(web_return_amount)    AS total_web_returns
FROM joined_data
GROUP BY ROLLUP (item_id, hour)
ORDER BY item_id, hour
