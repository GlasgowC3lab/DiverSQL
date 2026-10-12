-- Goal:  Compare sales performance across catalog, store, and web channels per item and month, including inventory and returns, while keeping only catalog sales that have no matching store return (anti‑join) and preserving unmatched rows from the full outer joins.
WITH
    -- Base sales from the catalog with its date information
    cs_base AS (
        SELECT cs.*, d.d_year, d.d_month_seq
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    )
SELECT
    i_cat.i_item_id,
    d_cs.d_year,
    d_cs.d_month_seq,
    SUM(COALESCE(cs.cs_ext_sales_price, 0))               AS total_catalog_sales,
    SUM(COALESCE(ss.ss_ext_sales_price, 0))               AS total_store_sales,
    SUM(COALESCE(ws.ws_ext_sales_price, 0))               AS total_web_sales,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0))            AS total_inventory_onhand,
    SUM(COALESCE(sr.sr_return_quantity, 0))               AS total_store_return_qty,
    SUM(COALESCE(wr.wr_return_quantity, 0))               AS total_web_return_qty
FROM
    catalog_sales cs
    JOIN date_dim d_cs                                 ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer c_bill                               ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill                ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill               ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN item i_cat                                    ON cs.cs_item_sk = i_cat.i_item_sk

    -- Full outer joins to bring in store and web sales for the same item/date
    FULL OUTER JOIN store_sales ss
        ON cs.cs_item_sk = ss.ss_item_sk
       AND cs.cs_sold_date_sk = ss.ss_sold_date_sk

    FULL OUTER JOIN web_sales ws
        ON cs.cs_item_sk = ws.ws_item_sk
       AND cs.cs_sold_date_sk = ws.ws_sold_date_sk

    -- Additional dimension joins for the store and web facts
    JOIN date_dim d_ss                                 ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN date_dim d_ws                                 ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i_ss                                     ON ss.ss_item_sk = i_ss.i_item_sk
    JOIN item i_ws                                     ON ws.ws_item_sk = i_ws.i_item_sk

    -- Left joins to bring in returns, inventory, web page and site info
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk

    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk

    LEFT JOIN inventory inv
        ON cs.cs_item_sk = inv.inv_item_sk
       AND cs.cs_sold_date_sk = inv.inv_date_sk

    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk

    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
          AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
    )
GROUP BY
    i_cat.i_item_id,
    d_cs.d_year,
    d_cs.d_month_seq
ORDER BY
    total_catalog_sales DESC
LIMIT 100
