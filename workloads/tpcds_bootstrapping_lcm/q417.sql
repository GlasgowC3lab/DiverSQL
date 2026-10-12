WITH returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(*) AS total_returns,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        SUM(CASE WHEN wp.wp_type = 'promo' THEN 1 ELSE 0 END) AS promo_pages,
        COUNT(DISTINCT d_access.d_day_name) AS distinct_access_days,
        MIN(d_ship.d_year) AS first_ship_year,
        MIN(d_sales.d_year) AS first_sales_year,
        MAX(d_closed.d_current_year) AS store_closed_year
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY s.s_store_id, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    store_id,
    return_year,
    month_seq,
    total_net_loss,
    avg_net_loss,
    total_returns,
    distinct_customers,
    distinct_web_pages,
    promo_pages,
    distinct_access_days,
    first_ship_year,
    first_sales_year,
    store_closed_year,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_agg
WHERE return_year = 2022
ORDER BY net_loss_rank
LIMIT 100
