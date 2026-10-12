WITH returns_by_cc_year AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        d_ret.d_year AS return_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_call_center_id, cc.cc_name, d_ret.d_year
),
sales_by_year AS (
    SELECT
        d_sold.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    GROUP BY d_sold.d_year
),
store_closure_by_year AS (
    SELECT
        d_store.d_year AS store_closed_year,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed,
        SUM(s.s_floor_space) AS total_floor_space_closed
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY d_store.d_year
),
call_center_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        d_open.d_year AS open_year,
        d_closed.d_year AS closed_year,
        cc.cc_employees,
        cc.cc_sq_ft
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
)
SELECT
    r.cc_call_center_id,
    r.cc_name,
    r.return_year,
    r.total_return_amount,
    r.total_net_loss,
    s.total_net_profit,
    s.total_sales,
    s.total_quantity_sold,
    s.total_orders,
    s.avg_ship_delay_days,
    sc.stores_closed,
    sc.total_floor_space_closed,
    cc.open_year,
    cc.closed_year,
    cc.cc_employees,
    cc.cc_sq_ft,
    (s.total_net_profit - r.total_return_amount) AS profit_minus_returns,
    ROW_NUMBER() OVER (PARTITION BY r.return_year ORDER BY (s.total_net_profit - r.total_return_amount) DESC) AS rank_by_profit
FROM returns_by_cc_year r
JOIN sales_by_year s ON r.return_year = s.sales_year
JOIN store_closure_by_year sc ON r.return_year = sc.store_closed_year
JOIN call_center_dates cc ON r.cc_call_center_sk = cc.cc_call_center_sk
WHERE r.return_year >= 2000
ORDER BY profit_minus_returns DESC
LIMIT 100
