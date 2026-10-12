SELECT
    t.*,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        d_cc_open.d_year AS cc_open_year,
        d_promo_start.d_year AS promo_start_year,
        d_promo_end.d_year AS promo_end_year,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND d_cc_open.d_year <= d_sold.d_year
      AND d_sold.d_year BETWEEN d_promo_start.d_year AND d_promo_end.d_year
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_ship.d_year,
        d_cc_open.d_year,
        d_promo_start.d_year,
        d_promo_end.d_year
) t
ORDER BY total_sales DESC
LIMIT 100
