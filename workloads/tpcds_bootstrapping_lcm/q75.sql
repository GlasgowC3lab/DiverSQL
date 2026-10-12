WITH
sales_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_state,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
        AVG(ws.ws_quantity) AS avg_quantity_sold,
        SUM(CASE WHEN ws.ws_coupon_amt > 0 THEN 1 ELSE 0 END) AS coupon_orders,
        AVG(date_diff('day', d.d_date, d_ship.d_date)) AS avg_days_to_ship,
        AVG(d_wp_creation.d_year) AS avg_page_creation_year,
        AVG(d_wp_access.d_year) AS avg_page_access_year,
        SUM(CASE WHEN d_wp_access.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_page_accesses
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    GROUP BY
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_state,
        wp.wp_type
),
returns_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_fee) AS total_return_fee,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_state
)
SELECT
    COALESCE(sa.d_year, ra.d_year) AS year,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_num,
    CASE
        WHEN COALESCE(sa.d_month_seq, ra.d_month_seq) BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    COALESCE(sa.s_state, ra.s_state) AS state,
    sa.wp_type,
    sa.web_order_cnt,
    ra.return_order_cnt,
    sa.total_web_sales,
    sa.total_web_profit,
    sa.total_ext_sales_price,
    ra.total_return_amount,
    ra.total_return_loss,
    ra.total_return_fee,
    sa.avg_quantity_sold,
    sa.coupon_orders,
    sa.avg_days_to_ship,
    sa.avg_page_creation_year,
    sa.avg_page_access_year,
    sa.weekend_page_accesses
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.d_date_sk = ra.d_date_sk
    AND sa.s_state = ra.s_state
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
ORDER BY
    year,
    month_num,
    state,
    wp_type
