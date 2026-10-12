WITH cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cc.cc_name,
    i.i_brand,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    AVG(ws.ws_net_paid) AS avg_web_paid,
    MIN(cs.cs_net_paid) AS min_sale,
    MAX(cs.cs_net_paid) AS max_sale
FROM cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
LEFT JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
WHERE
    i.i_color = 'turquoise'
    AND cc.cc_mkt_id = 3
    AND i.i_wholesale_cost > 10.00
    AND hd.hd_vehicle_count >= 2
GROUP BY
    cc.cc_name,
    i.i_brand,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
