WITH joined AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_hours,
        dr.d_date,
        dr.d_year,
        tr.t_shift,
        w.w_warehouse_id,
        w.w_country,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state AS customer_state,
        hd.hd_income_band_sk,
        wp.wp_url,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM catalog_returns cr
    RIGHT OUTER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr
        ON cr.cr_returned_time_sk = tr.t_time_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON dr.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = dr.d_date_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND tr.t_shift = 'first'
      AND w.w_country = 'United States'
      AND p.p_discount_active = 'N'
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    SUM(ws_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank,
    hour_part
FROM joined
CROSS JOIN UNNEST(split(cc_hours, ',')) AS t(hour_part)
GROUP BY s_store_id, s_store_name, d_year, hour_part
ORDER BY d_year, profit_rank
LIMIT 100
