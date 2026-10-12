WITH date_filter AS (
   SELECT DISTINCT cs.cs_sold_date_sk AS date_sk
   FROM catalog_sales cs
   WHERE cs.cs_net_paid > 1000
),

catalog_part AS (
   SELECT
       cs.cs_sold_date_sk AS date_sk,
       sm.sm_ship_mode_id AS ship_mode_id,
       SUM(cs.cs_net_profit) AS metric_value,
       'CATALOG' AS source
   FROM catalog_sales cs
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE sm.sm_type = 'AIR'
     AND td.t_shift = 'first'
     AND cd.cd_gender = 'M'
     AND cs.cs_sold_date_sk IN (SELECT date_sk FROM date_filter)
   GROUP BY cs.cs_sold_date_sk, sm.sm_ship_mode_id
),

web_part AS (
   SELECT
       ws.ws_sold_date_sk AS date_sk,
       wp.wp_url,
       segment,
       SUM(wr.wr_net_loss) AS metric_value,
       'WEB_RETURN' AS source
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(segment)
   WHERE td.t_am_pm = 'AM'
     AND cd.cd_gender = 'F'
     AND ws.ws_sold_date_sk IN (SELECT date_sk FROM date_filter)
   GROUP BY ws.ws_sold_date_sk, wp.wp_url, segment
)

SELECT
    date_sk,
    source,
    metric_value,
    ship_mode_id,
    wp_url,
    segment
FROM (
    SELECT date_sk, source, metric_value, ship_mode_id, NULL AS wp_url, NULL AS segment FROM catalog_part
    UNION ALL
    SELECT date_sk, source, metric_value, NULL AS ship_mode_id, wp_url, segment FROM web_part
) final
ORDER BY date_sk DESC, source
