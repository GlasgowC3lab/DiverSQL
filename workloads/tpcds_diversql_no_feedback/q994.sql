WITH base AS (
    SELECT
        d.d_year,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        sm.sm_type,
        r.r_reason_desc,
        ca.ca_state,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_refunded_cash
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'EXPRESS'
      AND r.r_reason_desc LIKE '%price%'
      AND cc.cc_state = 'CA'
      AND we.web_country = 'United States'
      AND inv.inv_quantity_on_hand > 100
      AND ws.ws_net_profit > 0
),
agg AS (
    SELECT
        d_year,
        sm_type,
        COUNT(DISTINCT ws_order_number) AS orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        SUM(wr_refunded_cash) AS total_refunded
    FROM base
    GROUP BY d_year, sm_type
)
SELECT
    a.sm_type,
    a.grand_sales,
    a.avg_profit_across_years,
    a.total_refunded,
    c.val AS dummy_val
FROM (
    SELECT
        sm_type,
        SUM(total_sales) AS grand_sales,
        AVG(avg_profit) AS avg_profit_across_years,
        SUM(total_refunded) AS total_refunded
    FROM agg
    GROUP BY sm_type
    HAVING SUM(total_sales) > 100000
) a
CROSS JOIN (SELECT 1 AS val UNION ALL SELECT 2) c
ORDER BY a.grand_sales DESC
LIMIT 100
