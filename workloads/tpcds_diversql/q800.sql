WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        p.p_promo_name,
        ws.ws_promo_sk,
        d.d_year,
        w.web_name,
        regexp_extract(p.p_promo_name, '(\\d{3})', 1) AS promo_code
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(p.p_promo_name, '\\d{3}')
      AND w.web_name LIKE '%Shop%'
),
returns AS (
    SELECT
        wr.wr_order_number,
        r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage')
),
intersect_set AS (
    SELECT ws_order_number FROM sales
    INTERSECT
    SELECT wr_order_number FROM returns
),
exempt_set AS (
    SELECT ws_order_number FROM sales WHERE ws_quantity > 10
),
final_keys AS (
    SELECT ws_order_number FROM intersect_set
    EXCEPT
    SELECT ws_order_number FROM exempt_set
),
agg AS (
    SELECT
        p.p_promo_name,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        LAG(SUM(ws.ws_net_profit)) OVER (PARTITION BY p.p_promo_sk ORDER BY d.d_year) AS lag_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_net_profit > (
        SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2
    )
    GROUP BY p.p_promo_name, d.d_year, p.p_promo_sk
)
SELECT *
FROM (
    SELECT
        f.ws_order_number,
        CAST(NULL AS varchar) AS promo_name,
        CAST(NULL AS integer) AS year,
        CAST(NULL AS bigint) AS orders_cnt,
        CAST(NULL AS decimal(15,2)) AS total_profit,
        CAST(NULL AS decimal(15,2)) AS lag_profit
    FROM final_keys f
    UNION DISTINCT
    SELECT
        CAST(NULL AS integer) AS ws_order_number,
        a.p_promo_name,
        a.d_year,
        a.orders_cnt,
        a.total_profit,
        a.lag_profit
    FROM agg a
) AS combined
ORDER BY ws_order_number, promo_name
LIMIT 100
