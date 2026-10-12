WITH
income_loss AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND cr.cr_fee >= 0
      AND cr.cr_return_ship_cost < 5000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
store_hd_full AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        hd.hd_demo_sk,
        hd.hd_income_band_sk
    FROM store_returns sr
    FULL OUTER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE (sr.sr_return_quantity > 0 OR sr.sr_return_quantity IS NULL)
      AND (hd.hd_vehicle_count >= 0 OR hd.hd_vehicle_count IS NULL)
      AND (sr.sr_return_ship_cost > 0 OR sr.sr_return_ship_cost IS NULL)
),
web_sales_detail AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        wp.wp_web_page_id,
        wsit.web_name,
        ib.ib_income_band_sk,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_web_site_sk) AS profit_by_site,
        COUNT(wr.wr_return_quantity) AS web_return_count
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws.ws_quantity > 0
      AND ws.ws_sales_price > 0
      AND ws.ws_net_profit <> 0
      AND wsit.web_state IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_site_sk, ws.ws_net_profit,
             wp.wp_web_page_id, wsit.web_name, ib.ib_income_band_sk
),
union_data AS (
    SELECT
        ib_income_band_sk,
        total_net_loss AS metric,
        'INCOME_LOSS' AS src
    FROM income_loss
    UNION DISTINCT
    SELECT
        ws_web_site_sk AS ib_income_band_sk,
        SUM(ws_net_profit) AS metric,
        'WEB_PROFIT' AS src
    FROM web_sales_detail
    GROUP BY ws_web_site_sk
),
order_intersect AS (
    SELECT cr_order_number AS order_num FROM catalog_returns cr WHERE cr.cr_return_quantity > 0
    INTERSECT
    SELECT wr_order_number FROM web_returns wr WHERE wr.wr_return_quantity > 0
)
SELECT
    u.ib_income_band_sk,
    u.metric,
    u.src,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_hdemo_sk = hd.hd_demo_sk) AS store_return_count,
    CASE WHEN u.metric > 5000 THEN 'BIG' ELSE 'SMALL' END AS metric_level,
    CASE WHEN EXISTS (SELECT 1 FROM order_intersect oi WHERE oi.order_num = u.ib_income_band_sk) THEN 1 ELSE 0 END AS has_common_order
FROM union_data u
JOIN income_band i ON u.ib_income_band_sk = i.ib_income_band_sk
JOIN household_demographics hd ON i.ib_income_band_sk = hd.hd_income_band_sk
ORDER BY u.metric DESC, u.src
