WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_class_id,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_radio,
        p.p_response_target
    FROM tpcds.item i
    FULL OUTER JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (4, 6, 9)
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_radio = 'N'
      AND p.p_response_target > 0
),
sales_with_returns AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_addr_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_ext_list_price,
        r.total_return_qty,
        r.total_return_amt
    FROM tpcds.web_sales ws
    LEFT JOIN LATERAL (
        SELECT
            SUM(wr.wr_return_quantity) AS total_return_qty,
            SUM(wr.wr_return_amt) AS total_return_amt
        FROM tpcds.web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
    ) r ON TRUE
    WHERE ws.ws_ship_addr_sk IN (3252549, 527861, 4379475)
      AND ws.ws_ext_list_price > 500
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
) 
SELECT
    ip.i_brand,
    ip.i_class_id,
    ip.p_promo_name,
    swr.ws_ship_addr_sk,
    SUM(swr.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT swr.ws_order_number) AS distinct_orders,
    AVG(swr.ws_ext_discount_amt) AS avg_discount,
    MIN(swr.ws_net_profit) AS min_profit,
    MAX(swr.ws_net_profit) AS max_profit,
    SUM(COALESCE(swr.total_return_qty, 0)) AS total_return_qty,
    SUM(COALESCE(swr.total_return_amt, 0)) AS total_return_amt
FROM item_promo ip
JOIN sales_with_returns swr
    ON swr.ws_item_sk = ip.i_item_sk
   AND swr.ws_promo_sk = ip.p_promo_sk
GROUP BY CUBE (ip.i_brand, ip.i_class_id, ip.p_promo_name, swr.ws_ship_addr_sk)
ORDER BY total_net_paid DESC
LIMIT 100
