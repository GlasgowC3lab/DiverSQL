WITH
    inventory_items AS (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 100
    ),
    ws_items AS (
        SELECT DISTINCT ws_item_sk
        FROM web_sales
    ),
    sr_items AS (
        SELECT DISTINCT sr_item_sk
        FROM store_returns
    ),
    exclusive_ws_items AS (
        SELECT ws_item_sk
        FROM ws_items
        EXCEPT
        SELECT sr_item_sk
        FROM sr_items
    ),
    website_words AS (
        SELECT ws.web_site_sk,
               word
        FROM web_site ws
        CROSS JOIN UNNEST(split(ws.web_street_name, ' ')) AS t(word)
    )
SELECT *
FROM (
    SELECT
        i.i_item_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        sm.sm_type,
        site.web_state,
        ww.word,
        SUM(ws.ws_net_paid)                               AS total_net_paid,
        COUNT(*)                                           AS sales_cnt,
        AVG(ws.ws_ext_discount_amt)                        AS avg_discount,
        COUNT(DISTINCT site.web_suite_number)              AS suite_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN inventory_items ii ON i.i_item_sk = ii.inv_item_sk
    JOIN website_words ww ON site.web_site_sk = ww.web_site_sk
    WHERE i.i_category = 'Sports'
      AND site.web_city = 'New York'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_item_sk IN (SELECT ws_item_sk FROM exclusive_ws_items)
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 200
      )
    GROUP BY i.i_item_id, cd.cd_gender, hd.hd_vehicle_count, sm.sm_type, site.web_state, ww.word

    UNION DISTINCT

    SELECT
        i.i_item_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        CAST(NULL AS varchar)                         AS sm_type,
        CAST(NULL AS varchar)                         AS web_state,
        CAST(NULL AS varchar)                         AS word,
        SUM(sr.sr_net_loss)                            AS total_net_paid,
        COUNT(*)                                        AS sales_cnt,
        AVG(sr.sr_return_amt)                          AS avg_discount,
        0                                               AS suite_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE i.i_category = 'Sports'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_item_sk IN (SELECT ws_item_sk FROM exclusive_ws_items)
    GROUP BY i.i_item_id, cd.cd_gender, hd.hd_vehicle_count
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
