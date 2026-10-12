WITH union_data AS (
  /* Store sales branch */
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    CAST(NULL AS varchar) AS carrier,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_amount,
    CASE WHEN ss.ss_quantity > 100 THEN 'HIGH' ELSE 'LOW' END AS volume_category,
    (SELECT AVG(i3.i_current_price)
       FROM item i3
      WHERE i3.i_category = i.i_category) AS avg_price_category
  FROM store_sales ss
  JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  RIGHT OUTER JOIN store s      ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr  ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN ship_mode sm        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
  LEFT JOIN reason r            ON r.r_reason_sk = cr.cr_reason_sk
  LEFT JOIN call_center cc      ON cc.cc_call_center_sk = cr.cr_call_center_sk
  LEFT JOIN catalog_page cp     ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
  LEFT JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_page wp          ON wp.wp_web_page_sk = wr.wr_web_page_sk
  LEFT JOIN web_site ws          ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND s.s_state = 'CA'
  UNION
  /* Catalog returns branch */
  SELECT
    d2.d_year AS year,
    d2.d_moy AS month,
    sm2.sm_carrier AS carrier,
    cr2.cr_return_quantity AS quantity,
    cr2.cr_return_amount + cr2.cr_return_tax AS net_amount,
    CASE WHEN cr2.cr_return_quantity > 100 THEN 'HIGH' ELSE 'LOW' END AS volume_category,
    (SELECT AVG(i4.i_current_price)
       FROM item i4
      WHERE i4.i_category = i2.i_category) AS avg_price_category
  FROM catalog_returns cr2
  JOIN date_dim d2               ON cr2.cr_returned_date_sk = d2.d_date_sk
  JOIN time_dim t2               ON cr2.cr_returned_time_sk = t2.t_time_sk
  JOIN item i2                  ON cr2.cr_item_sk = i2.i_item_sk
  JOIN household_demographics hd2 ON cr2.cr_refunded_hdemo_sk = hd2.hd_demo_sk
  JOIN ship_mode sm2            ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN reason r2                ON cr2.cr_reason_sk = r2.r_reason_sk
  JOIN call_center cc2          ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
  JOIN catalog_page cp2         ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
  LEFT JOIN store s2            ON s2.s_closed_date_sk = d2.d_date_sk
  LEFT JOIN inventory inv2       ON inv2.inv_item_sk = i2.i_item_sk AND inv2.inv_date_sk = d2.d_date_sk
  LEFT JOIN web_returns wr2     ON wr2.wr_returned_date_sk = d2.d_date_sk
  LEFT JOIN web_page wp2         ON wp2.wp_web_page_sk = wr2.wr_web_page_sk
  LEFT JOIN web_site ws2         ON ws2.web_open_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2001
    AND sm2.sm_carrier = 'FEDEX'
    AND cp2.cp_department = 'Electronics'
)
SELECT
  year,
  month,
  carrier,
  volume_category,
  SUM(net_amount) AS total_net_amount,
  COUNT(*)      AS transaction_count,
  AVG(net_amount) AS avg_net_amount,
  MIN(net_amount) AS min_net_amount,
  MAX(net_amount) AS max_net_amount
FROM union_data
GROUP BY year, month, carrier, volume_category
ORDER BY total_net_amount DESC
LIMIT 100
