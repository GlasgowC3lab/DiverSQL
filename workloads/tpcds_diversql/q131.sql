WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CONCAT(CAST(ws.ws_web_site_sk AS VARCHAR), '-', CAST(ws.ws_promo_sk AS VARCHAR)) AS site_promo_key
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_web_site_sk, ws.ws_promo_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
    GROUP BY wr.wr_order_number, wr.wr_returned_date_sk
)
SELECT
    COALESCE(sa.ws_order_number, ra.wr_order_number) AS order_number,
    COALESCE(sa.ws_sold_date_sk, ra.wr_returned_date_sk) AS date_sk,
    (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) AS net_amount,
    sa.sales_cnt,
    ra.returns_cnt,
    CASE
        WHEN sa.site_promo_key IS NOT NULL AND regexp_like(sa.site_promo_key, '^\\d+-\\d+$')
        THEN regexp_extract(sa.site_promo_key, '(\\d+)-(\\d+)', 1)
        ELSE NULL
    END AS extracted_site_sk,
    CASE
        WHEN wsit.web_name IS NOT NULL AND regexp_like(wsit.web_name, 'Shop.*')
        THEN substr(wsit.web_name, 1, 10)
        ELSE NULL
    END AS shop_name_prefix,
    CASE
        WHEN p.p_promo_name IS NOT NULL AND regexp_like(p.p_promo_name, '.*Discount.*')
        THEN p.p_promo_name
        ELSE NULL
    END AS discount_promo_name,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0)) DESC) AS rn
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.ws_order_number = ra.wr_order_number
LEFT JOIN web_site wsit
    ON sa.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN promotion p
    ON sa.ws_promo_sk = p.p_promo_sk
WHERE (
        sa.site_promo_key LIKE '%1%'
        OR ra.returns_cnt IS NOT NULL
      )
ORDER BY net_amount DESC
LIMIT 100
