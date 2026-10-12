WITH key_diff AS (
    SELECT cd.cd_demo_sk
    FROM customer_demographics cd
    JOIN store_sales ss ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 70
    EXCEPT
    SELECT cd.cd_demo_sk
    FROM customer_demographics cd
    JOIN web_sales ws ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_quantity < 10
), agg_all AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_store_sk) AS store_count,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_paid) AS avg_store_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        MIN(ws.ws_net_paid) AS min_web_net_paid,
        MAX(ws.ws_net_paid) AS max_web_net_paid
    FROM customer_demographics cd
    JOIN store_sales ss ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 3
      AND ss.ss_quantity BETWEEN 20 AND 80
      AND wp.wp_image_count >= 4
      AND web.web_state = 'CA'
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    a.cd_demo_sk,
    a.cd_gender,
    a.cd_marital_status,
    a.store_count,
    a.total_quantity,
    a.avg_store_net_paid,
    a.total_web_net_paid,
    a.min_web_net_paid,
    a.max_web_net_paid
FROM agg_all a
WHERE a.cd_demo_sk IN (SELECT cd_demo_sk FROM key_diff)
ORDER BY a.total_web_net_paid DESC
LIMIT 100
