WITH sales_summary AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        MIN(ws_ship_date_sk) AS first_ship_date_sk,
        MAX(ws_ship_date_sk) AS last_ship_date_sk
    FROM web_sales
    WHERE ws_quantity > 5
      AND ws_net_paid > 100.00
      AND ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ws_order_number, ws_item_sk
),
joined_data AS (
    SELECT
        s.ws_item_sk,
        ws.ws_ship_mode_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(s.total_net_paid) AS total_sales_net_paid,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        CASE
            WHEN SUM(s.total_net_paid) = 0 THEN 0
            ELSE SUM(wr.wr_return_amt) / SUM(s.total_net_paid)
        END AS return_to_sales_ratio
    FROM sales_summary s
    JOIN web_returns wr
        ON s.ws_order_number = wr.wr_order_number
       AND s.ws_item_sk = wr.wr_item_sk
    JOIN web_sales ws
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0.00
      AND ws.ws_ship_mode_sk IS NOT NULL
    GROUP BY s.ws_item_sk, ws.ws_ship_mode_sk
    HAVING SUM(wr.wr_return_amt) > 500.00
),
ranked_data AS (
    SELECT
        jd.*,
        RANK() OVER (PARTITION BY jd.ws_ship_mode_sk ORDER BY jd.total_return_amount DESC) AS ship_mode_return_rank,
        (SELECT COUNT(*) FROM store) AS total_stores
    FROM joined_data jd
)
SELECT
    ws_item_sk,
    ws_ship_mode_sk,
    return_count,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    total_sales_net_paid,
    avg_return_qty,
    return_to_sales_ratio,
    ship_mode_return_rank,
    total_stores
FROM ranked_data
ORDER BY total_return_amount DESC
LIMIT 100
