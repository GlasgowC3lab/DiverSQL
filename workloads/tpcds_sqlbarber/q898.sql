SELECT
    sm.sm_ship_mode_id,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    (SELECT ws2.ws_order_number
     FROM web_sales ws2
     WHERE ws2.ws_sold_date_sk = 2450884
     LIMIT 1) AS example_order_number
FROM
    catalog_returns cr
    INNER JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    cr.cr_returned_date_sk = 2450918
    AND cs.cs_sold_date_sk = 2450820
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_ship_mode_sk
HAVING
    SUM(cr.cr_return_amount) > 829.40
