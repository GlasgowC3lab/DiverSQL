/*
Goal: Analyze total sales and returns per customer and product category, including promotional cost, risk flags and metric sums, while showing subtotals (ROLLUP), top‑5 categories per customer, and expanding a derived metric array.
*/
WITH joined_data AS (
    SELECT
        c_bill.c_customer_id,
        i.i_category,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        wr.wr_net_loss,
        sr.sr_net_loss,
        promo.p_cost,
        cd_bill.cd_credit_rating,
        ARRAY[ws.ws_quantity, ws.ws_ext_sales_price] AS metrics_array
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN promotion promo
        ON ws.ws_promo_sk = promo.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c_bill.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
),
expanded AS (
    SELECT
        jd.*, 
        metric_value
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.metrics_array) AS t(metric_value)
),
aggregated AS (
    SELECT
        c_customer_id,
        i_category,
        SUM(ws_net_paid) AS total_sales,
        SUM(wr_net_loss) AS total_web_returns,
        SUM(sr_net_loss) AS total_store_returns,
        AVG(p_cost) AS avg_promo_cost,
        SUM(CASE WHEN cd_credit_rating = 'High Risk' THEN 1 ELSE 0 END) AS high_risk_count,
        SUM(metric_value) AS sum_metrics
    FROM expanded
    GROUP BY ROLLUP (c_customer_id, i_category)
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_sales DESC) AS rn
    FROM aggregated
)
SELECT
    c_customer_id,
    i_category,
    total_sales,
    total_web_returns,
    total_store_returns,
    avg_promo_cost,
    high_risk_count,
    sum_metrics
FROM ranked
WHERE (c_customer_id IS NOT NULL AND rn <= 5)  -- top‑5 categories per customer
   OR c_customer_id IS NULL                      -- keep subtotal & grand‑total rows
ORDER BY c_customer_id, i_category
LIMIT 100
