WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_order_number,
        r.r_reason_desc,
        s.s_store_id,
        s.s_state,
        s.s_tax_percentage,
        d_ret.d_year,
        d_ret.d_month_seq,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_ret.d_year = 2001
      AND d_ret.d_month_seq BETWEEN 1200 AND 1212
      AND r.r_reason_desc = 'Gift exchange'
      AND s.s_state = 'CA'
      AND s.s_tax_percentage > 5.0
      AND ws.ws_net_paid_inc_ship_tax > 3000.00
      AND cr.cr_return_quantity > 0
),
agg_data AS (
    SELECT
        s_store_id,
        s_state,
        r_reason_desc,
        d_year,
        d_month_seq,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
        COUNT(DISTINCT cr_order_number) AS cnt_return_orders,
        AVG(ws_quantity) AS avg_quantity,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(ws_net_paid_inc_ship_tax) AS max_net_paid,
        CASE WHEN SUM(cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_level,
        (
            SELECT SUM(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = agg_data.d_year
        ) AS profit_in_year
    FROM joined_data agg_data
    GROUP BY
        s_store_id,
        s_state,
        r_reason_desc,
        d_year,
        d_month_seq
)
SELECT
    s_store_id,
    s_state,
    r_reason_desc,
    d_year,
    d_month_seq,
    total_return_amount,
    total_net_paid_inc_ship_tax,
    cnt_return_orders,
    avg_quantity,
    min_return_amount,
    max_net_paid,
    return_level,
    profit_in_year,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM agg_data
ORDER BY total_return_amount DESC, rn
LIMIT 100
