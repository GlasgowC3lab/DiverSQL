WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_id,
        s.s_state,
        ss.ss_list_price,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        c.c_customer_id,
        c.c_customer_sk,
        ca.ca_gmt_offset,
        cd.cd_demo_sk,
        hd.hd_buy_potential,
        inv.inv_quantity_on_hand,
        cc.cc_manager,
        cp.cp_catalog_page_id,
        w.w_warehouse_sk
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND cc.cc_manager = 'Richard James'
      AND hd.hd_buy_potential = '>10000'
      AND inv.inv_quantity_on_hand > 500
      AND ss.ss_list_price > 50
      AND ca.ca_gmt_offset BETWEEN -5 AND 5
),
per_customer_store AS (
    SELECT
        c_customer_id,
        c_customer_sk,
        s_store_id,
        d_year,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM base
    GROUP BY c_customer_id, c_customer_sk, s_store_id, d_year
)
SELECT
    pcs.c_customer_id,
    pcs.s_store_id,
    pcs.d_year,
    pcs.total_sales,
    pcs.total_profit,
    pcs.sales_cnt,
    (pcs.total_sales / pcs.sales_cnt) AS avg_sales_per_tx,
    (SELECT SUM(ws.ws_net_profit)
     FROM tpcds.web_sales ws
     WHERE ws.ws_bill_customer_sk = pcs.c_customer_sk) AS total_web_profit_for_customer
FROM per_customer_store pcs
ORDER BY pcs.total_profit DESC
LIMIT 100
