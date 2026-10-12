WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
intersected_customers AS (
    SELECT sr.sr_customer_sk AS cust_sk FROM store_returns sr
    INTERSECT
    SELECT wr.wr_refunded_customer_sk AS cust_sk FROM web_returns wr
),
main_join AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        c.c_customer_id,
        c.c_customer_sk,
        ca.ca_state,
        s.s_store_name,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        we.web_country,
        r.r_reason_desc,
        wp.wp_url,
        w.w_warehouse_name,
        sr_agg.total_return_amt,
        sr_agg.cnt_returns
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                           AND sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN sr_agg ON sr_agg.sr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 30
      AND sm.sm_contract = 'YvxVaJI10'
      AND ca.ca_state = 'CA'
      AND we.web_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
      AND c.c_customer_sk IN (SELECT cust_sk FROM intersected_customers)
),
-- LATERAL sampling of a small fraction of store_returns for the same item
lateral_sample AS (
    SELECT
        mj.*,
        lt.sampled_return_qty
    FROM main_join mj
    CROSS JOIN LATERAL (
        SELECT sr2.sr_return_quantity AS sampled_return_qty
        FROM store_returns sr2
        TABLESAMPLE BERNOULLI (5)
        WHERE sr2.sr_item_sk = mj.i_item_sk
        LIMIT 1
    ) lt
),
final_agg AS (
    SELECT
        i_item_id,
        i_product_name,
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(total_return_amt, 0)) AS total_returns,
        AVG(ws_net_profit) AS avg_profit,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ws_ext_sales_price) DESC) AS rn_state,
        LAG(SUM(ws_ext_sales_price)) OVER (PARTITION BY ca_state ORDER BY SUM(ws_ext_sales_price)) AS lag_sales
    FROM lateral_sample
    GROUP BY i_item_id, i_product_name, ca_state
    HAVING SUM(ws_ext_sales_price) > (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales
        WHERE ws_sold_date_sk < 2452000
    )
)
SELECT *
FROM final_agg
WHERE rn_state = 1
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
