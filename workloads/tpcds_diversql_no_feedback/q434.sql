WITH filtered_returns AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_net_loss,
        wp.wp_url,
        ws.ws_web_site_sk
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason rs ON wr.wr_reason_sk = rs.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = ws.ws_item_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.pdf$')
      AND rs.r_reason_desc LIKE '%damaged%'
      AND wr.wr_returning_hdemo_sk IN (
          SELECT hd_demo_sk
          FROM household_demographics
          WHERE hd_vehicle_count >= 2
      )
)
SELECT
    concat(substring(ws.web_name, 1, 10), '_', regexp_extract(fr.wp_url, 'https?://([^/]+)/', 1)) AS site_domain_key,
    td.t_hour,
    sum(fr.wr_net_loss) AS total_net_loss,
    count(*) AS return_cnt
FROM filtered_returns fr
JOIN time_dim td ON fr.wr_returned_time_sk = td.t_time_sk
JOIN web_site ws ON fr.ws_web_site_sk = ws.web_site_sk
GROUP BY
    concat(substring(ws.web_name, 1, 10), '_', regexp_extract(fr.wp_url, 'https?://([^/]+)/', 1)),
    td.t_hour
ORDER BY total_net_loss DESC
LIMIT 100
