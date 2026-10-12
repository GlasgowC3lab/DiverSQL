WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_bill_cdemo_sk,
        ws_ship_cdemo_sk,
        ws_web_page_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS item_cnt
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_sales_price > 0
    GROUP BY ws_order_number, ws_bill_cdemo_sk, ws_ship_cdemo_sk, ws_web_page_sk
),
wp_segments AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        segment
    FROM web_page wp
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(segment)
    WHERE wp.wp_url IS NOT NULL
)
SELECT
    ws_agg.ws_order_number,
    ws_agg.total_profit,
    ws_agg.item_cnt,
    wr.wr_net_loss,
    sr.sr_net_loss,
    cd.cd_gender,
    td.t_time_id,
    wp_seg.segment,
    RANK() OVER (ORDER BY ws_agg.total_profit DESC) AS profit_rank
FROM ws_agg
JOIN web_returns wr
    ON wr.wr_order_number = ws_agg.ws_order_number
JOIN customer_demographics cd
    ON cd.cd_demo_sk = ws_agg.ws_bill_cdemo_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td
    ON td.t_time_sk = sr.sr_return_time_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws_agg.ws_web_page_sk
JOIN wp_segments wp_seg
    ON wp_seg.wp_web_page_sk = wp.wp_web_page_sk
WHERE cd.cd_gender = 'M'
  AND td.t_second BETWEEN 10 AND 30
  AND wr.wr_net_loss > 1000
  AND sr.sr_return_amt > 150
  AND wp.wp_type = 'Content'
ORDER BY profit_rank, ws_agg.total_profit DESC
LIMIT 100
