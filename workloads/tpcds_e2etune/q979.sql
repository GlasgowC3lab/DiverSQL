WITH agg AS (
    SELECT
        w.web_name,
        wp.wp_type,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
      AND w.web_state = 'CA'
      AND wp.wp_type IS NOT NULL
    GROUP BY w.web_name, wp.wp_type, cd_bill.cd_gender, cd_ship.cd_gender
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT
    web_name,
    wp_type,
    bill_gender,
    ship_gender,
    total_net_paid,
    total_net_profit,
    avg_discount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
