WITH intersect_orders AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity > 2
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_net_profit > 0
    ),
    base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_net_paid,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_promo_sk,
            ws.ws_web_site_sk,
            ws.ws_bill_cdemo_sk,
            d.d_date,
            d.d_year,
            t.t_hour,
            p.p_promo_name,
            p.p_channel_radio,
            cc.cc_state,
            cc.cc_division,
            cc.cc_division_name,
            cd.cd_credit_rating,
            cd.cd_dep_count,
            wsit.web_name,
            wsit.web_country
        FROM web_sales ws
        JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN call_center cc
            ON cc.cc_open_date_sk = d.d_date_sk
        JOIN web_site wsit
            ON ws.ws_web_site_sk = wsit.web_site_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year = 2001
          AND t.t_hour BETWEEN 9 AND 17
          AND p.p_channel_radio = 'N'
          AND cc.cc_state = 'CA'
          AND cd.cd_credit_rating = 'Good'
          AND wsit.web_country = 'USA'
    )
SELECT
    b.ws_order_number,
    b.d_date,
    b.t_hour,
    b.p_promo_name,
    b.cc_division_name,
    b.cd_credit_rating,
    b.ws_quantity,
    b.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY b.cc_division ORDER BY b.ws_net_profit DESC) AS profit_rank,
    COUNT(DISTINCT b.ws_order_number) OVER (PARTITION BY b.cc_division) AS distinct_orders_per_div,
    COUNT(DISTINCT b.ws_item_sk) OVER () AS total_distinct_items
FROM base b
JOIN intersect_orders io
    ON b.ws_order_number = io.ws_order_number
WHERE b.ws_net_profit > 0
ORDER BY profit_rank ASC, b.ws_net_profit DESC
OFFSET 0 LIMIT 100
