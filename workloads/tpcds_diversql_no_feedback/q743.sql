SELECT category,
       total_return,
       source
FROM (
    SELECT i.i_category AS category,
           SUM(cr.cr_return_amount) AS total_return,
           'CATALOG' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2020
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_category
    UNION
    SELECT i.i_category AS category,
           SUM(sr.sr_return_amt) AS total_return,
           'STORE' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND i.i_class = 'Electronics'
    GROUP BY i.i_category
) AS combined
ORDER BY category,
         total_return DESC
LIMIT 100
