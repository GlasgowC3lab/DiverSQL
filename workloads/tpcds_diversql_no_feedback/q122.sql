WITH base AS (
    SELECT
        ws.ws_order_number AS order_number,
        d_sold.d_year AS d_year,
        i.i_brand AS brand,
        s.s_store_name AS store_name,
        ws.ws_net_paid AS net_paid,
        ws.ws_sales_price AS sales_price,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        i.i_current_price AS current_price,
        -- correlated scalar subquery: total return amount for the same item and sold date
        (SELECT SUM(sr2.sr_return_amt)
         FROM tpcds.store_returns sr2
         WHERE sr2.sr_item_sk = ws.ws_item_sk
           AND sr2.sr_returned_date_sk = ws.ws_sold_date_sk) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rn
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE i.i_current_price > (SELECT AVG(i2.i_current_price) FROM tpcds.item i2)
)
SELECT
    order_number,
    d_year,
    brand,
    store_name,
    SUM(net_paid) AS total_net_paid,
    COUNT(*) AS sales_count,
    AVG(sales_price) AS avg_sales_price,
    SUM(total_return_amt) AS total_return_amount,
    MAX(rn) AS max_rank_per_order
FROM base
GROUP BY order_number, d_year, brand, store_name
HAVING SUM(net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
