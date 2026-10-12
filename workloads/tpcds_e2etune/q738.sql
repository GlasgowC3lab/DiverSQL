WITH promo_sales AS (
    SELECT
        p.p_promo_name,
        p.p_channel_email,
        p.p_start_date_sk,
        p.p_end_date_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Sports'
      AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY p.p_promo_name, p.p_channel_email, p.p_start_date_sk, p.p_end_date_sk
),
promo_returns AS (
    SELECT
        p.p_promo_name,
        p.p_channel_email,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(wr.wr_order_number) AS return_txns
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer rc
        ON wr.wr_refunded_customer_sk = rc.c_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Sports'
      AND wr.wr_returned_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY p.p_promo_name, p.p_channel_email
)
SELECT
    s.p_promo_name,
    s.p_channel_email,
    s.total_store_profit,
    s.store_txns,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_txns, 0) AS return_txns,
    (s.total_store_profit - COALESCE(r.total_return_loss, 0)) AS net_effect
FROM promo_sales s
LEFT JOIN promo_returns r
    ON s.p_promo_name = r.p_promo_name
   AND s.p_channel_email = r.p_channel_email
ORDER BY net_effect DESC
LIMIT 50
