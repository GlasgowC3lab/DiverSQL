WITH base AS (
    SELECT
        cp.cp_department,
        s.s_state,
        wp.wp_type,
        t.t_hour,
        cr.cr_return_amount,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        wr.wr_account_credit,
        sr.sr_return_time_sk,
        t.t_time_sk
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    RIGHT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    cp_department,
    s_state,
    wp_type,
    t_hour,
    SUM(cr_return_amount)               AS total_return_amount,
    SUM(store_net_loss)                  AS total_store_net_loss,
    SUM(web_net_loss)                    AS total_web_net_loss,
    SUM(ws_ext_sales_price)              AS total_sales_price,
    SUM(ws_net_profit)                   AS total_net_profit,
    COUNT(*)                             AS transaction_cnt
FROM base
WHERE cr_return_amount > 100.00
  AND sr_return_time_sk IN (37700, 34073)
  AND wr_account_credit > 0
  AND ws_sold_date_sk BETWEEN 2451483 AND 2452224
  AND s_state = 'CA'
GROUP BY ROLLUP (cp_department, s_state, wp_type, t_hour)

UNION DISTINCT

SELECT
    cp_department,
    s_state,
    wp_type,
    t_hour,
    SUM(cr_return_amount)               AS total_return_amount,
    SUM(store_net_loss)                  AS total_store_net_loss,
    SUM(web_net_loss)                    AS total_web_net_loss,
    SUM(ws_ext_sales_price)              AS total_sales_price,
    SUM(ws_net_profit)                   AS total_net_profit,
    COUNT(*)                             AS transaction_cnt
FROM base
WHERE cr_return_amount > 200.00
  AND t_hour = 14
  AND wp_type = 'home'
  AND s_state = 'NY'
  AND wr_account_credit < 50
GROUP BY ROLLUP (cp_department, s_state, wp_type, t_hour)
LIMIT 100
