WITH aggregated AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_type,
        d_start.d_year AS catalog_start_year,
        d_end.d_year AS catalog_end_year,
        ws.web_name,
        s.s_market_id,
        s.s_division_name,
        COUNT(DISTINCT ws_sales.ws_order_number) AS distinct_orders,
        SUM(ws_sales.ws_quantity) AS total_quantity,
        SUM(ws_sales.ws_net_paid) AS total_net_paid,
        SUM(ws_sales.ws_net_profit) AS total_net_profit,
        AVG(ws_sales.ws_sales_price) AS avg_sales_price,
        MAX(ws_sales.ws_coupon_amt) AS max_coupon_amount,
        MIN(ws_sales.ws_ext_discount_amt) AS min_discount_amount,
        SUM(CASE WHEN d_ship.d_month_seq = d_start.d_month_seq THEN ws_sales.ws_net_profit ELSE 0 END) AS net_profit_same_month_as_catalog_start
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_start.d_date_sk
    JOIN web_sales ws_sales
        ON ws_sales.ws_web_site_sk = ws.web_site_sk
    JOIN date_dim d_sold
        ON ws_sales.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws_sales.ws_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ws_close.d_date_sk
    WHERE d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
      AND d_ship.d_date BETWEEN d_start.d_date AND d_end.d_date
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_type,
        d_start.d_year,
        d_end.d_year,
        ws.web_name,
        s.s_market_id,
        s.s_division_name
    HAVING SUM(ws_sales.ws_net_profit) > 0
)
SELECT
    cp_catalog_page_id,
    cp_catalog_number,
    cp_type,
    catalog_start_year,
    catalog_end_year,
    web_name,
    s_market_id,
    s_division_name,
    distinct_orders,
    total_quantity,
    total_net_paid,
    total_net_profit,
    avg_sales_price,
    max_coupon_amount,
    min_discount_amount,
    net_profit_same_month_as_catalog_start,
    ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_id ORDER BY total_net_profit DESC) AS sales_rank_by_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
