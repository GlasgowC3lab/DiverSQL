WITH sales_agg AS (
    SELECT
        ws_web_page_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(ws_quantity) AS avg_qty
    FROM tpcds.web_sales
    WHERE ws_quantity > 5
    GROUP BY ws_web_page_sk, ws_bill_cdemo_sk, ws_bill_hdemo_sk
)
SELECT
    wp.wp_web_page_id,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(sa.total_net_paid) AS total_sales,
    SUM(sa.order_cnt) AS total_orders,
    AVG(sa.avg_qty) AS avg_quantity_per_group
FROM sales_agg sa
JOIN tpcds.web_page wp
    ON sa.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.customer_demographics cd
    ON sa.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON sa.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
  AND cd.cd_education_status = 'College'
  AND hd.hd_buy_potential = '1001-5000'
  AND wp.wp_web_page_sk IN (
        SELECT ws_web_page_sk
        FROM tpcds.web_sales
        WHERE ws_ext_discount_amt > 0
    )
GROUP BY wp.wp_web_page_id, cd.cd_gender, hd.hd_vehicle_count
HAVING SUM(sa.total_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
