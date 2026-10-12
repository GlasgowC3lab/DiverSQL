WITH joined_data AS (
  SELECT
    site.web_name AS site_name,
    cd_ret.cd_gender AS gender,
    cr.cr_return_amount AS return_amount,
    ws.ws_net_paid AS net_paid,
    ws.ws_order_number AS order_number,
    wp.wp_url AS page_url
  FROM catalog_returns cr
  LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  LEFT JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN time_dim td_ret
    ON cr.cr_returned_time_sk = td_ret.t_time_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td_ret.t_time_sk
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN time_dim td_extra
    ON cr.cr_returned_time_sk = td_extra.t_time_sk
  RIGHT OUTER JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
),
expanded AS (
  SELECT
    jd.*,
    url_part
  FROM joined_data jd
  CROSS JOIN UNNEST(split(jd.page_url, '/')) AS t(url_part)
),
aggregated AS (
  SELECT
    site_name,
    gender,
    SUM(return_amount)               AS total_return_amount,
    SUM(net_paid)                    AS total_sales,
    COUNT(DISTINCT order_number)     AS distinct_orders,
    COUNT(url_part)                  AS url_part_count
  FROM expanded
  GROUP BY ROLLUP (site_name, gender)
)
SELECT
  site_name,
  gender,
  total_return_amount,
  total_sales,
  distinct_orders,
  url_part_count,
  ROW_NUMBER() OVER (PARTITION BY site_name ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
