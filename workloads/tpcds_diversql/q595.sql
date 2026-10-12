WITH
    promo_sales AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            p.p_channel_catalog,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            AVG(ws.ws_net_profit) AS avg_profit,
            COUNT(*) AS order_cnt,
            MIN(ws.ws_ext_sales_price) AS min_sale,
            MAX(ws.ws_ext_sales_price) AS max_sale
        FROM promotion p
        JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_channel_catalog = 'N'
          AND p.p_promo_sk IN (3, 4, 10, 16, 18)
          AND ws.ws_net_paid_inc_ship_tax > 1000
          AND ws.ws_quantity >= 2
          AND ws.ws_ship_customer_sk <> 7963718
          AND ws.ws_ship_cdemo_sk BETWEEN 200000 AND 800000
        GROUP BY p.p_promo_sk, p.p_promo_id, p.p_channel_catalog
    ),
    promo_sales_all AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            AVG(ws.ws_net_profit) AS avg_profit,
            COUNT(*) AS order_cnt
        FROM promotion p
        JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_channel_catalog = 'N'
          AND p.p_promo_sk IN (3, 4, 10, 16, 18)
          AND ws.ws_net_paid_inc_ship_tax > 1000
          AND ws.ws_quantity >= 2
          AND ws.ws_ship_customer_sk <> 7963718
          AND ws.ws_ship_cdemo_sk BETWEEN 200000 AND 800000
        GROUP BY p.p_promo_sk, p.p_promo_id
    )
SELECT
    ps.p_promo_sk,
    ps.p_promo_id,
    ps.total_sales,
    ps.avg_profit,
    ps.order_cnt,
    (
        SELECT MAX(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = ps.p_promo_sk
    ) AS max_discount,
    (
        SELECT COUNT(*)
        FROM web_sales ws3
        WHERE ws3.ws_promo_sk = ps.p_promo_sk
          AND ws3.ws_ext_sales_price > ps.avg_profit
    ) AS high_sales_cnt
FROM promo_sales ps
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ps.p_promo_sk
          AND p2.p_purpose = 'Unknown'
    )
  AND ps.p_promo_sk NOT IN (
        SELECT p3.p_promo_sk
        FROM promotion p3
        WHERE p3.p_channel_tv = 'Y'
    )
EXCEPT
SELECT
    pa.p_promo_sk,
    pa.p_promo_id,
    pa.total_sales,
    pa.avg_profit,
    pa.order_cnt,
    (
        SELECT MAX(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = pa.p_promo_sk
    ) AS max_discount,
    (
        SELECT COUNT(*)
        FROM web_sales ws3
        WHERE ws3.ws_promo_sk = pa.p_promo_sk
          AND ws3.ws_ext_sales_price > pa.avg_profit
    ) AS high_sales_cnt
FROM promo_sales_all pa
ORDER BY total_sales DESC
