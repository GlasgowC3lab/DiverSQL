WITH profit_by_mode_promo AS (
    SELECT
        sm.sm_ship_mode_id AS sm_id,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
        d.d_year = 2002
        AND sm.sm_contract = 'A5BYO1qH8HGTTN'
        AND p.p_discount_active = 'Y'
        AND wsite.web_company_id IN (1, 3, 5)
    GROUP BY
        sm.sm_ship_mode_id,
        p.p_promo_name
)
SELECT
    sm_id,
    AVG(total_profit) AS avg_profit
FROM
    profit_by_mode_promo
WHERE
    sm_id NOT IN (
        SELECT sm_ship_mode_id FROM ship_mode WHERE sm_carrier = 'USPS'
    )
GROUP BY
    sm_id
HAVING
    AVG(total_profit) > (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2002
    )
ORDER BY
    avg_profit DESC
LIMIT 100
