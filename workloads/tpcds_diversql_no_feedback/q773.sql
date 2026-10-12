WITH
    small_date AS (
        SELECT d_date_sk, d_year
        FROM date_dim
        WHERE d_year = 2001
        LIMIT 1
    ),
    flag_set AS (
        SELECT 1 AS flag UNION ALL SELECT 2 AS flag
    ),
    first_part AS (
        SELECT
            p.p_promo_name,
            s.s_store_name,
            d_sold.d_year,
            SUM(cr.cr_net_loss)            AS total_net_loss,
            SUM(ws.ws_net_profit)          AS total_net_profit,
            COUNT(DISTINCT cr.cr_order_number) AS cnt_returns,
            COUNT(DISTINCT ws.ws_order_number) AS cnt_sales
        FROM catalog_returns cr
        JOIN date_dim d_ret           ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN web_sales ws             ON ws.ws_sold_date_sk = d_ret.d_date_sk
        JOIN date_dim d_sold          ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d_promo_start   ON p.p_start_date_sk = d_promo_start.d_date_sk
        JOIN date_dim d_promo_end     ON p.p_end_date_sk = d_promo_end.d_date_sk
        JOIN store s                  ON s.s_closed_date_sk = d_ret.d_date_sk
        JOIN web_site ws_site         ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN date_dim d_site_open     ON ws_site.web_open_date_sk = d_site_open.d_date_sk
        JOIN date_dim d_site_close    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
        CROSS JOIN small_date
        CROSS JOIN flag_set
        WHERE EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = cr.cr_item_sk
              AND ws2.ws_sold_date_sk = cr.cr_returned_date_sk
        )
        GROUP BY ROLLUP (p.p_promo_name, s.s_store_name, d_sold.d_year)
    ),
    second_part AS (
        SELECT
            p.p_promo_name,
            s.s_store_name,
            d_sold.d_year,
            0.0                         AS total_net_loss,
            SUM(ws.ws_net_profit)      AS total_net_profit,
            0                           AS cnt_returns,
            COUNT(DISTINCT ws.ws_order_number) AS cnt_sales
        FROM web_sales ws
        JOIN date_dim d_sold          ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d_promo_start   ON p.p_start_date_sk = d_promo_start.d_date_sk
        JOIN date_dim d_promo_end     ON p.p_end_date_sk = d_promo_end.d_date_sk
        JOIN store s                  ON s.s_closed_date_sk = d_sold.d_date_sk
        JOIN web_site ws_site         ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN date_dim d_site_open     ON ws_site.web_open_date_sk = d_site_open.d_date_sk
        JOIN date_dim d_site_close    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
        CROSS JOIN small_date
        CROSS JOIN flag_set
        WHERE ws.ws_coupon_amt > 1000.00
        GROUP BY ROLLUP (p.p_promo_name, s.s_store_name, d_sold.d_year)
    )
SELECT *
FROM (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
) combined
ORDER BY p_promo_name ASC NULLS LAST,
         s_store_name ASC NULLS LAST,
         d_year ASC NULLS LAST
