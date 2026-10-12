WITH
    store_agg AS (
        SELECT
            i.i_item_id AS item_id,
            ss.ss_sold_date_sk AS sold_date_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(*) AS order_cnt
        FROM tpcds.store_sales ss
        JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
        JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE t.t_hour BETWEEN 9 AND 17
          AND i.i_color = 'yellow'
          AND cd.cd_purchase_estimate > (
                SELECT AVG(cd2.cd_purchase_estimate)
                FROM tpcds.customer_demographics cd2
                WHERE cd2.cd_education_status = 'College'
            )
        GROUP BY i.i_item_id, ss.ss_sold_date_sk
    ),
    web_agg AS (
        SELECT
            i.i_item_id AS item_id,
            ws.ws_sold_date_sk AS sold_date_sk,
            SUM(ws.ws_net_paid) AS total_net_paid,
            COUNT(*) AS order_cnt
        FROM tpcds.web_sales ws
        JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
        JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN tpcds.household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        WHERE t.t_hour BETWEEN 9 AND 17
          AND i.i_color = 'yellow'
          AND hd.hd_income_band_sk = (
                SELECT MIN(hd2.hd_income_band_sk)
                FROM tpcds.household_demographics hd2
            )
        GROUP BY i.i_item_id, ws.ws_sold_date_sk
    )
SELECT
    item_id,
    sold_date_sk,
    total_net_paid,
    order_cnt
FROM store_agg
UNION ALL
SELECT
    item_id,
    sold_date_sk,
    total_net_paid,
    order_cnt
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
