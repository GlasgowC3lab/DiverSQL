WITH
catalog_sales_agg AS (
    SELECT
        p.p_promo_id,
        ca.ca_state,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(cs.cs_net_paid) AS catalog_sales_amount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY p.p_promo_id, ca.ca_state
),
catalog_returns_agg AS (
    SELECT
        p.p_promo_id,
        ca.ca_state,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY p.p_promo_id, ca.ca_state
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(ws.ws_net_paid) AS web_sales_amount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY p.p_promo_id, ca.ca_state
),
store_returns_agg AS (
    SELECT
        ca.ca_state,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amount
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ca.ca_state
)
SELECT
    cs.p_promo_id,
    cs.ca_state,
    cs.catalog_sales_profit,
    cr.catalog_return_loss,
    ws.web_sales_profit,
    sr.store_return_loss
FROM catalog_sales_agg cs
LEFT JOIN catalog_returns_agg cr
    ON cs.p_promo_id = cr.p_promo_id
    AND cs.ca_state = cr.ca_state
LEFT JOIN web_sales_agg ws
    ON cs.p_promo_id = ws.p_promo_id
    AND cs.ca_state = ws.ca_state
LEFT JOIN store_returns_agg sr
    ON cs.ca_state = sr.ca_state
WHERE cs.catalog_sales_profit > 0
ORDER BY cs.catalog_sales_profit DESC
LIMIT 100
