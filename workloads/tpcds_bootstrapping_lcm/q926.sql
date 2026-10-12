WITH sales_summary AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_company_name,
        cc.cc_city,
        st.s_store_name,
        st.s_state,
        p.p_promo_name,
        d_closed.d_year,
        d_closed.d_month_seq,
        d_ship.d_month_seq            AS ship_month_seq,
        d_promo_start.d_date          AS promo_start_date,
        d_promo_end.d_date            AS promo_end_date,
        SUM(ws.ws_net_paid)           AS total_net_paid,
        SUM(ws.ws_quantity)           AS total_quantity,
        AVG(ws.ws_ext_discount_amt)   AS avg_discount_amt
    FROM call_center cc
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store st
        ON st.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_closed.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_closed.d_year = 2022
      AND st.s_state = 'CA'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_company_name,
        cc.cc_city,
        st.s_store_name,
        st.s_state,
        p.p_promo_name,
        d_closed.d_year,
        d_closed.d_month_seq,
        d_ship.d_month_seq,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_paid DESC) AS store_rank
FROM sales_summary
ORDER BY total_net_paid DESC
LIMIT 100
