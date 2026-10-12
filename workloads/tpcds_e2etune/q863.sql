WITH pref_mex_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_country = 'MEXICO'
      AND c.c_preferred_cust_flag = 'Y'
),
sales_filtered AS (
    SELECT ws.ws_ship_mode_sk,
           ws.ws_web_site_sk,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_quantity
    FROM web_sales ws
    JOIN pref_mex_customers pc ON ws.ws_bill_customer_sk = pc.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450200
),
agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        wsit.web_market_manager,
        SUM(sales.ws_net_profit) AS total_net_profit,
        AVG(sales.ws_ext_discount_amt) AS avg_discount,
        SUM(sales.ws_quantity) AS total_quantity
    FROM sales_filtered sales
    JOIN ship_mode sm ON sales.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON sales.ws_web_site_sk = wsit.web_site_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, wsit.web_market_manager
    HAVING SUM(sales.ws_net_profit) > 0
),
ranked AS (
    SELECT
        agg.*, 
        RANK() OVER (PARTITION BY agg.web_market_manager ORDER BY agg.total_net_profit DESC) AS profit_rank
    FROM agg
)
SELECT
    sm_ship_mode_id,
    sm_type,
    web_market_manager,
    total_net_profit,
    avg_discount,
    total_quantity,
    profit_rank
FROM ranked
WHERE profit_rank <= 3
ORDER BY web_market_manager, profit_rank
