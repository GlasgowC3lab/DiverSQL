WITH base AS (
    SELECT
        d_ws.d_year,
        hd.hd_buy_potential,
        p.p_promo_name,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        AVG(ws.ws_quantity) AS avg_ws_quantity,
        MIN(cs.cs_sales_price) AS min_cs_sales_price,
        MAX(p.p_cost) AS max_promo_cost
    FROM web_sales ws
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year BETWEEN 1998 AND 2000
      AND ib.ib_upper_bound >= 50000
      AND ib.ib_lower_bound <= 150000
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'content'
      AND cs.cs_quantity > 1
      AND ws.ws_quantity < 5
    GROUP BY
        d_ws.d_year,
        hd.hd_buy_potential,
        p.p_promo_name,
        wp.wp_type
)
SELECT
    d_year,
    hd_buy_potential,
    p_promo_name,
    wp_type,
    orders,
    total_ws_net_paid,
    total_cs_net_paid,
    avg_ws_quantity,
    min_cs_sales_price,
    max_promo_cost,
    LAG(total_ws_net_paid) OVER (PARTITION BY hd_buy_potential ORDER BY d_year) AS lag_total_ws_net_paid
FROM base
ORDER BY total_ws_net_paid DESC
LIMIT 100
