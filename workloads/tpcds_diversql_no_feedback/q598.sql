WITH base AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        sm.sm_type,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        r.r_reason_desc,
        t.t_am_pm,
        we.web_country
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%price%'
      AND we.web_country = 'United States'
      AND ws.ws_item_sk IN (
          SELECT DISTINCT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 100
      )
      AND t.t_am_pm = 'PM'
),
agg1 AS (
    SELECT
        d_year,
        w_warehouse_name,
        sm_type,
        SUM(ws_ext_sales_price) AS yearly_sales,
        COUNT(DISTINCT ws_order_number) AS orders_cnt
    FROM base
    GROUP BY d_year, w_warehouse_name, sm_type
    HAVING SUM(ws_ext_sales_price) > 10000
)
SELECT
    d_year,
    w_warehouse_name,
    sm_type,
    yearly_sales,
    orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY yearly_sales DESC) AS sales_rank,
    AVG(yearly_sales) OVER (PARTITION BY sm_type) AS avg_sales_by_ship_type
FROM agg1
WHERE yearly_sales > (SELECT AVG(yearly_sales) FROM agg1)
ORDER BY yearly_sales DESC
LIMIT 100
