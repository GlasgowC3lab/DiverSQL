WITH sales_agg AS (
    SELECT
        i.i_category,
        sm.sm_type,
        cd.cd_marital_status,
        d_sold.d_quarter_name,
        wsit.web_state,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cp.cp_type = 'monthly'
      AND d_sold.d_year = 2000
      AND wsit.web_state = 'CA'
    GROUP BY i.i_category, sm.sm_type, cd.cd_marital_status, d_sold.d_quarter_name, wsit.web_state
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    i_category,
    sm_type,
    cd_marital_status,
    d_quarter_name,
    web_state,
    distinct_customers,
    total_net_profit,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY sm_type ORDER BY total_net_profit DESC) AS profit_rank_by_shipmode
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 50
