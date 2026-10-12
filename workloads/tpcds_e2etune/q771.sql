WITH web_sales_agg AS (
    SELECT
        i.i_category AS category,
        ws.ws_sold_date_sk AS date_sk,
        sm.sm_type AS ship_mode,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE sm.sm_type = 'AIR'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450365
    GROUP BY i.i_category, ws.ws_sold_date_sk, sm.sm_type
),
store_returns_agg AS (
    SELECT
        i.i_category AS category,
        sr.sr_returned_date_sk AS date_sk,
        s.s_state AS store_state,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_store_credit) AS total_store_credit,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450365
    GROUP BY i.i_category, sr.sr_returned_date_sk, s.s_state
)
SELECT
    ws.category,
    ws.date_sk AS sale_date_sk,
    ws.ship_mode,
    ws.total_sales,
    ws.total_discount,
    ws.total_profit,
    sr.total_return_amount,
    sr.total_refunded_cash,
    sr.total_store_credit,
    (ws.total_sales - COALESCE(sr.total_return_amount, 0)) AS net_revenue,
    (ws.total_profit - COALESCE(sr.total_refunded_cash, 0) - COALESCE(sr.total_store_credit, 0)) AS net_profit_after_returns
FROM web_sales_agg ws
LEFT JOIN store_returns_agg sr
  ON ws.category = sr.category
  AND ws.date_sk = sr.date_sk
WHERE (ws.total_sales - COALESCE(sr.total_return_amount, 0)) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
