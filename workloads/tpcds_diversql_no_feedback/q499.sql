WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        AVG(ws_sales_price)      AS avg_sales_price,
        COUNT(*)                 AS ws_cnt
    FROM web_sales
    WHERE ws_sales_price > 10
    GROUP BY ws_order_number, ws_item_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    r.r_reason_desc,
    ws_agg.total_net_paid,
    ws_agg.avg_sales_price,
    COUNT(*)                                 AS return_cnt,
    SUM(wr.wr_return_amt)                    AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ws_agg.total_net_paid DESC) AS gender_rank
FROM ws_agg
JOIN web_returns wr
    ON ws_agg.ws_order_number = wr.wr_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    cd.cd_marital_status = 'M'
    AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
    AND wr.wr_return_amt > 50
    AND cs.cs_quantity BETWEEN 1 AND 5
    AND ws_agg.total_net_paid > (
        SELECT AVG(cs_ext_discount_amt)
        FROM catalog_sales
        WHERE cs_quantity = 1
    )
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = ws_agg.ws_order_number
          AND cs2.cs_quantity > 5
    )
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    r.r_reason_desc,
    ws_agg.total_net_paid,
    ws_agg.avg_sales_price
ORDER BY total_return_amount DESC
LIMIT 100
