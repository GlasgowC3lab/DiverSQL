WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        MAX(wr_return_tax) AS max_return_tax
    FROM web_returns
    WHERE wr_return_tax > 20
    GROUP BY wr_order_number
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_net_profit,
    i.i_item_id,
    i.i_brand,
    sm.sm_code,
    ws_site.web_site_id,
    ws_site.web_city,
    ra.total_return_amt,
    ra.return_cnt,
    SUM(ws.ws_net_profit) OVER (
        PARTITION BY ws_site.web_site_id
        ORDER BY ws.ws_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit,
    RANK() OVER (
        PARTITION BY ws_site.web_site_id
        ORDER BY ra.total_return_amt DESC
    ) AS return_rank
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
WHERE
    i.i_brand = 'BrandX'
    AND sm.sm_contract IN ('qENFQ', '6Hzzp4JkzjqD8MGXLCDa')
    AND ws_site.web_city = 'Spring Hill'
    AND ws.ws_sold_date_sk BETWEEN 2451500 AND 2451900
    AND ws.ws_item_sk IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_category = 'CategoryA'
    )
ORDER BY ws_site.web_site_id, ws.ws_sold_date_sk DESC
LIMIT 100
