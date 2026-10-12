WITH base AS (
    SELECT
        sr.sr_net_loss,
        sr.sr_store_credit,
        sr.sr_return_quantity,
        s.s_division_name,
        s.s_state,
        CASE 
            WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
            WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
            ELSE 'Other'
        END AS region,
        d_ret.d_year,
        d_ret.d_quarter_name,
        ws.web_mkt_class,
        wp.wp_web_page_id,
        wp.wp_image_count
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_close
        ON s.s_closed_date_sk = d_store_close.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_store_close.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
       AND wp.wp_access_date_sk = d_ws_close.d_date_sk
)
SELECT
    s_division_name,
    d_year,
    web_mkt_class,
    region,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(sr_store_credit) AS total_store_credit,
    AVG(sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wp_web_page_id) AS distinct_web_pages,
    SUM(wp_image_count) AS total_image_count,
    COUNT(*) AS transaction_count
FROM base
GROUP BY GROUPING SETS (
    (s_division_name, d_year, web_mkt_class, region),
    (s_division_name, d_year, web_mkt_class),
    (s_division_name, d_year),
    (web_mkt_class)
)
HAVING SUM(sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
