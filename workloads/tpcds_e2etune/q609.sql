WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ws.ws_web_site_sk, ws.ws_promo_sk, ws.ws_sold_date_sk
),
returns_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_sold_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ws.ws_web_site_sk, ws.ws_promo_sk, ws.ws_sold_date_sk
)
SELECT
    s.ws_sold_date_sk AS sold_date_sk,
    site.web_name,
    promo.p_promo_name,
    s.total_net_paid,
    s.total_discount,
    s.total_net_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    (s.total_net_paid - COALESCE(r.total_return_amt, 0)) AS net_paid_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_web_site_sk = r.ws_web_site_sk
   AND s.ws_promo_sk = r.ws_promo_sk
   AND s.ws_sold_date_sk = r.ws_sold_date_sk
JOIN web_site site
    ON s.ws_web_site_sk = site.web_site_sk
JOIN promotion promo
    ON s.ws_promo_sk = promo.p_promo_sk
WHERE promo.p_discount_active = 'Y'
  AND (promo.p_channel_email = 'Y' OR promo.p_channel_tv = 'Y')
ORDER BY net_profit_after_returns DESC
LIMIT 100
