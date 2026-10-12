WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
full_date_site AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.web_site_sk,
        s.web_name,
        s.web_mkt_id,
        s.web_city,
        s.web_state
    FROM date_dim d
    FULL OUTER JOIN web_site s
        ON s.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.web_mkt_id IN (1, 3, 5)
)
SELECT
    combined.d_year,
    combined.web_name,
    combined.orders_cnt,
    combined.total_paid_inc_ship,
    combined.avg_coupon,
    combined.min_profit,
    combined.max_profit,
    combined.site_total_profit
FROM (
    SELECT
        f.d_year,
        f.web_name,
        COUNT(s.ws_order_number) AS orders_cnt,
        SUM(s.ws_net_paid_inc_ship) AS total_paid_inc_ship,
        AVG(s.ws_coupon_amt) AS avg_coupon,
        MIN(s.ws_net_profit) AS min_profit,
        MAX(s.ws_net_profit) AS max_profit,
        (
            SELECT SUM(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = f.web_site_sk
        ) AS site_total_profit
    FROM full_date_site f
    LEFT JOIN sampled_sales s
        ON s.ws_sold_date_sk = f.d_date_sk
    WHERE s.ws_quantity > 2
      AND s.ws_ext_discount_amt < 500
      AND f.web_mkt_id <> 2
      AND (f.d_year = 2001 OR f.d_year = 2002)
      AND s.ws_net_paid_inc_ship BETWEEN 1000 AND 8000
      AND EXISTS (
            SELECT 1
            FROM web_site ws3
            WHERE ws3.web_site_sk = f.web_site_sk
              AND ws3.web_city = 'San Francisco'
        )
    GROUP BY f.d_year, f.web_name, f.web_site_sk
    HAVING COUNT(s.ws_order_number) > 5

    UNION DISTINCT

    SELECT
        f.d_year,
        f.web_name,
        COUNT(s.ws_order_number) AS orders_cnt,
        SUM(s.ws_net_paid_inc_ship) AS total_paid_inc_ship,
        AVG(s.ws_coupon_amt) AS avg_coupon,
        MIN(s.ws_net_profit) AS min_profit,
        MAX(s.ws_net_profit) AS max_profit,
        (
            SELECT SUM(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = f.web_site_sk
        ) AS site_total_profit
    FROM full_date_site f
    LEFT JOIN sampled_sales s
        ON s.ws_ship_date_sk = f.d_date_sk
    WHERE s.ws_quantity <= 5
      AND s.ws_ext_discount_amt >= 200
      AND f.web_mkt_id = 3
      AND f.d_year = 2001
      AND s.ws_net_paid_inc_ship > 2000
      AND EXISTS (
            SELECT 1
            FROM web_site ws3
            WHERE ws3.web_site_sk = f.web_site_sk
              AND ws3.web_state = 'CA'
        )
    GROUP BY f.d_year, f.web_name, f.web_site_sk
    HAVING COUNT(s.ws_order_number) > 3
) AS combined
ORDER BY combined.total_paid_inc_ship DESC
LIMIT 100
