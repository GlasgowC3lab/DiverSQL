WITH
    sr_agg AS (
        SELECT
            sr_returned_date_sk,
            sr_store_sk,
            SUM(sr_net_loss) AS total_store_loss,
            COUNT(*) AS cnt_store_returns
        FROM store_returns
        WHERE sr_return_quantity > 0
          AND sr_return_amt > 0
        GROUP BY sr_returned_date_sk, sr_store_sk
    ),
    ws_agg AS (
        SELECT
            ws_sold_date_sk,
            ws_web_page_sk,
            SUM(ws_net_profit) AS total_web_profit,
            COUNT(*) AS cnt_web_sales
        FROM web_sales
        WHERE ws_quantity > 0
          AND ws_sales_price > 0
        GROUP BY ws_sold_date_sk, ws_web_page_sk
    ),
    cr_agg AS (
        SELECT
            cr_returned_date_sk,
            cr_refunded_customer_sk,
            SUM(cr_net_loss) AS total_catalog_loss,
            COUNT(*) AS cnt_catalog_returns
        FROM catalog_returns
        WHERE cr_return_amount > 0
          AND cr_return_quantity > 0
        GROUP BY cr_returned_date_sk, cr_refunded_customer_sk
    ),
    intersect_dates AS (
        SELECT sr_returned_date_sk AS d_date_sk
        FROM store_returns
        GROUP BY sr_returned_date_sk
        INTERSECT
        SELECT ws_sold_date_sk
        FROM web_sales
        GROUP BY ws_sold_date_sk
    )
SELECT
    d.d_date,
    s.s_store_name,
    wp.wp_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    SUM(sr_agg.total_store_loss) AS sum_store_loss,
    SUM(ws_agg.total_web_profit) AS sum_web_profit,
    SUM(cr_agg.total_catalog_loss) AS sum_catalog_loss,
    COUNT(DISTINCT sr_agg.sr_returned_date_sk) AS distinct_store_dates,
    COUNT(DISTINCT ws_agg.ws_sold_date_sk) AS distinct_web_dates
FROM intersect_dates id
JOIN date_dim d ON id.d_date_sk = d.d_date_sk
JOIN sr_agg ON sr_agg.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN cr_agg ON cr_agg.cr_returned_date_sk = d.d_date_sk
JOIN customer c ON cr_agg.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws_agg ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 120 AND 130
  AND d.d_holiday = 'N'
  AND s.s_state = 'CA'
  AND ib.ib_lower_bound >= 30000
  AND hd.hd_buy_potential LIKE '%500-1000%'
  AND wp.wp_type = 'content'
GROUP BY d.d_date, s.s_store_name, wp.wp_type, hd.hd_buy_potential, ib.ib_lower_bound
ORDER BY sum_store_loss DESC
LIMIT 100
