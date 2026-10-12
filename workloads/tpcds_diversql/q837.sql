WITH max_price AS (
    SELECT max(ws2.ws_ext_sales_price) AS max_sp
    FROM web_sales ws2
)
SELECT *
FROM (
    SELECT
        'Web' AS return_source,
        i.i_item_id,
        i.i_product_name,
        ws.ws_ext_sales_price AS amount,
        CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        CASE WHEN ws.ws_ext_sales_price > (SELECT max_sp FROM max_price) THEN 'Above Max' ELSE 'Below Max' END AS price_flag,
        dim.region,
        tag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    CROSS JOIN (VALUES (1, 'North'), (2, 'South')) AS dim(region_id, region)
    CROSS JOIN UNNEST(array['promo','sale']) AS t(tag)
    WHERE i.i_rec_start_date >= DATE '2000-01-01'

    UNION ALL

    SELECT
        'Store' AS return_source,
        i.i_item_id,
        i.i_product_name,
        sr.sr_return_amt AS amount,
        CASE WHEN sr.sr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        CASE WHEN sr.sr_return_amt > (SELECT max_sp FROM max_price) THEN 'Above Max' ELSE 'Below Max' END AS price_flag,
        dim.region,
        tag
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN (VALUES (1, 'North'), (2, 'South')) AS dim(region_id, region)
    CROSS JOIN UNNEST(array['return','adjust']) AS t(tag)
    WHERE s.s_state = 'CA'
) AS combined
LIMIT 100
