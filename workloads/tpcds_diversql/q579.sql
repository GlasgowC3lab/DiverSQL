WITH
    sr_agg AS (
        SELECT
            sr_returned_date_sk,
            sr_return_time_sk,
            sr_store_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_net_loss) AS total_net_loss
        FROM store_returns
        GROUP BY sr_returned_date_sk, sr_return_time_sk, sr_store_sk
    ),
    promo_not_used AS (
        SELECT p_promo_sk
        FROM promotion
        EXCEPT
        SELECT ws_promo_sk
        FROM web_sales
    ),
    intersect_promos AS (
        SELECT ws_promo_sk
        FROM web_sales
        INTERSECT
        SELECT p_promo_sk
        FROM promotion
        WHERE p_discount_active = 'Y'
    )
SELECT
    d_sale.d_year,
    d_sale.d_month_seq,
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.total_return_amt) AS total_returns,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
        ELSE SUM(sr.total_return_amt) / SUM(ws.ws_ext_sales_price)
    END AS return_rate,
    MAX(CASE WHEN ws.ws_net_paid > (
            SELECT AVG(ws2.ws_net_paid)
            FROM web_sales ws2
        ) THEN 1 ELSE 0 END) AS high_avg_flag,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    SUM(u.metric) AS metric_sum
FROM
    web_sales ws
    /* sold date */
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    /* sold time */
    JOIN time_dim t_sale ON ws.ws_sold_time_sk = t_sale.t_time_sk
    /* web page */
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    /* promotion */
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    /* promotion start date */
    JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
    /* promotion end date */
    JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
    /* web page creation date */
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    /* web page access date */
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    /* aggregated store returns */
    LEFT JOIN sr_agg sr ON ws.ws_sold_date_sk = sr.sr_returned_date_sk
        AND ws.ws_sold_time_sk = sr.sr_return_time_sk
    /* return date */
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    /* return time */
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    /* unnest two numeric metrics per sale */
    CROSS JOIN UNNEST(ARRAY[ws.ws_quantity, CAST(ws.ws_sales_price AS double)]) AS u(metric)
WHERE
    p.p_promo_sk IN (SELECT ws_promo_sk FROM intersect_promos)
    AND p.p_promo_sk NOT IN (SELECT p_promo_sk FROM promo_not_used)
GROUP BY
    d_sale.d_year,
    d_sale.d_month_seq,
    p.p_promo_name
ORDER BY
    d_sale.d_year,
    d_sale.d_month_seq,
    total_sales DESC
LIMIT 100
